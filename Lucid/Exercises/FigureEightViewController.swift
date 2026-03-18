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
            
        // AR session to run head/eye tracking.
        private let arSession = ARSession()
        private var isLookingAtScreen = false
        private let errorHapticGenerator = UINotificationFeedbackGenerator()
            
        private enum ExercisePhase {
            case none, tracking, waitingForRotation
        }
        private var currentPhase: ExercisePhase = .none
            
        // Monitors gaze and animation state
        private var gazeTimer: Timer?
        private var countdownRemaining = 0
        private var isAnimationPaused = false
        
        // Tracking the actual exercise duration
        private var sessionStartTime: Date?
            
        // Tracks the 3 loop sequences and the device rotation halves
        private var currentLoopIndex = 0
        private var currentPath: UIBezierPath?
        private var isSecondPart = false // Becomes true after they rotate the phone
            
        override func viewDidLoad() {
            super.viewDidLoad()
            setupInitialUI()
            errorHapticGenerator.prepare()
                
            startInitialCountdown()
        }
            
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            self.navigationController?.setNavigationBarHidden(false, animated: animated)
     
            self.tabBarController?.tabBar.isHidden = true
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let config = ARFaceTrackingConfiguration()
            arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
            
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            arSession.pause()
            gazeTimer?.invalidate()
            circleView.layer.removeAllAnimations()
            trackLayer?.removeFromSuperlayer()
                
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.removeObserver(self)
        }
            
        // MARK: - UI Setup
        private func setupInitialUI() {
            circleView.layer.cornerRadius = circleView.bounds.width / 2
            circleView.backgroundColor = .systemOrange
                
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
                    self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                        
                        // START THE CLOCK HERE
                        self.sessionStartTime = Date()
                        
                        self.showPreparationMessage()
                    }
                }
            }
        }
            
        private func showPreparationMessage() {
            currentPhase = .none
            centerMessageLabel.text = "Move your eyes with\nthe yellow dot"
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    self.startFigureEightPhase()
                }
            }
        }
            
        private func startFigureEightPhase() {
            currentPhase = .tracking
            currentLoopIndex = 0
            isAnimationPaused = false
            resetLayerSpeed(layer: circleView.layer)
                
            instructionLabel.text = "Move your eyes with the yellow dot"
            instructionLabel.textColor = .lightGray
            instructionLabel.alpha = 1
                
            // Generate path based on current orientation bounds
            currentPath = createInfinityPath()
            drawBackgroundTrack(with: currentPath!)
                
            // Fade in UI
            fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                    
                // Wait 2 seconds, fade instruction, start moving
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    guard self.currentPhase == .tracking else { return }
                        
                    UIView.animate(withDuration: 0.5) {
                        self.instructionLabel.alpha = 0
                    } completion: { _ in
                        self.startGazeMonitor()
                        self.startFigureEightAnimation()
                    }
                }
            }
        }
            
        // MARK: - Figure Eight Math & Animation
            
        private func createInfinityPath() -> UIBezierPath {
            let path = UIBezierPath()
            let screenWidth = view.bounds.width
            let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
                
            let loopWidth = (screenWidth - 80) / 2
            let loopHeight = loopWidth * 0.8
                
            path.move(to: center)
                
            // Right Loop
            path.addCurve(to: CGPoint(x: center.x + loopWidth, y: center.y),
                          controlPoint1: CGPoint(x: center.x + loopWidth/2, y: center.y - loopHeight),
                          controlPoint2: CGPoint(x: center.x + loopWidth, y: center.y - loopHeight))
            path.addCurve(to: center,
                          controlPoint1: CGPoint(x: center.x + loopWidth, y: center.y + loopHeight),
                          controlPoint2: CGPoint(x: center.x + loopWidth/2, y: center.y + loopHeight))
                
            // Left Loop
            path.addCurve(to: CGPoint(x: center.x - loopWidth, y: center.y),
                          controlPoint1: CGPoint(x: center.x - loopWidth/2, y: center.y - loopHeight),
                          controlPoint2: CGPoint(x: center.x - loopWidth, y: center.y - loopHeight))
            path.addCurve(to: center,
                          controlPoint1: CGPoint(x: center.x - loopWidth, y: center.y + loopHeight),
                          controlPoint2: CGPoint(x: center.x - loopWidth/2, y: center.y + loopHeight))
                
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
            guard currentPhase == .tracking, let path = currentPath else { return }
                
            if currentLoopIndex >= 3 {
                if !isSecondPart {
                    promptRotationPhase() // Ask them to flip the phone
                } else {
                    finishExercise()      // Second half is done!
                }
                return
            }
                
            let loopDurations: [CFTimeInterval] = [10.0, 6.0, 4.5]
            let currentDuration = loopDurations[currentLoopIndex]
                
            let animation = CAKeyframeAnimation(keyPath: "position")
            animation.path = path.cgPath
            animation.duration = currentDuration
            animation.repeatCount = 1
            animation.calculationMode = .paced
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
                
            // 🚨 THIS IS THE MAGIC LINE THAT WAS MISSING! 🚨
            animation.delegate = self
                
            // Safely remove previous animations to prevent stacking issues
            circleView.layer.removeAllAnimations()
            circleView.layer.add(animation, forKey: "figureEightAnimation_\(currentLoopIndex)")
        }
            
        // Triggers automatically when a single figure-eight loop completes
        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            // Only trigger if it finished completely naturally
            if flag && currentPhase == .tracking {
                currentLoopIndex += 1
                    
                // CRITICAL FIX: Reset the layer's timeline so the next animation starts cleanly!
                resetLayerSpeed(layer: circleView.layer)
                isAnimationPaused = false
                    
                startFigureEightAnimation() // Kick off the next, faster loop
            }
        }
            
        // MARK: - Pausing & Gaze Monitoring

        private func startGazeMonitor() {
            gazeTimer?.invalidate()
                
            // Check frequently (every 0.1s) for instant reaction
            gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, self.currentPhase == .tracking else { return }
                    
                // Check ARKit directly instead of relying on the delegate (much more reliable)
                var isLooking = false
                if let frame = self.arSession.currentFrame,
                   let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first,
                   faceAnchor.isTracked {
                    let lookAt = faceAnchor.lookAtPoint
                    isLooking = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
                }
                    
                if isLooking {
                    if self.isAnimationPaused {
                        self.resumeLayer(layer: self.circleView.layer)
                        self.isAnimationPaused = false
                    }
                    if self.instructionLabel.alpha != 0 {
                        UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
                    }
                } else {
                    if !self.isAnimationPaused {
                        self.pauseLayer(layer: self.circleView.layer)
                        self.isAnimationPaused = true
                        self.errorHapticGenerator.notificationOccurred(.error)
                            
                        self.instructionLabel.layer.removeAllAnimations()
                        self.instructionLabel.textColor = .systemRed
                        self.instructionLabel.text = "⚠️ Please keep your eyes on the screen!"
                        self.instructionLabel.alpha = 1
                    }
                }
            }
        }
            
        // Freezes the CAAnimation perfectly in time
        private func pauseLayer(layer: CALayer) {
            let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
            layer.speed = 0.0
            layer.timeOffset = pausedTime
        }

        // Resumes the CAAnimation exactly where it left off
        private func resumeLayer(layer: CALayer) {
            let pausedTime: CFTimeInterval = layer.timeOffset
            layer.speed = 1.0
            layer.timeOffset = 0.0
            layer.beginTime = 0.0
            let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            layer.beginTime = timeSincePause
        }
            
        // Wipes all time manipulation from the layer
        private func resetLayerSpeed(layer: CALayer) {
            layer.speed = 1.0
            layer.timeOffset = 0.0
            layer.beginTime = 0.0
        }
            
        // MARK: - Rotation & Completion
            
        private func promptRotationPhase() {
            currentPhase = .none
            gazeTimer?.invalidate()
            circleView.layer.removeAllAnimations()
            resetLayerSpeed(layer: circleView.layer)
            isSecondPart = true
                
            UIView.animate(withDuration: 0.5) { self.trackLayer?.opacity = 0 }
                
            centerMessageLabel.text = "Nicely done !"
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.currentPhase = .waitingForRotation
                self.centerMessageLabel.text = "Rotate your device"
                    
                // Listen for the device flipping over
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDidRotate), name: UIDevice.orientationDidChangeNotification, object: nil)
            }
        }
            
        // Catches the standard device orientation change (if portrait lock is off)
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
                
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                guard let self = self else { return }
                if self.currentPhase == .waitingForRotation {
                    self.startSecondPhase()
                }
            }
        }
            
        // Fallback catching raw gyro changes just in case view transition gets missed
        @objc private func deviceDidRotate() {
            guard currentPhase == .waitingForRotation else { return }
            if UIDevice.current.orientation.isValidInterfaceOrientation {
                startSecondPhase()
            }
        }
            
        private func startSecondPhase() {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
                
            // This will redraw the path using the new landscape/portrait bounds automatically!
            startFigureEightPhase()
        }
            
        private func finishExercise() {
            currentPhase = .none
            gazeTimer?.invalidate()
            circleView.layer.removeAllAnimations()
            
            // STOP THE CLOCK AND SAVE
            if let startTime = sessionStartTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                let elapsedSeconds = Int(elapsedTime)
                
                ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
            }
                
            UIView.animate(withDuration: 0.5) { self.trackLayer?.opacity = 0 }
                
            centerMessageLabel.text = "Nicely done !"
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("Exercise Completed - Transitioning to summary")
                // Handle dismissal or segue
            }
        }
    }
