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
    private var isExerciseActive = true
    
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
        self.tabBarController?.tabBar.isHidden = false
        arSession.pause()
        gazeTimer?.invalidate(); gazeTimer = nil
        circleView.layer.removeAllAnimations()
        centerMessageLabel.layer.removeAllAnimations()
        instructionLabel.layer.removeAllAnimations()
        currentPhase = .none
        isLookingAtScreen = false
    }

    private func runInstructionSequence(index: Int) {
        guard isExerciseActive else { return }
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive else { return }
                self.centerMessageLabel.text = step.message
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                        guard let self = self, self.isExerciseActive else { return }
                        self.runInstructionSequence(index: index + 1)
                    }
                }
            }
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive else { return }
                self.sessionStartTime = Date()
                self.startBringingCloserPhase()
            }
        }
    }

    private func startBringingCloserPhase() {
        guard isExerciseActive else { return }
        currentPhase = .bringingCloser
        self.instructionLabel.textColor = .lightGray
        self.instructionLabel.text = "Bring phone closer"
        self.circleView.transform = .identity
        
        UIView.animate(withDuration: 0.3, animations: {
            self.centerMessageLabel.alpha = 0
        }) { _ in
            guard self.isExerciseActive else { return }
            self.fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                guard self.isExerciseActive else { return }
                self.startGazeMonitor()
            }
        }
    }

    private func handleFullRepCompletion() {
        guard isExerciseActive else { return }
        successHapticGenerator.notificationOccurred(.success)
        successHapticGenerator.prepare()
        gazeTimer?.invalidate()
        
        if currentRep < maxReps {
            currentRep += 1
            currentPhase = .waitingForReset
            
            fadeTransition(showCenterMessage: false, showExerciseUI: false) { [weak self] in
                guard let self = self, self.isExerciseActive else { return }
                self.centerMessageLabel.text = "Get back to the initial position"
                UIView.animate(withDuration: 0.5) {
                    self.centerMessageLabel.alpha = 1
                }
            }
        } else {
            currentPhase = .none
            finishExercise()
        }
    }

    private func finishExercise() {
        guard isExerciseActive else { return }
        gazeTimer?.invalidate()
        currentPhase = .none
        
        if let startTime = sessionStartTime {
            let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
        }
        
        heavyHapticGenerator.impactOccurred()
        
        fadeTransition(showCenterMessage: false, showExerciseUI: false) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.centerMessageLabel.text = "Exercise Complete!"
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    guard self.isExerciseActive else { return }
                    if let nav = self.navigationController {
                        nav.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }

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
        guard isExerciseActive, let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        
        let lookAt = faceAnchor.lookAtPoint
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        
        let transform = faceAnchor.transform
        let distance = sqrt(pow(transform.columns.3.x, 2) + pow(transform.columns.3.y, 2) + pow(transform.columns.3.z, 2))
        self.currentFaceDistance = distance
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            if self.currentPhase != .none {
                let distanceInCM = Int(self.currentFaceDistance * 100)
                self.distanceLabel.text = "\(distanceInCM) cm"
                self.checkDistanceGoal()
            }
        }
    }

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
            guard let self = self, self.isExerciseActive, self.currentPhase == .bringingCloser else { return }
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
}
