import UIKit
import ARKit
import Speech

class LandoltCViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var landoltImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var currentScale: CGFloat = 1.0
    private var successCount = 0
    private var currentCorrectNumber = ""
    private var isEyeRequirementMet = false
    private var isProcessing = false // Prevents double-trigger crashes
    
    private let directionMap: [Int: String] = [
        0: "4", 45: "5", 90: "6", 135: "7", 180: "8", 225: "1", 270: "2", 315: "3"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIX: ARKit cannot be "hidden". Set alpha to near-zero instead.
        sceneView.isHidden = false
        sceneView.alpha = 0.1
        
        setupARKit()
        setupSpeech()
        generateNextTarget(isSuccess: false)
    }

    private func setupARKit() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.delegate = self
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        let leftBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
        let rightBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0

        DispatchQueue.main.async {
            // Forgiving threshold for testing
            self.isEyeRequirementMet = (leftBlink > 0.3 || rightBlink > 0.3)
            self.statusLabel.text = self.isEyeRequirementMet ? "Listening..." : "Cover Eye"
            self.statusLabel.textColor = self.isEyeRequirementMet ? .green : .red
        }
    }

    private func startRecording() {
        if audioEngine.isRunning { stopAudio() }
        isProcessing = false
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                let spoken = result.bestTranscription.formattedString.lowercased()
                print("🗣 Heard: \(spoken) | Target: \(self.currentCorrectNumber)")
                
                // CHECK LOGIC: contains() is better than ==
                if !self.isProcessing && (spoken.contains(self.currentCorrectNumber) || spoken.contains(self.numToText(self.currentCorrectNumber))) {
                    self.isProcessing = true
                    print("✅ Correct Answer!")
                    self.generateNextTarget(isSuccess: true)
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
    }

    private func stopAudio() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func generateNextTarget(isSuccess: Bool) {
        DispatchQueue.main.async {
            self.stopAudio()
            
            if isSuccess { self.successCount += 1; self.currentScale *= 0.8 }
            
            if self.successCount >= 15{
                self.instructionLabel.text = "Switch Eye!"
                self.successCount = 0
                self.currentScale = 1.0
            }

            let randomAngle = self.directionMap.keys.randomElement()!
            self.currentCorrectNumber = self.directionMap[randomAngle]!

            UIView.animate(withDuration: 0.4) {
                let rotation = CGAffineTransform(rotationAngle: CGFloat(randomAngle) * .pi / 180)
                self.landoltImageView.transform = rotation.concatenating(CGAffineTransform(scaleX: self.currentScale, y: self.currentScale))
            }
            
            // Restart mic after a short delay to clear the buffer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.startRecording()
            }
        }
    }

    private func numToText(_ num: String) -> String {
        let dict = ["1":"one","2":"two","3":"three","4":"four","5":"five","6":"six","7":"seven","8":"eight"]
        return dict[num] ?? ""
    }
    
    private func setupSpeech() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
}

//
//import UIKit
//import ARKit
//import Speech
//
//class LandoltCViewController: UIViewController, ARSessionDelegate {
//    
//    @IBOutlet weak var sceneView: ARSCNView!
//    @IBOutlet weak var landoltImageView: UIImageView!
//    @IBOutlet weak var statusLabel: UILabel!
//    @IBOutlet weak var instructionLabel: UILabel!
//    
//    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "hi-IN"))
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private let audioEngine = AVAudioEngine()
//    
//    private var currentScale: CGFloat = 1.0
//    private var successCount = 0
//    private var currentCorrectNumber = ""
//    private var isEyeRequirementMet = false
//    private var isProcessing = false
//    
//    // Mapping angles to digits (1-8)
//    private let directionMap: [Int: String] = [
//        0: "4", 45: "5", 90: "6", 135: "7", 180: "8", 225: "1", 270: "2", 315: "3"
//    ]
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        sceneView.alpha = 0.1 // Keep active but semi-transparent
//        setupARKit()
//        setupSpeech()
//        generateNextTarget(isSuccess: false)
//    }
//
//    private func setupARKit() {
//        guard ARFaceTrackingConfiguration.isSupported else { return }
//        let configuration = ARFaceTrackingConfiguration()
//        sceneView.session.delegate = self
//        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//    }
//
//    // MARK: - ARFaceAnchor Logic
//    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
//        
//        // Detecting if either eye is significantly closed/covered
//        let leftBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
//        let rightBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0
//
//        DispatchQueue.main.async {
//            // Requirement: One eye must be closed (>0.5 threshold)
//            self.isEyeRequirementMet = (leftBlink > 0.5 || rightBlink > 0.5)
//            self.statusLabel.text = self.isEyeRequirementMet ? "Listening..." : "Cover One Eye!"
//            self.statusLabel.textColor = self.isEyeRequirementMet ? .green : .orange
//        }
//    }
//
//    // MARK: - Speech Recognition Logic
//    private func startRecording() {
//        if audioEngine.isRunning { stopAudio() }
//        isProcessing = false
//        
//        let audioSession = AVAudioSession.sharedInstance()
//        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        let inputNode = audioEngine.inputNode
//        
//        // CRITICAL: Remove existing tap to prevent "Bus 0 already has a tap" crash
//        inputNode.removeTap(onBus: 0)
//
//        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
//            guard let result = result else { return }
//            let spoken = result.bestTranscription.formattedString.lowercased()
//            
//            // Check against Hindi and English variations
//            let matches = self.getPossibleMatches(for: self.currentCorrectNumber)
//            
//            if !self.isProcessing && self.isEyeRequirementMet {
//                for word in matches {
//                    if spoken.contains(word) {
//                        self.isProcessing = true
//                        print("✅ Recognized: \(word)")
//                        self.generateNextTarget(isSuccess: true)
//                        break
//                    }
//                }
//            }
//        }
//
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            self.recognitionRequest?.append(buffer)
//        }
//
//        audioEngine.prepare()
//        try? audioEngine.start()
//    }
//
//    private func stopAudio() {
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
//        recognitionRequest?.endAudio()
//        recognitionTask?.finish()
//        recognitionRequest = nil
//        recognitionTask = nil
//    }
//
//    // MARK: - Gameplay Logic
//    private func generateNextTarget(isSuccess: Bool) {
//        DispatchQueue.main.async {
//            self.stopAudio()
//            
//            if isSuccess {
//                self.successCount += 1
//                self.currentScale *= 0.8 // Shrink for difficulty
//            }
//            
//            if self.successCount >= 10 {
//                self.instructionLabel.text = "Switch Eye & Restart!"
//                self.successCount = 0
//                self.currentScale = 1.0
//            }
//
//            let randomAngle = self.directionMap.keys.randomElement()!
//            self.currentCorrectNumber = self.directionMap[randomAngle]!
//
//            UIView.animate(withDuration: 0.3) {
//                let rotation = CGAffineTransform(rotationAngle: CGFloat(randomAngle) * .pi / 180)
//                let scale = CGAffineTransform(scaleX: self.currentScale, y: self.currentScale)
//                self.landoltImageView.transform = rotation.concatenating(scale)
//            }
//            
//            // Short delay to let the user focus before the mic opens again
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
//                self.startRecording()
//            }
//        }
//    }
//
//    // Returns Hindi words, English words, and Digits for the target
//    private func getPossibleMatches(for num: String) -> [String] {
//        let dict: [String: [String]] = [
//            "1": ["1", "one", "एक", "१"], "2": ["2", "two", "दो", "२"],
//            "3": ["3", "three", "तीन", "३"], "4": ["4", "four", "चार", "४"],
//            "5": ["5", "five", "पाँच", "५"], "6": ["6", "six", "छह", "६"],
//            "7": ["7", "seven", "सात", "७"], "8": ["8", "eight", "आठ", "८"]
//        ]
//        return dict[num] ?? []
//    }
//    
//    private func setupSpeech() {
//        SFSpeechRecognizer.requestAuthorization { _ in }
//    }
//}
