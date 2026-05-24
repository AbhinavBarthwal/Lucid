//
//  PeripheralAwarenessViewController.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/16/26.
//

import UIKit
import ARKit

class PeripheralAwarenessViewController: UIViewController, ARSessionDelegate, CAAnimationDelegate {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var centerDotView: UIView!
    @IBOutlet weak var peripheralDotView: UIView!
    
    private let arSession = ARSession()
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private var sessionStartTime: Date?
    private let successHapticGenerator = UINotificationFeedbackGenerator()
    private var isExerciseActive = true

    override var prefersStatusBarHidden: Bool { return true }
    
    private enum ExercisePhase {
        case none, tracking
    }
    private var currentPhase: ExercisePhase = .none
    
    private var gazeTimer: Timer?
    private var countdownRemaining = 0
    private var isAnimationPaused = false
    
    private var currentLoopIndex = 0
    private let totalLoops = 3
    private var currentPath: UIBezierPath?
    private var totalFramesChecked = 0
    private var totalErrors = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare()
        startInitialCountdown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isExerciseActive = true
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isExerciseActive = false
        arSession.pause()
        gazeTimer?.invalidate()
        peripheralDotView.layer.removeAllAnimations()
        centerDotView.layer.removeAllAnimations()
        instructionLabel.layer.removeAllAnimations()
        centerMessageLabel.layer.removeAllAnimations()
        currentPhase = .none
    }
    
    private func setupInitialUI() {
        centerDotView.layer.cornerRadius = centerDotView.bounds.width / 2
        centerDotView.backgroundColor = .accent
        peripheralDotView.layer.cornerRadius = peripheralDotView.bounds.width / 2
        peripheralDotView.backgroundColor = .white
        
        instructionLabel.alpha = 0
        centerDotView.alpha = 0
        peripheralDotView.alpha = 0
        centerMessageLabel.alpha = 1
        
        instructionLabel.isHidden = false
        centerDotView.isHidden = false
        peripheralDotView.isHidden = false
        centerMessageLabel.isHidden = false
        
        view.layoutIfNeeded()
        let startY = view.bounds.height - 120
        peripheralDotView.center = CGPoint(x: view.bounds.midX, y: startY)
    }
    
    private func fadeTransition(showCenterMessage: Bool, showDots: Bool, instructionText: String? = nil, completion: (() -> Void)? = nil) {
        if let text = instructionText {
            self.instructionLabel.text = text
            self.instructionLabel.textColor = .lightGray
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showDots ? 1 : 0
            if showDots { self.centerDotView.alpha = 1 }
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
                self.fadeTransition(showCenterMessage: false, showDots: false) {
                    guard self.isExerciseActive, self.currentPhase == .none else { return }
                    self.showPreparationSequence()
                }
            }
        }
    }
    
    private func showPreparationSequence() {
        currentPhase = .none
        centerMessageLabel.text = "Keep your phone at\narm's length"
        fadeTransition(showCenterMessage: true, showDots: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
            self.fadeTransition(showCenterMessage: false, showDots: true, instructionText: "Focus on the yellow dot,\nkeeping the white dot in your vision") {
                guard self.isExerciseActive, self.currentPhase == .none else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    guard self.isExerciseActive, self.currentPhase == .none else { return }
                    self.revealPeripheralDot()
                }
            }
        }
    }
    
    private func revealPeripheralDot() {
        instructionLabel.text = "Try to keep the white\ndot in check"
        UIView.animate(withDuration: 0.5) {
            self.peripheralDotView.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
            self.startPeripheralPhase()
        }
    }
    
    private func startPeripheralPhase() {
        currentPhase = .tracking
        currentLoopIndex = 0
        isAnimationPaused = false
        self.sessionStartTime = Date()
        resetLayerSpeed(layer: peripheralDotView.layer)
        currentPath = createPeripheralTrack()
        
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel.alpha = 0
        } completion: { _ in
            guard self.isExerciseActive else { return }
            self.startGazeMonitor()
            self.startOrbitAnimation()
        }
    }
    
    private func createPeripheralTrack() -> UIBezierPath {
        view.layoutIfNeeded()
        let path = UIBezierPath()
        let padX: CGFloat = 20
        let padY: CGFloat = 140
        let minX = padX
        let maxX = view.bounds.width - padX
        let minY = padY
        let maxY = view.bounds.height - padY
        let midX = view.bounds.midX
        let cornerRadius: CGFloat = 40
        
        path.move(to: CGPoint(x: midX, y: maxY))
        path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
        path.addQuadCurve(to: CGPoint(x: minX, y: maxY - cornerRadius), controlPoint: CGPoint(x: minX, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: minX + cornerRadius, y: minY), controlPoint: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
        path.addQuadCurve(to: CGPoint(x: maxX, y: minY + cornerRadius), controlPoint: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: maxX - cornerRadius, y: maxY), controlPoint: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: midX, y: maxY))
        return path
    }
    
    private func startOrbitAnimation() {
        guard isExerciseActive, currentPhase == .tracking, let path = currentPath else { return }
        
        if currentLoopIndex >= totalLoops {
            finishExercise()
            return
        }
        
        let loopDurations: [CFTimeInterval] = [12.0 , 10.0 , 8.0]
        let currentDuration = loopDurations[currentLoopIndex]
        
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        animation.duration = currentDuration
        animation.repeatCount = 1
        animation.calculationMode = .paced
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        
        peripheralDotView.layer.removeAllAnimations()
        peripheralDotView.layer.add(animation, forKey: "orbitAnimation_\(currentLoopIndex)")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if isExerciseActive && flag && currentPhase == .tracking {
            currentLoopIndex += 1
            resetLayerSpeed(layer: peripheralDotView.layer)
            isAnimationPaused = false
            startOrbitAnimation()
        }
    }
    
    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isExerciseActive, self.currentPhase == .tracking else { return }
            
            self.totalFramesChecked += 1
            
            var isLookingAtCenter = false
            if let frame = self.arSession.currentFrame,
               let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first,
               faceAnchor.isTracked {
                let lookAt = faceAnchor.lookAtPoint
                isLookingAtCenter = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
            }
            
            if isLookingAtCenter {
                if self.isAnimationPaused {
                    self.resumeLayer(layer: self.peripheralDotView.layer)
                    self.isAnimationPaused = false
                }
                if self.instructionLabel.alpha != 0 {
                    UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
                }
            } else {
                self.totalErrors += 1
                if !self.isAnimationPaused {
                    self.pauseLayer(layer: self.peripheralDotView.layer)
                    self.isAnimationPaused = true
                    self.errorHapticGenerator.notificationOccurred(.error)
                    self.instructionLabel.layer.removeAllAnimations()
                    self.instructionLabel.textColor = .systemRed
                    self.instructionLabel.text = "⚠️ Keep your eyes strictly on the yellow dot!"
                    self.instructionLabel.alpha = 1
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
    
    private func finishExercise() {
        currentPhase = .none
        gazeTimer?.invalidate()
        peripheralDotView.layer.removeAllAnimations()
        
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
        
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(
            type: "PeripheralAwareness",
            duration: elapsedSeconds,
            accuracy: accuracy,
            errors: totalErrors
        )
        newSession.user = user
        context.insert(newSession)
        
        do {
            try context.save()
            successHapticGenerator.notificationOccurred(.success)
        } catch {
            print("❌ Peripheral Awareness Save failed: \(error)")
        }
        
        UIView.animate(withDuration: 0.5) {
            self.centerDotView.alpha = 0
            self.peripheralDotView.alpha = 0
        }
        
        let messages = [
            "Fantastic job!",
            "Great work!",
            "Awesome focus!",
            "Excellent effort!",
            "Superb session!",
            "Nicely done!",
            "Brilliant job!"
        ]
        centerMessageLabel.text = messages.randomElement() ?? "Nicely done !"
        
        UIView.animate(withDuration: 0.5) {
            self.centerMessageLabel.alpha = 1
            self.instructionLabel.alpha = 0
        }
        
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
