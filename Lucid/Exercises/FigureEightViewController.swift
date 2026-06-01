//
//  FigureEightViewController.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/16/26.
//

import UIKit
import ARKit

private enum FigureEightExercisePhase {
    case none, tracking
}

class FigureEightViewController: UIViewController, ARSessionDelegate, CAAnimationDelegate {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!

    private var trackLayer: CAShapeLayer?
    private let arSession = ARSession()
    private var isLookingAtScreen = false
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private var isExerciseActive = true // Master kill switch
        
    private var currentPhase: FigureEightExercisePhase = .none

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

    // Navigation/Skip buttons for instructions
    private var instructionNextButton: UIButton?
    private var instructionPrevButton: UIButton?
    private var currentInstructionIndex = 0

    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "Keep the phone close to your face, but where you can clearly see the screen,\nand move your eyes with the yellow dot", duration: 6.5)
    ]

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

    private func runInstructionSequence(index: Int) {
        guard isExerciseActive, currentPhase == .none else { return }
        currentInstructionIndex = index
        let isFirstRun = InstructionTracker.isFirstRun(for: "Figure8")
        
        let isLandscape = view.bounds.width > view.bounds.height
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            if isLandscape {
                if isFirstRun {
                    instructionNextButton?.isHidden = false
                    let canGoBack = index > 0
                    instructionPrevButton?.isHidden = !canGoBack
                    
                    let isLastStep = (index == exerciseInstructions.count - 1)
                    instructionNextButton?.setTitle(isLastStep ? "Start Exercise" : "Next", for: .normal)
                } else {
                    instructionNextButton?.isHidden = false
                    instructionPrevButton?.isHidden = true
                    instructionNextButton?.setTitle("Skip", for: .normal)
                }
            } else {
                instructionNextButton?.isHidden = true
                instructionPrevButton?.isHidden = true
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive, self.currentPhase == .none else { return }
                
                if isLandscape {
                    self.centerMessageLabel.text = step.message
                    UIView.animate(withDuration: 0.4, animations: {
                        self.centerMessageLabel.alpha = 1
                    }) { _ in
                        if !isFirstRun {
                            DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                                guard let self = self, self.isExerciseActive, self.currentPhase == .none, self.currentInstructionIndex == index else { return }
                                self.runInstructionSequence(index: index + 1)
                            }
                        }
                    }
                } else {
                    self.centerMessageLabel.text = "Rotate phone to Landscape"
                    self.centerMessageLabel.alpha = 1
                }
            }
        } else {
            finishInstructionsAndStartExercise()
        }
    }

    private func setupInstructionButtons() {
        let isFirstRun = InstructionTracker.isFirstRun(for: "Figure8")
        
        let nextBtn = UIButton(type: .system)
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.layer.cornerRadius = 14
        nextBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextBtn.setTitleColor(.white, for: .normal)
        nextBtn.backgroundColor = UIColor(named: "AccentColor") ?? .systemOrange
        view.addSubview(nextBtn)
        self.instructionNextButton = nextBtn
        nextBtn.addTarget(self, action: #selector(instructionNextTapped), for: .touchUpInside)
        
        if isFirstRun {
            nextBtn.setTitle("Next", for: .normal)
            
            let prevBtn = UIButton(type: .system)
            prevBtn.translatesAutoresizingMaskIntoConstraints = false
            prevBtn.layer.cornerRadius = 14
            prevBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            prevBtn.setTitleColor(.white, for: .normal)
            prevBtn.backgroundColor = .clear
            prevBtn.layer.borderWidth = 1
            prevBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            prevBtn.setTitle("Previous", for: .normal)
            view.addSubview(prevBtn)
            self.instructionPrevButton = prevBtn
            prevBtn.addTarget(self, action: #selector(instructionPrevTapped), for: .touchUpInside)
            
            NSLayoutConstraint.activate([
                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                nextBtn.bottomAnchor.constraint(equalTo: prevBtn.topAnchor, constant: -12),
                nextBtn.heightAnchor.constraint(equalToConstant: 50),
                
                prevBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                prevBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                prevBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                prevBtn.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            prevBtn.isHidden = true // Hidden initially for step 0
        } else {
            nextBtn.setTitle("Skip", for: .normal)
            
            NSLayoutConstraint.activate([
                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                nextBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                nextBtn.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }
    
    @objc private func instructionNextTapped() {
        // Only accept input if in landscape
        guard view.bounds.width > view.bounds.height else { return }
        
        if InstructionTracker.isFirstRun(for: "Figure8") {
            runInstructionSequence(index: currentInstructionIndex + 1)
        } else {
            finishInstructionsAndStartExercise()
        }
    }
    
    @objc private func instructionPrevTapped() {
        // Only accept input if in landscape
        guard view.bounds.width > view.bounds.height else { return }
        
        if InstructionTracker.isFirstRun(for: "Figure8") && currentInstructionIndex > 0 {
            runInstructionSequence(index: currentInstructionIndex - 1)
        }
    }
    
    private func finishInstructionsAndStartExercise() {
        InstructionTracker.markAsCompleted(for: "Figure8")
        currentInstructionIndex = 999
        
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionNextButton?.alpha = 0
            self.instructionPrevButton?.alpha = 0
        }) { _ in
            self.instructionNextButton?.removeFromSuperview()
            self.instructionPrevButton?.removeFromSuperview()
        }
        
        runStartCountdown { [weak self] in
            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
            self.startFigureEightPhase()
        }
    }

    private func runStartCountdown(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.centerMessageLabel.alpha = 0
        }) { _ in
            self.centerMessageLabel.text = "3"
            UIView.animate(withDuration: 0.3, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
                    UIView.animate(withDuration: 0.2, animations: {
                        self.centerMessageLabel.alpha = 0
                    }) { _ in
                        self.centerMessageLabel.text = "2"
                        UIView.animate(withDuration: 0.3, animations: {
                            self.centerMessageLabel.alpha = 1
                        }) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
                                UIView.animate(withDuration: 0.2, animations: {
                                    self.centerMessageLabel.alpha = 0
                                }) { _ in
                                    self.centerMessageLabel.text = "1"
                                    UIView.animate(withDuration: 0.3, animations: {
                                        self.centerMessageLabel.alpha = 1
                                    }) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
                                            UIView.animate(withDuration: 0.3, animations: {
                                                self.centerMessageLabel.alpha = 0
                                            }) { _ in
                                                self.centerMessageLabel.text = ""
                                                completion()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
        
    private func checkOrientationAndAdvance() {
        guard !isFinished else { return }
        let isLandscape = view.bounds.width > view.bounds.height
        let isPortrait = !isLandscape
        let isFirstRun = InstructionTracker.isFirstRun(for: "Figure8")
        
        if !isSecondPart {
            if isLandscape {
                if !hasStartedCountdown {
                    hasStartedCountdown = true
                    centerMessageLabel.alpha = 1
                    setupInstructionButtons()
                    runInstructionSequence(index: 0)
                } else if currentPhase == .none {
                    // Resuming instructions in landscape
                    centerMessageLabel.alpha = 1
                    instructionNextButton?.isHidden = false
                    if isFirstRun {
                        instructionPrevButton?.isHidden = (currentInstructionIndex == 0)
                    }
                    if currentInstructionIndex < exerciseInstructions.count {
                        centerMessageLabel.text = exerciseInstructions[currentInstructionIndex].message
                    }
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
                    if currentPhase == .none {
                        // Hide buttons and show rotate instruction
                        instructionNextButton?.isHidden = true
                        instructionPrevButton?.isHidden = true
                    } else if currentPhase == .tracking {
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
            
        instructionLabel.text = "Keep the phone close to your face (where you can clearly see the screen) and track the yellow dot"
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
        
        instructionLabel.text = "Keep the phone close to your face (where you can clearly see the screen) and track the yellow dot"
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
            
        if currentLoopIndex >= 1 {
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
