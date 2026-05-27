import UIKit
import ARKit

class NearFarFocusViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    
    private let arSession = ARSession()
    private var isLookingAtScreen = false
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private var isExerciseActive = true

    override var prefersStatusBarHidden: Bool { return true }
    
    private enum ExercisePhase {
        case none, near, far
    }
    private var currentPhase: ExercisePhase = .none
    private var isInstructionPhase = true
    
    private var phaseTimer: Timer?
    private var secondsRemaining = 0
    private var sessionStartTime: Date?
    private var totalFramesChecked = 0
    private var totalErrors = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        arSession.delegate = self
        errorHapticGenerator.prepare()
        startInitialCountdown()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isExerciseActive = true
        guard ARFaceTrackingConfiguration.isSupported else { return }
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isExerciseActive = false
        arSession.pause()
        phaseTimer?.invalidate(); phaseTimer = nil
        circleView.layer.removeAllAnimations()
        instructionLabel.layer.removeAllAnimations()
        currentPhase = .none
        isLookingAtScreen = false
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isExerciseActive, let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        let lookAt = faceAnchor.lookAtPoint
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
    }
    
    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        timerLabel.alpha = 0
        instructionLabel.alpha = 0
        circleView.alpha = 0
        timerLabel.isHidden = false
        instructionLabel.isHidden = false
        circleView.isHidden = false
        centerMessageLabel.alpha = 1
        centerMessageLabel.isHidden = false
    }
    
    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.timerLabel.alpha = showExerciseUI ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = showExerciseUI ? 1 : 0
        }) { _ in
            completion?()
        }
    }
    
    private func startInitialCountdown() {
        currentPhase = .none
        secondsRemaining = 5
        centerMessageLabel.text = "\(secondsRemaining)"
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isExerciseActive, self.isInstructionPhase else {
                timer.invalidate()
                return
            }
            self.secondsRemaining -= 1
            
            if self.secondsRemaining > 0 {
                self.centerMessageLabel.text = "\(self.secondsRemaining)"
            } else {
                timer.invalidate()
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    guard self.isExerciseActive, self.isInstructionPhase else { return }
                    self.sessionStartTime = Date()
                    self.showPreparationMessage("Focus on the dot, keep your screen\nwithin the range of 25-40cms") {
                        guard self.isExerciseActive, self.isInstructionPhase else { return }
                        self.startNearFocusPhase()
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, self.isExerciseActive, self.isInstructionPhase else { return }
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                guard self.isExerciseActive, self.isInstructionPhase else { return }
                completion()
            }
        }
    }
    
    private func startNearFocusPhase() {
        currentPhase = .near
        isInstructionPhase = false
        secondsRemaining = 15
        timerLabel.text = "\(secondsRemaining)"
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Focus on the dot, keep your screen\nwithin the range of 25-40cms"
        
        circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: 15.0, delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }
            self.startPhaseTimer {
                guard self.isExerciseActive else { return }
                self.startTransitionPhase(nextPhase: self.prepareFarFocus)
            }
        }
    }
    
    private func prepareFarFocus() {
        showPreparationMessage("Focus at a distant object\nor look outside the window") { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.startFarFocusPhase()
        }
    }
    
    private func startFarFocusPhase() {
        currentPhase = .far
        secondsRemaining = 15
        timerLabel.text = "\(secondsRemaining)"
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Focus at a distant object\nor look outside the window"
        
        circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: 15.0, delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            self.startPhaseTimer {
                guard self.isExerciseActive else { return }
                self.finishExercise()
            }
        }
    }
    
    private func startTransitionPhase(nextPhase: @escaping () -> Void) {
        currentPhase = .none
        circleView.layer.removeAllAnimations()
        centerMessageLabel.text = "Nicely Done!"
        
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                guard self.isExerciseActive else { return }
                nextPhase()
            }
        }
    }
    
    private func startPhaseTimer(completion: @escaping () -> Void) {
        phaseTimer?.invalidate()
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isExerciseActive else {
                timer.invalidate()
                return
            }
            
            self.totalFramesChecked += 1
            var isValid = true
            
            if self.currentPhase == .near {
                isValid = self.isLookingAtScreen
                self.instructionLabel.textColor = isValid ? .lightGray : .systemRed
                self.instructionLabel.text = isValid ? "Focus on the dot, keep your screen\nwithin the range of 25-40cms" : "⚠️ Please look AT the screen!"
            } else if self.currentPhase == .far {
                isValid = !self.isLookingAtScreen
                self.instructionLabel.textColor = isValid ? .lightGray : .systemRed
                self.instructionLabel.text = isValid ? "Focus at a distant object\nor look outside the window" : "⚠️ Please look AWAY from the screen!"
            }
            
            if isValid {
                self.secondsRemaining -= 1
                self.timerLabel.text = "\(self.secondsRemaining)"
            } else {
                self.totalErrors += 1
                self.errorHapticGenerator.notificationOccurred(.error)
            }
            
            if self.secondsRemaining <= 0 {
                timer.invalidate()
                self.instructionLabel.textColor = .lightGray
                completion()
            }
        }
    }
    
    private func finishExercise() {
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
        
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(
            type: "NearFar",
            duration: elapsedSeconds,
            accuracy: accuracy,
            errors: totalErrors
        )
        newSession.user = user
        context.insert(newSession)
        
        do {
            try context.save()
            errorHapticGenerator.notificationOccurred(.success)
        } catch {
            print("❌ Near Far Focus Save failed: \(error)")
        }
        
        currentPhase = .none
        circleView.layer.removeAllAnimations()
        let messages = [
            "Fantastic job!",
            "Great work!",
            "Awesome focus!",
            "Excellent effort!",
            "Superb session!",
            "Nicely done!",
            "Brilliant job!"
        ]
        centerMessageLabel.font = .systemFont(ofSize: 36, weight: .bold)
        centerMessageLabel.text = messages.randomElement() ?? "Nicely Done!"
        
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.isExerciseActive = false
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }


}
