import UIKit
import ARKit
import Speech

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
    private var secondsRemaining = 5

    private var isTestingRightEye    = false
    private var isEyeRequirementMet  = false
    private var isProcessing         = false
    private var isTestActive         = false
    private var didComplete          = false
    private var isMicActive          = false   // tracks whether mic is genuinely open
    private var isInstructionPhase   = true

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
        runInitialCountdown()
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
    }

    // MARK: - Countdown & Instructions

    private func fadeTransition(text: String, duration: TimeInterval = 0.5, completion: @escaping () -> Void) {
        UIView.animate(withDuration: duration, animations: {
            self.instructionLabel.alpha = 0
        }) { _ in
            self.instructionLabel.text = text
            UIView.animate(withDuration: duration, animations: {
                self.instructionLabel.alpha = 1
            }) { _ in
                completion()
            }
        }
    }

    private func runInitialCountdown() {
        secondsRemaining = 5
        instructionLabel.text = "\(secondsRemaining)"

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            guard self.isInstructionPhase else {
                timer.invalidate()
                return
            }
            if self.secondsRemaining > 1 {
                self.secondsRemaining -= 1
                self.instructionLabel.text = "\(self.secondsRemaining)"
            } else {
                timer.invalidate()
                self.showDistanceInstruction()
            }
        }
    }

    private func showDistanceInstruction() {
        guard isInstructionPhase else { return }
        fadeTransition(text: "Keep the phone at arm's length") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                guard self.isInstructionPhase else { return }
                self.showFocusInstruction()
            }
        }
    }

    private func showFocusInstruction() {
        guard isInstructionPhase else { return }
        fadeTransition(text: "Focus on the opening and speak the corresponding number") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                guard self.isInstructionPhase else { return }
                self.showSkipInstruction()
            }
        }
    }

    private func showSkipInstruction() {
        guard isInstructionPhase else { return }
        fadeTransition(text: "If you cannot see the opening say 'cannot see' or 'skip' to skip.") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                guard self.isInstructionPhase else { return }
                self.startActivePhase()
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
        guard let faceAnchor = anchors.first as? ARFaceAnchor, isTestActive else { return }

        let physicalRightEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue  ?? 0
        let physicalLeftEyeBlink  = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0

        DispatchQueue.main.async {
            let previouslyMet = self.isEyeRequirementMet
            let nowMet: Bool

            if !self.isTestingRightEye {
                nowMet = physicalRightEyeBlink > 0.45
                self.statusLabel.text = nowMet ? "" : "Close Right Eye"
            } else {
                nowMet = physicalLeftEyeBlink > 0.45
                self.statusLabel.text = nowMet ? "" : "Close Left Eye"
            }

            // Guard: only act when the state actually flips — not every frame
            guard nowMet != previouslyMet else { return }

            self.isEyeRequirementMet = nowMet
            self.statusLabel.textColor = nowMet ? .white : .systemRed

            if !nowMet {
                // Eye opened → hide border (smooth fade via display link)
                SiriListeningBorderView.shared.hide()
            } else if self.isMicActive {
                // Eye closed again and mic is running → show border (smooth fade in)
                SiriListeningBorderView.shared.show()
            }
        }
    }

    // MARK: - Target Generation

    private func generateNextTarget(isSuccess: Bool) {
        if iterationCount >= maxIterations {
            finishCurrentEye()
            return
        }

        DispatchQueue.main.async {
            self.stopAudio(hideBorder: false)

            if isSuccess {
                self.notificationGen.notificationOccurred(.success)
                if !self.isTestingRightEye { self.leftEyeScore += 1 } else { self.rightEyeScore += 1 }
                self.currentScale /= 1.258 // LogMAR Step
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
        self.notificationGen.notificationOccurred(.warning)

        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                self.landoltImageView.alpha = 0
                self.statusLabel.alpha = 0
                self.numbers.forEach { $0.alpha = 0 }
                self.instructionLabel.alpha = 0
            }) { _ in
                self.instructionLabel.text = "Skipped"
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
                self.instructionLabel.text = "Close Left Eye"
                self.instructionLabel.alpha = 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.startActivePhaseFromSwitch()
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
                    self.generateNextTarget(isSuccess: true)
                } else if isSkip {
                    self.isProcessing = true
                    self.handleUserSkip()
                } else {
                    let words = spoken.components(separatedBy: " ")
                    if let lastWord = words.last, self.isNumber(lastWord) {
                        self.isProcessing = true
                        self.notificationGen.notificationOccurred(.error)
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
