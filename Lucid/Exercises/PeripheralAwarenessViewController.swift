////
////  PeripheralAwarenessViewController.swift
////  Lucid
////
////  Created by Abhinav Barthwal on 3/16/26.
////
//
//import UIKit
//import ARKit
//
//private enum PeripheralAwarenessExercisePhase {
//    case none, tracking
//}
//
//@MainActor
//class PeripheralAwarenessViewController: UIViewController, ARSessionDelegate, CAAnimationDelegate ,Sendable{
//
//    @IBOutlet weak var instructionLabel: UILabel!
//    @IBOutlet weak var centerMessageLabel: UILabel!
//    @IBOutlet weak var centerDotView: UIView!
//    @IBOutlet weak var peripheralDotView: UIView!
//    
//    private let arSession = ARSession()
//    private let errorHapticGenerator = UINotificationFeedbackGenerator()
//    private var sessionStartTime: Date?
//    private let successHapticGenerator = UINotificationFeedbackGenerator()
//    private var isExerciseActive = true
//
//    override var prefersStatusBarHidden: Bool { return true }
//    
//    private var currentPhase: PeripheralAwarenessExercisePhase = .none
//    
//    private var gazeTimer: Timer?
//    private var countdownRemaining = 0
//    private var isAnimationPaused = false
//    
//    // Navigation/Skip buttons for instructions
//    private var instructionNextButton: UIButton?
//    private var instructionPrevButton: UIButton?
//    private var currentInstructionIndex = 0
//
//    private let exerciseInstructions: [InstructionStep] = [
//        InstructionStep(message: "Keep your phone at\narm's length", duration: 3.5),
//        InstructionStep(message: "Focus on the yellow dot,\nkeeping the white dot in your vision", duration: 5.0),
//        InstructionStep(message: "Try to keep the white\ndot in check", duration: 4.0)
//    ]
//    
//    private var currentLoopIndex = 0
//    private let totalLoops = 1
//    private var currentPath: UIBezierPath?
//    private var totalFramesChecked = 0
//    private var totalErrors = 0
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupInitialUI()
//        errorHapticGenerator.prepare()
//        successHapticGenerator.prepare()
//        setupInstructionButtons()
//        runInstructionSequence(index: 0)
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        isExerciseActive = true
//        guard ARFaceTrackingConfiguration.isSupported else { return }
//        arSession.delegate = self
//        let config = ARFaceTrackingConfiguration()
//        self.navigationController?.setNavigationBarHidden(false, animated: animated)
//        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        isExerciseActive = false
//        arSession.pause()
//        gazeTimer?.invalidate()
//        peripheralDotView.layer.removeAllAnimations()
//        centerDotView.layer.removeAllAnimations()
//        instructionLabel.layer.removeAllAnimations()
//        centerMessageLabel.layer.removeAllAnimations()
//        currentPhase = .none
//    }
//
//    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        // ARSessionDelegate delegate callback to ensure tracking updates are processed smoothly
//    }
//    
//    private func setupInitialUI() {
//        peripheralDotView.translatesAutoresizingMaskIntoConstraints = true
//        peripheralDotView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//        peripheralDotView.layer.cornerRadius = 10
//        peripheralDotView.backgroundColor = .white
//        
//        centerDotView.layer.cornerRadius = centerDotView.bounds.width / 2
//        centerDotView.backgroundColor = .accent
//        
//        instructionLabel.alpha = 0
//        centerDotView.alpha = 0
//        peripheralDotView.alpha = 0
//        centerMessageLabel.alpha = 1
//        
//        instructionLabel.isHidden = false
//        centerDotView.isHidden = false
//        peripheralDotView.isHidden = false
//        centerMessageLabel.isHidden = false
//        
//        view.layoutIfNeeded()
//        let startY = view.bounds.height - 120
//        peripheralDotView.center = CGPoint(x: view.bounds.midX, y: startY)
//    }
//    
//    private func fadeTransition(showCenterMessage: Bool, showDots: Bool, instructionText: String? = nil, completion: (() -> Void)? = nil) {
//        if let text = instructionText {
//            self.instructionLabel.text = text
//            self.instructionLabel.textColor = .lightGray
//        }
//        
//        UIView.animate(withDuration: 0.5, animations: {
//            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
//            self.instructionLabel.alpha = showDots ? 1 : 0
//            if showDots { self.centerDotView.alpha = 1 }
//        }) { _ in
//            completion?()
//        }
//    }
//    
//    private func runInstructionSequence(index: Int) {
//        guard isExerciseActive, currentPhase == .none else { return }
//        currentInstructionIndex = index
//        let isFirstRun = InstructionTracker.isFirstRun(for: "PeripheralAwareness")
//        
//        if index < exerciseInstructions.count {
//            let step = exerciseInstructions[index]
//            
//            if isFirstRun {
//                instructionNextButton?.isHidden = false
//                let canGoBack = index > 0
//                instructionPrevButton?.isHidden = !canGoBack
//                
//                let isLastStep = (index == exerciseInstructions.count - 1)
//                instructionNextButton?.setTitle(isLastStep ? "Start Exercise" : "Next", for: .normal)
//            } else {
//                instructionNextButton?.isHidden = false
//                instructionPrevButton?.isHidden = true
//                instructionNextButton?.setTitle("Skip", for: .normal)
//            }
//            
//            if index == 0 {
//                UIView.animate(withDuration: 0.4, animations: {
//                    self.centerMessageLabel.alpha = 0
//                    self.instructionLabel.alpha = 0
//                    self.centerDotView.alpha = 0
//                    self.peripheralDotView.alpha = 0
//                }) { _ in
//                    guard self.isExerciseActive, self.currentPhase == .none else { return }
//                    self.centerMessageLabel.text = step.message
//                    UIView.animate(withDuration: 0.4, animations: {
//                        self.centerMessageLabel.alpha = 1
//                    }) { _ in
//                        self.autoAdvanceIfRequired(index: index, duration: step.duration)
//                    }
//                }
//            } else if index == 1 {
//                UIView.animate(withDuration: 0.4, animations: {
//                    self.centerMessageLabel.alpha = 0
//                    self.instructionLabel.alpha = 0
//                    self.peripheralDotView.alpha = 0
//                }) { _ in
//                    guard self.isExerciseActive, self.currentPhase == .none else { return }
//                    self.instructionLabel.text = step.message
//                    self.instructionLabel.textColor = .lightGray
//                    UIView.animate(withDuration: 0.4, animations: {
//                        self.instructionLabel.alpha = 1
//                        self.centerDotView.alpha = 1
//                    }) { _ in
//                        self.autoAdvanceIfRequired(index: index, duration: step.duration)
//                    }
//                }
//            } else if index == 2 {
//                UIView.animate(withDuration: 0.4, animations: {
//                    self.instructionLabel.alpha = 0
//                }) { _ in
//                    guard self.isExerciseActive, self.currentPhase == .none else { return }
//                    self.instructionLabel.text = step.message
//                    UIView.animate(withDuration: 0.4, animations: {
//                        self.instructionLabel.alpha = 1
//                        self.peripheralDotView.alpha = 1
//                    }) { _ in
//                        self.autoAdvanceIfRequired(index: index, duration: step.duration)
//                    }
//                }
//            }
//        } else {
//            finishInstructionsAndStartExercise()
//        }
//    }
//    
//    private func autoAdvanceIfRequired(index: Int, duration: TimeInterval) {
//        if !InstructionTracker.isFirstRun(for: "PeripheralAwareness") {
//            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
//                guard let self = self, self.isExerciseActive, self.currentPhase == .none, self.currentInstructionIndex == index else { return }
//                self.runInstructionSequence(index: index + 1)
//            }
//        }
//    }
//
//    private func setupInstructionButtons() {
//        let isFirstRun = InstructionTracker.isFirstRun(for: "PeripheralAwareness")
//        
//        let nextBtn = UIButton(type: .system)
//        nextBtn.translatesAutoresizingMaskIntoConstraints = false
//        nextBtn.layer.cornerRadius = 14
//        nextBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
//        nextBtn.setTitleColor(.white, for: .normal)
//        nextBtn.backgroundColor = UIColor(named: "AccentColor") ?? .systemOrange
//        view.addSubview(nextBtn)
//        self.instructionNextButton = nextBtn
//        nextBtn.addTarget(self, action: #selector(instructionNextTapped), for: .touchUpInside)
//        
//        if isFirstRun {
//            nextBtn.setTitle("Next", for: .normal)
//            
//            let prevBtn = UIButton(type: .system)
//            prevBtn.translatesAutoresizingMaskIntoConstraints = false
//            prevBtn.layer.cornerRadius = 14
//            prevBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
//            prevBtn.setTitleColor(.white, for: .normal)
//            prevBtn.backgroundColor = .clear
//            prevBtn.layer.borderWidth = 1
//            prevBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
//            prevBtn.setTitle("Previous", for: .normal)
//            view.addSubview(prevBtn)
//            self.instructionPrevButton = prevBtn
//            prevBtn.addTarget(self, action: #selector(instructionPrevTapped), for: .touchUpInside)
//            
//            NSLayoutConstraint.activate([
//                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
//                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
//                nextBtn.bottomAnchor.constraint(equalTo: prevBtn.topAnchor, constant: -12),
//                nextBtn.heightAnchor.constraint(equalToConstant: 50),
//                
//                prevBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
//                prevBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
//                prevBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//                prevBtn.heightAnchor.constraint(equalToConstant: 50)
//            ])
//            
//            prevBtn.isHidden = true // Hidden initially for step 0
//        } else {
//            nextBtn.setTitle("Skip", for: .normal)
//            
//            NSLayoutConstraint.activate([
//                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
//                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
//                nextBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//                nextBtn.heightAnchor.constraint(equalToConstant: 50)
//            ])
//        }
//    }
//    
//    @objc private func instructionNextTapped() {
//        if InstructionTracker.isFirstRun(for: "PeripheralAwareness") {
//            runInstructionSequence(index: currentInstructionIndex + 1)
//        } else {
//            finishInstructionsAndStartExercise()
//        }
//    }
//    
//    @objc private func instructionPrevTapped() {
//        if InstructionTracker.isFirstRun(for: "PeripheralAwareness") && currentInstructionIndex > 0 {
//            runInstructionSequence(index: currentInstructionIndex - 1)
//        }
//    }
//    
//    private func finishInstructionsAndStartExercise() {
//        InstructionTracker.markAsCompleted(for: "PeripheralAwareness")
//        currentInstructionIndex = 999
//        
//        UIView.animate(withDuration: 0.3, animations: {
//            self.instructionNextButton?.alpha = 0
//            self.instructionPrevButton?.alpha = 0
//        }) { _ in
//            self.instructionNextButton?.removeFromSuperview()
//            self.instructionPrevButton?.removeFromSuperview()
//        }
//        
//        runStartCountdown { [weak self] in
//            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
//            self.startPeripheralPhase()
//        }
//    }
//
//    private func runStartCountdown(completion: @escaping () -> Void) {
//        UIView.animate(withDuration: 0.3) {
//            self.instructionLabel.alpha = 0
//            self.centerDotView.alpha = 0
//            self.peripheralDotView.alpha = 0
//        }
//        
//        UIView.animate(withDuration: 0.2, animations: {
//            self.centerMessageLabel.alpha = 0
//        }) { _ in
//            self.centerMessageLabel.text = "3"
//            UIView.animate(withDuration: 0.3, animations: {
//                self.centerMessageLabel.alpha = 1
//            }) { _ in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//                    guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
//                    UIView.animate(withDuration: 0.2, animations: {
//                        self.centerMessageLabel.alpha = 0
//                    }) { _ in
//                        self.centerMessageLabel.text = "2"
//                        UIView.animate(withDuration: 0.3, animations: {
//                            self.centerMessageLabel.alpha = 1
//                        }) { _ in
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//                                guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
//                                UIView.animate(withDuration: 0.2, animations: {
//                                    self.centerMessageLabel.alpha = 0
//                                }) { _ in
//                                    self.centerMessageLabel.text = "1"
//                                    UIView.animate(withDuration: 0.3, animations: {
//                                        self.centerMessageLabel.alpha = 1
//                                    }) { _ in
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//                                            guard let self = self, self.isExerciseActive, self.currentPhase == .none else { return }
//                                            UIView.animate(withDuration: 0.3, animations: {
//                                                self.centerMessageLabel.alpha = 0
//                                            }) { _ in
//                                                self.centerMessageLabel.text = ""
//                                                self.centerDotView.alpha = 1
//                                                self.peripheralDotView.alpha = 1
//                                                completion()
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private func startPeripheralPhase() {
//        currentPhase = .tracking
//        currentLoopIndex = 0
//        isAnimationPaused = false
//        self.sessionStartTime = Date()
//        resetLayerSpeed(layer: peripheralDotView.layer)
//        currentPath = createPeripheralTrack()
//        
//        self.startGazeMonitor()
//        self.startOrbitAnimation()
//    }
//    
//    private func createPeripheralTrack() -> UIBezierPath {
//        view.layoutIfNeeded()
//        let path = UIBezierPath()
//        let padX: CGFloat = 20
//        let padY: CGFloat = 140
//        let minX = padX
//        let maxX = view.bounds.width - padX
//        let minY = padY
//        let maxY = view.bounds.height - padY
//        let midX = view.bounds.midX
//        let cornerRadius: CGFloat = 40
//        
//        path.move(to: CGPoint(x: midX, y: maxY))
//        path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
//        path.addQuadCurve(to: CGPoint(x: minX, y: maxY - cornerRadius), controlPoint: CGPoint(x: minX, y: maxY))
//        path.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
//        path.addQuadCurve(to: CGPoint(x: minX + cornerRadius, y: minY), controlPoint: CGPoint(x: minX, y: minY))
//        path.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
//        path.addQuadCurve(to: CGPoint(x: maxX, y: minY + cornerRadius), controlPoint: CGPoint(x: maxX, y: minY))
//        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
//        path.addQuadCurve(to: CGPoint(x: maxX - cornerRadius, y: maxY), controlPoint: CGPoint(x: maxX, y: maxY))
//        path.addLine(to: CGPoint(x: midX, y: maxY))
//        return path
//    }
//    
//    private func startOrbitAnimation() {
//        guard isExerciseActive, currentPhase == .tracking, let path = currentPath else { return }
//        
//        if currentLoopIndex >= totalLoops {
//            finishExercise()
//            return
//        }
//        
//        let loopDurations: [CFTimeInterval] = [12.0 , 10.5 , 9.0 , 7.5 , 6.0]
//        let currentDuration = loopDurations[currentLoopIndex]
//        
//        let animation = CAKeyframeAnimation(keyPath: "position")
//        animation.path = path.cgPath
//        animation.duration = currentDuration
//        animation.repeatCount = 1
//        animation.calculationMode = .paced
//        animation.fillMode = .forwards
//        animation.isRemovedOnCompletion = false
//        animation.delegate = self
//        
//        peripheralDotView.layer.removeAllAnimations()
//        peripheralDotView.layer.add(animation, forKey: "orbitAnimation_\(currentLoopIndex)")
//    }
//    
//    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
//        if isExerciseActive && flag && currentPhase == .tracking {
//            currentLoopIndex += 1
//            resetLayerSpeed(layer: peripheralDotView.layer)
//            isAnimationPaused = false
//            startOrbitAnimation()
//        }
//    }
//    
//    private func startGazeMonitor() {
//        gazeTimer?.invalidate()
//        gazeTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
//            guard let self = self, self.isExerciseActive, self.currentPhase == .tracking else { return }
//            
//            self.totalFramesChecked += 1
//            
//            var isLookingAtCenter = false
//            if let frame = self.arSession.currentFrame,
//               let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first,
//               faceAnchor.isTracked {
//                let lookAt = faceAnchor.lookAtPoint
//                isLookingAtCenter = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
//            }
//            
//            if isLookingAtCenter {
//                if self.isAnimationPaused {
//                    self.resumeLayer(layer: self.peripheralDotView.layer)
//                    self.isAnimationPaused = false
//                }
//                if self.instructionLabel.alpha != 0 {
//                    UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
//                }
//            } else {
//                self.totalErrors += 1
//                if !self.isAnimationPaused {
//                    self.pauseLayer(layer: self.peripheralDotView.layer)
//                    self.isAnimationPaused = true
//                    self.errorHapticGenerator.notificationOccurred(.error)
//                    self.instructionLabel.layer.removeAllAnimations()
//                    self.instructionLabel.textColor = .systemRed
//                    self.instructionLabel.text = "⚠️ Keep your eyes strictly on the yellow dot!"
//                    self.instructionLabel.alpha = 1
//                }
//            }
//        }
//        RunLoop.main.add(self.gazeTimer!, forMode: .common)
//    }
//    
//    private func pauseLayer(layer: CALayer) {
//        let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
//        layer.speed = 0.0
//        layer.timeOffset = pausedTime
//    }
//
//    private func resumeLayer(layer: CALayer) {
//        let pausedTime: CFTimeInterval = layer.timeOffset
//        layer.speed = 1.0
//        layer.timeOffset = 0.0
//        layer.beginTime = 0.0
//        let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
//        layer.beginTime = timeSincePause
//    }
//    
//    private func resetLayerSpeed(layer: CALayer) {
//        layer.speed = 1.0
//        layer.timeOffset = 0.0
//        layer.beginTime = 0.0
//    }
//    
//    private func finishExercise() {
//        currentPhase = .none
//        gazeTimer?.invalidate()
//        peripheralDotView.layer.removeAllAnimations()
//        
//        let startTime = sessionStartTime ?? Date()
//        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
//        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
//        
//        let context = SwiftDataManager.shared.context
//        let user = SwiftDataManager.shared.getOrCreateUser()
//        let newSession = ExerciseSession(
//            type: "PeripheralAwareness",
//            duration: elapsedSeconds,
//            accuracy: accuracy,
//            errors: totalErrors
//        )
//        newSession.user = user
//        context.insert(newSession)
//        
//        do {
//            try context.save()
//            successHapticGenerator.notificationOccurred(.success)
//        } catch {
//            print("❌ Peripheral Awareness Save failed: \(error)")
//        }
//        
//        UIView.animate(withDuration: 0.5) {
//            self.centerDotView.alpha = 0
//            self.peripheralDotView.alpha = 0
//        }
//        
//        let messages = [
//            "Fantastic job!",
//            "Great work!",
//            "Awesome focus!",
//            "Excellent effort!",
//            "Superb session!",
//            "Nicely done!",
//            "Brilliant job!"
//        ]
//        centerMessageLabel.font = .systemFont(ofSize: 36, weight: .bold)
//        centerMessageLabel.text = messages.randomElement() ?? "Nicely done !"
//        
//        UIView.animate(withDuration: 0.5) {
//            self.centerMessageLabel.alpha = 1
//            self.instructionLabel.alpha = 0
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
//            guard let self = self, self.isExerciseActive else { return }
//            self.isExerciseActive = false
//            if let nav = self.navigationController {
//                nav.popViewController(animated: true)
//            } else {
//                self.dismiss(animated: true)
//            }
//        }
//    }
//
//
//}
