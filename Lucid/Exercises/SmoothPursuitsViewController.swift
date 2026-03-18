////
////  SmoothPursuitsViewController.swift
////  Lucid
////
////  Created by Abhinav Barthwal on 3/16/26.
////
//
//import UIKit
//import ARKit
//
//class SmoothPursuitsViewController: UIViewController, ARSessionDelegate {
//    
//    @IBOutlet weak var instructionLabel: UILabel!
//    @IBOutlet weak var centerMessageLabel: UILabel!
//    @IBOutlet weak var circleView: UIView!
//
//        // AR session to run head/eye tracking.
//        private let arSession = ARSession()
//        private var isLookingAtScreen = false
//        
//        // Haptic generators
//        private let errorHapticGenerator = UINotificationFeedbackGenerator()
//        private let successHapticGenerator = UINotificationFeedbackGenerator()
//        
//        // --- TIME TRACKING VARIABLES ---
//        private var sessionStartTime: Date?
//        
//        // Categorizes the phases of the smooth pursuit exercise.
//        private enum ExercisePhase {
//            case none, tracking
//        }
//        private var currentPhase: ExercisePhase = .none
//        
//        // Timer to monitor the user's gaze continuously
//        private var gazeTimer: Timer?
//        private var countdownRemaining = 0
//        
//        override func viewDidLoad() {
//            super.viewDidLoad()
//            setupInitialUI()
//            arSession.delegate = self
//            
//            errorHapticGenerator.prepare()
//            successHapticGenerator.prepare()
//            startInitialCountdown()
//        }
//        
//        override func viewWillAppear(_ animated: Bool) {
//            super.viewWillAppear(animated)
//            guard ARFaceTrackingConfiguration.isSupported else { return }
//            
//            let config = ARFaceTrackingConfiguration()
//            arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
//        }
//        
//        override func viewWillDisappear(_ animated: Bool) {
//            super.viewWillDisappear(animated)
//            arSession.pause()
//            gazeTimer?.invalidate()
//            circleView.layer.removeAllAnimations()
//        }
//        
//        // MARK: - ARSessionDelegate
//        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
//                isLookingAtScreen = false
//                return
//            }
//            
//            let lookAt = faceAnchor.lookAtPoint
//            // If the X and Y coordinates of the gaze are within 0.2 units they are looking at the screen.
//            isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
//        }
//        
//        // MARK: - UI Setup
//        private func setupInitialUI() {
//            circleView.layer.cornerRadius = circleView.bounds.width / 2
//            instructionLabel.alpha = 0
//            circleView.alpha = 0
//            
//            instructionLabel.isHidden = false
//            circleView.isHidden = false
//            
//            centerMessageLabel.alpha = 1
//            centerMessageLabel.isHidden = false
//        }
//        
//        private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
//            UIView.animate(withDuration: 0.5, animations: {
//                self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
//                self.instructionLabel.alpha = showExerciseUI ? 1 : 0
//                self.circleView.alpha = showExerciseUI ? 1 : 0
//            }) { _ in
//                completion?()
//            }
//        }
//        
//        // MARK: - Sequences
//        private func startInitialCountdown() {
//            currentPhase = .none
//            countdownRemaining = 5
//            centerMessageLabel.text = "\(countdownRemaining)"
//            
//            gazeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
//                guard let self = self else { return }
//                self.countdownRemaining -= 1
//                
//                if self.countdownRemaining > 0 {
//                    self.centerMessageLabel.text = "\(self.countdownRemaining)"
//                } else {
//                    timer.invalidate()
//                    self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
//                        self.showPreparationMessage("Follow the dot closely\nwith your eyes only") {
//                            self.startSmoothPursuitPhase()
//                        }
//                    }
//                }
//            }
//        }
//        
//        private func showPreparationMessage(_ message: String, completion: @escaping () -> Void) {
//            currentPhase = .none
//            circleView.layer.removeAllAnimations()
//            centerMessageLabel.text = message
//            
//            fadeTransition(showCenterMessage: true, showExerciseUI: false)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
//                    completion()
//                }
//            }
//        }
//        
//        private func startSmoothPursuitPhase() {
//            currentPhase = .tracking
//            
//            instructionLabel.textColor = .lightGray
//            instructionLabel.text = "Keep your head still and follow the dot"
//            instructionLabel.alpha = 1
//            
//            circleView.transform = .identity
//            
//            fadeTransition(showCenterMessage: false, showExerciseUI: true) {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                    guard self.currentPhase == .tracking else { return }
//                    
//                    // START THE CLOCK: The user begins moving their eyes here
//                    self.sessionStartTime = Date()
//                    
//                    UIView.animate(withDuration: 0.5) {
//                        self.instructionLabel.alpha = 0
//                    } completion: { _ in
//                        self.startGazeMonitor()
//                        self.startStarPathAnimation(targetIndex: 0)
//                    }
//                }
//            }
//        }
//        
//        // MARK: - Core Logic & Animation
//        private func startStarPathAnimation(targetIndex: Int) {
//            guard currentPhase == .tracking else { return }
//            
//            let padX: CGFloat = 40
//            let padY: CGFloat = 80
//            
//            let minX = -(view.bounds.width / 2) + padX
//            let maxX = (view.bounds.width / 2) - padX
//            let minY = -(view.bounds.height / 2) + padY
//            let maxY = (view.bounds.height / 2) - padY
//            let midX: CGFloat = 0
//            let midY: CGFloat = 0
//            
//            let points: [CGPoint] = [
//                CGPoint(x: midX, y: minY), // Top-Center
//                CGPoint(x: maxX, y: minY), // Top-Right
//                CGPoint(x: maxX, y: midY), // Right-Center
//                CGPoint(x: maxX, y: maxY), // Bottom-Right
//                CGPoint(x: midX, y: maxY), // Bottom-Center
//                CGPoint(x: minX, y: maxY), // Bottom-Left
//                CGPoint(x: minX, y: midY), // Left-Center
//                CGPoint(x: minX, y: minY)  // Top-Left
//            ]
//            
//            if targetIndex >= points.count {
//                finishExercise()
//                return
//            }
//            
//            let nextPoint = points[targetIndex]
//            let maxDuration: Double = 1.8
//            let minDuration: Double = 0.75
//            let step = (maxDuration - minDuration) / Double(points.count - 1)
//            let currentDuration = maxDuration - (Double(targetIndex) * step)
//            
//            UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
//                self.circleView.transform = CGAffineTransform(translationX: nextPoint.x, y: nextPoint.y)
//            } completion: { _ in
//                guard self.currentPhase == .tracking else { return }
//                
//                UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
//                    self.circleView.transform = .identity
//                } completion: { _ in
//                    if self.currentPhase == .tracking {
//                        self.startStarPathAnimation(targetIndex: targetIndex + 1)
//                    }
//                }
//            }
//        }
//        
//        private func startGazeMonitor() {
//            gazeTimer?.invalidate()
//            gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
//                guard let self = self, self.currentPhase == .tracking else { return }
//                
//                if self.isLookingAtScreen {
//                    if self.instructionLabel.alpha != 0 {
//                        UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
//                    }
//                } else {
//                    self.errorHapticGenerator.notificationOccurred(.error)
//                    self.instructionLabel.layer.removeAllAnimations()
//                    self.instructionLabel.textColor = .systemRed
//                    self.instructionLabel.text = "⚠️ Please keep your eyes on the screen!"
//                    self.instructionLabel.alpha = 1
//                }
//            }
//        }
//        
//        // MARK: - Completion
//        private func finishExercise() {
//            // --- STOP THE CLOCK AND SAVE ---
//            if let startTime = sessionStartTime {
//                let elapsedTime = Date().timeIntervalSince(startTime)
//                let elapsedSeconds = Int(elapsedTime)
//                ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
//                
//                successHapticGenerator.notificationOccurred(.success)
//            }
//            
//            startTransitionPhase(message: "Nicely Done!") {
//                print("Exercise Completed - Transitioning to summary")
//                // Dismiss or Segue here
//            }
//        }
//        
//        private func startTransitionPhase(message: String, nextPhase: @escaping () -> Void) {
//            currentPhase = .none
//            gazeTimer?.invalidate()
//            circleView.layer.removeAllAnimations()
//            centerMessageLabel.text = message
//            
//            fadeTransition(showCenterMessage: true, showExerciseUI: false)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
//                    nextPhase()
//                }
//            }
//        }
//    }



//
//  SmoothPursuitsViewController.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/16/26.
//

import UIKit
import ARKit
import SwiftData

class SmoothPursuitsViewController: UIViewController, ARSessionDelegate {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    // MARK: - Outlets
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var centerMessageLabel: UILabel!
    @IBOutlet private weak var circleView: UIView!
>>>>>>> Stashed changes

    // AR session to run head/eye tracking.
    private let arSession = ARSession()
    private var isLookingAtScreen = false
<<<<<<< Updated upstream
    
    // Haptic generators
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private let successHapticGenerator = UINotificationFeedbackGenerator()
    
    // --- TIME & PHASE TRACKING VARIABLES ---
=======

    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    private let successHapticGenerator = UINotificationFeedbackGenerator()

<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    private var sessionStartTime: Date?
    
    private enum ExercisePhase {
        case none, tracking
    }
    private var currentPhase: ExercisePhase = .none
    
    // Timer to monitor the user's gaze continuously
    private var gazeTimer: Timer?
    private var countdownRemaining = 0
<<<<<<< Updated upstream
    
    // --- SWIFTDATA TRACKING VARIABLES ---
    var modelContext: ModelContext?
    
=======

    var modelContext: ModelContext?

<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    private var totalFramesChecked = 0
    private var totalErrors = 0
    private var currentTargetDirectionIndex = 0
    
    // Track checks and failures per direction (Top, TopRight, etc.)
    private var directionChecks: [String: Int] = [:]
    private var directionFails: [String: Int] = [:]
    
    // Track head movement degrees to see if they are cheating
    private var headMovementSamples: [Float] = []
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    // MARK: - Lifecycle
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        arSession.delegate = self
        
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare()
        startInitialCountdown()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSession.pause()
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    // MARK: - ARSessionDelegate
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        
        let lookAt = faceAnchor.lookAtPoint
        // If the X and Y coordinates of the gaze are within 0.2 units they are looking at the screen.
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        
        // Track Head Movement to ensure they are using their eyes, not their neck
        if currentPhase == .tracking {
            let transform = faceAnchor.transform
            // Approximate Pitch & Yaw magnitude in degrees
            let pitch = abs(asin(min(1.0, max(-1.0, Double(transform.columns.2.y)))))
            let yaw = abs(atan2(Double(transform.columns.2.x), Double(transform.columns.2.z)))
            let totalMovementDegrees = Float((pitch + yaw) * (180.0 / .pi))
            headMovementSamples.append(totalMovementDegrees)
        }
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    // MARK: - UI Setup
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        instructionLabel.alpha = 0
        circleView.alpha = 0
        
        instructionLabel.isHidden = false
        circleView.isHidden = false
        
        centerMessageLabel.alpha = 1
        centerMessageLabel.isHidden = false
    }
    
    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = showExerciseUI ? 1 : 0
        }) { _ in
            completion?()
        }
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    // MARK: - Sequences
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
    private func startInitialCountdown() {
        currentPhase = .none
        countdownRemaining = 5
        centerMessageLabel.text = "\(countdownRemaining)"
        
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.countdownRemaining -= 1
            
            if self.countdownRemaining > 0 {
                self.centerMessageLabel.text = "\(self.countdownRemaining)"
            } else {
                timer.invalidate()
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    self.showPreparationMessage("Follow the dot closely\nwith your eyes only") {
                        self.startSmoothPursuitPhase()
                    }
                }
            }
        }
    }
    
    private func showPreparationMessage(_ message: String, completion: @escaping () -> Void) {
        currentPhase = .none
        circleView.layer.removeAllAnimations()
        centerMessageLabel.text = message
        
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                completion()
            }
        }
    }
    
    private func startSmoothPursuitPhase() {
        currentPhase = .tracking
        
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Keep your head still and follow the dot"
        instructionLabel.alpha = 1
        
        circleView.transform = .identity
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                guard self.currentPhase == .tracking else { return }
                
                // START THE CLOCK: The user begins moving their eyes here
                self.sessionStartTime = Date()
                
                UIView.animate(withDuration: 0.5) {
                    self.instructionLabel.alpha = 0
                } completion: { _ in
                    self.startGazeMonitor()
                    self.startStarPathAnimation(targetIndex: 0)
                }
            }
        }
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    
    // MARK: - Core Logic & Animation
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
=======

>>>>>>> Stashed changes
    private func startStarPathAnimation(targetIndex: Int) {
        guard currentPhase == .tracking else { return }
        
        let padX: CGFloat = 40
        let padY: CGFloat = 80
        
        let minX = -(view.bounds.width / 2) + padX
        let maxX = (view.bounds.width / 2) - padX
        let minY = -(view.bounds.height / 2) + padY
        let maxY = (view.bounds.height / 2) - padY
        let midX: CGFloat = 0
        let midY: CGFloat = 0
        
        let points: [CGPoint] = [
            CGPoint(x: midX, y: minY), // 0: Top-Center
            CGPoint(x: maxX, y: minY), // 1: Top-Right
            CGPoint(x: maxX, y: midY), // 2: Right-Center
            CGPoint(x: maxX, y: maxY), // 3: Bottom-Right
            CGPoint(x: midX, y: maxY), // 4: Bottom-Center
            CGPoint(x: minX, y: maxY), // 5: Bottom-Left
            CGPoint(x: minX, y: midY), // 6: Left-Center
            CGPoint(x: minX, y: minY)  // 7: Top-Left
        ]
        
        if targetIndex >= points.count {
            finishExercise()
            return
        }
        
        // Update SwiftData Tracking Index
        self.currentTargetDirectionIndex = targetIndex
        
        let nextPoint = points[targetIndex]
        let maxDuration: Double = 1.8
        let minDuration: Double = 0.75
        let step = (maxDuration - minDuration) / Double(points.count - 1)
        let currentDuration = maxDuration - (Double(targetIndex) * step)
        
        UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
            self.circleView.transform = CGAffineTransform(translationX: nextPoint.x, y: nextPoint.y)
        } completion: { _ in
            guard self.currentPhase == .tracking else { return }
            
            UIView.animate(withDuration: currentDuration, delay: 0, options: [.curveEaseInOut]) {
                self.circleView.transform = .identity
            } completion: { _ in
                if self.currentPhase == .tracking {
                    self.startStarPathAnimation(targetIndex: targetIndex + 1)
                }
            }
        }
    }
    
    private func startGazeMonitor() {
        gazeTimer?.invalidate()
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.currentPhase == .tracking else { return }
            
            // Track total frames checked
            self.totalFramesChecked += 1
            
            // Map the current target index to a String direction
            let currentDirection = self.getDirectionName(for: self.currentTargetDirectionIndex)
            self.directionChecks[currentDirection, default: 0] += 1
            
            if self.isLookingAtScreen {
                if self.instructionLabel.alpha != 0 {
                    UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
                }
            } else {
                // LOG THE ERROR FOR THE SPECIFIC DIRECTION
                self.totalErrors += 1
                self.directionFails[currentDirection, default: 0] += 1
                
                self.errorHapticGenerator.notificationOccurred(.error)
                self.instructionLabel.layer.removeAllAnimations()
                self.instructionLabel.textColor = .systemRed
                self.instructionLabel.text = "⚠️ Please keep your eyes on the screen!"
                self.instructionLabel.alpha = 1
            }
        }
    }
    
    private func getDirectionName(for index: Int) -> String {
        let names = ["top", "topRight", "right", "bottomRight", "bottom", "bottomLeft", "left", "topLeft"]
        guard index >= 0 && index < names.count else { return "center" }
        return names[index]
    }
<<<<<<< Updated upstream
    
    // MARK: - SwiftData Integration & Completion
=======


<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    private func finishExercise() {
        currentPhase = .none
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        
        
        // --- CALCULATION PHASE ---
        let startTime = sessionStartTime ?? Date()
        let endTime = Date()
        let elapsedSeconds = Int(endTime.timeIntervalSince(startTime))
        
        // Calculate Global Accuracy (0 to 100)
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100) : 0
        
        // Calculate Average Head Movement
        let avgHeadMovement = headMovementSamples.isEmpty ? 0.0 : headMovementSamples.reduce(0, +) / Float(headMovementSamples.count)
        
        // Calculate Directional Error Rates (Percentage of failure per direction)
        var calculatedDirectionErrors: [String: Double] = [:]
        for (direction, totalChecks) in directionChecks {
            let fails = directionFails[direction] ?? 0
            let errorPercentage = totalChecks > 0 ? (Double(fails) / Double(totalChecks)) * 100 : 0.0
            calculatedDirectionErrors[direction] = errorPercentage
        }
        
        // --- SWIFTDATA OBJECT CREATION ---
        let newSession = ExerciseSession(
            type: "SmoothPursuit",
            duration: elapsedSeconds,
            accuracy: accuracy,
            errors: totalErrors
        )
                        
                        ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
        newSession.startingTime = startTime
        newSession.endingTime = endTime
        newSession.headMovementDegrees = avgHeadMovement
        newSession.directionErrors = calculatedDirectionErrors
        
        successHapticGenerator.notificationOccurred(.success)
        
        // --- CONSOLE VERIFICATION & DB SAVE ---
        print("""
            \n🔥 --- NEW SMOOTH PURSUIT SESSION SAVED --- 🔥
            Type: \(newSession.type)
            Duration: \(newSession.durationSeconds) seconds
            Accuracy Score: \(newSession.accuracyScore ?? 0)%
            Total Errors: \(newSession.errorCount ?? 0)
            Average Head Movement: \(newSession.headMovementDegrees ?? 0) degrees
            Direction Errors Map: \(newSession.directionErrors ?? [:])
            🔥 ---------------------------------------- 🔥\n
            """)
        
        if let context = modelContext {
            context.insert(newSession)
            
            do {
                try context.save()
                print("\n✅ SMOOTH PURSUITS DATA SAVED SUCCESSFULLY ✅")
                
                // Fetch Verification
                let fetchDescriptor = FetchDescriptor<ExerciseSession>()
                let allSessions = try context.fetch(fetchDescriptor)
                
                print("🚨 DB VERIFICATION: There are now \(allSessions.count) total ExerciseSessions.")
                if let saved = allSessions.last {
                    print("🚨 CONFIRMED IN DB -> ID: \(saved.id) | Type: \(saved.type)\n")
                }
                
            } catch {
                print("\n❌ SWIFTDATA SAVE FAILED: \(error) ❌\n")
            }
        } else {
            print("\n☠️ FATAL ERROR: modelContext IS NIL! ☠️")
            print("Make sure to pass the context into SmoothPursuitsViewController.\n")
        }
        
        startTransitionPhase(message: "Nicely Done!") {
            print("Exercise Completed - Transitioning to summary")
            self.dismiss(animated: true)
        }
    }
    
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

        // 1. Calculations
        let startTime = sessionStartTime ?? Date() 
        let endTime = Date()
        let elapsedSeconds = Int(endTime.timeIntervalSince(startTime))
        
        let accuracy = totalFramesChecked > 0 ? Int((Double(totalFramesChecked - totalErrors) / Double(totalFramesChecked)) * 100.0) : 0
        let avgHeadMovement: Float = headMovementSamples.isEmpty ? 0.0 : headMovementSamples.reduce(0, +) / Float(headMovementSamples.count)

        var calculatedDirectionErrors: [String: Double] = [:]
        for (direction, totalChecks) in directionChecks {
            let fails = directionFails[direction] ?? 0
            let errorPercentage = totalChecks > 0 ? (Double(fails) / Double(totalChecks)) * 100.0 : 0.0
            calculatedDirectionErrors[direction] = errorPercentage
        }

        // 2. Save Data using Singleton Context
        let context = SwiftDataManager.shared.context
        let newSession = ExerciseSession(type: "SmoothPursuit", duration: elapsedSeconds, accuracy: accuracy, errors: totalErrors)
        newSession.headMovementDegrees = avgHeadMovement
        newSession.directionErrors = calculatedDirectionErrors
        context.insert(newSession)
        
        ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
        
        try? context.save()

        // 3. Navigate to Report
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Report", bundle: nil)
            guard let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController else { return }

            reportVC.sessionType = "SmoothPursuit"
            reportVC.overallScore = accuracy
            reportVC.totalErrors = self.totalErrors
            reportVC.avgHeadMovement = avgHeadMovement
            reportVC.directionErrors = calculatedDirectionErrors

            let nav = UINavigationController(rootViewController: reportVC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }

<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    private func startTransitionPhase(message: String, nextPhase: @escaping () -> Void) {
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        centerMessageLabel.text = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                nextPhase()
            }
        }
    }
}
