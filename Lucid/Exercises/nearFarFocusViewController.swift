import UIKit
import AVFoundation

class NearFarFocusViewController: UIViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Audio Session error: \(error)")
        }
        
        startInitialCountdown()
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
        circleView.layer.removeAllAnimations()
        instructionLabel.layer.removeAllAnimations()
        currentPhase = .none
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
    
    private func startInitialCountdown() {
        currentPhase = .none
        secondsRemaining = 5
        centerMessageLabel.text = "\(secondsRemaining)"
        
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Alternate focusing on the screen and looking away.\nFollow the audio and visual cues."
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel.alpha = 1.0
        }
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isExerciseActive, self.isInstructionPhase else {
                timer.invalidate()
                return
            }
            self.secondsRemaining -= 1
            
            if self.secondsRemaining > 0 {
                self.centerMessageLabel.text = "\(self.secondsRemaining)"
            } else {
                timer.invalidate()
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    guard self.isExerciseActive, self.isInstructionPhase else { return }
                    self.sessionStartTime = Date()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard let self = self, self.isExerciseActive else { return }
                        self.startNearFocusPhase()
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
        instructionLabel.text = "Look at the screen\n(Round \(currentRound)/\(totalRounds))"
        
        speak("Look at the screen")
        
        circleView.layer.removeAllAnimations()
        circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: Double(randomDuration), delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
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
        instructionLabel.text = "Look away from the screen\n(Round \(currentRound)/\(totalRounds))"
        
        speak("Look away")
        
        circleView.layer.removeAllAnimations()
        circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: Double(randomDuration), delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }
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
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(
            type: "NearFar",
            duration: elapsedSeconds,
            accuracy: 100,
            errors: 0
        )
        newSession.user = user
        context.insert(newSession)
        
        do {
            try context.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
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
}
