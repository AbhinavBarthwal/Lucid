import UIKit
import ARKit

private enum PencilPushUpExercisePhase {
    case none, bringingCloser, waitingForReset
}

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

    override var prefersStatusBarHidden: Bool { return true }
    
    private var currentPhase: PencilPushUpExercisePhase = .none
    
    private var isLookingAtScreen = false
    private var currentFaceDistance: Float = 0.0
    private var sessionStartTime: Date?
    private var gazeTimer: Timer?
    
    private var currentRep = 1
    private let maxReps = 8
    private var totalFramesChecked = 0
    private var totalErrors = 0

    // Navigation/Skip buttons for instructions
    private var instructionNextButton: UIButton?
    private var instructionPrevButton: UIButton?
    private var currentInstructionIndex = 0

    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "3", duration: 1.0),
        InstructionStep(message: "2", duration: 1.0),
        InstructionStep(message: "1", duration: 1.0),
        InstructionStep(message: "Keep your phone at arm's length", duration: 3.0),
        InstructionStep(message: "Focus on the green dot at the top of the display", duration: 2.5),
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
        setupInstructionButtons()
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
        guard isExerciseActive, currentPhase == .none else { return }
        currentInstructionIndex = index
        let isFirstRun = InstructionTracker.isFirstRun(for: "PencilPushup")
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            let isCountdown = Int(step.message) != nil
            
            if isCountdown {
                instructionNextButton?.isHidden = true
                instructionPrevButton?.isHidden = true
            } else {
                if isFirstRun {
                    instructionNextButton?.isHidden = false
                    let canGoBack = index > 0 && Int(exerciseInstructions[index - 1].message) == nil
                    instructionPrevButton?.isHidden = !canGoBack
                    
                    let isLastStep = (index == exerciseInstructions.count - 1)
                    instructionNextButton?.setTitle(isLastStep ? "Start Exercise" : "Next", for: .normal)
                } else {
                    instructionNextButton?.isHidden = false
                    instructionPrevButton?.isHidden = true
                    instructionNextButton?.setTitle("Skip", for: .normal)
                }
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive, self.currentPhase == .none else { return }
                self.centerMessageLabel.text = step.message
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    if isCountdown || !isFirstRun {
                        DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                            guard let self = self, self.isExerciseActive, self.currentPhase == .none, self.currentInstructionIndex == index else { return }
                            self.runInstructionSequence(index: index + 1)
                        }
                    }
                }
            }
        } else {
            finishInstructionsAndStartExercise()
        }
    }

    private func setupInstructionButtons() {
        let isFirstRun = InstructionTracker.isFirstRun(for: "PencilPushup")
        
        let nextBtn = UIButton(type: .system)
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.layer.cornerRadius = 14
        nextBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextBtn.setTitleColor(.white, for: .normal)
        nextBtn.backgroundColor = UIColor(named: "AccentColor") ?? .systemOrange
        view.addSubview(nextBtn)
        self.instructionNextButton = nextBtn
        nextBtn.addTarget(self, action: #selector(instructionNextTapped), for: .touchUpInside)
        
        if isFirstRun {
            nextBtn.setTitle("Next", for: .normal)
            
            let prevBtn = UIButton(type: .system)
            prevBtn.translatesAutoresizingMaskIntoConstraints = false
            prevBtn.layer.cornerRadius = 14
            prevBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            prevBtn.setTitleColor(.white, for: .normal)
            prevBtn.backgroundColor = .clear
            prevBtn.layer.borderWidth = 1
            prevBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            prevBtn.setTitle("Previous", for: .normal)
            view.addSubview(prevBtn)
            self.instructionPrevButton = prevBtn
            prevBtn.addTarget(self, action: #selector(instructionPrevTapped), for: .touchUpInside)
            
            NSLayoutConstraint.activate([
                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                nextBtn.bottomAnchor.constraint(equalTo: prevBtn.topAnchor, constant: -12),
                nextBtn.heightAnchor.constraint(equalToConstant: 50),
                
                prevBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                prevBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                prevBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                prevBtn.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            prevBtn.isHidden = true // Hidden initially for step 0
        } else {
            nextBtn.setTitle("Skip", for: .normal)
            
            NSLayoutConstraint.activate([
                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                nextBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                nextBtn.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }
    
    @objc private func instructionNextTapped() {
        if InstructionTracker.isFirstRun(for: "PencilPushup") {
            runInstructionSequence(index: currentInstructionIndex + 1)
        } else {
            finishInstructionsAndStartExercise()
        }
    }
    
    @objc private func instructionPrevTapped() {
        if InstructionTracker.isFirstRun(for: "PencilPushup") && currentInstructionIndex > 0 {
            runInstructionSequence(index: currentInstructionIndex - 1)
        }
    }
    
    private func finishInstructionsAndStartExercise() {
        InstructionTracker.markAsCompleted(for: "PencilPushup")
        
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionNextButton?.alpha = 0
            self.instructionPrevButton?.alpha = 0
        }) { _ in
            self.instructionNextButton?.removeFromSuperview()
            self.instructionPrevButton?.removeFromSuperview()
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = 0
        }) { _ in
            guard self.isExerciseActive, self.currentPhase == .none else { return }
            self.sessionStartTime = Date()
            self.startBringingCloserPhase()
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
                self.instructionLabel.text = nil
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
        
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
        
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(
            type: "PencilPushup",
            duration: elapsedSeconds,
            accuracy: accuracy,
            errors: totalErrors
        )
        newSession.user = user
        context.insert(newSession)
        
        do {
            try context.save()
            heavyHapticGenerator.impactOccurred()
        } catch {
            print("❌ Pencil Push-Ups Save failed: \(error)")
        }
        
        fadeTransition(showCenterMessage: false, showExerciseUI: false) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            let messages = [
                "Fantastic job!",
                "Great work!",
                "Awesome focus!",
                "Excellent effort!",
                "Superb session!",
                "Nicely done!",
                "Brilliant job!"
            ]
            self.centerMessageLabel.font = .systemFont(ofSize: 36, weight: .bold)
            self.centerMessageLabel.text = messages.randomElement() ?? "Exercise Complete!"
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    guard self.isExerciseActive else { return }
                    self.isExerciseActive = false
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
        circleView.backgroundColor = .accent
        distanceLabel.alpha = 0
        instructionLabel.alpha = 0
        circleView.alpha = 0
        circleView.isHidden = true
        centerMessageLabel.alpha = 0
    }

    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = 0
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
                self.instructionLabel.text = "⚠️ Please look at the green dot at the top of the display!"
                self.instructionLabel.alpha = 1
            }
        }
    }


}
