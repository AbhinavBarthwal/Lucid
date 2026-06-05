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
    private var pendingSpeechCandidate: (value: String, isSkip: Bool, count: Int)?

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
        InstructionStep(message: "This test checks how clearly each eye can see.", duration: 4.5),
        InstructionStep(message: "Hold your phone at arm's length and close the eye as instructed", duration: 5.0),
        InstructionStep(message: "Look at the open side of the C and say the matching number out loud.", duration: 5.0),
        InstructionStep(message: "If you cannot see it, say 'cannot see' or 'skip' to move on.", duration: 5.5),
        InstructionStep(message: "Green light means correct. Red light means wrong.", duration: 3.0)
    ]

    private let directionMap: [Int: String] = [
        0: "2", 90: "3", 180: "4", 270: "1"
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

        // Stop the audio engine, cancel recognition, and hide the border
        stopAudio(hideBorder: true)

        // Fully shut down SiriListeningBorderView
        SiriListeningBorderView.shared.stopListening()
        SiriListeningBorderView.shared.hide()
        SiriListeningBorderView._latestRMS = 0

        // Pause AR session
        sceneView?.session.pause()

        // Mark test inactive so no pending dispatches can restart the mic
        isTestActive = false
        isProcessing = false
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
        instructionLabel.font = .systemFont(ofSize: 32, weight: .bold)
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        
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

        // Always show "Cover your right eye" before the left-eye test —
        // mandatory and cannot be skipped even if the instructions were skipped.
        // ↓ Change the value below to adjust how long this message stays on screen.
        let eyeInstructionDuration: TimeInterval = 2.0  // ← seconds the message is visible

        self.instructionLabel.text = "Cover your right eye"
        UIView.animate(withDuration: 0.3) {
            self.instructionLabel.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + eyeInstructionDuration) {
            UIView.animate(withDuration: 0.4, animations: {
                self.instructionLabel.alpha = 0
            }) { _ in
                self.instructionLabel.text = ""
                UIView.animate(withDuration: 0.8) {
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
        
        let leftEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
        let rightEyeBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        
        // Left eye tested -> Right eye must be closed.
        // Right eye tested -> Left eye must be closed.
        let correctEyeClosed: Bool
        if !isTestingRightEye {
            correctEyeClosed = rightEyeBlink > 0.3
        } else {
            correctEyeClosed = leftEyeBlink > 0.3
        }
        
        DispatchQueue.main.async {
            if correctEyeClosed {
                self.hideWarningSmoothly()
            } else {
                self.showWarningSmoothly()
            }
            
            // Keep the Siri listening border view state matching mic activity
            if self.isMicActive {
                if !self.isProcessing {
                    SiriListeningBorderView.shared.show()
                    SiriListeningBorderView.shared.setBorderState(.listening)
                }
            } else {
                if !self.isProcessing {
                    SiriListeningBorderView.shared.hide()
                }
            }
        }
    }

    private func showWarningSmoothly() {
        let expectedText = !isTestingRightEye ? "Please close your right eye" : "Please close your left eye"
        if eyeWarningLabel.text != expectedText {
            eyeWarningLabel.text = expectedText
        }
        eyeWarningLabel.layer.removeAllAnimations()
        eyeWarningLabel.alpha = 1.0
    }
    
    private func hideWarningSmoothly() {
        eyeWarningLabel.layer.removeAllAnimations()
        eyeWarningLabel.alpha = 0.0
    }

    // MARK: - Target Generation

    /// Full response feedback sequence for a correct or incorrect answer:
    ///
    ///   1. Green/red border is already on (set by caller before this runs).
    ///   2. C fades out over `cFadeOutDuration`.            ← change here
    ///   3. Border + C hold (border on, C hidden) for `holdDuration`. ← change here
    ///   4. Border fades away over `borderFadeOutDuration`. ← change here
    ///   5. Next C fades in + mic restarts simultaneously.
    ///
    /// `completion` fires at step 5 with the C still hidden — generateNextTarget
    /// sets the new rotation and fades it back in for exactly one clean blink.
    private func blinkC(completion: @escaping () -> Void) {
        let cFadeOutDuration:      TimeInterval = 0.25  // ← how long the C takes to fade out
        let holdDuration:          TimeInterval = 0.50  // ← how long the border+hidden-C are held
        let borderFadeOutDuration: TimeInterval = 0.25  // ← how long the border takes to fade out

        // Always run on main thread — this may be called from a recognition callback
        DispatchQueue.main.async {
            // Step 2: fade the C out
            UIView.animate(withDuration: cFadeOutDuration, animations: {
                self.landoltImageView.alpha = 0
            }) { _ in
                // Step 3: hold
                DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                    // Step 4: fade the border away
                    SiriListeningBorderView.shared.hide()
                    DispatchQueue.main.asyncAfter(deadline: .now() + borderFadeOutDuration) {
                        // Step 5: next target fades in and mic restarts at the same moment
                        completion()
                    }
                }
            }
        }
    }

    private func generateNextTarget(isSuccess: Bool) {
        DispatchQueue.main.async {
            if isSuccess {
                Vibrator.playSingle()
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

            // C is already hidden (blinkC left it at alpha 0).
            // Set the new rotation, start the mic, then fade in simultaneously.
            // ↓ Change the value below to adjust how long the next C takes to fade in.
            let fadeInDuration: TimeInterval = 0.15  // ← next C fade-in duration

            let rotation = CGAffineTransform(rotationAngle: CGFloat(randomAngle) * .pi / 180)
            self.landoltImageView.transform = rotation.concatenating(
                CGAffineTransform(scaleX: self.currentScale, y: self.currentScale)
            )

            // Restart the mic now — it warms up during the fade-in so it's fully
            // ready by the time the C is visible. isProcessing is reset inside startRecording().
            self.startRecording()

            // Fade the new C in.
            UIView.animate(withDuration: fadeInDuration) { self.landoltImageView.alpha = 1 }
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

                // Always show "Cover your left eye" before the right-eye test —
                // mandatory, mirrors the right-eye instruction in startActivePhase().
                // ↓ Change the value below to adjust how long this message stays on screen.
                let eyeInstructionDuration: TimeInterval = 2.0  // ← seconds the message is visible
                self.instructionLabel.text = "Cover your left eye"
                UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 1 }

                DispatchQueue.main.asyncAfter(deadline: .now() + eyeInstructionDuration) {
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
        pendingSpeechCandidate = nil

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // STEP 1: Configure AVAudioSession BEFORE reading any format or installing tap.
        // Reading inputNode.outputFormat(forBus:) before the session is active returns an
        // invalid sample rate (0 Hz), which causes AVAudioEngine to abort with:
        // "required condition is false: IsFormatSampleRateAndChannelCountValid(format)"
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self, let result = result else { return }

            let spoken = result.bestTranscription.formattedString.lowercased()
            print("--- DEBUG SPEECH: \(spoken) ---")

            if !self.isProcessing {
                guard let candidate = self.speechCandidate(from: result) else { return }
                guard self.isReadyToProcess(candidate: candidate, isFinal: result.isFinal) else { return }

                if candidate.isSkip {
                    self.isProcessing = true
                    self.handleUserSkip()
                } else if candidate.value == self.currentCorrectNumber {
                    self.isProcessing = true
                    self.stopAudio(hideBorder: false)        // close mic immediately on recognition
                    SiriListeningBorderView.shared.setBorderState(.correct)   // green light on
                    self.blinkC {
                        self.generateNextTarget(isSuccess: true)
                    }
                } else {
                    self.isProcessing = true
                    self.stopAudio(hideBorder: false)        // close mic immediately on recognition
                    SiriListeningBorderView.shared.setBorderState(.incorrect) // red light on
                    Vibrator.playDouble()
                    self.blinkC {
                        self.generateNextTarget(isSuccess: false)
                    }
                }
            }
        }

        // STEP 2: Read format AFTER the session is active — sample rate is now valid.
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // STEP 3: Install tap with the now-valid format.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            SiriListeningBorderView.feedBuffer(buffer)  // feed RMS to border
        }

        // STEP 4: Start the engine.
        audioEngine.prepare()
        try? audioEngine.start()

        // STEP 5: Update UI state once the engine is running.
        isMicActive = true
        SiriListeningBorderView.shared.setBorderState(.listening)
        SiriListeningBorderView.shared.startListening(audioEngine: audioEngine)
        SiriListeningBorderView.shared.show()
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
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

    private func speechCandidate(from result: SFSpeechRecognitionResult) -> (value: String, isSkip: Bool, confidence: Float)? {
        let transcription = result.bestTranscription
        let spoken = transcription.formattedString.lowercased()
        let normalized = spoken
            .replacingOccurrences(of: "can't see", with: "cannot see")
            .replacingOccurrences(of: "cant see", with: "cannot see")

        if normalized.contains("cannot see") || normalized.contains("skip") {
            return (value: "skip", isSkip: true, confidence: 1.0)
        }

        guard let lastSegment = transcription.segments.last else { return nil }
        let token = cleanSpeechToken(lastSegment.substring)
        guard let value = numberValue(for: token) else { return nil }

        return (value: value, isSkip: false, confidence: lastSegment.confidence)
    }

    private func isReadyToProcess(candidate: (value: String, isSkip: Bool, confidence: Float), isFinal: Bool) -> Bool {
        if candidate.isSkip || candidate.confidence >= 0.55 || isFinal {
            pendingSpeechCandidate = nil
            return true
        }

        if let pendingSpeechCandidate,
           pendingSpeechCandidate.value == candidate.value,
           pendingSpeechCandidate.isSkip == candidate.isSkip {
            let updatedCount = pendingSpeechCandidate.count + 1
            self.pendingSpeechCandidate = (value: candidate.value, isSkip: candidate.isSkip, count: updatedCount)
            if updatedCount >= 2 {
                self.pendingSpeechCandidate = nil
                return true
            }
        } else {
            pendingSpeechCandidate = (value: candidate.value, isSkip: candidate.isSkip, count: 1)
        }

        return false
    }

    private func cleanSpeechToken(_ token: String) -> String {
        token.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private func numberValue(for token: String) -> String? {
        let dict = [
            "1": "1", "one": "1",
            "2": "2", "two": "2", "to": "2", "too": "2", "do": "2", "t": "2", "tu": "2", "true": "2", "who": "2", "you": "2",
            "3": "3", "three": "3",
            "4": "4", "four": "4", "for": "4", "far": "4", "or": "4", "core": "4", "door": "4", "more": "4", "pour": "4", "poor": "4", "our": "4"
               ]
        return dict[token]
    }


}
