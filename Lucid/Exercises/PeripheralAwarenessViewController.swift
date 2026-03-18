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
    
    // We need two dots for this exercise
    @IBOutlet weak var centerDotView: UIView!
    @IBOutlet weak var peripheralDotView: UIView!
    
    // AR session to run head/eye tracking.
    private let arSession = ARSession()
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private var sessionStartTime: Date?

    private let successHapticGenerator = UINotificationFeedbackGenerator()
    
    private enum ExercisePhase {
        case none, tracking
    }
    private var currentPhase: ExercisePhase = .none
    
    // Monitors gaze and animation state
    private var gazeTimer: Timer?
    private var countdownRemaining = 0
    private var isAnimationPaused = false
    
    // Tracks the loops
    private var currentLoopIndex = 0
    private let totalLoops = 3
    private var currentPath: UIBezierPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare() // Add this
        
        startInitialCountdown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSession.pause()
        gazeTimer?.invalidate()
        peripheralDotView.layer.removeAllAnimations()
    }
    
    // MARK: - UI Setup
    private func setupInitialUI() {
        // Style the center dot (Orange/Yellow)
        centerDotView.layer.cornerRadius = centerDotView.bounds.width / 2
        centerDotView.backgroundColor = .systemOrange
        
        // Style the peripheral dot (White)
        peripheralDotView.layer.cornerRadius = peripheralDotView.bounds.width / 2
        peripheralDotView.backgroundColor = .white
        
        // Initial opacities
        instructionLabel.alpha = 0
        centerDotView.alpha = 0
        peripheralDotView.alpha = 0
        centerMessageLabel.alpha = 1
        
        instructionLabel.isHidden = false
        centerDotView.isHidden = false
        peripheralDotView.isHidden = false
        centerMessageLabel.isHidden = false
        
        // Snap peripheral dot to the bottom center to start
        view.layoutIfNeeded()
        let startY = view.bounds.height - 120 // 120 padding from bottom
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
            
            // Only fade center dot initially, peripheral dot is handled separately in sequence
            if showDots { self.centerDotView.alpha = 1 }
        }) { _ in
            completion?()
        }
    }
    
    // MARK: - Sequence Phasing
    private func startInitialCountdown() {
        currentPhase = .none
        countdownRemaining = 5
        centerMessageLabel.text = "\(countdownRemaining)"
        
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.countdownRemaining -= 1
            
            if self.countdownRemaining > 0 {
                self.centerMessageLabel.text = "\(self.countdownRemaining)"
            } else {
                timer.invalidate()
                self.fadeTransition(showCenterMessage: false, showDots: false) {
                    self.showPreparationSequence()
                }
            }
        }
    }
    
    private func showPreparationSequence() {
        currentPhase = .none
        centerMessageLabel.text = "Keep your phone at\narm's length"
        
        fadeTransition(showCenterMessage: true, showDots: false)
        
        // Wait 3 seconds, then show the center dot
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.fadeTransition(showCenterMessage: false, showDots: true, instructionText: "Focus on the yellow dot,\nkeeping the white dot in your vision") {
                
                // Wait 4 seconds, then reveal the white dot
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
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
        
        // Wait 3 seconds, then start the exercise!
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startPeripheralPhase()
        }
    }
    
    private func startPeripheralPhase() {
        currentPhase = .tracking
        currentLoopIndex = 0
        isAnimationPaused = false
        
        // START THE CLOCK HERE
        self.sessionStartTime = Date()
        
        resetLayerSpeed(layer: peripheralDotView.layer)

    
        // Generate the orbit path
        currentPath = createPeripheralTrack()
        
        // Fade out instruction label
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel.alpha = 0
        } completion: { _ in
            self.startGazeMonitor()
            self.startOrbitAnimation()
        }
    }
    
    // MARK: - Peripheral Math & Animation
    
    // Creates a smooth rounded rectangle around the edges of the screen
    private func createPeripheralTrack() -> UIBezierPath {
        view.layoutIfNeeded()
        let path = UIBezierPath()
        
        let padX: CGFloat = 20
        let padY: CGFloat = 140 // Keeps it away from top/bottom safe areas
        
        let minX = padX
        let maxX = view.bounds.width - padX
        let minY = padY
        let maxY = view.bounds.height - padY
        let midX = view.bounds.midX
        
        let cornerRadius: CGFloat = 40
        
        // 1. Start exactly at bottom-center (where the dot is spawned)
        path.move(to: CGPoint(x: midX, y: maxY))
        
        // 2. Go Left to Bottom-Left corner
        path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
        path.addQuadCurve(to: CGPoint(x: minX, y: maxY - cornerRadius), controlPoint: CGPoint(x: minX, y: maxY))
        
        // 3. Go Up to Top-Left corner
        path.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: minX + cornerRadius, y: minY), controlPoint: CGPoint(x: minX, y: minY))
        
        // 4. Go Right to Top-Right corner
        path.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
        path.addQuadCurve(to: CGPoint(x: maxX, y: minY + cornerRadius), controlPoint: CGPoint(x: maxX, y: minY))
        
        // 5. Go Down to Bottom-Right corner
        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: maxX - cornerRadius, y: maxY), controlPoint: CGPoint(x: maxX, y: maxY))
        
        // 6. Return to Bottom-Center
        path.addLine(to: CGPoint(x: midX, y: maxY))
        
        return path
    }
    
    private func startOrbitAnimation() {
        guard currentPhase == .tracking, let path = currentPath else { return }
        
        if currentLoopIndex >= totalLoops {
            finishExercise()
            return
        }
        
        // Peripheral vision gets harder if it moves faster. Let's start slow and gradually increase.
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
        if flag && currentPhase == .tracking {
            currentLoopIndex += 1
            
            resetLayerSpeed(layer: peripheralDotView.layer)
            isAnimationPaused = false
            
            startOrbitAnimation()
        }
    }
    
    // MARK: - Pausing & Gaze Monitoring
    
    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        
        // Check every 0.1s. The user MUST keep looking at the center!
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.currentPhase == .tracking else { return }
            
            var isLookingAtCenter = false
            if let frame = self.arSession.currentFrame,
               let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first,
               faceAnchor.isTracked {
                let lookAt = faceAnchor.lookAtPoint
                // Strict bounds to ensure they look at the center, not the moving white dot
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
    
    // MARK: - Completion
    
    private func finishExercise() {
        currentPhase = .none
        gazeTimer?.invalidate()
        peripheralDotView.layer.removeAllAnimations()
        
        // STOP THE CLOCK AND SAVE
        if let startTime = sessionStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            let elapsedSeconds = Int(elapsedTime)
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
            
            // Optional: Trigger success haptic
            successHapticGenerator.notificationOccurred(.success)
        }
        
        UIView.animate(withDuration: 0.5) {
            self.centerDotView.alpha = 0
            self.peripheralDotView.alpha = 0
        }
        
        centerMessageLabel.text = "Nicely done !"
        
        UIView.animate(withDuration: 0.5) {
            self.centerMessageLabel.alpha = 1
            self.instructionLabel.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("Exercise Completed - Transitioning to summary")
            // Your dismissal/segue logic
        }
    
    }
}
