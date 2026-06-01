import UIKit
import ARKit
import AudioToolbox
import AVFoundation

struct InstructionStep {
    let message: String
    let duration: TimeInterval
}

private enum SmoothPursuitsExercisePhase { case none, tracking }

class SmoothPursuitsViewController: UIViewController, ARSessionDelegate {

    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var centerMessageLabel: UILabel!
    @IBOutlet private weak var circleView: UIView!

    private let arSession = ARSession()
    private var isLookingAtScreen = false
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private let successHapticGenerator = UINotificationFeedbackGenerator()
    private var isExerciseActive = true

    override var prefersStatusBarHidden: Bool { return true }

    private var sessionStartTime: Date?
    private var currentPhase: SmoothPursuitsExercisePhase = .none
    private var gazeTimer: Timer?
    
    private var currentSpeedLevel = 0
    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "Follow the dot closely", duration: 3.0),
        InstructionStep(message: "Keep your head still", duration: 3.5),
        InstructionStep(message: "Keep your phone at 20cm", duration: 3.5),
        InstructionStep(message: "The phone will vibrate if you look away from the screen, and also when you finish a round.", duration: 6.0)
    ]

    private let phaseDurations: [Double] = [2.0 , 1.75 , 1.5 , 1.25 , 1.0]
    

    private var totalFramesChecked = 0
    private var totalErrors = 0
    private var currentTargetDirectionIndex = 0
    private var directionChecks: [String: Int] = [:]
    private var directionFails: [String: Int] = [:]
    private var headMovementSamples: [Float] = []

    // Navigation/Skip buttons for instructions
    private var instructionNextButton: UIButton?
    private var instructionPrevButton: UIButton?
    private var currentInstructionIndex = 0

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
        
        setupInitialUI()
        arSession.delegate = self
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare()

        centerMessageLabel.alpha = 0
        setupInstructionButtons()
        runInstructionSequence(index: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isExerciseActive = true
        guard ARFaceTrackingConfiguration.isSupported else { return }
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isExerciseActive = false
        arSession.pause()
        gazeTimer?.invalidate(); gazeTimer = nil
        circleView.layer.removeAllAnimations()
        centerMessageLabel.layer.removeAllAnimations()
        instructionLabel.layer.removeAllAnimations()
        currentPhase = .none
        isLookingAtScreen = false
        self.tabBarController?.tabBar.isHidden = false
    }

    private func runInstructionSequence(index: Int) {
        guard isExerciseActive, currentPhase == .none else { return }
        currentInstructionIndex = index
        let isFirstRun = InstructionTracker.isFirstRun(for: "SmoothPursuits")
        
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
                self.centerMessageLabel.alpha = 0
            }) { _ in
                guard self.isExerciseActive, self.currentPhase == .none else { return }
                self.centerMessageLabel.text = step.message
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    if !isFirstRun {
                        DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                            guard let self = self, self.isExerciseActive, self.currentPhase == .none, self.currentInstructionIndex == index else { return }
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
        let isFirstRun = InstructionTracker.isFirstRun(for: "SmoothPursuits")
        
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
        if InstructionTracker.isFirstRun(for: "SmoothPursuits") {
            runInstructionSequence(index: currentInstructionIndex + 1)
        } else {
            finishInstructionsAndStartExercise()
        }
    }
    
    @objc private func instructionPrevTapped() {
        if InstructionTracker.isFirstRun(for: "SmoothPursuits") && currentInstructionIndex > 0 {
            runInstructionSequence(index: currentInstructionIndex - 1)
        }
    }
    
    private func finishInstructionsAndStartExercise() {
        InstructionTracker.markAsCompleted(for: "SmoothPursuits")
        currentInstructionIndex = 999
        
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionNextButton?.alpha = 0
            self.instructionPrevButton?.alpha = 0
        }) { _ in
            self.instructionNextButton?.removeFromSuperview()
            self.instructionPrevButton?.removeFromSuperview()
        }
        
        runStartCountdown { [weak self] in
            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
            self.startSmoothPursuitPhase()
        }
    }

    private func runStartCountdown(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.centerMessageLabel.alpha = 0
        }) { _ in
            self.centerMessageLabel.text = "3"
            UIView.animate(withDuration: 0.3, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
                    UIView.animate(withDuration: 0.2, animations: {
                        self.centerMessageLabel.alpha = 0
                    }) { _ in
                        self.centerMessageLabel.text = "2"
                        UIView.animate(withDuration: 0.3, animations: {
                            self.centerMessageLabel.alpha = 1
                        }) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
                                UIView.animate(withDuration: 0.2, animations: {
                                    self.centerMessageLabel.alpha = 0
                                }) { _ in
                                    self.centerMessageLabel.text = "1"
                                    UIView.animate(withDuration: 0.3, animations: {
                                        self.centerMessageLabel.alpha = 1
                                    }) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
                                            UIView.animate(withDuration: 0.3, animations: {
                                                self.centerMessageLabel.alpha = 0
                                            }) { _ in
                                                self.centerMessageLabel.text = ""
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

    private func startSmoothPursuitPhase() {
        guard isExerciseActive else { return }
        currentPhase = .tracking
        if sessionStartTime == nil { sessionStartTime = Date() }

        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Keep your head still and follow the dot"
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard self.isExerciseActive, self.currentPhase == .tracking else { return }
                
                UIView.animate(withDuration: 0.5) {
                    self.instructionLabel.alpha = 0
                } completion: { _ in
                    guard self.isExerciseActive else { return }
                    self.startGazeMonitor()
                    self.startStarPathAnimation(targetIndex: 0)
                }
            }
        }
    }

    private func startStarPathAnimation(targetIndex: Int) {
        guard isExerciseActive, currentPhase == .tracking else { return }

        let padX: CGFloat = 40
        let padY: CGFloat = 80
        let points: [CGPoint] = [
            CGPoint(x: 0, y: -(view.bounds.height / 2) + padY),
            CGPoint(x: (view.bounds.width / 2) - padX, y: -(view.bounds.height / 2) + padY),
            CGPoint(x: (view.bounds.width / 2) - padX, y: 0),
            CGPoint(x: (view.bounds.width / 2) - padX, y: (view.bounds.height / 2) - padY),
            CGPoint(x: 0, y: (view.bounds.height / 2) - padY),
            CGPoint(x: -(view.bounds.width / 2) + padX, y: (view.bounds.height / 2) - padY),
            CGPoint(x: -(view.bounds.width / 2) + padX, y: 0),
            CGPoint(x: -(view.bounds.width / 2) + padX, y: -(view.bounds.height / 2) + padY)
        ]

        if targetIndex >= points.count {
            handlePhaseTransition()
            return
        }

        self.currentTargetDirectionIndex = targetIndex
        let nextPoint = points[targetIndex]
        let currentDuration = phaseDurations[currentSpeedLevel]

        UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
            self.circleView.transform = CGAffineTransform(translationX: nextPoint.x, y: nextPoint.y)
        } completion: { _ in
            guard self.isExerciseActive, self.currentPhase == .tracking else { return }
            UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
                self.circleView.transform = .identity
            } completion: { _ in
                if self.isExerciseActive && self.currentPhase == .tracking {
                    self.startStarPathAnimation(targetIndex: targetIndex + 1)
                }
            }
        }
    }

    private func handlePhaseTransition() {
        guard isExerciseActive else { return }
        currentSpeedLevel += 1
        Vibrator.playSuccess()

        if currentSpeedLevel >= phaseDurations.count {
            finishExercise()
        } else {
            gazeTimer?.invalidate()
            let message = currentSpeedLevel == phaseDurations.count - 1 ? "Final round! Maximum speed" : "Good, Let's ramp up the speed"
            
            showTransitionMessage(message) { [weak self] in
                guard let self = self, self.isExerciseActive else { return }
                self.startSmoothPursuitPhase()
            }
        }
    }

    private func showTransitionMessage(_ message: String, completion: @escaping () -> Void) {
        currentPhase = .none
        
        UIView.animate(withDuration: 0.4, animations: {
            self.centerMessageLabel.alpha = 0
        }) { _ in
            guard self.isExerciseActive else { return }
            self.centerMessageLabel.text = message
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    guard let self = self, self.isExerciseActive else { return }
                    UIView.animate(withDuration: 0.4, animations: {
                        self.centerMessageLabel.alpha = 0
                    }) { _ in
                        guard self.isExerciseActive else { return }
                        completion()
                    }
                }
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isExerciseActive, let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        let lookAt = faceAnchor.lookAtPoint
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        if currentPhase == .tracking {
            let transform = faceAnchor.transform
            let pitch = abs(asin(min(1.0, max(-1.0, Double(transform.columns.2.y)))))
            let yaw = abs(atan2(Double(transform.columns.2.x), Double(transform.columns.2.z)))
            let totalMovementDegrees = Float((pitch + yaw) * (180.0 / .pi))
            headMovementSamples.append(totalMovementDegrees)
        }
    }

    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        instructionLabel.alpha = 0
        circleView.alpha = 0
        instructionLabel.isHidden = false
        circleView.isHidden = false
        centerMessageLabel.isHidden = false
        
        instructionLabel.numberOfLines = 0
        centerMessageLabel.numberOfLines = 0
    }

    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = showExerciseUI ? 1 : 0
        }) { _ in completion?() }
    }

    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isExerciseActive, self.currentPhase == .tracking else { return }
                self.totalFramesChecked += 1
                let currentDirection = self.getDirectionName(for: self.currentTargetDirectionIndex)
                self.directionChecks[currentDirection, default: 0] += 1
                if self.isLookingAtScreen {
                    if self.instructionLabel.alpha != 0 { UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 } }
                } else {
                    self.totalErrors += 1
                    self.directionFails[currentDirection, default: 0] += 1
                    Vibrator.playError()
                    self.instructionLabel.textColor = .systemRed
                    self.instructionLabel.text = "⚠️ Please keep your eyes on the screen!"
                    self.instructionLabel.alpha = 1
                }
            }
        }
    }

    private func getDirectionName(for index: Int) -> String {
        let names = ["top", "topRight", "right", "bottomRight", "bottom", "bottomLeft", "left", "topLeft"]
        return (index >= 0 && index < names.count) ? names[index] : "center"
    }

    private func finishExercise() {
        currentPhase = .none
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
        let startTime = sessionStartTime ?? Date()
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
        let avgHeadMovement: Float = headMovementSamples.isEmpty ? 0.0 : headMovementSamples.reduce(0, +) / Float(headMovementSamples.count)
        var calculatedDirectionErrors: [String: Double] = [:]
        for (direction, totalChecks) in directionChecks {
            let fails = directionFails[direction] ?? 0
            calculatedDirectionErrors[direction] = totalChecks > 0 ? (Double(fails) / Double(totalChecks)) * 100.0 : 0.0
        }
        let context = SwiftDataManager.shared.context
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(type: "SmoothPursuit", duration: elapsedSeconds, accuracy: accuracy, errors: totalErrors)
        newSession.user = user
        newSession.headMovementDegrees = avgHeadMovement
        newSession.directionErrors = calculatedDirectionErrors
        context.insert(newSession)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            let storyboard = UIStoryboard(name: "Report", bundle: nil)
            guard let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController else { return }
            reportVC.sessionType = "SmoothPursuit"
            reportVC.overallScore = accuracy
            reportVC.totalErrors = self.totalErrors
            reportVC.directionErrors = calculatedDirectionErrors
            
            let nav = UINavigationController(rootViewController: reportVC)
            nav.modalPresentationStyle = .fullScreen
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
            
            if let navStack = self.navigationController {
                navStack.popViewController(animated: false)
            } else {
                self.dismiss(animated: false)
            }
            
            rootVC.present(nav, animated: true)
        }
        do { try context.save(); Vibrator.playSuccess() } catch { print("Error: \(error)") }
    }

    private func startTransitionPhase(message: String, nextPhase: @escaping () -> Void) {
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        centerMessageLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isExerciseActive else { return }
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                guard self.isExerciseActive else { return }
                nextPhase()
            }
        }
    }


}
