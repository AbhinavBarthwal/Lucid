import UIKit
import ARKit
import SwiftData

class PencilPushUpViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!

    private let arSession = ARSession()
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private let successHapticGenerator = UINotificationFeedbackGenerator()
    private let heavyHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    private enum ExercisePhase {
        case none, bringingCloser, waitingForReset
    }
    private var currentPhase: ExercisePhase = .none
    
    private var isLookingAtScreen = false
    private var currentFaceDistance: Float = 0.0
    private var sessionStartTime: Date?
    private var gazeTimer: Timer?
    
    private var currentRep = 1
    private let maxReps = 5
    private var totalFramesChecked = 0
    private var totalErrors = 0

    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "3", duration: 0.6),
        InstructionStep(message: "2", duration: 0.6),
        InstructionStep(message: "1", duration: 0.6),
        InstructionStep(message: "Keep your phone at arm's length", duration: 3.0),
        InstructionStep(message: "Focus on the dot", duration: 2.5),
        InstructionStep(message: "Bring the phone closer slowly", duration: 3.0)
    ]

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // RESTORE the tab bar here
        self.tabBarController?.tabBar.isHidden = false
        
        arSession.pause()
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        
        arSession.delegate = self
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare()
        heavyHapticGenerator.prepare()
        
        centerMessageLabel.alpha = 0
        runInstructionSequence(index: 0)
    }

    // MARK: - Instruction Sequence
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
                self.sessionStartTime = Date()
                self.startBringingCloserPhase()
            }
        }
    }

    private func startBringingCloserPhase() {
        currentPhase = .bringingCloser
        
        // Prepare UI state while hidden
        self.instructionLabel.textColor = .lightGray
        self.instructionLabel.text = "Bring phone closer"
        self.circleView.transform = .identity
        
        // Fade out any lingering center messages first
        UIView.animate(withDuration: 0.3, animations: {
            self.centerMessageLabel.alpha = 0
        }) { _ in
            // Now show exercise UI
            self.fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                self.startGazeMonitor()
            }
        }
    }

    // MARK: - Rep Logic
    private func handleFullRepCompletion() {
        successHapticGenerator.notificationOccurred(.success)
        successHapticGenerator.prepare()
        gazeTimer?.invalidate()
        
        if currentRep < maxReps {
            currentRep += 1
            currentPhase = .waitingForReset
            
            // Hide exercise UI and show reset message
            fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                self.centerMessageLabel.text = "Get back to the initial position"
                UIView.animate(withDuration: 0.5) {
                    self.centerMessageLabel.alpha = 1
                }
            }
        } else {
            // Final rep finished - skip reset and go to finish
            currentPhase = .none
            finishExercise()
        }
    }

    private func finishExercise() {
        // Stop everything immediately
        gazeTimer?.invalidate()
        currentPhase = .none
        
        if let startTime = sessionStartTime {
            let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
        }
        
        heavyHapticGenerator.impactOccurred()
        
        // Full UI reset to clean state
        fadeTransition(showCenterMessage: false, showExerciseUI: false) {
            self.centerMessageLabel.text = "Exercise Complete!"
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let nav = self.navigationController {
                        nav.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Tracking & Goals
    private func checkDistanceGoal() {
        if currentPhase == .bringingCloser {
            if currentFaceDistance > 0 && currentFaceDistance <= 0.21 && isLookingAtScreen {
                handleFullRepCompletion()
            }
        } else if currentPhase == .waitingForReset {
            if currentFaceDistance >= 0.40 {
                heavyHapticGenerator.impactOccurred()
                heavyHapticGenerator.prepare()
                startBringingCloserPhase()
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        
        let lookAt = faceAnchor.lookAtPoint
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        
        let transform = faceAnchor.transform
        let distance = sqrt(pow(transform.columns.3.x, 2) + pow(transform.columns.3.y, 2) + pow(transform.columns.3.z, 2))
        self.currentFaceDistance = distance
        
        DispatchQueue.main.async {
            if self.currentPhase != .none {
                let distanceInCM = Int(self.currentFaceDistance * 100)
                self.distanceLabel.text = "\(distanceInCM) cm"
                self.checkDistanceGoal()
            }
        }
    }

    // MARK: - Helpers
    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        circleView.backgroundColor = .systemOrange
        distanceLabel.alpha = 0
        instructionLabel.alpha = 0
        circleView.alpha = 0
        centerMessageLabel.alpha = 0
    }

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

    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.currentPhase == .bringingCloser else { return }
            self.totalFramesChecked += 1
            
            if self.isLookingAtScreen {
                if self.instructionLabel.text != "Bring phone closer" {
                    UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
                }
            } else {
                self.totalErrors += 1
                self.errorHapticGenerator.notificationOccurred(.error)
                self.instructionLabel.textColor = .systemRed
                self.instructionLabel.text = "⚠️ Please look at the dot!"
                self.instructionLabel.alpha = 1
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    

}
