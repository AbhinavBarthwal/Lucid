//
//  SaccadicJumps.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/18/26.
//


import UIKit
import ARKit

class SaccadicJumps: UIViewController, ARSessionDelegate {
    
    
    // MARK: - Outlets
    @IBOutlet weak var dotTarget: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    
    @IBOutlet weak var centerXConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerYConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    enum Position: CaseIterable {
        case center, topLeft, topRight, bottomLeft, bottomRight     //position where the dot will appear
    }
    
    var lastPosition: Position = .center
    var dotCount = 0
    var successfulFollows = 0
    var hasLookedAtCurrentDot = false
    let faceTrackingSession = ARSession()
    var currentGazePoint = CGPoint.zero
    
    var exerciseTimer: Timer?   //exercise time 30 sec
    var sessionTimer: Timer?       // entire duration
    var countdownTimer: Timer?      // 5 second countdown
    var countdownTime = 5

    // Hide the Status Bar for a clean Full Screen
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareInitialState()
        setupEyeTracking()
        startCountdownPhase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func prepareInitialState() {        //setup initial
        dotTarget.layer.cornerRadius = dotTarget.frame.size.width / 2
        dotTarget.clipsToBounds = true
        [dotTarget, countdownLabel, instructionLabel, scoreLabel].forEach { $0?.alpha = 0 }
        scoreLabel.text = "Score: 0"
    }

    func setupEyeTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        faceTrackingSession.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        faceTrackingSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        let rawLookAt = faceAnchor.lookAtPoint
        
        DispatchQueue.main.async {
            self.currentGazePoint = self.calculateHighSensitivityPoint(rawLookAt)
            if !self.hasLookedAtCurrentDot && self.dotTarget.alpha == 1 {
                self.detectMagneticFocus()
            }
        }
    }
    
    func calculateHighSensitivityPoint(_ lookAt: simd_float3) -> CGPoint {
        guard let windowScene = view.window?.windowScene else { return .zero }
        let screen = windowScene.screen.bounds
        
        let sensitivity: CGFloat = 8.0
        let x = (screen.width / 2) + (CGFloat(lookAt.x) * screen.width * sensitivity)
        
        // Lowered yOffset for camera location
        let yOffset = screen.height * 0.08
        let y = (screen.height / 2) - (CGFloat(lookAt.y) * screen.height * sensitivity) + yOffset
        
        return CGPoint(x: x, y: y)
    }

    func detectMagneticFocus() {
        let targetCenter = dotTarget.center
        let distance = sqrt(pow(targetCenter.x - currentGazePoint.x, 2) + pow(targetCenter.y - currentGazePoint.y, 2))
        
        // Threshold 180 for "around the dot" detection
        if distance < 180 {
            hasLookedAtCurrentDot = true
            successfulFollows += 1
            HapticManager.shared.triggerTick() //   Coorect movement haptic
            
            scoreLabel.text = "Score: \(successfulFollows)"
            UIView.animate(withDuration: 0.1) {
                self.dotTarget.backgroundColor = .systemGreen
                self.dotTarget.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
        }
    }


    func performSaccadicJump() {
        if !hasLookedAtCurrentDot && dotCount > 0 {
            HapticManager.shared.triggerFailure() // Missed dot buzz
        }
        
        hasLookedAtCurrentDot = false
        dotTarget.backgroundColor = .systemOrange
        dotTarget.transform = .identity
        
        /* BREATHING ROOM: Using view.bounds with a 60pt margin
        This spreads the dots across the whole screen but keeps them
        away from the very edge for better gaze accuracy.*/
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        let horizontalPadding: CGFloat = 60
        let verticalPadding: CGFloat = 100 // padding for top/bottom
        
        let maxX = (screenWidth / 2) - horizontalPadding
        let maxY = (screenHeight / 2) - verticalPadding
        
        let available = Position.allCases.filter { $0 != lastPosition }
        if let next = available.randomElement() {
            switch next {
            case .center:
                centerXConstraint.constant = 0
                centerYConstraint.constant = 0
            case .topLeft:
                centerXConstraint.constant = -maxX
                centerYConstraint.constant = -maxY
            case .topRight:
                centerXConstraint.constant = maxX
                centerYConstraint.constant = -maxY
            case .bottomLeft:
                centerXConstraint.constant = -maxX
                centerYConstraint.constant = maxY
            case .bottomRight:
                centerXConstraint.constant = maxX
                centerYConstraint.constant = maxY
            }
            lastPosition = next
            dotCount += 1
        }
        
        UIView.animate(withDuration: 0.0) { self.view.layoutIfNeeded() }
    }

    // MARK: - Control Flow
    func startInstructionPhase() {
        // Show instructions for 4 seconds, then start countdown
        UIView.animate(withDuration: 1.0) {
            self.instructionLabel.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 1.0) {
                self.instructionLabel.alpha = 0
            } completion: { _ in
                self.startCountdownPhase() // Start countdown ONLY after instructions finish
            }
        }
    }

    func startCountdownPhase() {
        countdownLabel.alpha = 1
        countdownTime = 5 // Reset time to 5
        countdownLabel.text = "\(countdownTime)"
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.countdownTime -= 1
            
            if self.countdownTime > 0 {
                self.countdownLabel.text = "\(self.countdownTime)"
            } else {
                timer.invalidate() // Stop the timer
                self.transitionToExercise()
            }
        }
    }
    
    func transitionToExercise() {
        setNeedsStatusBarAppearanceUpdate() // Triggers hiding the clock/bar
        UIView.animate(withDuration: 0.5) {
            self.dotTarget.alpha = 1
            self.scoreLabel.alpha = 1
            self.countdownLabel.alpha = 0
        }
        startExercise()
    }

    func startExercise() {
        HapticManager.shared.triggerSuccessNotification()
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in   // dot generating time
            self?.performSaccadicJump()
        }
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in  // session time
            self?.endExercise()
        }
    }
    
    func endExercise() {
        exerciseTimer?.invalidate(); sessionTimer?.invalidate(); faceTrackingSession.pause()       // result animation
        UIView.animate(withDuration: 1.0) {
            self.dotTarget.alpha = 0
            self.scoreLabel.text = "Final Score: \(self.successfulFollows)"
        }
    }
}
