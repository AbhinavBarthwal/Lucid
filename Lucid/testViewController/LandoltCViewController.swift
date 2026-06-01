import UIKit
import ARKit
import Speech
import AudioToolbox

class LandoltCViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var landoltImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet var numbers: [UILabel]!

    // MARK: - Presenter Callbacks & Toggles (Fixes the OnboardingPresenter error)
    var onTestCompleted: (() -> Void)?
    var shouldShowCompletionSummary: Bool = true

    // MARK: - Speech
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let notificationGen = UINotificationFeedbackGenerator()

    // MARK: - Test State
    private var currentScale: CGFloat = 1.0
    private var leftEyeScore = 0
    private var rightEyeScore = 0
    private var iterationCount = 0
    private let maxIterations = 6
    private var currentCorrectNumber = ""

    private var isTestingRightEye    = false
    private var isEyeRequirementMet  = true
    private var isProcessing         = false
    private var isTestActive         = false
    private var didComplete          = false
    private var isMicActive          = false   // tracks whether mic is genuinely open
    private var isInstructionPhase   = true

    // Navigation/Skip buttons for instructions
    private var instructionNextButton: UIButton?
    private var instructionPrevButton: UIButton?
    private var currentInstructionIndex = 0

    private let eyeWarningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 0
        label.alpha = 0
        return label
    }()
    private var lastUpdateTimestamp: TimeInterval = 0
    private var incorrectEyeOpenDuration: TimeInterval = 0
    private var isWarningShown = false

    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "In this test, you must speak the matching numbers out loud!", duration: 4.5),
        InstructionStep(message: "Please hold your phone at arm's length", duration: 3.5),
        InstructionStep(message: "Look at the opening and say the matching number out loud!", duration: 4.5),
        InstructionStep(message: "If it's hard to see, just say 'cannot see' or 'skip' to move on.", duration: 5.5),
        InstructionStep(message: "You will see the flashes around the edges for your response.", duration: 6.0)
    ]

    private let directionMap: [Int: String] = [
        0: "4", 45: "5", 90: "6", 135: "7", 180: "8", 225: "1", 270: "2", 315: "3"
    ]

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIInitialState()
        setupARKit()
        setupSpeech()
        instructionLabel.alpha = 0
        setupInstructionButtons()
        
        // Adjust the numbers spacing programmatically to prevent them from sticking to the edges
        for label in numbers {
            for constraint in view.constraints {
                if constraint.firstItem === label {
                    if constraint.firstAttribute == .leading {
                        constraint.constant = 24
                    } else if constraint.firstAttribute == .trailing {
                        constraint.constant = -24
                    }
                } else if constraint.secondItem === label {
                    if constraint.secondAttribute == .leading {
                        constraint.constant = -24
                    } else if constraint.secondAttribute == .trailing {
                        constraint.constant = 24
                    }
                }
            }
        }
        
        runInstructionSequence(index: 0)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudio(hideBorder: true)
        // Assuming SiriListeningBorderView is implemented elsewhere in your project
        SiriListeningBorderView.shared.stopListening()
        sceneView?.session.pause()
    }

    // MARK: - UI Setup

    private func setupUIInitialState() {
        view.backgroundColor = .black
        sceneView.alpha = 0
        landoltImageView.alpha = 0
        statusLabel.alpha = 0
        self.numbers.forEach { $0.alpha = 0 }
        
        statusLabel.numberOfLines = 0
        instructionLabel.numberOfLines = 0
        
        view.addSubview(eyeWarningLabel)
        eyeWarningLabel.numberOfLines = 0
        NSLayoutConstraint.activate([
            eyeWarningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            eyeWarningLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            eyeWarningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            eyeWarningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - Countdown & Instructions

    // MARK: - Countdown & Instructions

    private func runInstructionSequence(index: Int) {
        guard isInstructionPhase else { return }
        currentInstructionIndex = index
        let isFirstRun = InstructionTracker.isFirstRun(for: "CTest")
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            if isFirstRun {
                instructionNextButton?.isHidden = false
                let canGoBack = index > 0
                instructionPrevButton?.isHidden = !canGoBack
                
                let isLastStep = (index == exerciseInstructions.count - 1)
                instructionNextButton?.setTitle(isLastStep ? "Start Test" : "Next", for: .normal)
            } else {
                instructionNextButton?.isHidden = false
                instructionPrevButton?.isHidden = true
                instructionNextButton?.setTitle("Skip", for: .normal)
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.instructionLabel.alpha = 0
            }) { _ in
                self.instructionLabel.text = step.message
                UIView.animate(withDuration: 0.4, animations: {
                    self.instructionLabel.alpha = 1
                }) { _ in
                    if !isFirstRun {
                        DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                            guard let self = self, self.isInstructionPhase, self.currentInstructionIndex == index else { return }
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
        let isFirstRun = InstructionTracker.isFirstRun(for: "CTest")
        
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
        if InstructionTracker.isFirstRun(for: "CTest") {
            runInstructionSequence(index: currentInstructionIndex + 1)
        } else {
            finishInstructionsAndStartExercise()
        }
    }
    
    @objc private func instructionPrevTapped() {
        if InstructionTracker.isFirstRun(for: "CTest") && currentInstructionIndex > 0 {
            runInstructionSequence(index: currentInstructionIndex - 1)
        }
    }
    
    private func finishInstructionsAndStartExercise() {
        InstructionTracker.markAsCompleted(for: "CTest")
        currentInstructionIndex = 999
        
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionNextButton?.alpha = 0
            self.instructionPrevButton?.alpha = 0
        }) { _ in
            self.instructionNextButton?.removeFromSuperview()
            self.instructionPrevButton?.removeFromSuperview()
        }
        
        runStartCountdown { [weak self] in
            guard let self = self, self.isInstructionPhase else { return }
            self.startActivePhase()
        }
    }

    private func runStartCountdown(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionLabel.alpha = 0
        }) { _ in
            self.instructionLabel.text = "3"
            UIView.animate(withDuration: 0.3, animations: {
                self.instructionLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.isInstructionPhase else { return }
                    UIView.animate(withDuration: 0.2, animations: {
                        self.instructionLabel.alpha = 0
                    }) { _ in
                        self.instructionLabel.text = "2"
                        UIView.animate(withDuration: 0.3, animations: {
                            self.instructionLabel.alpha = 1
                        }) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                guard let self = self, self.isInstructionPhase else { return }
                                UIView.animate(withDuration: 0.2, animations: {
                                    self.instructionLabel.alpha = 0
                                }) { _ in
                                    self.instructionLabel.text = "1"
                                    UIView.animate(withDuration: 0.3, animations: {
                                        self.instructionLabel.alpha = 1
                                    }) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                            guard let self = self, self.isInstructionPhase else { return }
                                            UIView.animate(withDuration: 0.3, animations: {
                                                self.instructionLabel.alpha = 0
                                            }) { _ in
                                                self.instructionLabel.text = ""
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

    // MARK: - Active Phase

    private func startActivePhase() {
        isInstructionPhase = false

        UIView.animate(withDuration: 0.8) {
            self.instructionLabel.alpha = 0
            self.landoltImageView.alpha = 1
            self.statusLabel.alpha = 1
            self.numbers.forEach { $0.alpha = 1 }
        } completion: { _ in
            self.isTestActive = true
            self.currentScale = 1.0
            self.iterationCount = 0
            self.generateNextTarget(isSuccess: false)
        }
    }

    private func startActivePhaseFromSwitch() {

        
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel.alpha = 0
            self.landoltImageView.alpha = 1
            self.statusLabel.alpha = 1
            self.numbers.forEach { $0.alpha = 1 }
        } completion: { _ in
            self.isTestActive = true
            self.generateNextTarget(isSuccess: false)
        }
    }

    // MARK: - ARSession Delegate

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isTestActive, let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            DispatchQueue.main.async {
                self.hideWarningSmoothly()
            }
            return
        }
        
        let currentTime = CACurrentMediaTime()
        if lastUpdateTimestamp == 0 {
            lastUpdateTimestamp = currentTime
        }
        let deltaTime = currentTime - lastUpdateTimestamp
        lastUpdateTimestamp = currentTime
        
        let leftEyeBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        let rightEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
        
        // Left eye tested -> Right eye must be closed.
        // Right eye tested -> Left eye must be closed.
        let correctEyeClosed: Bool
        if !isTestingRightEye {
            correctEyeClosed = rightEyeBlink > 0.6
        } else {
            correctEyeClosed = leftEyeBlink > 0.6
        }
        
        DispatchQueue.main.async {
            if correctEyeClosed {
                self.incorrectEyeOpenDuration = max(0, self.incorrectEyeOpenDuration - deltaTime * 2.0)
                if self.incorrectEyeOpenDuration == 0 {
                    self.hideWarningSmoothly()
                }
            } else {
                self.incorrectEyeOpenDuration += deltaTime
                if self.incorrectEyeOpenDuration >= 1.5 {
                    self.showWarningSmoothly()
                }
            }
            
            // Keep the Siri listening border view state matching mic activity
            if self.isMicActive {
                SiriListeningBorderView.shared.show()
            } else {
                SiriListeningBorderView.shared.hide()
            }
        }
    }

    private func showWarningSmoothly() {
        let expectedText = !isTestingRightEye ? "Please close your right eye" : "Please close your left eye"
        if eyeWarningLabel.text != expectedText {
            eyeWarningLabel.text = expectedText
        }
        
        guard !isWarningShown else { return }
        isWarningShown = true
        UIView.animate(withDuration: 0.3) {
            self.eyeWarningLabel.alpha = 1.0
        }
    }
    
    private func hideWarningSmoothly() {
        guard isWarningShown else { return }
        isWarningShown = false
        UIView.animate(withDuration: 0.3) {
            self.eyeWarningLabel.alpha = 0.0
        }
    }

    // MARK: - Target Generation

    private func generateNextTarget(isSuccess: Bool) {
        DispatchQueue.main.async {
            self.stopAudio(hideBorder: false)

            if isSuccess {
                Vibrator.playSuccess()
                if !self.isTestingRightEye { self.leftEyeScore += 1 } else { self.rightEyeScore += 1 }
                self.currentScale /= 1.258 // LogMAR Step
            }

            if self.iterationCount >= self.maxIterations {
                self.finishCurrentEye()
                return
            }

            self.iterationCount += 1
            let randomAngle = self.directionMap.keys.randomElement()!
            self.currentCorrectNumber = self.directionMap[randomAngle]!

            UIView.animate(withDuration: 0.15, animations: {
                self.landoltImageView.alpha = 0
            }) { _ in
                let rotation = CGAffineTransform(rotationAngle: CGFloat(randomAngle) * .pi / 180)
                self.landoltImageView.transform = rotation.concatenating(
                    CGAffineTransform(scaleX: self.currentScale, y: self.currentScale)
                )
                UIView.animate(withDuration: 0.15) { self.landoltImageView.alpha = 1 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if self.isTestActive { self.startRecording() }
                }
            }
        }
    }

    // MARK: - Skip

    private func handleUserSkip() {
        self.isTestActive = false
        self.stopAudio(hideBorder: true)
        Vibrator.playWarning()

        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                self.landoltImageView.alpha = 0
                self.statusLabel.alpha = 0
                self.numbers.forEach { $0.alpha = 0 }
                self.instructionLabel.alpha = 0
            }) { _ in
                self.instructionLabel.text = "Skipped! Let's continue."
                UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 1 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.instructionLabel.alpha = 0
                    }) { _ in self.finishCurrentEye() }
                }
            }
        }
    }

    // MARK: - Eye Switch & Completion

    private func finishCurrentEye() {
        self.isTestActive = false
        self.stopAudio(hideBorder: true)

        DispatchQueue.main.async {
            if !self.isTestingRightEye {
                self.isTestingRightEye = true
                self.iterationCount = 0
                self.currentScale = 1.0
                self.landoltImageView.alpha = 0
                self.numbers.forEach { $0.alpha = 0 }

                // Show "cover your left eye" instruction, auto-dismiss after 2s
                self.instructionLabel.text = "Cover your left eye"
                UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 1 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIView.animate(withDuration: 0.4) { self.instructionLabel.alpha = 0 } completion: { _ in
                        self.instructionLabel.text = ""
                        self.startActivePhaseFromSwitch()
                    }
                }
            } else {
                self.completeTest()
            }
        }
    }

    private func completeTest() {
        guard !didComplete else { return }
        didComplete = true

        stopAudio(hideBorder: true)
        sceneView?.session.pause()

        // Always save the scores globally regardless of routing
        EyeTestDataManager.shared.saveEyeTestScore(score: Double(leftEyeScore),  eye: "Left")
        EyeTestDataManager.shared.saveEyeTestScore(score: Double(rightEyeScore), eye: "Right")

        if shouldShowCompletionSummary {
            // MARK: - Old Flow (Detailed Result View)
            let leftResult = CTestEyeResult.make(for: "Left Eye", rawScore: leftEyeScore)
            let rightResult = CTestEyeResult.make(for: "Right Eye", rawScore: rightEyeScore)

            let recentLeftSessions = EyeTestDataManager.shared.fetchRecentEyeTestSessions(for: "Left", limit: 2)
            let recentRightSessions = EyeTestDataManager.shared.fetchRecentEyeTestSessions(for: "Right", limit: 2)
            
            let previousComparison: CTestComparison? = {
                guard recentLeftSessions.count > 1, recentRightSessions.count > 1 else {
                    return nil
                }
                return CTestComparison(
                    previousLeft: Int(recentLeftSessions[1].score.rounded()),
                    previousRight: Int(recentRightSessions[1].score.rounded())
                )
            }()

            let resultViewController = CTestResultPageCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
            resultViewController.leftEyeResult = leftResult
            resultViewController.rightEyeResult = rightResult
            resultViewController.previousResult = previousComparison

            if let navigationController {
                navigationController.popViewController(animated: false)
                let nav = UINavigationController(rootViewController: resultViewController)
                nav.modalPresentationStyle = .fullScreen
                nav.navigationBar.prefersLargeTitles = false
                navigationController.present(nav, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: resultViewController)
                nav.modalPresentationStyle = .fullScreen
                nav.navigationBar.prefersLargeTitles = false
                present(nav, animated: true)
            }
            
        } else {
            // MARK: - New Flow (Onboarding Completion)
            onTestCompleted?()
        }
    }

    func getSnellenScore(for points: Int) -> String {
        let mapping = [0: "20/200", 1: "20/100", 2: "20/70", 3: "20/50",
                       4: "20/40",  5: "20/25",  6: "20/20"]
        return mapping[points] ?? "N/A"
    }

    // MARK: - Recording

    private func startRecording() {
        guard isTestActive && isEyeRequirementMet else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.startRecording() }
            return
        }

        isProcessing = false

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .measurement,
                                      options: [.duckOthers, .defaultToSpeaker])
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self, let result = result else { return }

            let spoken = result.bestTranscription.formattedString.lowercased()
            print("--- DEBUG SPEECH: \(spoken) ---")

            if !self.isProcessing {
                let isMatch = spoken.contains(self.currentCorrectNumber)
                           || spoken.contains(self.numToText(self.currentCorrectNumber))
                           || (self.currentCorrectNumber == "6" && (spoken.contains("six") || spoken.contains("sex")))

                let isSkip = spoken.contains("cannot see")
                          || spoken.contains("can't see")
                          || spoken.contains("skip")

                if isMatch {
                    self.isProcessing = true
                    SiriListeningBorderView.shared.setBorderState(.correct)
                    self.generateNextTarget(isSuccess: true)
                } else if isSkip {
                    self.isProcessing = true
                    self.handleUserSkip()
                } else {
                    let words = spoken.components(separatedBy: " ")
                    if let lastWord = words.last, self.isNumber(lastWord) {
                        self.isProcessing = true
                        SiriListeningBorderView.shared.setBorderState(.incorrect)
                        Vibrator.playError()
                        self.generateNextTarget(isSuccess: false)
                    }
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            SiriListeningBorderView.feedBuffer(buffer)  // feed RMS to border
        }

        audioEngine.prepare()
        try? audioEngine.start()

        // Mark mic as open, then smoothly show the border
        isMicActive = true
        SiriListeningBorderView.shared.setBorderState(.listening)
        SiriListeningBorderView.shared.startListening(audioEngine: audioEngine)
        SiriListeningBorderView.shared.show()
    }

    private func stopAudio(hideBorder: Bool = true) {
        guard isMicActive else { return }   // prevent double-stop
        isMicActive = false

        if hideBorder {
            // Smoothly hide border — display link fades it, no pop
            SiriListeningBorderView.shared.hide()
            SiriListeningBorderView._latestRMS = 0
        }

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    // MARK: - Setup

    private func setupARKit() {
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.delegate = self
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    private func setupSpeech() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    // MARK: - Helpers

    private func isNumber(_ word: String) -> Bool {
        let numberWords = ["one", "two", "three", "four", "five", "six", "seven", "eight"]
        let digits      = ["1", "2", "3", "4", "5", "6", "7", "8"]
        return numberWords.contains(word) || digits.contains(word)
    }

    private func numToText(_ num: String) -> String {
        let dict = ["1": "one", "2": "two",   "3": "three", "4": "four",
                    "5": "five", "6": "six",  "7": "seven", "8": "eight"]
        return dict[num] ?? ""
    }


}
