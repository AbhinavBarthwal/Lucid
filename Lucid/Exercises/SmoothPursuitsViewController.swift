//
//  SmoothPursuitsViewController.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/16/26.
//

import UIKit
import ARKit

class SmoothPursuitsViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!

        // AR session to run head/eye tracking.
        private let arSession = ARSession()
        private var isLookingAtScreen = false
        
        // Haptic generators
        private let errorHapticGenerator = UINotificationFeedbackGenerator()
        private let successHapticGenerator = UINotificationFeedbackGenerator()
        
        // --- TIME TRACKING VARIABLES ---
        private var sessionStartTime: Date?
        
        // Categorizes the phases of the smooth pursuit exercise.
        private enum ExercisePhase {
            case none, tracking
        }
        private var currentPhase: ExercisePhase = .none
        
        // Timer to monitor the user's gaze continuously
        private var gazeTimer: Timer?
        private var countdownRemaining = 0
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupInitialUI()
            arSession.delegate = self
            
            errorHapticGenerator.prepare()
            successHapticGenerator.prepare()
            startInitialCountdown()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard ARFaceTrackingConfiguration.isSupported else { return }
            
            let config = ARFaceTrackingConfiguration()
            arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            arSession.pause()
            gazeTimer?.invalidate()
            circleView.layer.removeAllAnimations()
        }
        
        // MARK: - ARSessionDelegate
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
                isLookingAtScreen = false
                return
            }
            
            let lookAt = faceAnchor.lookAtPoint
            // If the X and Y coordinates of the gaze are within 0.2 units they are looking at the screen.
            isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        }
        
        // MARK: - UI Setup
        private func setupInitialUI() {
            circleView.layer.cornerRadius = circleView.bounds.width / 2
            instructionLabel.alpha = 0
            circleView.alpha = 0
            
            instructionLabel.isHidden = false
            circleView.isHidden = false
            
            centerMessageLabel.alpha = 1
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
        
        // MARK: - Sequences
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
                        self.showPreparationMessage("Follow the dot closely\nwith your eyes only") {
                            self.startSmoothPursuitPhase()
                        }
                    }
                }
            }
        }
        
        private func showPreparationMessage(_ message: String, completion: @escaping () -> Void) {
            currentPhase = .none
            circleView.layer.removeAllAnimations()
            centerMessageLabel.text = message
            
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    completion()
                }
            }
        }
        
        private func startSmoothPursuitPhase() {
            currentPhase = .tracking
            
            instructionLabel.textColor = .lightGray
            instructionLabel.text = "Keep your head still and follow the dot"
            instructionLabel.alpha = 1
            
            circleView.transform = .identity
            
            fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    guard self.currentPhase == .tracking else { return }
                    
                    // START THE CLOCK: The user begins moving their eyes here
                    self.sessionStartTime = Date()
                    
                    UIView.animate(withDuration: 0.5) {
                        self.instructionLabel.alpha = 0
                    } completion: { _ in
                        self.startGazeMonitor()
                        self.startStarPathAnimation(targetIndex: 0)
                    }
                }
            }
        }
        
        // MARK: - Core Logic & Animation
        private func startStarPathAnimation(targetIndex: Int) {
            guard currentPhase == .tracking else { return }
            
            let padX: CGFloat = 40
            let padY: CGFloat = 80
            
            let minX = -(view.bounds.width / 2) + padX
            let maxX = (view.bounds.width / 2) - padX
            let minY = -(view.bounds.height / 2) + padY
            let maxY = (view.bounds.height / 2) - padY
            let midX: CGFloat = 0
            let midY: CGFloat = 0
            
            let points: [CGPoint] = [
                CGPoint(x: midX, y: minY), // Top-Center
                CGPoint(x: maxX, y: minY), // Top-Right
                CGPoint(x: maxX, y: midY), // Right-Center
                CGPoint(x: maxX, y: maxY), // Bottom-Right
                CGPoint(x: midX, y: maxY), // Bottom-Center
                CGPoint(x: minX, y: maxY), // Bottom-Left
                CGPoint(x: minX, y: midY), // Left-Center
                CGPoint(x: minX, y: minY)  // Top-Left
            ]
            
            if targetIndex >= points.count {
                finishExercise()
                return
            }
            
            let nextPoint = points[targetIndex]
            let maxDuration: Double = 1.8
            let minDuration: Double = 0.75
            let step = (maxDuration - minDuration) / Double(points.count - 1)
            let currentDuration = maxDuration - (Double(targetIndex) * step)
            
            UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
                self.circleView.transform = CGAffineTransform(translationX: nextPoint.x, y: nextPoint.y)
            } completion: { _ in
                guard self.currentPhase == .tracking else { return }
                
                UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
                    self.circleView.transform = .identity
                } completion: { _ in
                    if self.currentPhase == .tracking {
                        self.startStarPathAnimation(targetIndex: targetIndex + 1)
                    }
                }
            }
        }
        
        private func startGazeMonitor() {
            gazeTimer?.invalidate()
            gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self = self, self.currentPhase == .tracking else { return }
                
                if self.isLookingAtScreen {
                    if self.instructionLabel.alpha != 0 {
                        UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
                    }
                } else {
                    self.errorHapticGenerator.notificationOccurred(.error)
                    self.instructionLabel.layer.removeAllAnimations()
                    self.instructionLabel.textColor = .systemRed
                    self.instructionLabel.text = "⚠️ Please keep your eyes on the screen!"
                    self.instructionLabel.alpha = 1
                }
            }
        }
        
        // MARK: - Completion
        private func finishExercise() {
            // --- STOP THE CLOCK AND SAVE ---
            if let startTime = sessionStartTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                let elapsedSeconds = Int(elapsedTime)
                ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
                
                successHapticGenerator.notificationOccurred(.success)
            }
            
            startTransitionPhase(message: "Nicely Done!") {
                print("Exercise Completed - Transitioning to summary")
                // Dismiss or Segue here
            }
        }
        
        private func startTransitionPhase(message: String, nextPhase: @escaping () -> Void) {
            currentPhase = .none
            gazeTimer?.invalidate()
            circleView.layer.removeAllAnimations()
            centerMessageLabel.text = message
            
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    nextPhase()
                }
            }
        }
    }
