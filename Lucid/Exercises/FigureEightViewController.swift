//
//  FigureEightViewController.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/16/26.
//

import UIKit
import ARKit

class FigureEightViewController: UIViewController, ARSessionDelegate, CAAnimationDelegate {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!

    private var trackLayer: CAShapeLayer?
    private let arSession = ARSession()
    private var isLookingAtScreen = false
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private var isExerciseActive = true // Master kill switch
        
    private enum ExercisePhase {
        case none, tracking
    }
    private var currentPhase: ExercisePhase = .none

    private var gazeTimer: Timer?
    private var countdownRemaining = 0
    private var isAnimationPaused = false
    private var sessionStartTime: Date?
    private var currentLoopIndex = 0
    private var currentPath: UIBezierPath?
    private var isSecondPart = false
    private var hasStartedCountdown = false
    private var totalFramesChecked = 0
    private var totalErrors = 0
    private var isFinished = false

    override var prefersStatusBarHidden: Bool { return true }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        errorHapticGenerator.prepare()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        checkOrientationAndAdvance()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isExerciseActive = true
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isExerciseActive = false
        arSession.pause()
        gazeTimer?.invalidate(); gazeTimer = nil
        circleView.layer.removeAllAnimations()
        instructionLabel.layer.removeAllAnimations()
        trackLayer?.removeFromSuperlayer(); trackLayer = nil
        self.tabBarController?.tabBar.isHidden = false
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
        currentPhase = .none
        isAnimationPaused = false
    }

    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        circleView.backgroundColor = .accent
        instructionLabel.alpha = 0
        circleView.alpha = 0
        centerMessageLabel.alpha = 1
        instructionLabel.isHidden = false
        circleView.isHidden = false
        centerMessageLabel.isHidden = false
    }
        
    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = showExerciseUI ? 1 : 0
        }) { _ in
            completion?()
        }
    }

    private func startInitialCountdown() {
        currentPhase = .none
        countdownRemaining = 5
        centerMessageLabel.text = "\(countdownRemaining)"
            
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isExerciseActive, self.currentPhase == .none else {
                timer.invalidate()
                return
            }
            self.countdownRemaining -= 1
                
            if self.countdownRemaining > 0 {
                self.centerMessageLabel.text = "\(self.countdownRemaining)"
            } else {
                timer.invalidate()
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    guard self.isExerciseActive, self.currentPhase == .none else { return }
                    self.sessionStartTime = Date()
                    self.showPreparationMessage()
                }
            }
        }
    }
        
    private func showPreparationMessage() {
        currentPhase = .none
        centerMessageLabel.text = "Keep the phone as close as possible\nand move your eyes with the yellow dot"
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                guard self.isExerciseActive, self.currentPhase == .none else { return }
                self.startFigureEightPhase()
            }
        }
    }
        
    private func checkOrientationAndAdvance() {
        guard !isFinished else { return }
        let isLandscape = view.bounds.width > view.bounds.height
        let isPortrait = !isLandscape
        
        if !isSecondPart {
            if isLandscape {
                if !hasStartedCountdown {
                    hasStartedCountdown = true
                    centerMessageLabel.alpha = 1
                    startInitialCountdown()
                } else if currentPhase == .tracking {
                    centerMessageLabel.alpha = 0
                    circleView.alpha = 1
                    trackLayer?.opacity = 1
                    
                    // Re-draw path for current landscape bounds
                    currentPath = createInfinityPath(isVertical: false)
                    if let path = currentPath {
                        drawBackgroundTrack(with: path)
                    }
                    
                    if isAnimationPaused {
                        resumeLayer(layer: circleView.layer)
                        isAnimationPaused = false
                    }
                    startGazeMonitor()
                }
            } else {
                // If they rotate back to portrait, pause it
                if hasStartedCountdown {
                    if currentPhase == .tracking {
                        if !isAnimationPaused {
                            pauseLayer(layer: circleView.layer)
                            isAnimationPaused = true
                        }
                        circleView.alpha = 0
                        trackLayer?.opacity = 0
                        gazeTimer?.invalidate()
                    }
                    centerMessageLabel.text = "Rotate phone to Landscape"
                    centerMessageLabel.alpha = 1
                } else {
                    centerMessageLabel.text = "Rotate phone to Landscape"
                    centerMessageLabel.alpha = 1
                }
            }
        } else {
            if isPortrait {
                if currentPhase == .none {
                    startSecondPhaseTracking()
                } else if currentPhase == .tracking {
                    centerMessageLabel.alpha = 0
                    circleView.alpha = 1
                    trackLayer?.opacity = 1
                    
                    // Re-draw path for current portrait bounds
                    currentPath = createInfinityPath(isVertical: true)
                    if let path = currentPath {
                        drawBackgroundTrack(with: path)
                    }
                    
                    if isAnimationPaused {
                        resumeLayer(layer: circleView.layer)
                        isAnimationPaused = false
                    }
                    startGazeMonitor()
                }
            } else {
                // If they rotate back to landscape during Phase 2, pause it
                if currentPhase == .tracking {
                    if !isAnimationPaused {
                        pauseLayer(layer: circleView.layer)
                        isAnimationPaused = true
                    }
                    circleView.alpha = 0
                    trackLayer?.opacity = 0
                    gazeTimer?.invalidate()
                }
                centerMessageLabel.text = "Halfway there!\nRotate phone to Portrait"
                centerMessageLabel.alpha = 1
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.checkOrientationAndAdvance()
        }, completion: nil)
    }

    private func startFigureEightPhase() {
        currentPhase = .tracking
        currentLoopIndex = 0
        isAnimationPaused = false
        resetLayerSpeed(layer: circleView.layer)
            
        instructionLabel.text = "Keep the phone close and track the yellow dot"
        instructionLabel.textColor = .lightGray
        instructionLabel.alpha = 1
            
        currentPath = createInfinityPath(isVertical: false)
        if let path = currentPath {
            drawBackgroundTrack(with: path)
        }
            
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self else { return }
            self.startGazeMonitor()
            self.startFigureEightAnimation()
        }
    }

    private func startSecondPhaseTracking() {
        currentPhase = .tracking
        currentLoopIndex = 0
        isAnimationPaused = false
        resetLayerSpeed(layer: circleView.layer)
        
        instructionLabel.text = "Keep the phone close and track the yellow dot"
        instructionLabel.textColor = .lightGray
        instructionLabel.alpha = 1
        
        currentPath = createInfinityPath(isVertical: true)
        if let path = currentPath {
            drawBackgroundTrack(with: path)
        }
        
        centerMessageLabel.alpha = 0
        circleView.alpha = 1
        trackLayer?.opacity = 1
        
        startGazeMonitor()
        startFigureEightAnimation()
    }
        
    private func createInfinityPath(isVertical: Bool) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        if isVertical {
            // Vertical figure eight (loops top and bottom)
            let loopHeight = ((view.bounds.height - 180) / 2) * 0.80
            let loopWidth = min(view.bounds.width - 40, ((view.bounds.height - 180) / 2) * 0.8) * 0.80
            
            path.move(to: center)
            path.addCurve(to: CGPoint(x: center.x, y: center.y - loopHeight),
                          controlPoint1: CGPoint(x: center.x - loopWidth, y: center.y - loopHeight / 2),
                          controlPoint2: CGPoint(x: center.x - loopWidth, y: center.y - loopHeight))
            path.addCurve(to: center,
                          controlPoint1: CGPoint(x: center.x + loopWidth, y: center.y - loopHeight),
                          controlPoint2: CGPoint(x: center.x + loopWidth, y: center.y - loopHeight / 2))
            
            path.addCurve(to: CGPoint(x: center.x, y: center.y + loopHeight),
                          controlPoint1: CGPoint(x: center.x - loopWidth, y: center.y + loopHeight / 2),
                          controlPoint2: CGPoint(x: center.x - loopWidth, y: center.y + loopHeight))
            path.addCurve(to: center,
                          controlPoint1: CGPoint(x: center.x + loopWidth, y: center.y + loopHeight),
                          controlPoint2: CGPoint(x: center.x + loopWidth, y: center.y + loopHeight / 2))
        } else {
            // Horizontal figure eight (loops left and right) — fits in portrait
            let screenWidth = view.bounds.width
            let loopWidth = ((screenWidth - 60) / 2) * 0.80
            let loopHeight = loopWidth * 0.55
            
            path.move(to: center)
            path.addCurve(to: CGPoint(x: center.x + loopWidth, y: center.y),
                          controlPoint1: CGPoint(x: center.x + loopWidth / 2, y: center.y - loopHeight),
                          controlPoint2: CGPoint(x: center.x + loopWidth, y: center.y - loopHeight))
            path.addCurve(to: center,
                          controlPoint1: CGPoint(x: center.x + loopWidth, y: center.y + loopHeight),
                          controlPoint2: CGPoint(x: center.x + loopWidth / 2, y: center.y + loopHeight))
            
            path.addCurve(to: CGPoint(x: center.x - loopWidth, y: center.y),
                          controlPoint1: CGPoint(x: center.x - loopWidth / 2, y: center.y - loopHeight),
                          controlPoint2: CGPoint(x: center.x - loopWidth, y: center.y - loopHeight))
            path.addCurve(to: center,
                          controlPoint1: CGPoint(x: center.x - loopWidth, y: center.y + loopHeight),
                          controlPoint2: CGPoint(x: center.x - loopWidth / 2, y: center.y + loopHeight))
        }
        return path
    }
        
    private func drawBackgroundTrack(with path: UIBezierPath) {
        trackLayer?.removeFromSuperlayer()
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = UIColor.darkGray.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 5.0
        layer.lineCap = .round
        layer.lineJoin = .round
        view.layer.insertSublayer(layer, below: circleView.layer)
        self.trackLayer = layer
    }
        
    private func startFigureEightAnimation() {
        guard isExerciseActive, currentPhase == .tracking, let path = currentPath else { return }
            
        if currentLoopIndex >= 5 {
            if !isSecondPart {
                promptRotationPhase()
            } else {
                finishExercise()
            }
            return
        }
            
        let loopDurations: [CFTimeInterval] = [10.0, 8.0, 6.5, 5.0, 4.0]
        let currentDuration = loopDurations[currentLoopIndex]
            
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        animation.duration = currentDuration
        animation.repeatCount = 1
        animation.calculationMode = .paced
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.delegate = self
            
        circleView.layer.removeAllAnimations()
        circleView.layer.add(animation, forKey: "figureEightAnimation_\(currentLoopIndex)")
    }
        
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if isExerciseActive && flag && currentPhase == .tracking {
            currentLoopIndex += 1
            resetLayerSpeed(layer: circleView.layer)
            isAnimationPaused = false
            startFigureEightAnimation()
        }
    }
        
    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isExerciseActive, self.currentPhase == .tracking else { return }
            
            self.totalFramesChecked += 1
            
            let isLooking = true
                
            if isLooking {
                if self.isAnimationPaused {
                    self.resumeLayer(layer: self.circleView.layer)
                    self.isAnimationPaused = false
                }
                if self.instructionLabel.alpha != 0 {
                    UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
                }
            }
        }
    }
        
    private func pauseLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }

    private func resumeLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
        
    private func resetLayerSpeed(layer: CALayer) {
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
    }
        
    private func promptRotationPhase() {
        currentPhase = .none
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
        circleView.layer.speed = 0.0
        circleView.transform = .identity
        isSecondPart = true
            
        UIView.animate(withDuration: 0.5) { self.trackLayer?.opacity = 0 }
        centerMessageLabel.text = "Halfway there!\nRotate phone to Portrait"
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
    }
        
    private func finishExercise() {
        isFinished = true
        currentPhase = .none
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
        circleView.layer.speed = 0.0
        circleView.transform = .identity
        
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
        
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(
            type: "Figure8",
            duration: elapsedSeconds,
            accuracy: accuracy,
            errors: totalErrors
        )
        newSession.user = user
        context.insert(newSession)
        
        do {
            try context.save()
            errorHapticGenerator.notificationOccurred(.success)
        } catch {
            print("❌ Figure Eight Save failed: \(error)")
        }
            
        UIView.animate(withDuration: 0.5) { self.trackLayer?.opacity = 0 }
        let messages = [
            "Well done!",
            "Fantastic job!",
            "Great work!",
            "Awesome focus!",
            "Excellent effort!",
            "Superb session!",
            "Nicely done!",
            "Brilliant job!"
        ]
        centerMessageLabel.font = .systemFont(ofSize: 36, weight: .bold)
        centerMessageLabel.text = messages.randomElement() ?? "Well done!"
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.isExerciseActive = false
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }



}
