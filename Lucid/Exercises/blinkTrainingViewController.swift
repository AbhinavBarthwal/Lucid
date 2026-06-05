import UIKit
import ARKit
import SceneKit
import AVFoundation
import SwiftUI
import AudioToolbox

var doubleBlink = 8
var LeftRighEyeBlink = 8
private var globalSessionStartTime: Date? // Renamed to avoid shadow warning

enum TypeOfBlink {
    case doubleBlink(remaining: Int)
    case singleBlink(eye: String, remaining: Int)
    case completed
    
    var remaining: Int {
        switch self {
        case .doubleBlink(let r): return r
        case .singleBlink(_, let r): return r
        case .completed: return 0
        }
    }
    
    mutating func decrement() {
        switch self {
        case .doubleBlink(let r): self = .doubleBlink(remaining: r - 1)
        case .singleBlink(let e, let r): self = .singleBlink(eye: e, remaining: r - 1)
        case .completed: break
        }
    }
}

class BlinkTrainingViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var largeCountLabel: UILabel!
    @IBOutlet var centerMessageLAbel: UILabel!
    
    private var sessionStartTime: Date?
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var isExerciseActive = true

    override var prefersStatusBarHidden: Bool { return true }
    
    private var currentPhase: TypeOfBlink = .completed
    private var isInstructionPhase = true
    private var isAcceptingInput = false
    private var isLeftEyeClosed = false
    private var isRightEyeClosed = false
    private let blinkThreshold: Float = 0.75
    
    private var totalErrors = 0
    private var failedAttemptsForCurrentBlink = 0
    private var consecutiveErrors = 0
    private var errorsPerPhase: [Int] = [0, 0, 0]
    
    private var responseTimer: Timer?
    private var phaseTimer: Timer?
    private var secondsRemaining = 0
    private var cueTime: Date?
    private var reactionTimes: [TimeInterval] = []

    // Navigation/Skip buttons for instructions
    private var instructionNextButton: UIButton?
    private var instructionPrevButton: UIButton?
    private var currentInstructionIndex = 0

    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "Blink both eyes after you feel the vibration", duration: 4.5),
        InstructionStep(message: "You will feel one vibration for the cue and two vibrations when your blink is wrong.", duration: 5.5)
    ]
    
    private var leftMaxBlinks: [Float] = []
    private var rightMaxBlinks: [Float] = []
    private var currentBlinkMaxLeft: Float = 0.0
    private var currentBlinkMaxRight: Float = 0.0
    
    private let impactMed = UIImpactFeedbackGenerator(style: .rigid)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .rigid)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGen = UINotificationFeedbackGenerator()
    


    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
            try session.setActive(true)
        } catch {
            print("Audio Session error: \(error)")
        }
        
        setupBackgroundVideo()
        setupInitialUI()
        setupInstructionButtons()
        runInstructionSequence(index: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isExerciseActive = true
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        let config = ARFaceTrackingConfiguration()
        sceneView.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isExerciseActive = false
        sceneView.session.pause()
        phaseTimer?.invalidate(); phaseTimer = nil
        responseTimer?.invalidate(); responseTimer = nil
        player?.pause()
        playerLayer?.removeFromSuperlayer(); playerLayer = nil
        sceneView.delegate = nil
        isAcceptingInput = false
        currentPhase = .completed
        instructionLabel.layer.removeAllAnimations()
        largeCountLabel.layer.removeAllAnimations()
        centerMessageLAbel.layer.removeAllAnimations()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
        
    private func setupInitialUI() {
        instructionLabel.alpha = 0
        largeCountLabel.alpha = 0
        playerLayer?.opacity = 0
        instructionLabel.isHidden = false
        largeCountLabel.isHidden = false
        centerMessageLAbel.isHidden = false
        centerMessageLAbel.alpha = 1
        sceneView.delegate = self
        sceneView.alpha = 0
        
        instructionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        instructionLabel.textColor = .lightGray
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        
        centerMessageLAbel.font = .systemFont(ofSize: 32, weight: .bold)
        centerMessageLAbel.textColor = .white
        centerMessageLAbel.textAlignment = .center
        centerMessageLAbel.numberOfLines = 0
        
        largeCountLabel.numberOfLines = 0
    }
    
    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLAbel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.largeCountLabel.alpha = showExerciseUI ? 1 : 0
            self.playerLayer?.opacity = showExerciseUI ? 1 : 0
        }) { _ in
            completion?()
        }
    }
    
    private func runInstructionSequence(index: Int) {
        guard isExerciseActive, isInstructionPhase else { return }
        currentInstructionIndex = index
        let isFirstRun = InstructionTracker.isFirstRun(for: "Blink")
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            if isFirstRun {
                instructionNextButton?.isHidden = false
                let canGoBack = index > 0
                instructionPrevButton?.isHidden = !canGoBack
                
                let isLastStep = (index == exerciseInstructions.count - 1)
                instructionNextButton?.setTitle(isLastStep ? "Start Exercise" : "Next", for: .normal)
            } else {
                instructionNextButton?.isHidden = false
                instructionPrevButton?.isHidden = true
                instructionNextButton?.setTitle("Skip", for: .normal)
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLAbel.alpha = 0
            }) { _ in
                guard self.isExerciseActive, self.isInstructionPhase else { return }
                self.centerMessageLAbel.text = step.message
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLAbel.alpha = 1
                }) { _ in
                    if !isFirstRun {
                        DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                            guard let self = self, self.isExerciseActive, self.isInstructionPhase, self.currentInstructionIndex == index else { return }
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
        let isFirstRun = InstructionTracker.isFirstRun(for: "Blink")
        
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
        if InstructionTracker.isFirstRun(for: "Blink") {
            runInstructionSequence(index: currentInstructionIndex + 1)
        } else {
            finishInstructionsAndStartExercise()
        }
    }
    
    @objc private func instructionPrevTapped() {
        if InstructionTracker.isFirstRun(for: "Blink") && currentInstructionIndex > 0 {
            runInstructionSequence(index: currentInstructionIndex - 1)
        }
    }
    
    private func finishInstructionsAndStartExercise() {
        InstructionTracker.markAsCompleted(for: "Blink")
        currentInstructionIndex = 999
        
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionNextButton?.alpha = 0
            self.instructionPrevButton?.alpha = 0
        }) { _ in
            self.instructionNextButton?.removeFromSuperview()
            self.instructionPrevButton?.removeFromSuperview()
        }
        
        runStartCountdown { [weak self] in
            guard let self = self, self.isExerciseActive, self.isInstructionPhase else { return }
            self.sessionStartTime = Date()
            self.currentPhase = .doubleBlink(remaining: doubleBlink)
            self.startActiveBlinkPhase()
        }
    }

    private func runStartCountdown(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.centerMessageLAbel.alpha = 0
        }) { _ in
            self.centerMessageLAbel.text = "3"
            UIView.animate(withDuration: 0.3, animations: {
                self.centerMessageLAbel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.isExerciseActive, self.isInstructionPhase else { return }
                    UIView.animate(withDuration: 0.2, animations: {
                        self.centerMessageLAbel.alpha = 0
                    }) { _ in
                        self.centerMessageLAbel.text = "2"
                        UIView.animate(withDuration: 0.3, animations: {
                            self.centerMessageLAbel.alpha = 1
                        }) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                guard let self = self, self.isExerciseActive, self.isInstructionPhase else { return }
                                UIView.animate(withDuration: 0.2, animations: {
                                    self.centerMessageLAbel.alpha = 0
                                }) { _ in
                                    self.centerMessageLAbel.text = "1"
                                    UIView.animate(withDuration: 0.3, animations: {
                                        self.centerMessageLAbel.alpha = 1
                                    }) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                            guard let self = self, self.isExerciseActive, self.isInstructionPhase else { return }
                                            UIView.animate(withDuration: 0.3, animations: {
                                                self.centerMessageLAbel.alpha = 0
                                            }) { _ in
                                                self.centerMessageLAbel.text = ""
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
    
    private func showPreparationMessage(_ message: String, completion: @escaping () -> Void) {
        isAcceptingInput = false
        isInstructionPhase = true
        centerMessageLAbel.text = message
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isExerciseActive, self.isInstructionPhase else { return }
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                guard self.isExerciseActive, self.isInstructionPhase else { return }
                completion()
            }
        }
    }
    

    
    private func startTransitionPhase(message: String = "Nicely Done!", nextPhase: @escaping () -> Void) {
        isAcceptingInput = false
        responseTimer?.invalidate()
        phaseTimer?.invalidate()
        
        centerMessageLAbel.text = message
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                guard self.isExerciseActive else { return }
                nextPhase()
            }
        }
    }
    
    private func startActiveBlinkPhase() {
        guard isExerciseActive else { return }
        isInstructionPhase = false
        secondsRemaining = 40
        largeCountLabel.text = "\(currentPhase.remaining)"
        instructionLabel.text = ""
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.triggerNextCue()
            self.startPhaseTimer()
        }
    }
    
    private func startPhaseTimer() {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isExerciseActive else {
                timer.invalidate()
                return
            }
            self.secondsRemaining -= 1
            
            if self.secondsRemaining <= 0 {
                timer.invalidate()
                self.centerMessageLAbel.text = "Time's Up!"
                self.startTransitionPhase {
                    guard self.isExerciseActive else { return }
                    self.advancePhase()
                }
            }
        }
    }
        
    private func triggerNextCue() {
        guard isExerciseActive else { return }
        isAcceptingInput = false
        hideNudge()
        currentBlinkMaxLeft = 0.0
        currentBlinkMaxRight = 0.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            Vibrator.playDouble()
            self.isAcceptingInput = true
            self.cueTime = Date()
            self.startResponseTimer()
        }
    }
    
    private func startResponseTimer() {
        responseTimer?.invalidate()
        responseTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { [weak self] _ in
            guard let self = self, self.isExerciseActive else { return }
            self.skipCurrentBlinkSectionDueToNoResponse()
        }
    }

    private func skipCurrentBlinkSectionDueToNoResponse() {
        guard isExerciseActive, isAcceptingInput else { return }
        isAcceptingInput = false
        responseTimer?.invalidate()
        phaseTimer?.invalidate()
        recordZeroMarksForSkippedSection()
        cueTime = nil
        failedAttemptsForCurrentBlink = 0
        consecutiveErrors = 0
        hideNudge()
        advancePhase(skippedCurrentSection: true)
    }

    private func recordZeroMarksForSkippedSection() {
        switch currentPhase {
        case .doubleBlink(let remaining):
            leftMaxBlinks.append(contentsOf: Array(repeating: 0.0, count: remaining))
            rightMaxBlinks.append(contentsOf: Array(repeating: 0.0, count: remaining))
        case .singleBlink(let eye, let remaining):
            if eye == "left" {
                leftMaxBlinks.append(contentsOf: Array(repeating: 0.0, count: remaining))
            } else if eye == "right" {
                rightMaxBlinks.append(contentsOf: Array(repeating: 0.0, count: remaining))
            }
        case .completed:
            break
        }
    }
    
    private func showContextualNudge() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            let nudgeText: String
            switch self.currentPhase {
            case .doubleBlink: nudgeText = "Please, try a double blink"
            case .singleBlink(let eye, _): nudgeText = "Please, blink your \(eye) eye"
            default: return
            }
            self.instructionLabel.text = nudgeText
            UIView.animate(withDuration: 0.5) { self.instructionLabel.alpha = 1.0 }
        }
    }
    
    private func hideNudge() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard isExerciseActive, let faceAnchor = anchor as? ARFaceAnchor, isAcceptingInput else { return }
        
        let realLeftValue = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        let realRightValue = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
        
        if realLeftValue > currentBlinkMaxLeft { currentBlinkMaxLeft = realLeftValue }
        if realRightValue > currentBlinkMaxRight { currentBlinkMaxRight = realRightValue }
        
        let leftClosedNow = realLeftValue > blinkThreshold
        let rightClosedNow = realRightValue > blinkThreshold
        
        let leftOpened = isLeftEyeClosed && !leftClosedNow
        let rightOpened = isRightEyeClosed && !rightClosedNow
        
        if leftOpened || rightOpened {
            handleBlinkAttempt(left: leftOpened, right: rightOpened)
        }
        
        isLeftEyeClosed = leftClosedNow
        isRightEyeClosed = rightClosedNow
    }
    
    private func handleBlinkAttempt(left: Bool, right: Bool) {
        let isCorrect: Bool
        switch currentPhase {
        case .doubleBlink: isCorrect = left && right
        case .singleBlink(let eye, _): isCorrect = (eye == "left") ? (left && !right) : (right && !left)
        default: return
        }
        
        if isCorrect {
            switch currentPhase {
            case .doubleBlink:
                leftMaxBlinks.append(currentBlinkMaxLeft)
                rightMaxBlinks.append(currentBlinkMaxRight)
            case .singleBlink(let eye, _):
                if eye == "left" { leftMaxBlinks.append(currentBlinkMaxLeft) }
                else if eye == "right" { rightMaxBlinks.append(currentBlinkMaxRight) }
            default: break
            }
            
            consecutiveErrors = 0
            failedAttemptsForCurrentBlink = 0
            processSuccess()
        } else {
            handleError()
        }
    }
    
    private func handleError() {
        totalErrors += 1
        consecutiveErrors += 1
        failedAttemptsForCurrentBlink += 1
        
        switch currentPhase {
        case .doubleBlink: errorsPerPhase[0] += 1
        case .singleBlink(let eye, _): errorsPerPhase[eye == "left" ? 1 : 2] += 1
        default: break
        }
        
        Vibrator.playError()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            UIView.animate(withDuration: 0.2, animations: {
                self.largeCountLabel.textColor = .systemRed
            }) { _ in
                UIView.animate(withDuration: 0.2) { self.largeCountLabel.textColor = .white }
            }
            
            if self.consecutiveErrors >= 3 { self.showContextualNudge() }
            
            if self.failedAttemptsForCurrentBlink >= 10 {
                self.failedAttemptsForCurrentBlink = 0
                self.processSuccess()
            }
        }
    }
    
    private func processSuccess() {
        if let cue = cueTime {
            let elapsed = Date().timeIntervalSince(cue)
            reactionTimes.append(elapsed)
            cueTime = nil
        }
        responseTimer?.invalidate()
        isAcceptingInput = false
        hideNudge()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.currentPhase.decrement()
            self.largeCountLabel.text = "\(self.currentPhase.remaining)"
            Vibrator.playSingle()
            
            if self.currentPhase.remaining <= 0 {
                Vibrator.playSuccess()
                self.phaseTimer?.invalidate()
                self.advancePhase()
            } else {
                self.triggerNextCue()
            }
        }
    }
    
    private func advancePhase(skippedCurrentSection: Bool = false) {
        guard isExerciseActive else { return }
        consecutiveErrors = 0
        let transitionMessage = skippedCurrentSection ? "Let's go to the next step" : "Nicely Done!"
        
        switch currentPhase {
        case .doubleBlink:
            self.currentPhase = .singleBlink(eye: "left", remaining: LeftRighEyeBlink)
            startTransitionPhase(message: transitionMessage) { [weak self] in
                guard let self = self, self.isExerciseActive else { return }
                self.showPreparationMessage("Blink left eye only after the vibration") {
                    guard self.isExerciseActive else { return }
                    self.startActiveBlinkPhase()
                }
            }
        case .singleBlink(let eye, _):
            if eye == "left" {
                self.currentPhase = .singleBlink(eye: "right", remaining: LeftRighEyeBlink)
                startTransitionPhase(message: transitionMessage) { [weak self] in
                    guard let self = self, self.isExerciseActive else { return }
                    self.showPreparationMessage("Blink right eye only after the vibration") {
                        guard self.isExerciseActive else { return }
                        self.startActiveBlinkPhase()
                    }
                }
            } else {
                guard !skippedCurrentSection else {
                    finishSession()
                    return
                }
                
                startTransitionPhase { [weak self] in
                    guard let self = self, self.isExerciseActive else { return }
                    self.finishSession()
                }
            }
        default: break
        }
    }
    
    private func finishSession() {
        currentPhase = .completed
        phaseTimer?.invalidate()
        
        let startTime = sessionStartTime ?? Date()
        let endTime = Date()
        let elapsedSeconds = Int(endTime.timeIntervalSince(startTime))
        
        let allPeaks = leftMaxBlinks + rightMaxBlinks
        let baseScore = allPeaks.isEmpty ? 0 : (allPeaks.reduce(0, +) / Float(allPeaks.count)) * 100
        
        let avgReactionTime = reactionTimes.isEmpty ? 1.5 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        
        let newSession = ExerciseSession(
            type: "Blink",
            duration: elapsedSeconds,
            intensity: allPeaks.isEmpty ? 0 : allPeaks.reduce(0, +) / Float(allPeaks.count),
            errors: totalErrors
        )
        
        newSession.startingTime = startTime
        newSession.endingTime = endTime
        newSession.leftEyeBlinks = leftMaxBlinks.count
        newSession.rightEyeBlinks = rightMaxBlinks.count
        newSession.errorsPerSession = errorsPerPhase
        newSession.responsivenessScore = avgReactionTime
        
        let activeUser = SwiftDataManager.shared.getOrCreateUser()
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            print("\n BLINK DATA SAVED & LINKED TO: \(activeUser.name)")
        } catch {
            print("\n SAVE FAILED: \(error) \n")
        }
        
        showSummaryScreen(score: baseScore, avgReactionTime: avgReactionTime)
    }

    private func showSummaryScreen(score: Float, avgReactionTime: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
            
            let storyboard = UIStoryboard(name: "Report", bundle: nil)
            guard let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController else {
                return
            }
            
            reportVC.overallScore = Int(score)
            reportVC.totalErrors = self.totalErrors
            reportVC.chartData = [
                "Left": self.leftMaxBlinks,
                "Right": self.rightMaxBlinks
            ]
            reportVC.avgReactionTimeSeconds = avgReactionTime
            
            let navWrapper = UINavigationController(rootViewController: reportVC)
            navWrapper.modalPresentationStyle = .fullScreen
            
            if let nav = self.navigationController {
                nav.popViewController(animated: false)
            } else {
                self.dismiss(animated: false)
            }
            
            rootVC.present(navWrapper, animated: true)
        }
    }

    private func setupBackgroundVideo() {
        guard let path = Bundle.main.path(forResource: "eyeBlinkBackground", ofType: "mp4") else { return }
        let url = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: url)
        player = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(playerLayer!, at: 0)
        player?.isMuted = true
        player?.play()
    }


}

struct Vibrator {
    /// Plays a short, distinct vibration representing a success event.
    static func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        // Play system pop/success haptic sound (1520 is a physical double/medium tap sound)
        AudioServicesPlaySystemSound(1520)
    }
    
    /// Plays a double vibration for a wrong response.
    static func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let secondGenerator = UIImpactFeedbackGenerator(style: .heavy)
            secondGenerator.prepare()
            secondGenerator.impactOccurred()
            AudioServicesPlaySystemSound(1520)
        }
    }
    
    /// Plays a standard single vibration.
    static func playSingle() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        AudioServicesPlaySystemSound(1520)
    }
    
    /// Plays a standard double vibration with a short delay.
    static func playDouble() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        
        AudioServicesPlaySystemSound(1520)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let secondGenerator = UIImpactFeedbackGenerator(style: .heavy)
            secondGenerator.prepare()
            secondGenerator.impactOccurred()
            AudioServicesPlaySystemSound(1520)
        }
    }
    
    /// Plays a strong physical vibration (e.g. using the full vibration motor).
    static func playHeavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        
        // 4095 is kSystemSoundID_Vibrate, which physically shakes the device
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    /// Plays a warning style vibration.
    static func playWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        
        AudioServicesPlaySystemSound(1520)
    }
}
