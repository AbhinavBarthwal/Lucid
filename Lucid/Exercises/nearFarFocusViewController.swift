import UIKit
import AVFoundation
import ARKit
import AudioToolbox

class NearFarFocusViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    
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
    
    private var currentRound = 1
    private let totalRounds = 10
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let arSession = ARSession()
    private var isLookingAtScreen = false
    private var totalFramesChecked = 0
    private var totalErrors = 0
    private var gazeTimer: Timer?
    
    // Navigation/Skip buttons for instructions
    private var instructionNextButton: UIButton?
    private var instructionPrevButton: UIButton?
    private var currentInstructionIndex = 0

    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "You will be asked to look at the screen and look away please follow accordingly.", duration: 7.0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
            try session.setActive(true)
        } catch {
            print("Audio Session error: \(error)")
        }
        
        setupEyeTracking()
        setupInstructionButtons()
        runInstructionSequence(index: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isExerciseActive = true
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isExerciseActive = false
        phaseTimer?.invalidate(); phaseTimer = nil
        gazeTimer?.invalidate(); gazeTimer = nil
        circleView.layer.removeAllAnimations()
        instructionLabel.layer.removeAllAnimations()
        currentPhase = .none
        arSession.pause()
        self.tabBarController?.tabBar.isHidden = false
        
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
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
        
        instructionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        instructionLabel.textColor = .lightGray
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        
        centerMessageLabel.font = .systemFont(ofSize: 32, weight: .bold)
        centerMessageLabel.textColor = .white
        centerMessageLabel.textAlignment = .center
        centerMessageLabel.numberOfLines = 0
        
        timerLabel.numberOfLines = 0
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
    
    private func transitionToNextPhase(completion: @escaping () -> Void) {
        gazeTimer?.invalidate(); gazeTimer = nil
        UIView.animate(withDuration: 0.3, animations: {
            self.timerLabel.alpha = 0
            self.instructionLabel.alpha = 0
            self.circleView.alpha = 0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.isExerciseActive else { return }
                completion()
            }
        }
    }
    
    private func runInstructionSequence(index: Int) {
        guard isExerciseActive, isInstructionPhase else { return }
        currentInstructionIndex = index
        let isFirstRun = InstructionTracker.isFirstRun(for: "NearFar")
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            if isFirstRun {
                instructionNextButton?.isHidden = false
                let canGoBack = index > 0
                instructionPrevButton?.isHidden = !canGoBack
                
                let isLastStep = (index == exerciseInstructions.count - 1)
                instructionNextButton?.setTitle(isLastStep ? "Start Exercise" : "Next", for: .normal)
            } else {
                instructionNextButton?.isHidden = false
                instructionPrevButton?.isHidden = true
                instructionNextButton?.setTitle("Skip", for: .normal)
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive, self.isInstructionPhase else { return }
                self.centerMessageLabel.text = step.message
                
                self.instructionLabel.textColor = .lightGray
                self.instructionLabel.text = ""
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                    self.instructionLabel.alpha = 1.0
                }) { _ in
                    if !isFirstRun {
                        DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                            guard let self = self, self.isExerciseActive, self.isInstructionPhase, self.currentInstructionIndex == index else { return }
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
        let isFirstRun = InstructionTracker.isFirstRun(for: "NearFar")
        
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
        if InstructionTracker.isFirstRun(for: "NearFar") {
            runInstructionSequence(index: currentInstructionIndex + 1)
        } else {
            finishInstructionsAndStartExercise()
        }
    }
    
    @objc private func instructionPrevTapped() {
        if InstructionTracker.isFirstRun(for: "NearFar") && currentInstructionIndex > 0 {
            runInstructionSequence(index: currentInstructionIndex - 1)
        }
    }
    
    private func finishInstructionsAndStartExercise() {
        InstructionTracker.markAsCompleted(for: "NearFar")
        currentInstructionIndex = 999
        
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionNextButton?.alpha = 0
            self.instructionPrevButton?.alpha = 0
        }) { _ in
            self.instructionNextButton?.removeFromSuperview()
            self.instructionPrevButton?.removeFromSuperview()
        }
        
        runStartCountdown { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.sessionStartTime = Date()
            self.startNearFocusPhase()
        }
    }

    private func runStartCountdown(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.centerMessageLabel.alpha = 0
            self.instructionLabel.alpha = 0
        }) { _ in
            self.centerMessageLabel.text = "3"
            UIView.animate(withDuration: 0.3, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.isExerciseActive else { return }
                    UIView.animate(withDuration: 0.2, animations: {
                        self.centerMessageLabel.alpha = 0
                    }) { _ in
                        self.centerMessageLabel.text = "2"
                        UIView.animate(withDuration: 0.3, animations: {
                            self.centerMessageLabel.alpha = 1
                        }) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                guard let self = self, self.isExerciseActive else { return }
                                UIView.animate(withDuration: 0.2, animations: {
                                    self.centerMessageLabel.alpha = 0
                                }) { _ in
                                    self.centerMessageLabel.text = "1"
                                    UIView.animate(withDuration: 0.3, animations: {
                                        self.centerMessageLabel.alpha = 1
                                    }) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                            guard let self = self, self.isExerciseActive else { return }
                                            UIView.animate(withDuration: 0.3, animations: {
                                                self.centerMessageLabel.alpha = 0
                                            }) { _ in
                                                self.centerMessageLabel.text = ""
                                                completion()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func speak(_ text: String) {
        guard isExerciseActive else { return }
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 1.0
        speechSynthesizer.speak(utterance)
    }
    
    private func startNearFocusPhase() {
        guard isExerciseActive else { return }
        currentPhase = .near
        isInstructionPhase = false
        
        let randomDuration = Int.random(in: 3...8)
        secondsRemaining = randomDuration
        timerLabel.text = "\(secondsRemaining)"
        
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Look at the screen\n\(currentRound)/\(totalRounds)"
        
        speak("Look at the screen")
        
        circleView.layer.removeAllAnimations()
        circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: Double(randomDuration), delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            self.startGazeMonitor()
            self.startPhaseTimer {
                guard self.isExerciseActive else { return }
                self.transitionToNextPhase {
                    self.startFarFocusPhase()
                }
            }
        }
    }
    
    private func startFarFocusPhase() {
        guard isExerciseActive else { return }
        currentPhase = .far
        
        let randomDuration = Int.random(in: 3...8)
        secondsRemaining = randomDuration
        timerLabel.text = "\(secondsRemaining)"
        
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Look away from the screen"
        
        speak("Look away")
        
        circleView.layer.removeAllAnimations()
        circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: Double(randomDuration), delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }
            self.startGazeMonitor()
            self.startPhaseTimer {
                guard self.isExerciseActive else { return }
                
                if self.currentRound < self.totalRounds {
                    self.currentRound += 1
                    self.transitionToNextPhase {
                        self.startNearFocusPhase()
                    }
                } else {
                    self.transitionToNextPhase {
                        self.finishExercise()
                    }
                }
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
            
            self.secondsRemaining -= 1
            self.timerLabel.text = "\(self.secondsRemaining)"
            
            if self.secondsRemaining <= 0 {
                timer.invalidate()
                completion()
            }
        }
    }
    
    private func finishExercise() {
        gazeTimer?.invalidate(); gazeTimer = nil
        arSession.pause()
        
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 100
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
            Vibrator.playSuccess()
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
    
    private func setupEyeTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        arSession.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isExerciseActive, let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        let lookAt = faceAnchor.lookAtPoint
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
    }
    
    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isExerciseActive else { return }
                self.totalFramesChecked += 1
                
                if self.currentPhase == .near {
                    if self.isLookingAtScreen {
                        if self.instructionLabel.textColor == .systemRed {
                            UIView.animate(withDuration: 0.3) {
                                self.instructionLabel.textColor = .lightGray
                                self.instructionLabel.text = "Look at the screen\n\(self.currentRound)/\(self.totalRounds)"
                            }
                        }
                    } else {
                        self.totalErrors += 1
                        Vibrator.playError()
                        self.instructionLabel.textColor = .systemRed
                        self.instructionLabel.text = "⚠️ Please look at the screen!"
                    }
                } else if self.currentPhase == .far {
                    if !self.isLookingAtScreen {
                        if self.instructionLabel.textColor == .systemRed {
                            UIView.animate(withDuration: 0.3) {
                                self.instructionLabel.textColor = .lightGray
                                self.instructionLabel.text = "Look away from the screen"
                            }
                        }
                    } else {
                        self.totalErrors += 1
                        Vibrator.playError()
                        self.instructionLabel.textColor = .systemRed
                        self.instructionLabel.text = "Please look away from the screen!"
                    }
                }
            }
        }
    }
}
