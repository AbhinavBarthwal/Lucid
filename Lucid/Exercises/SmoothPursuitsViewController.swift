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
        
        // Haptic generator used to alert the user if they look away.
        private let errorHapticGenerator = UINotificationFeedbackGenerator()
        
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
            startInitialCountdown()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard ARFaceTrackingConfiguration.isSupported else { return }
            
            // Tracking the face
            let config = ARFaceTrackingConfiguration()
            arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // Clean up
            arSession.pause()
            gazeTimer?.invalidate()
            circleView.layer.removeAllAnimations()
        }
        
        // Session that figures out where the user is looking
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
                isLookingAtScreen = false
                return
            }
            
            let lookAt = faceAnchor.lookAtPoint
            
            // If the X and Y coordinates of the gaze are within 0.2 units they are looking at the screen.
            isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        }
        
        // Configures the starting opacities so only the central countdown message is visible initially.
        private func setupInitialUI() {
            circleView.layer.cornerRadius = circleView.bounds.width / 2
            instructionLabel.alpha = 0
            circleView.alpha = 0
            
            instructionLabel.isHidden = false
            circleView.isHidden = false
            
            centerMessageLabel.alpha = 1
            centerMessageLabel.isHidden = false
        }
        
        // Crossfades between the instructional center text and the exercise.
        private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
                self.instructionLabel.alpha = showExerciseUI ? 1 : 0
                self.circleView.alpha = showExerciseUI ? 1 : 0
            }) { _ in
                completion?()
            }
        }
        
        // Runs a simple 5-1 countdown in the center of the screen before the real exercise begins.
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
        
        // Displays instructions to let the user prepare.
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
        
        // The phase where the user must follow the moving dot.
        private func startSmoothPursuitPhase() {
            currentPhase = .tracking
            
            instructionLabel.textColor = .lightGray
            instructionLabel.text = "Keep your head still and follow the dot"
            instructionLabel.alpha = 1 // Ensure it's visible at the start
            
            // Reset dot position to center
            circleView.transform = .identity
            
            fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                
                // Wait 3 seconds, then fade instruction and start ball movement
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    guard self.currentPhase == .tracking else { return }
                    
                    UIView.animate(withDuration: 0.5) {
                        self.instructionLabel.alpha = 0
                    } completion: { _ in
                        
                        // Start monitoring gaze
                        self.startGazeMonitor()
                        
                        // Start the center-to-extreme path animation
                        self.startStarPathAnimation(targetIndex: 0)
                    }
                }
            }
        }
        
        // Smoothly moves the dot from center -> extreme point -> center
        private func startStarPathAnimation(targetIndex: Int) {
            guard currentPhase == .tracking else { return }
            
            // Define boundaries with padding so the dot doesn't get clipped
            let padX: CGFloat = 40
            let padY: CGFloat = 80
            
            let minX = -(view.bounds.width / 2) + padX
            let maxX = (view.bounds.width / 2) - padX
            let minY = -(view.bounds.height / 2) + padY
            let maxY = (view.bounds.height / 2) - padY
            let midX: CGFloat = 0
            let midY: CGFloat = 0
            
            // The 8 extreme points (clockwise starting from Top-Center)
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
            
            // Base case: If we've completed all 8 points, finish the exercise!
            if targetIndex >= points.count {
                finishExercise()
                return
            }
            
            let nextPoint = points[targetIndex]
            
            // Calculate the speed (duration). It starts slow and gets faster as targetIndex increases.
            // e.g., starts at 1.8 seconds per move, goes down to 0.75 seconds per move by the end.
            let maxDuration: Double = 1.8
            let minDuration: Double = 0.75
            let step = (maxDuration - minDuration) / Double(points.count - 1)
            let currentDuration = maxDuration - (Double(targetIndex) * step)
            
            // 1. Move from Center to Extreme Point
            UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
                self.circleView.transform = CGAffineTransform(translationX: nextPoint.x, y: nextPoint.y)
            } completion: { _ in
                
                guard self.currentPhase == .tracking else { return }
                
                // 2. Move from Extreme Point back to Center
                UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
                    self.circleView.transform = .identity
                } completion: { _ in
                    
                    // Recursively call for the next point
                    if self.currentPhase == .tracking {
                        self.startStarPathAnimation(targetIndex: targetIndex + 1)
                    }
                }
            }
        }
        
        // Shows a transition message
        private func startTransitionPhase(message: String, nextPhase: @escaping () -> Void) {
            currentPhase = .none // This safely stops all recursive animations and timers
            circleView.layer.removeAllAnimations()
            centerMessageLabel.text = message
            
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    nextPhase()
                }
            }
        }
        
        // Monitors if the user is keeping their eyes on the screen
        private func startGazeMonitor() {
            gazeTimer?.invalidate()
            
            gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self = self, self.currentPhase == .tracking else { return }
                
                if self.isLookingAtScreen {
                    // If they are looking, make sure warning text is hidden
                    if self.instructionLabel.alpha != 0 {
                        UIView.animate(withDuration: 0.3) {
                            self.instructionLabel.alpha = 0
                        }
                    }
                } else {
                    // If they look away, show red warning immediately and fire haptic
                    self.errorHapticGenerator.notificationOccurred(.error)
                    self.instructionLabel.layer.removeAllAnimations()
                    self.instructionLabel.textColor = .systemRed
                    self.instructionLabel.text = "⚠️ Please keep your eyes on the screen!"
                    self.instructionLabel.alpha = 1
                }
            }
        }
        
        // Finish
        private func finishExercise() {
            startTransitionPhase(message: "Nicely Done!") {
                print("Exercise Completed - Transitioning to summary")
                // Handle your view controller dismissal or segue here
            }
        }
    }
