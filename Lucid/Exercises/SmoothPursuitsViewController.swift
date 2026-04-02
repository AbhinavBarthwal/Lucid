import UIKit
import ARKit
import SwiftData

struct InstructionStep {
    let message: String
    let duration: TimeInterval
}

class SmoothPursuitsViewController: UIViewController, ARSessionDelegate {

    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var centerMessageLabel: UILabel!
    @IBOutlet private weak var circleView: UIView!

    private let arSession = ARSession()
    private var isLookingAtScreen = false
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private let successHapticGenerator = UINotificationFeedbackGenerator()

    private var sessionStartTime: Date?
    private enum ExercisePhase { case none, tracking }
    private var currentPhase: ExercisePhase = .none
    private var gazeTimer: Timer?
    
    private var currentSpeedLevel = 0
    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "3", duration: 0.6),
        InstructionStep(message: "2", duration: 0.6),
        InstructionStep(message: "1", duration: 0.6),
        InstructionStep(message: "Follow the dot closely", duration: 2.0),
        InstructionStep(message: "Keep your head still", duration: 1.5),
        InstructionStep(message: "Keep your phone at 20cm", duration: 2.0)
    ]

    private let phaseDurations: [Double] = [2.0 , 1.5 , 1.0]
    
    var modelContext: ModelContext?
    private var totalFramesChecked = 0
    private var totalErrors = 0
    private var currentTargetDirectionIndex = 0
    private var directionChecks: [String: Int] = [:]
    private var directionFails: [String: Int] = [:]
    private var headMovementSamples: [Float] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        arSession.delegate = self
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare()

        centerMessageLabel.alpha = 0
        runInstructionSequence(index: 0)
    }

    private func runInstructionSequence(index: Int) {
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            

            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
   
                self.centerMessageLabel.text = step.message
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) {
                        self.runInstructionSequence(index: index + 1)
                    }
                }
            }
        } else {

            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                self.startSmoothPursuitPhase()
            }
        }
    }

    private func startSmoothPursuitPhase() {
        currentPhase = .tracking
        if sessionStartTime == nil { sessionStartTime = Date() }

        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Keep your head still and follow the dot"
        
        // Show exercise UI
        fadeTransition(showCenterMessage: false, showExerciseUI: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard self.currentPhase == .tracking else { return }
                
                UIView.animate(withDuration: 0.5) {
                    self.instructionLabel.alpha = 0
                } completion: { _ in
                    self.startGazeMonitor()
                    self.startStarPathAnimation(targetIndex: 0)
                }
            }
        }
    }

    private func startStarPathAnimation(targetIndex: Int) {
        guard currentPhase == .tracking else { return }

        let padX: CGFloat = 40
        let padY: CGFloat = 80
        let points: [CGPoint] = [
            CGPoint(x: 0, y: -(view.bounds.height / 2) + padY),
            CGPoint(x: (view.bounds.width / 2) - padX, y: -(view.bounds.height / 2) + padY),
            CGPoint(x: (view.bounds.width / 2) - padX, y: 0),
            CGPoint(x: (view.bounds.width / 2) - padX, y: (view.bounds.height / 2) - padY),
            CGPoint(x: 0, y: (view.bounds.height / 2) - padY),
            CGPoint(x: -(view.bounds.width / 2) + padX, y: (view.bounds.height / 2) - padY),
            CGPoint(x: -(view.bounds.width / 2) + padX, y: 0),
            CGPoint(x: -(view.bounds.width / 2) + padX, y: -(view.bounds.height / 2) + padY)
        ]

        if targetIndex >= points.count {
            handlePhaseTransition()
            return
        }

        self.currentTargetDirectionIndex = targetIndex
        let nextPoint = points[targetIndex]
        let currentDuration = phaseDurations[currentSpeedLevel]

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

    private func handlePhaseTransition() {
            currentSpeedLevel += 1
            
            // Trigger haptic to signal the phase is complete
            successHapticGenerator.notificationOccurred(.success)
            // Re-prepare so it's ready for the next trigger without delay
            successHapticGenerator.prepare()

            if currentSpeedLevel > 2 {
                // If we've finished all 3 speeds, wrap it up
                finishExercise()
            } else {
                // Pause the monitor for the mid-exercise break
                gazeTimer?.invalidate()
                
                let message = currentSpeedLevel == 1 ? "Good, Let's ramp up the speed" : "Final round! Maximum speed"
                
                showTransitionMessage(message) {
                    self.startSmoothPursuitPhase()
                }
            }
        }

        private func showTransitionMessage(_ message: String, completion: @escaping () -> Void) {
            currentPhase = .none
            
            // Smooth cinematic fade for the phase transition message
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                self.centerMessageLabel.text = message
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    // Give them a moment to read the "Ramp up" text
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        UIView.animate(withDuration: 0.4, animations: {
                            self.centerMessageLabel.alpha = 0
                        }) { _ in
                            completion()
                        }
                    }
                }
            }
        }

    // MARK: - ARSession, UI Helpers, and Restored Logic
    // (Rest of the logic including startGazeMonitor, session, and finishExercise remains identical to your code)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard ARFaceTrackingConfiguration.isSupported else { return }
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSession.pause()
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        let lookAt = faceAnchor.lookAtPoint
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        if currentPhase == .tracking {
            let transform = faceAnchor.transform
            let pitch = abs(asin(min(1.0, max(-1.0, Double(transform.columns.2.y)))))
            let yaw = abs(atan2(Double(transform.columns.2.x), Double(transform.columns.2.z)))
            let totalMovementDegrees = Float((pitch + yaw) * (180.0 / .pi))
            headMovementSamples.append(totalMovementDegrees)
        }
    }

    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        instructionLabel.alpha = 0
        circleView.alpha = 0
        instructionLabel.isHidden = false
        circleView.isHidden = false
        centerMessageLabel.isHidden = false
    }

    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = showExerciseUI ? 1 : 0
        }) { _ in completion?() }
    }

    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.currentPhase == .tracking else { return }
            self.totalFramesChecked += 1
            let currentDirection = self.getDirectionName(for: self.currentTargetDirectionIndex)
            self.directionChecks[currentDirection, default: 0] += 1
            if self.isLookingAtScreen {
                if self.instructionLabel.alpha != 0 { UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 } }
            } else {
                self.totalErrors += 1
                self.directionFails[currentDirection, default: 0] += 1
                self.errorHapticGenerator.notificationOccurred(.error)
                self.instructionLabel.textColor = .systemRed
                self.instructionLabel.text = "⚠️ Please keep your eyes on the screen!"
                self.instructionLabel.alpha = 1
            }
        }
    }

    private func getDirectionName(for index: Int) -> String {
        let names = ["top", "topRight", "right", "bottomRight", "bottom", "bottomLeft", "left", "topLeft"]
        return (index >= 0 && index < names.count) ? names[index] : "center"
    }

    private func finishExercise() {
        currentPhase = .none
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
        let avgHeadMovement: Float = headMovementSamples.isEmpty ? 0.0 : headMovementSamples.reduce(0, +) / Float(headMovementSamples.count)
        var calculatedDirectionErrors: [String: Double] = [:]
        for (direction, totalChecks) in directionChecks {
            let fails = directionFails[direction] ?? 0
            calculatedDirectionErrors[direction] = totalChecks > 0 ? (Double(fails) / Double(totalChecks)) * 100.0 : 0.0
        }
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(type: "SmoothPursuit", duration: elapsedSeconds, accuracy: accuracy, errors: totalErrors)
        newSession.user = user
        newSession.headMovementDegrees = avgHeadMovement
        newSession.directionErrors = calculatedDirectionErrors
        context.insert(newSession)
        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Report", bundle: nil)
            guard let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController else { return }
            reportVC.sessionType = "SmoothPursuit"; reportVC.overallScore = accuracy; reportVC.totalErrors = self.totalErrors; reportVC.avgHeadMovement = avgHeadMovement; reportVC.directionErrors = calculatedDirectionErrors
            let nav = UINavigationController(rootViewController: reportVC); nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
        ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
        do { try context.save(); successHapticGenerator.notificationOccurred(.success) } catch { print("Error: \(error)") }
        startTransitionPhase(message: "Nicely Done!") {
            if let nav = self.navigationController { nav.popViewController(animated: true) } else { self.dismiss(animated: true) }
        }
    }

    private func startTransitionPhase(message: String, nextPhase: @escaping () -> Void) {
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        centerMessageLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) { nextPhase() }
        }
    }
}
