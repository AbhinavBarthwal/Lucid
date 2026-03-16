//
//  PencilPushUpViewController.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/16/26.
//

import UIKit
import ARKit

class PencilPushUpViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    //

        @IBOutlet weak var distanceLabel: UILabel! // New top label for distance

        // AR session to run head tracking for distance calculation.
        private let arSession = ARSession()
        
        // Haptic feedback for successful movements
        private let hapticGenerator = UINotificationFeedbackGenerator()
        
        // Categorizes the phases of the push-up exercise.
        private enum ExercisePhase {
            case none, bringingCloser, movingBack
        }
        private var currentPhase: ExercisePhase = .none
        
        // Tracks current distance from face to camera in meters
        private var currentFaceDistance: Float = 0.0
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupInitialUI()
            arSession.delegate = self
            hapticGenerator.prepare()
            
            // Start the sequence after a brief delay so the UI can load
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startInitialSequence()
            }
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
            circleView.layer.removeAllAnimations()
        }
        
        // Configures the starting opacities
        private func setupInitialUI() {
            circleView.layer.cornerRadius = circleView.bounds.width / 2
            circleView.backgroundColor = .systemOrange // To match your yellow/orange dot
            
            distanceLabel.alpha = 0
            instructionLabel.alpha = 0
            circleView.alpha = 0
            centerMessageLabel.alpha = 0
            
            distanceLabel.isHidden = false
            instructionLabel.isHidden = false
            circleView.isHidden = false
            centerMessageLabel.isHidden = false
        }
        
        // ARKit session delegate to calculate face distance
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
            
            // Extract the translation (position) matrix from the face anchor
            let transform = faceAnchor.transform
            
            // Calculate the straight-line distance in meters using Pythagorean theorem on X, Y, Z
            let distance = sqrt(pow(transform.columns.3.x, 2) + pow(transform.columns.3.y, 2) + pow(transform.columns.3.z, 2))
            self.currentFaceDistance = distance
            
            // Update the UI and check goals on the main thread
            DispatchQueue.main.async {
                // Convert to cm and update the top label if an exercise phase is active
                if self.currentPhase != .none {
                    let distanceInCM = Int(self.currentFaceDistance * 100)
                    self.distanceLabel.text = "\(distanceInCM) cm"
                }
                
                self.checkDistanceGoal()
            }
        }
        
        // Crossfades between the instructional center text and the exercise UI.
        private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
                self.instructionLabel.alpha = showExerciseUI ? 1 : 0
                self.circleView.alpha = showExerciseUI ? 1 : 0
                self.distanceLabel.alpha = showExerciseUI ? 1 : 0
            }) { _ in
                completion?()
            }
        }
        
        // Helper function to chain messages on screen easily
        private func showMessage(_ text: String, duration: TimeInterval, completion: @escaping () -> Void) {
            self.centerMessageLabel.text = text
            self.fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    completion()
                }
            }
        }
        
        // MARK: - Exercise Sequences
        
        private func startInitialSequence() {
            showMessage("Keep your phone at arm's length", duration: 3.0) {
                self.showMessage("focus on the yellow dot and slowly bring your phone closer till the dot is in focus", duration: 4.0) {
                    self.startBringingCloserPhase()
                }
            }
        }
        
        private func startBringingCloserPhase() {
            instructionLabel.text = "bring your phone\ncloser"
            circleView.transform = .identity // Normal size dot
            
            fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                self.currentPhase = .bringingCloser
            }
        }
        
        private func startReverseSequence() {
            showMessage("Nicely done !", duration: 2.0) {
                self.showMessage("Let's do it in reverse", duration: 2.0) {
                    self.showMessage("Hold your phone as close as possible", duration: 2.0) {
                        self.showMessage("Make sure the dot is in focus", duration: 2.5) {
                            self.startMovingBackPhase()
                        }
                    }
                }
            }
        }
        
        private func startMovingBackPhase() {
            instructionLabel.text = "Move your phone back"
            
            // Scale the dot up slightly to simulate it being close to the face, matching the video
            circleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            
            fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                self.currentPhase = .movingBack
            }
        }
        
        // MARK: - Core Logic
        
        private func checkDistanceGoal() {
            if currentPhase == .bringingCloser {
                // Target: Less than or equal to 15cm (0.15 meters)
                if currentFaceDistance > 0 && currentFaceDistance <= 0.20 {
                    currentPhase = .none // Lock it so it doesn't trigger repeatedly
                    hapticGenerator.notificationOccurred(.success)
                    startReverseSequence()
                }
            } else if currentPhase == .movingBack {
                // Target: Greater than or equal to 40cm (0.40 meters)
                if currentFaceDistance >= 0.50 {
                    currentPhase = .none // Lock it
                    hapticGenerator.notificationOccurred(.success)
                    finishExercise()
                }
            }
        }
        
        private func finishExercise() {
            showMessage("Nicely done !", duration: 2.5) {
                print("Exercise Completed - Transitioning to summary")
                // Handle your view controller dismissal or segue here
            }
        }
    }
