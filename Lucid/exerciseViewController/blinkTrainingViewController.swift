import UIKit
import ARKit
import SceneKit
import AVFoundation
import SwiftUI

var dBlink = 1
var LPBlink = 1

enum TrainingPhase {
    case doubleBlink(remaining: Int)
    case singleBlink(eye: String, remaining: Int)
    case completed
}

class blinkTrainingViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var leftEyeLabel: UILabel!
    @IBOutlet var rightEyeLabel: UILabel!
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!

    private let largeCountLabel = UILabel()
    private let phaseInstructionLabel = UILabel()
    private let instructionBackgroundView = UIView()

    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?

    private var currentPhase: TrainingPhase = .doubleBlink(remaining: dBlink)
    private var isAcceptingInput = false
    private var isLeftEyeClosed = false
    private var isRightEyeClosed = false
    private let blinkThreshold: Float = 0.7

    private var totalErrors = 0
    private var failedAttemptsForCurrentBlink = 0
    private var consecutiveErrors = 0

    private var responseTimer: Timer?
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
        setupBackgroundVideo()
        setupUI()

        currentPhase = .doubleBlink(remaining: dBlink)
        startNewPhase(text: "Blink BOTH eyes\nafter the vibration") {
            self.triggerNextCue()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        let config = ARFaceTrackingConfiguration()
        sceneView.session.run(config)
    }

    override var prefersHomeIndicatorAutoHidden: Bool { return true }

    private func triggerNextCue() {
        isAcceptingInput = false
        hideNudge()
        currentBlinkMaxLeft = 0.0
        currentBlinkMaxRight = 0.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.impactMed.impactOccurred()
            self.impactMed.impactOccurred()
            self.isAcceptingInput = true
            self.startResponseTimer()
        }
    }

    private func startResponseTimer() {
        responseTimer?.invalidate()
        responseTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.showContextualNudge()
            self?.impactMed.impactOccurred()
            self?.impactMed.impactOccurred()
        }
    }

    private func showContextualNudge() {
        DispatchQueue.main.async {
            var nudgeText = "Please, try to blink"
            switch self.currentPhase {
            case .doubleBlink: nudgeText = "Please, try a double blink"
            case .singleBlink(let eye, _): nudgeText = "Please, blink your \(eye) eye"
            default: break
            }
            self.instructionLabel.text = nudgeText
            UIView.animate(withDuration: 0.5) { self.instructionLabel.alpha = 1.0 }
        }
    }

    private func hideNudge() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor, isAcceptingInput else { return }

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
        var isCorrect = false
        switch currentPhase {
        case .doubleBlink: isCorrect = left && right
        case .singleBlink(let eye, _): isCorrect = (eye == "left") ? (left && !right) : (right && !left)
        default: break
        }

        if isCorrect {
            leftMaxBlinks.append(currentBlinkMaxLeft)
            rightMaxBlinks.append(currentBlinkMaxRight)
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

        self.notificationGen.notificationOccurred(.error)
        self.notificationGen.notificationOccurred(.error)
        self.impactHeavy.impactOccurred()
        self.impactHeavy.impactOccurred()

        DispatchQueue.main.async {
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
        responseTimer?.invalidate()
        isAcceptingInput = false
        hideNudge()

        DispatchQueue.main.async {
            self.updateCountDownState()
            self.impactRigid.impactOccurred()
            self.impactRigid.impactOccurred()

            if self.getCurrentRemaining() <= 0 {
                self.notificationGen.notificationOccurred(.success)
                self.notificationGen.notificationOccurred(.success)
                self.advancePhase()
            } else {
                self.triggerNextCue()
            }
        }
    }

    private func advancePhase() {
        consecutiveErrors = 0
        switch currentPhase {
        case .doubleBlink:
            self.currentPhase = .singleBlink(eye: "left", remaining: LPBlink)
            startNewPhase(text: "Blink LEFT eye only\nafter the vibration") { self.triggerNextCue() }
        case .singleBlink(let eye, _):
            if eye == "left" {
                self.currentPhase = .singleBlink(eye: "right", remaining: LPBlink)
                startNewPhase(text: "Blink RIGHT eye only\nafter the vibration") { self.triggerNextCue() }
            } else {
                finishSession()
            }
        default: break
        }
    }

    private func finishSession() {
        currentPhase = .completed
        self.showSummaryScreen()
    }

    private func showSummaryScreen() {
        DispatchQueue.main.async {
            let summaryView = BlinkSummaryView(
                leftPeaks: self.leftMaxBlinks,
                rightPeaks: self.rightMaxBlinks,
                totalErrors: self.totalErrors,
                onDismiss: {
                    self.dismiss(animated: true)
                }
            )
            let hostingController = UIHostingController(rootView: summaryView)
            hostingController.modalPresentationStyle = .fullScreen
            self.present(hostingController, animated: true)
        }
    }

    private func updateCountDownState() {
        switch currentPhase {
        case .doubleBlink(let rem): currentPhase = .doubleBlink(remaining: rem - 1)
        case .singleBlink(let eye, let rem): currentPhase = .singleBlink(eye: eye, remaining: rem - 1)
        default: break
        }
        largeCountLabel.text = "\(getCurrentRemaining())"
    }

    private func getCurrentRemaining() -> Int {
        if case .doubleBlink(let rem) = currentPhase { return rem }
        if case .singleBlink(_, let rem) = currentPhase { return rem }
        return 0
    }

    private func setupUI() {
        instructionBackgroundView.frame = view.bounds
        instructionBackgroundView.backgroundColor = .black
        instructionBackgroundView.alpha = 1.0
        view.addSubview(instructionBackgroundView)

        phaseInstructionLabel.frame = CGRect(x: 20, y: 0, width: view.frame.width - 40, height: 250)
        phaseInstructionLabel.center = view.center
        phaseInstructionLabel.textAlignment = .center
        phaseInstructionLabel.font = .systemFont(ofSize: 32, weight: .bold)
        phaseInstructionLabel.textColor = .white
        phaseInstructionLabel.numberOfLines = 0
        view.addSubview(phaseInstructionLabel)

        largeCountLabel.frame = CGRect(x: 0, y: 120, width: view.frame.width, height: 120)
        largeCountLabel.textAlignment = .center
        largeCountLabel.font = .systemFont(ofSize: 80, weight: .bold)
        largeCountLabel.textColor = .white
        largeCountLabel.text = "10"
        view.addSubview(largeCountLabel)

        instructionLabel.alpha = 0
        sceneView.delegate = self
        sceneView.alpha = 0.01
    }

    private func startNewPhase(text: String, completion: @escaping () -> Void) {
        isAcceptingInput = false
        largeCountLabel.isHidden = true
        playerLayer?.opacity = 0

        showPhaseInstruction(text) {
            self.largeCountLabel.text = "\(self.getCurrentRemaining())"
            self.largeCountLabel.isHidden = false
            self.playerLayer?.opacity = 1
            completion()
        }
    }

    private func showPhaseInstruction(_ text: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.phaseInstructionLabel.text = text
            self.instructionBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.7, animations: {
                self.instructionBackgroundView.alpha = 1.0
                self.phaseInstructionLabel.alpha = 1.0
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    UIView.animate(withDuration: 0.7, animations: {
                        self.instructionBackgroundView.alpha = 0.0
                        self.phaseInstructionLabel.alpha = 0.0
                    }) { _ in
                        self.instructionBackgroundView.isHidden = true
                        completion()
                    }
                }
            }
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
        player?.play()
    }
}
