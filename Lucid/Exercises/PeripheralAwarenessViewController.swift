//
//  PeripheralAwarenessViewController.swift
//  Lucid
//

import UIKit
import ARKit

class PeripheralAwarenessViewController: UIViewController, ARSessionDelegate, CAAnimationDelegate {

    // MARK: - UI ELEMENTS
    
    @IBOutlet weak var instructionLabel: UILabel!      // Shows warnings/instructions
    @IBOutlet weak var centerMessageLabel: UILabel!    // Countdown / phase messages
    
    // Two dots:
    // - Center dot → user must FIXATE on this
    // - Peripheral dot → user must detect this in side vision
    @IBOutlet weak var centerDotView: UIView!
    @IBOutlet weak var peripheralDotView: UIView!
        
    private let arSession = ARSession() // Face tracking session
    
    private let errorHapticGenerator = UINotificationFeedbackGenerator()   // Error feedback
    private let successHapticGenerator = UINotificationFeedbackGenerator() // Success feedback
    
    private var sessionStartTime: Date? // Tracks total exercise duration
    
    private enum ExercisePhase {
        case none, tracking
    }
    
    private var currentPhase: ExercisePhase = .none
        
    private var gazeTimer: Timer?     // Continuously checks gaze direction
    private var countdownRemaining = 0
    
    private var isAnimationPaused = false // Tracks whether animation is paused
        
    private var currentLoopIndex = 0
    private let totalLoops = 3        // Number of rounds
    
    private var currentPath: UIBezierPath? // Path for peripheral dot movement
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialUI()
        
        // Prepare haptics (reduces delay)
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare()
        
        // Start countdown before exercise
        startInitialCountdown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure device supports face tracking
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        let config = ARFaceTrackingConfiguration()
        
        // Run AR session
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop AR session and cleanup
        arSession.pause()
        gazeTimer?.invalidate()
        peripheralDotView.layer.removeAllAnimations()
    }
        
    private func setupInitialUI() {
        
        // Style center dot (focus point)
        centerDotView.layer.cornerRadius = centerDotView.bounds.width / 2
        centerDotView.backgroundColor = .systemOrange
        
        // Style peripheral dot (moving stimulus)
        peripheralDotView.layer.cornerRadius = peripheralDotView.bounds.width / 2
        peripheralDotView.backgroundColor = .white
        
        // Initial visibility
        instructionLabel.alpha = 0
        centerDotView.alpha = 0
        peripheralDotView.alpha = 0
        centerMessageLabel.alpha = 1
        
        // Ensure all views are visible (not hidden)
        instructionLabel.isHidden = false
        centerDotView.isHidden = false
        peripheralDotView.isHidden = false
        centerMessageLabel.isHidden = false
        
        // Place peripheral dot at bottom center initially
        view.layoutIfNeeded()
        let startY = view.bounds.height - 120
        peripheralDotView.center = CGPoint(x: view.bounds.midX, y: startY)
    }
        
    private func fadeTransition(showCenterMessage: Bool, showDots: Bool, instructionText: String? = nil, completion: (() -> Void)? = nil) {
        
        // Update instruction text if provided
        if let text = instructionText {
            self.instructionLabel.text = text
            self.instructionLabel.textColor = .lightGray
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showDots ? 1 : 0
            
            // Only center dot appears first
            if showDots {
                self.centerDotView.alpha = 1
            }
        }) { _ in
            completion?()
        }
    }
        
    private func startInitialCountdown() {
        
        currentPhase = .none
        
        countdownRemaining = 5
        centerMessageLabel.text = "\(countdownRemaining)"
        
        // Countdown every 1 second
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            
            guard let self = self else { return }
            
            self.countdownRemaining -= 1
            
            if self.countdownRemaining > 0 {
                self.centerMessageLabel.text = "\(self.countdownRemaining)"
            } else {
                timer.invalidate()
                
                // Move to preparation phase
                self.fadeTransition(showCenterMessage: false, showDots: false) {
                    self.showPreparationSequence()
                }
            }
        }
    }
        
    private func showPreparationSequence() {
        
        currentPhase = .none
        
        // Ask user to maintain distance
        centerMessageLabel.text = "Keep your phone at\narm's length"
        
        fadeTransition(showCenterMessage: true, showDots: false)
        
        // After 3 sec → show center dot
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            
            self.fadeTransition(
                showCenterMessage: false,
                showDots: true,
                instructionText: "Focus on the yellow dot,\nkeeping the white dot in your vision"
            ) {
                
                // After 4 sec → reveal peripheral dot
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.revealPeripheralDot()
                }
            }
        }
    }
    
    private func revealPeripheralDot() {
        
        instructionLabel.text = "Try to keep the white\ndot in check"
        
        // Fade in peripheral dot
        UIView.animate(withDuration: 0.5) {
            self.peripheralDotView.alpha = 1
        }
        
        // After 3 sec → start exercise
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startPeripheralPhase()
        }
    }
        
    private func startPeripheralPhase() {
        
        currentPhase = .tracking
        currentLoopIndex = 0
        isAnimationPaused = false
        
        // Start timer
        self.sessionStartTime = Date()
        
        // Reset animation state
        resetLayerSpeed(layer: peripheralDotView.layer)
        
        // Create movement path
        currentPath = createPeripheralTrack()
        
        // Hide instruction label
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel.alpha = 0
        } completion: { _ in
            
            // Start gaze tracking + animation
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
        
        // Create rounded rectangular path around screen edges
        
        path.move(to: CGPoint(x: midX, y: maxY))
        
        path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
        path.addQuadCurve(to: CGPoint(x: minX, y: maxY - cornerRadius),
                          controlPoint: CGPoint(x: minX, y: maxY))
        
        path.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: minX + cornerRadius, y: minY),
                          controlPoint: CGPoint(x: minX, y: minY))
        
        path.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
        path.addQuadCurve(to: CGPoint(x: maxX, y: minY + cornerRadius),
                          controlPoint: CGPoint(x: maxX, y: minY))
        
        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: maxX - cornerRadius, y: maxY),
                          controlPoint: CGPoint(x: maxX, y: maxY))
        
        path.addLine(to: CGPoint(x: midX, y: maxY))
        
        return path
    }
        
    private func startOrbitAnimation() {
        
        guard currentPhase == .tracking, let path = currentPath else { return }
        
        // If all loops done → finish
        if currentLoopIndex >= totalLoops {
            finishExercise()
            return
        }
        
        let loopDurations: [CFTimeInterval] = [12.0 , 10.0 , 8.0]
        let currentDuration = loopDurations[currentLoopIndex]
        
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        animation.duration = currentDuration
        
        // Smooth motion along path
        animation.calculationMode = .paced
        
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        animation.delegate = self
        
        peripheralDotView.layer.removeAllAnimations()
        peripheralDotView.layer.add(animation, forKey: "orbitAnimation_\(currentLoopIndex)")
    }
    
    // Called when animation finishes
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
        if flag && currentPhase == .tracking {
            
            currentLoopIndex += 1
            
            resetLayerSpeed(layer: peripheralDotView.layer)
            isAnimationPaused = false
            
            startOrbitAnimation()
        }
    }
        
    private func startGazeMonitor() {
        
        gazeTimer?.invalidate()
        
        // Check gaze every 0.1 sec
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            
            guard let self = self, self.currentPhase == .tracking else { return }
            
            var isLookingAtCenter = false
            
            if let frame = self.arSession.currentFrame,
               let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first,
               faceAnchor.isTracked {
                
                let lookAt = faceAnchor.lookAtPoint
                
                // Strict threshold → must focus on center dot
                isLookingAtCenter = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
            }
            
            if isLookingAtCenter {
                
                // Resume animation if paused
                if self.isAnimationPaused {
                    self.resumeLayer(layer: self.peripheralDotView.layer)
                    self.isAnimationPaused = false
                }
                
                // Hide warning
                if self.instructionLabel.alpha != 0 {
                    UIView.animate(withDuration: 0.3) {
                        self.instructionLabel.alpha = 0
                    }
                }
                
            } else {
                
                // Pause animation if user looks away
                if !self.isAnimationPaused {
                    
                    self.pauseLayer(layer: self.peripheralDotView.layer)
                    self.isAnimationPaused = true
                    
                    self.errorHapticGenerator.notificationOccurred(.error)
                    
                    // Show warning
                    self.instructionLabel.textColor = .systemRed
                    self.instructionLabel.text = "⚠️ Keep your eyes strictly on the yellow dot!"
                    self.instructionLabel.alpha = 1
                }
            }
        }
    }
        
    // Pause animation at current frame
    private func pauseLayer(layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }

    // Resume animation smoothly from paused point
    private func resumeLayer(layer: CALayer) {
        let pausedTime = layer.timeOffset
        
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    // Reset animation timing
    private func resetLayerSpeed(layer: CALayer) {
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
    }
    
    // MARK: - FINISH
    
    private func finishExercise() {
        
        currentPhase = .none
        
        gazeTimer?.invalidate()
        peripheralDotView.layer.removeAllAnimations()
        
        // Save duration
        if let startTime = sessionStartTime {
            let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
            
            successHapticGenerator.notificationOccurred(.success)
        }
        
        // Hide dots
        UIView.animate(withDuration: 0.5) {
            self.centerDotView.alpha = 0
            self.peripheralDotView.alpha = 0
        }
        
        // Show completion message
        centerMessageLabel.text = "Nicely done !"
        
        UIView.animate(withDuration: 0.5) {
            self.centerMessageLabel.alpha = 1
            self.instructionLabel.alpha = 0
        }
        
        // Transition after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("Exercise Completed - Transitioning to summary")
        }
    }
}
