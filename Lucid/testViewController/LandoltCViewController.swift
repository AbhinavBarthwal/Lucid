import UIKit
import ARKit
import Speech

class LandoltCViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var landoltImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet var numbers: [UILabel]!



    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let notificationGen = UINotificationFeedbackGenerator()
    
    private var currentScale: CGFloat = 1.0
    private var leftEyeScore = 0
    private var rightEyeScore = 0
    private var iterationCount = 0
    private let maxIterations = 6
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
        runInitialCountdown()
    }

    private func setupUIInitialState() {
        view.backgroundColor = .black
        sceneView.alpha = 0
        landoltImageView.alpha = 0
        statusLabel.alpha = 0
        self.numbers.forEach { $0.alpha = 0 }

    }

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
        fadeTransition(text: "Keep the phone at arm's length") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.showFocusInstruction()
            }
        }
    }

    private func showFocusInstruction() {
        fadeTransition(text: "Focus on the opening and speak the corresponding number") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.showSkipInstruction()
            }
        }
    }

    private func showSkipInstruction() {
        fadeTransition(text: "If you cannot see the opening say 'cannot see or skip ' to skip.") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.startActivePhase()
            }
        }
    }

    private func startActivePhase() {
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


    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor, isTestActive else { return }
        
        let physicalRightEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
        let physicalLeftEyeBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0

        DispatchQueue.main.async {
            if !self.isTestingRightEye {
                self.isEyeRequirementMet = (physicalRightEyeBlink > 0.45)
                self.statusLabel.text = self.isEyeRequirementMet ? "" : "Close Right Eye"
            } else {
                self.isEyeRequirementMet = (physicalLeftEyeBlink > 0.45)
                self.statusLabel.text = self.isEyeRequirementMet ? "" : "Close Left Eye"
            }
            self.statusLabel.textColor = self.isEyeRequirementMet ? .white : .systemRed
        }
    }


    private func generateNextTarget(isSuccess: Bool) {
        if iterationCount >= maxIterations {
            finishCurrentEye()
            return
        }

        DispatchQueue.main.async {
            self.stopAudio()
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
                self.landoltImageView.transform = rotation.concatenating(CGAffineTransform(scaleX: self.currentScale, y: self.currentScale))
                
                UIView.animate(withDuration: 0.15) {
                    self.landoltImageView.alpha = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if self.isTestActive { self.startRecording() }
                }
            }
        }
    }

    private func handleUserSkip() {
        self.isTestActive = false
        self.stopAudio()
        self.notificationGen.notificationOccurred(.warning)
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                self.landoltImageView.alpha = 0
                self.statusLabel.alpha = 0
                self.numbers.forEach { $0.alpha = 0 }
                self.instructionLabel.alpha = 0
            }) { _ in

                self.instructionLabel.text = "Skipped"
                
                UIView.animate(withDuration: 0.3) {
                    self.instructionLabel.alpha = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.instructionLabel.alpha = 0
                    }) { _ in
                        self.finishCurrentEye()
                    }
                }
            }
        }
    }

    private func finishCurrentEye() {
        self.isTestActive = false
        self.stopAudio()
        
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

    private func completeTest() {
            let leftSnellen = getSnellenScore(for: leftEyeScore)
            let rightSnellen = getSnellenScore(for: rightEyeScore)
            
            // Save using the new manager
            EyeTestDataManager.shared.saveEyeTestScore(score: Double(leftEyeScore), eye: "Left")
            EyeTestDataManager.shared.saveEyeTestScore(score: Double(rightEyeScore), eye: "Right")
            
            fadeTransition(text: "Test Complete.\nL: \(leftSnellen) | R: \(rightSnellen)") {
                self.landoltImageView.alpha = 0
                self.statusLabel.alpha = 0
                self.numbers.forEach { $0.alpha = 0 }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }

    func getSnellenScore(for points: Int) -> String {
        let mapping = [0: "20/200", 1: "20/100", 2: "20/70", 3: "20/50", 4: "20/40", 5: "20/25", 6: "20/20"]
        return mapping[points] ?? "N/A"
    }

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
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self, let result = result else { return }
            
  
            let spoken = result.bestTranscription.formattedString.lowercased()


            print("--- DEBUG SPEECH: \(spoken) ---")



            if !self.isProcessing {
                let isMatch = spoken.contains(self.currentCorrectNumber) ||
                              spoken.contains(self.numToText(self.currentCorrectNumber)) ||
                              (self.currentCorrectNumber == "6" && (spoken.contains("six") || spoken.contains("sex")))

                let isSkip = spoken.contains("cannot see") || spoken.contains("can't see") || spoken.contains("skip")

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

    private func setupARKit() {
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.delegate = self
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func setupSpeech() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    private func isNumber(_ word: String) -> Bool {
        let numberWords = ["one", "two", "three", "four", "five", "six", "seven", "eight"]
        let digits = ["1", "2", "3", "4", "5", "6", "7", "8"]
        return numberWords.contains(word) || digits.contains(word)
    }

    private func numToText(_ num: String) -> String {
        let dict = ["1":"one","2":"two","3":"three","4":"four","5":"five","6":"six","7":"seven","8":"eight"]
        return dict[num] ?? ""
    }
}
