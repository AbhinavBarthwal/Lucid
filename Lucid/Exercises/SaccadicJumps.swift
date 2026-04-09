import UIKit
import ARKit
import AVFoundation

class SaccadicJumps: UIViewController, ARSessionDelegate {

    @IBOutlet weak var centerMessageLabel: UILabel!
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let faceTrackingSession = ARSession()
    private var isExerciseActive = true

    private enum Direction: String, CaseIterable {
        case top = "Top", bottom = "Bottom", left = "Left", right = "Right"
    }
    
    private var currentDirection: Direction?
    private var repCount = 0
    private let totalReps = 16
    private var successfulFollows = 0
    private var isTracking = false
    private var hasLookedInDirection = false
    
    private let speedTiers: [Double] = [2.5 , 2.2 , 2.0 , 1.8]
    
    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "3", duration: 0.8),
        InstructionStep(message: "2", duration: 0.8),
        InstructionStep(message: "1", duration: 0.8),
        InstructionStep(message: "Move your eyes in the\ndirection announced", duration: 3.0),
        InstructionStep(message: "Keep your head still", duration: 2.5)
    ]

    private var sessionStartTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAudioSession()
        prepareInitialState()
        setupEyeTracking()
        notificationGenerator.prepare()
        impactGenerator.prepare()
        runInstructionSequence(index: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isExerciseActive = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isExerciseActive = false
        faceTrackingSession.pause()
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isTracking = false
        hasLookedInDirection = false
        currentDirection = nil
        repCount = totalReps // Break the loop
        centerMessageLabel.layer.removeAllAnimations()
        centerMessageLabel.alpha = 0
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Audio Session error: \(error)")
        }
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
                self.startExercise()
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isExerciseActive, isTracking, let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        let lookAt = faceAnchor.lookAtPoint
        
        let threshold: Float = 0.14
        let bottomThreshold: Float = 0.05
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            guard let target = self.currentDirection, !self.hasLookedInDirection else { return }
            
            var success = false
            switch target {
            case .top:    success = lookAt.y > threshold
            case .left:   success = lookAt.x < -threshold
            case .right:  success = lookAt.x > threshold
            case .bottom: success = lookAt.y < -bottomThreshold
            }
            
            if success {
                self.handleSuccessfulLook()
            }
        }
    }
    
    private func handleSuccessfulLook() {
        hasLookedInDirection = true
        successfulFollows += 1
        impactGenerator.impactOccurred()
    }

    private func startExercise() {
        guard isExerciseActive else { return }
        self.sessionStartTime = Date()
        self.isTracking = true
        triggerNextRep()
    }

    private func triggerNextRep() {
        guard isExerciseActive else { return }
        guard repCount < totalReps else {
            endExercise()
            return
        }
        
        repCount += 1
        hasLookedInDirection = false
        
        let nextDir = Direction.allCases.filter { $0 != currentDirection }.randomElement() ?? .top
        currentDirection = nextDir
        
        let currentTier = (repCount - 1) / 4
        let duration = speedTiers[currentTier]
        
        speak(nextDir.rawValue)
        
        centerMessageLabel.text = nextDir.rawValue
        UIView.animate(withDuration: 0.2) {
            self.centerMessageLabel.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            if !self.hasLookedInDirection {
                self.notificationGenerator.notificationOccurred(.error)
            }
            UIView.animate(withDuration: 0.2) { self.centerMessageLabel.alpha = 0 }
            self.triggerNextRep()
        }
    }

    private func speak(_ text: String) {
        guard isExerciseActive else { return }
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-IN")
        utterance.rate = 0.52
        utterance.volume = 1.0
        speechSynthesizer.speak(utterance)
    }

    private func endExercise() {
        isTracking = false
        faceTrackingSession.pause()
        
        if let startTime = sessionStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsed)
        }
        
        notificationGenerator.notificationOccurred(.success)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.text = "Finished!\nScore: \(self.successfulFollows)/16"
            self.centerMessageLabel.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self, self.isExerciseActive else { return }
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func prepareInitialState() {
        centerMessageLabel.alpha = 0
    }

    private func setupEyeTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        faceTrackingSession.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        faceTrackingSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
