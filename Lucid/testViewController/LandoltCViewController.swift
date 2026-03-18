import UIKit
import ARKit
import Speech

class LandoltCViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var landoltImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet var numbers: [UILabel]!

        @IBOutlet weak var actionButton: UIButton!

        private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
        private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        private var recognitionTask: SFSpeechRecognitionTask?
        private let audioEngine = AVAudioEngine()
        
        private let impactMed = UIImpactFeedbackGenerator(style: .medium)
        private let notificationGen = UINotificationFeedbackGenerator()
        
        private var currentScale: CGFloat = 1.0
        private var leftEyeScore = 0
        private var rightEyeScore = 0
        private var failureCount = 0
        private var currentCorrectNumber = ""
        private var secondsRemaining = 5
        
        private var isTestingRightEye = false
        private var isEyeRequirementMet = false
        private var isProcessing = false
        private var isTestActive = false
        
        private let directionMap: [Int: String] = [
            0: "4", 45: "5", 90: "6", 135: "7", 180: "8", 225: "1", 270: "2", 315: "3"
        ]

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
            runBlinkStyleCountdown()
        }

        private func setupUIInitialState() {
            view.backgroundColor = .black
            sceneView.alpha = 0
            landoltImageView.alpha = 0 // Ring is hidden
            statusLabel.alpha = 0
            // Replace: numbers.alpha = 0
            self.numbers.forEach { $0.alpha = 0 }
            actionButton.isHidden = true
            actionButton.layer.cornerRadius = 12
            
            instructionLabel.alpha = 1
            instructionLabel.textColor = .white
            instructionLabel.textAlignment = .center
            instructionLabel.numberOfLines = 0
            instructionLabel.font = .systemFont(ofSize: 80, weight: .bold)
        }

        // MARK: - Blink Style Flow Logic
        
    private func runBlinkStyleCountdown() {
                isTestActive = false
                secondsRemaining = 5
                
                // Ensure absolute blackout of test elements
                self.landoltImageView.alpha = 0
                self.statusLabel.alpha = 0
                self.sceneView.alpha = 0
        // Replace: numbers.alpha = 0
        self.numbers.forEach { $0.alpha = 0 }
                self.instructionLabel.alpha = 1
                self.instructionLabel.font = .systemFont(ofSize: 24, weight: .bold)
                
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                    guard let self = self else { return }
                    
                    if self.secondsRemaining > 0 {
                        self.instructionLabel.text = "\(self.secondsRemaining)"
                        self.secondsRemaining -= 1
                        self.impactMed.impactOccurred() // Subtle tick on each second
                    } else {
                        timer.invalidate()
                        self.showTestInstructions()
                    }
                }
            }

        private func showTestInstructions() {
            let eyeToClose = isTestingRightEye ? "LEFT" : "RIGHT"
            
            // Transition to text instructions
            UIView.animate(withDuration: 0.3) {
                self.instructionLabel.font = .systemFont(ofSize: 24, weight: .semibold)
                self.instructionLabel.text = "Speak the number that corresponds to the opening in the circle."
            }
            
            // Delay before fading in the actual test (Blink training logic)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.startActivePhase()
            }
        }

    private func startActivePhase() {
                // Now fade in the C-ring, numbers, and the camera feed
                UIView.animate(withDuration: 1.2) {
                    self.instructionLabel.alpha = 0
                    self.landoltImageView.alpha = 1  // C-ring appears now
                    self.statusLabel.alpha = 1
                    // Replace: numbers.alpha = 0
                    self.numbers.forEach { $0.alpha = 1 }
                    self.sceneView.alpha = 0.0
                } completion: { _ in
                    self.isTestActive = true
                    self.failureCount = 0
                    self.currentScale = 1.0
                    self.generateNextTarget(isSuccess: false)
                }
            }

        // MARK: - ARKit Delegate
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.first as? ARFaceAnchor, isTestActive else { return }
            
            let physicalRightEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
            let physicalLeftEyeBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0

            DispatchQueue.main.async {
                if !self.isTestingRightEye {
                    self.isEyeRequirementMet = (physicalRightEyeBlink > 0.45)
                    self.statusLabel.text = self.isEyeRequirementMet ? "Listening" : "Close Right Eye"
                } else {
                    self.isEyeRequirementMet = (physicalLeftEyeBlink > 0.45)
                    self.statusLabel.text = self.isEyeRequirementMet ? "Listening" : "Close Left Eye"
                }
                self.statusLabel.textColor = self.isEyeRequirementMet ? .systemGreen : .systemRed
            }
        }

        // MARK: - Test Logic
        private func generateNextTarget(isSuccess: Bool) {
            DispatchQueue.main.async {
                self.stopAudio()
                if isSuccess {
                    self.notificationGen.notificationOccurred(.success)
                    if !self.isTestingRightEye { self.leftEyeScore += 1 } else { self.rightEyeScore += 1 }
                    self.currentScale *= 0.8
                    self.failureCount = 0
                }

                let randomAngle = self.directionMap.keys.randomElement()!
                self.currentCorrectNumber = self.directionMap[randomAngle]!

                UIView.animate(withDuration: 0.3) {
                    let rotation = CGAffineTransform(rotationAngle: CGFloat(randomAngle) * .pi / 180)
                    self.landoltImageView.transform = rotation.concatenating(CGAffineTransform(scaleX: self.currentScale, y: self.currentScale))
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if self.isTestActive { self.startRecording() }
                }
            }
        }

        private func handleWrongAnswer() {
            self.failureCount += 1
            self.notificationGen.notificationOccurred(.error)
            
            if failureCount >= 3 {
                self.isTestActive = false
                self.stopAudio()
                DispatchQueue.main.async {
                    self.landoltImageView.alpha = 0.2
                    self.actionButton.isHidden = false
                    let btnText = !self.isTestingRightEye ? "Switch to Right Eye" : "Finish Test"
                    self.actionButton.setTitle(btnText, for: .normal)
                    self.statusLabel.text = "Failed 3 times"
                }
            } else {
                self.isProcessing = false
                self.stopAudio()
                self.startRecording()
            }
        }

        // MARK: - Speech Engine
        private func startRecording() {
            guard isTestActive && isEyeRequirementMet else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.startRecording() }
                return
            }

            isProcessing = false
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            let inputNode = audioEngine.inputNode
            recognitionRequest?.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
                guard let self = self, let result = result else { return }
                let spoken = result.bestTranscription.formattedString.lowercased()

                if !self.isProcessing {
                    let isMatch = spoken.contains(self.currentCorrectNumber) ||
                                  spoken.contains(self.numToText(self.currentCorrectNumber)) ||
                                  (self.currentCorrectNumber == "6" && (spoken.contains("six") || spoken.contains("sex")))

                    if isMatch {
                        self.isProcessing = true
                        self.generateNextTarget(isSuccess: true)
                    } else {
                        let words = spoken.components(separatedBy: " ")
                        if let lastWord = words.last, self.isNumber(lastWord) {
                            self.isProcessing = true
                            self.handleWrongAnswer()
                        }
                    }
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try? audioEngine.start()
        }

        private func stopAudio() {
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil
        }

        // MARK: - Navigation
        @IBAction func actionButtonTapped(_ sender: UIButton) {
            self.actionButton.isHidden = true
            if !isTestingRightEye {
                isTestingRightEye = true
                self.instructionLabel.font = .systemFont(ofSize: 40, weight: .bold)
                self.instructionLabel.alpha = 1
                self.instructionLabel.text = "Nicely Done!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.runBlinkStyleCountdown()
                }
            } else {
                showSummary()
            }
        }

        private func showSummary() {
            self.stopAudio()
            self.landoltImageView.isHidden = true
            self.statusLabel.isHidden = true
            self.instructionLabel.font = .systemFont(ofSize: 20, weight: .regular)
            self.instructionLabel.alpha = 1
            
        }

        private func setupARKit() {
            let configuration = ARFaceTrackingConfiguration()
            sceneView.session.delegate = self
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        private func setupSpeech() {
            SFSpeechRecognizer.requestAuthorization { _ in }
        }

        private func isNumber(_ word: String) -> Bool {
            let numberWords = ["one", "two", "three", "four", "five", "six", "seven", "eight", "sex"]
            let digits = ["1", "2", "3", "4", "5", "6", "7", "8"]
            return numberWords.contains(word) || digits.contains(word)
        }

        private func numToText(_ num: String) -> String {
            let dict = ["1":"one","2":"two","3":"three","4":"four","5":"five","6":"six","7":"seven","8":"eight"]
            return dict[num] ?? ""
        }
    }
