import UIKit
import ARKit
import AVFoundation

class SaccadicJumps: UIViewController, ARSessionDelegate {

    // Label used to display instructions and direction prompts to the user
    @IBOutlet weak var centerMessageLabel: UILabel!
        
    // Converts text (like "Top", "Left") into speech output
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // Provides success/error vibration feedback
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // Provides subtle tap feedback on correct response
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // ARKit session used for face tracking and gaze detection
    private let faceTrackingSession = ARSession()
    
    // Enum representing all possible gaze directions
    // CaseIterable allows looping/random selection
    private enum Direction: String, CaseIterable {
        case top = "Top", bottom = "Bottom", left = "Left", right = "Right"
    }
        
    private var currentDirection: Direction? // Current target direction user should look at
    
    private var repCount = 0                 // Tracks number of repetitions completed
    private let totalReps = 16               // Total number of repetitions in exercise
    
    private var successfulFollows = 0        // Counts how many correct responses user gave
    
    private var isTracking = false           // Indicates whether AR tracking is active
    
    // Prevents multiple counts for a single repetition
    private var hasLookedInDirection = false
        
    // Time allowed per rep (reduces as difficulty increases)
    private let speedTiers: [Double] = [2.5 , 2.2 , 2.0 , 1.8]
        
    // Instructions shown before exercise begins
    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "3", duration: 0.8),
        InstructionStep(message: "2", duration: 0.8),
        InstructionStep(message: "1", duration: 0.8),
        InstructionStep(message: "Move your eyes in the\ndirection announced", duration: 3.0),
        InstructionStep(message: "Keep your head still", duration: 2.5)
    ]

    // Stores when exercise started (used for duration tracking)
    private var sessionStartTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAudioSession()   // Setup audio for speech
        prepareInitialState()     // Reset UI
        setupEyeTracking()        // Start ARKit face tracking
        
        // Preload haptics to reduce delay when triggered
        notificationGenerator.prepare()
        impactGenerator.prepare()
        
        // Start instruction flow
        runInstructionSequence(index: 0)
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // .duckOthers reduces volume of other apps while this plays audio
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            
            try session.setActive(true)
        } catch {
            print("Audio Session error: \(error)")
        }
    }
    
    // Recursively displays instructions with smooth fade animations
    private func runInstructionSequence(index: Int) {
        
        // If instructions remain
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            // Fade out current text
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                
                // Update text
                self.centerMessageLabel.text = step.message
                
                // Fade in new text
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    
                    // Wait for step duration, then move to next instruction
                    DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) {
                        self.runInstructionSequence(index: index + 1)
                    }
                }
            }
        } else {
            // All instructions done → start exercise
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                self.startExercise()
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
        // Only proceed if tracking is active and face is detected
        guard isTracking,
              let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        
        // Gaze direction vector from ARKit
        let lookAt = faceAnchor.lookAtPoint
        
        // Threshold for detecting gaze direction
        let threshold: Float = 0.14
        
        // Lower threshold for bottom because downward eye movement is subtle
        let bottomThreshold: Float = 0.05
        
        DispatchQueue.main.async {
            
            // Ensure:
            // 1. There is a target direction
            // 2. User hasn't already completed this rep
            guard let target = self.currentDirection,
                  !self.hasLookedInDirection else { return }
            
            var success = false
            
            // Compare gaze direction against expected direction
            switch target {
            case .top:
                success = lookAt.y > threshold
                
            case .left:
                success = lookAt.x < -threshold
                
            case .right:
                success = lookAt.x > threshold
                
            case .bottom:
                // Stricter threshold for downward gaze
                success = lookAt.y < -bottomThreshold
            }
            
            // If user looked correctly → mark success
            if success {
                self.handleSuccessfulLook()
            }
        }
    }
    
    private func handleSuccessfulLook() {
        
        // Prevent multiple detections in same rep
        hasLookedInDirection = true
        
        // Increase correct response count
        successfulFollows += 1
        
        // Provide haptic feedback
        impactGenerator.impactOccurred()
    }
    
    private func startExercise() {
        self.sessionStartTime = Date()
        self.isTracking = true
        
        // Begin first repetition
        triggerNextRep()
    }
    
    private func triggerNextRep() {
        
        // If all repetitions completed → end exercise
        guard repCount < totalReps else {
            endExercise()
            return
        }
        
        repCount += 1
        hasLookedInDirection = false
        
        // Select a random direction (avoid repeating previous)
        let nextDir = Direction.allCases
            .filter { $0 != currentDirection }
            .randomElement() ?? .top
        
        currentDirection = nextDir
        
        // Determine speed tier (every 4 reps increases difficulty)
        let currentTier = (repCount - 1) / 4
        let duration = speedTiers[currentTier]
        
        // Speak direction aloud
        speak(nextDir.rawValue)
        
        // Display direction visually
        centerMessageLabel.text = nextDir.rawValue
        UIView.animate(withDuration: 0.2) {
            self.centerMessageLabel.alpha = 1
        }
        
        // Wait for user response
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            
            // If user failed → error feedback
            if !self.hasLookedInDirection {
                self.notificationGenerator.notificationOccurred(.error)
            }
            
            // Fade out text before next rep
            UIView.animate(withDuration: 0.2) {
                self.centerMessageLabel.alpha = 0
            }
            
            // Move to next repetition
            self.triggerNextRep()
        }
    }
    
    private func speak(_ text: String) {
        
        // Stop ongoing speech to prevent overlap
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Indian English voice
        utterance.voice = AVSpeechSynthesisVoice(language: "en-IN")
        
        utterance.rate = 0.52   // Slightly slower for clarity
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    private func endExercise() {
        
        isTracking = false
        faceTrackingSession.pause()
        
        // Calculate total duration
        if let startTime = sessionStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsed)
        }
        
        // Success feedback
        notificationGenerator.notificationOccurred(.success)
        
        // Display final score
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.text = "Finished!\nScore: \(self.successfulFollows)/16"
            self.centerMessageLabel.alpha = 1
        }) { _ in
            
            // Navigate back after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func prepareInitialState() {
        // Hide label initially
        centerMessageLabel.alpha = 0
    }
    
    private func setupEyeTracking() {
        
        // Ensure device supports face tracking (TrueDepth camera required)
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        faceTrackingSession.delegate = self
        
        let configuration = ARFaceTrackingConfiguration()
        
        // Reset tracking to avoid previous session interference
        faceTrackingSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
