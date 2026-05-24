import UIKit
import ARKit
import AVFoundation

class SaccadicJumpsViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var centerMessageLabel: UILabel!
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let faceTrackingSession = ARSession()
    private var isExerciseActive = true

    override var prefersStatusBarHidden: Bool { return true }

    enum Direction: String, CaseIterable {
        case top = "Top", bottom = "Bottom", left = "Left", right = "Right"

        var reportKey: String {
            switch self {
            case .top: return "top"
            case .bottom: return "bottom"
            case .left: return "left"
            case .right: return "right"
            }
        }
    }
    
    private var currentDirection: Direction?
    private var repCount = 0
    private let totalReps = 16
    private var successfulFollows = 0
    private var isTracking = false
    private var hasLookedInDirection = false
    private var directionAttempts: [Direction: Int] = [:]
    private var directionMisses: [Direction: Int] = [:]
    private var directionsPool: [Direction] = []
    
    private let speedTiers: [Double] = [2.5 , 2.2 , 2.0 , 1.8]
    
    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "3", duration: 0.8),
        InstructionStep(message: "2", duration: 0.8),
        InstructionStep(message: "1", duration: 0.8),
        InstructionStep(message: "Move your eyes in the\ndirection announced", duration: 3.0),
        InstructionStep(message: "Keep your head still", duration: 2.5)
    ]

    private var sessionStartTime: Date?
    private var cueTime: Date?
    private var reactionTimes: [TimeInterval] = []

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
        guard isExerciseActive, !isTracking else { return }
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive, !self.isTracking else { return }
                self.centerMessageLabel.text = step.message
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                        guard let self = self, self.isExerciseActive, !self.isTracking else { return }
                        self.runInstructionSequence(index: index + 1)
                    }
                }
            }
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive, !self.isTracking else { return }
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
        if let cue = cueTime {
            let elapsed = Date().timeIntervalSince(cue)
            reactionTimes.append(elapsed)
            cueTime = nil
        }
        hasLookedInDirection = true
        successfulFollows += 1
        impactGenerator.impactOccurred()
    }

    private func startExercise() {
        guard isExerciseActive else { return }
        var pool: [Direction] = []
        for direction in Direction.allCases {
            for _ in 0..<4 {
                pool.append(direction)
            }
        }
        
        for _ in 0..<1000 {
            pool.shuffle()
            var hasAdjacentDuplicate = false
            for i in 0..<(pool.count - 1) {
                if pool[i] == pool[i + 1] {
                    hasAdjacentDuplicate = true
                    break
                }
            }
            if !hasAdjacentDuplicate {
                break
            }
        }
        self.directionsPool = pool
        
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
        
        let nextDir = directionsPool.isEmpty ? (Direction.allCases.randomElement() ?? .top) : directionsPool.removeLast()
        currentDirection = nextDir
        directionAttempts[nextDir, default: 0] += 1
        
        let currentTier = (repCount - 1) / 4
        let duration = speedTiers[currentTier]
        
        speak(nextDir.rawValue)
        cueTime = Date()
        
        centerMessageLabel.text = nextDir.rawValue
        UIView.animate(withDuration: 0.2) {
            self.centerMessageLabel.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            if !self.hasLookedInDirection {
                if let currentDirection = self.currentDirection {
                    self.directionMisses[currentDirection, default: 0] += 1
                }
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
        
        let elapsed = sessionStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
        let accuracy = totalReps > 0 ? Int((Double(successfulFollows) / Double(totalReps)) * 100.0) : 0
        var calculatedDirectionErrors: [String: Double] = [:]
        for direction in Direction.allCases {
            let attempts = directionAttempts[direction] ?? 0
            let misses = directionMisses[direction] ?? 0
            calculatedDirectionErrors[direction.reportKey] = attempts > 0 ? (Double(misses) / Double(attempts)) * 100.0 : 0.0
        }
        
        let avgReactionTime = reactionTimes.isEmpty ? 1.5 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(
            type: "SaccadicJumps",
            duration: elapsed,
            accuracy: accuracy,
            errors: totalReps - successfulFollows
        )
        newSession.user = user
        newSession.directionErrors = calculatedDirectionErrors
        newSession.responsivenessScore = avgReactionTime
        context.insert(newSession)
        
        do {
            try context.save()
            notificationGenerator.notificationOccurred(.success)
        } catch {
            print("❌ Saccadic Jumps Save failed: \(error)")
        }
        
        showResultReport(avgReactionTime: avgReactionTime)
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

    private func showResultReport(avgReactionTime: Double) {
        let accuracy = totalReps > 0 ? Int((Double(successfulFollows) / Double(totalReps)) * 100.0) : 0
        var directionErrors: [String: Double] = [:]
        for direction in Direction.allCases {
            let attempts = directionAttempts[direction] ?? 0
            let misses = directionMisses[direction] ?? 0
            directionErrors[direction.reportKey] = attempts > 0 ? (Double(misses) / Double(attempts)) * 100.0 : 0.0
        }

        let storyboard = UIStoryboard(name: "Report", bundle: nil)
        guard let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController else { return }
        reportVC.sessionType = "SaccadicJumps"
        reportVC.overallScore = accuracy
        reportVC.totalErrors = totalReps - successfulFollows
        reportVC.directionErrors = directionErrors
        reportVC.avgReactionTimeSeconds = avgReactionTime

        let nav = UINavigationController(rootViewController: reportVC)
        nav.modalPresentationStyle = .fullScreen
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
            
            if let navStack = self.navigationController {
                navStack.popViewController(animated: false)
            } else {
                self.dismiss(animated: false)
            }
            
            rootVC.present(nav, animated: true)
        }
    }


}
