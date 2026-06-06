import UIKit
import AVFoundation


class SiriListeningBorderView: UIView {


    static let shared = SiriListeningBorderView()

    private let edgePadding:        CGFloat = 10      // inset from screen edge
    private let screenCornerRadius: CGFloat = 44
    private let baseStrokeWidth:    CGFloat = 30.0     // heavy single border
    private let maxStrokeWidth:     CGFloat = 35.0    // expands when loud
    private let baseOpacity:        Float   = 0.55    // always visible at rest
    private let maxOpacity:         Float   = 1.0


    enum BorderState {
        case listening
        case correct
        case incorrect
    }
    
    private var borderState: BorderState = .listening
    
    func setBorderState(_ state: BorderState) {
        self.borderState = state
        updateColorsForCurrentState()
    }
    
    private func updateColorsForCurrentState() {
        guard shimmerLayer != nil, borderLayer != nil, glowLayer != nil else { return }
        
        switch borderState {
        case .listening:
            shimmerLayer.colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor,
                UIColor.systemPink.cgColor,
                UIColor.systemOrange.cgColor,
                UIColor.systemBlue.cgColor
            ]
            borderLayer.strokeColor = UIColor.clear.withAlphaComponent(0.6).cgColor
            borderLayer.shadowColor = UIColor.clear.cgColor
            glowLayer.strokeColor = UIColor.clear.withAlphaComponent(0.25).cgColor
            glowLayer.shadowColor = UIColor.clear.cgColor
        case .correct:
            shimmerLayer.colors = [
                UIColor.systemGreen.cgColor,
                UIColor.systemGreen.withAlphaComponent(0.85).cgColor,
                UIColor.systemGreen.withAlphaComponent(0.7).cgColor,
                UIColor.systemGreen.withAlphaComponent(0.85).cgColor,
                UIColor.systemGreen.cgColor
            ]
            borderLayer.strokeColor = UIColor.systemGreen.cgColor
            borderLayer.shadowColor = UIColor.systemGreen.cgColor
            glowLayer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.4).cgColor
            glowLayer.shadowColor = UIColor.systemGreen.cgColor
        case .incorrect:
            shimmerLayer.colors = [
                UIColor.systemRed.cgColor,
                UIColor.systemRed.withAlphaComponent(0.85).cgColor,
                UIColor.systemRed.withAlphaComponent(0.7).cgColor,
                UIColor.systemRed.withAlphaComponent(0.85).cgColor,
                UIColor.systemRed.cgColor
            ]
            borderLayer.strokeColor = UIColor.systemRed.cgColor
            borderLayer.shadowColor = UIColor.systemRed.cgColor
            glowLayer.strokeColor = UIColor.systemRed.withAlphaComponent(0.4).cgColor
            glowLayer.shadowColor = UIColor.systemRed.cgColor
        }
    }


    private var borderLayer:   CAShapeLayer!   // main heavy stroke
    private var glowLayer:     CAShapeLayer!   // thick soft glow behind it
    private var shimmerLayer:  CAGradientLayer! // rotating colour shimmer

    // MARK: - Animation state
    private var displayLink:   CADisplayLink?
    private var smoothedLevel: CGFloat = 0
    private var breathPhase:   CGFloat = 0
    private var shimmerAngle:  Double  = 0
    private var isActive       = false
    private weak var linkedEngine: AVAudioEngine?

    // MARK: - Shared RMS pipe
    static var _latestRMS: Float = 0

    static func feedBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        let rms = sqrtf(sum / Float(count))
        _latestRMS = _latestRMS * 0.50 + rms * 0.50
    }

    // MARK: - Init
    private override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor          = .clear
        isUserInteractionEnabled = false
        clipsToBounds            = false
        layer.masksToBounds      = false
        layer.zPosition          = .greatestFiniteMagnitude
    }

    // MARK: - Public API
    
    func show() {
        guard isActive else { return }
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.6) {
            self.alpha = 0
        }
    }

    func startListening(audioEngine: AVAudioEngine) {
        if isActive { return }
        isActive      = true
        linkedEngine  = audioEngine
        borderState   = .listening
        SiriListeningBorderView._latestRMS = 0
        smoothedLevel = 0
        breathPhase   = 0
        shimmerAngle  = 0

        mountOnWindow()
        buildLayers()
        startDisplayLink()
    }

    func stopListening(animated: Bool = true) {
        guard isActive else { return }
        isActive = false
        stopDisplayLink()
        SiriListeningBorderView._latestRMS = 0

        let b = borderLayer
        let g = glowLayer
        let s = shimmerLayer

        if animated {
            UIView.animate(withDuration: 0.5, animations: {
                b?.opacity = 0
                g?.opacity = 0
                s?.opacity = 0
            }) { [weak self] _ in
                b?.removeFromSuperlayer()
                g?.removeFromSuperlayer()
                s?.removeFromSuperlayer()
                self?.borderLayer  = nil
                self?.glowLayer    = nil
                self?.shimmerLayer = nil
                self?.removeFromSuperview()
            }
        } else {
            b?.removeFromSuperlayer()
            g?.removeFromSuperlayer()
            s?.removeFromSuperlayer()
            borderLayer  = nil
            glowLayer    = nil
            shimmerLayer = nil
            removeFromSuperview()
        }
    }

    // MARK: - Mount on window

    private func mountOnWindow() {
        var window: UIWindow? = nil
        
        // Modern iOS 15+ window retrieval via active UIWindowScene
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        
        if let scene = activeScene {
            window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
        } else {
            // Fallback for non-active or background scenes (safely avoiding deprecated global windows)
            let anyScene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
            window = anyScene?.windows.first(where: { $0.isKeyWindow }) ?? anyScene?.windows.first
        }
        
        guard let w = window else { return }
        frame = w.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        w.addSubview(self)
        w.bringSubviewToFront(self)
    }

    // MARK: - Layer building

    private func buildLayers() {
        // Remove old
        borderLayer?.removeFromSuperlayer()
        glowLayer?.removeFromSuperlayer()
        shimmerLayer?.removeFromSuperlayer()

        let inset  = edgePadding
        let rect   = bounds.insetBy(dx: inset, dy: inset)
        let radius = max(screenCornerRadius - inset * 0.4, 16)
        let path   = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath

        // --- 1. Glow layer (wide, soft, behind everything) ---
        glowLayer              = CAShapeLayer()
        glowLayer.path         = path
        glowLayer.fillColor    = UIColor.clear.cgColor
        glowLayer.strokeColor  = UIColor.white.withAlphaComponent(0.45).cgColor
        glowLayer.lineWidth    = maxStrokeWidth * 3.5   // wide blur-like band
        glowLayer.opacity      = 0
        glowLayer.lineCap      = .round
        glowLayer.frame        = bounds
        // Soften using shadow blur on the glow layer itself
        glowLayer.shadowColor  = UIColor.white.cgColor
        glowLayer.shadowOffset = .zero
        glowLayer.shadowRadius = 18
        glowLayer.shadowOpacity = 0
        layer.addSublayer(glowLayer)

        // --- 2. Shimmer gradient mask (colour sweep that rotates) ---
        shimmerLayer               = CAGradientLayer()
        shimmerLayer.frame         = bounds
        shimmerLayer.type          = .conic
        shimmerLayer.startPoint    = CGPoint(x: 0.5, y: 0.5)
        shimmerLayer.endPoint      = CGPoint(x: 0.5, y: 0)
        shimmerLayer.colors        = [
            UIColor.systemBlue.cgColor,
            UIColor.systemPurple.cgColor,
            UIColor.systemPink.cgColor,
            UIColor.systemOrange.cgColor,
            UIColor.systemBlue.cgColor
        ]
        shimmerLayer.locations     = [0, 0.25, 0.5, 0.75, 1.0]
        shimmerLayer.opacity       = 0
        
        let shimmerMask = CAShapeLayer()
        shimmerMask.path = path
        shimmerMask.fillColor = UIColor.clear.cgColor
        shimmerMask.strokeColor = UIColor.white.cgColor
        shimmerMask.lineWidth = maxStrokeWidth * 3.5
        shimmerMask.lineCap = .round
        shimmerLayer.mask = shimmerMask
        
        layer.addSublayer(shimmerLayer)

        // --- 3. Main border layer (stroked, masked by shimmer look) ---
        borderLayer              = CAShapeLayer()
        borderLayer.path         = path
        borderLayer.fillColor    = UIColor.clear.cgColor
        borderLayer.strokeColor  = UIColor.white.withAlphaComponent(0.6).cgColor
        borderLayer.lineWidth    = baseStrokeWidth
        borderLayer.opacity      = baseOpacity
        borderLayer.lineCap      = .round
        borderLayer.lineJoin     = .round
        borderLayer.frame        = bounds
        borderLayer.shadowColor  = UIColor.white.cgColor
        borderLayer.shadowOffset = .zero
        borderLayer.shadowRadius = 8
        borderLayer.shadowOpacity = 0.6
        layer.addSublayer(borderLayer)
        
        updateColorsForCurrentState()
    }

    // MARK: - Display link

    private func startDisplayLink() {
        displayLink?.invalidate()
        let dl = CADisplayLink(target: self, selector: #selector(tick))
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        // --- Audio level ---
        let rms = SiriListeningBorderView._latestRMS
        var voice: CGFloat = 0
        if rms > 0.0001 {
            let db = CGFloat(20 * log10f(rms))
            let clamped = max(-60, min(-3, db))
            voice = (clamped + 60) / 57        // 0…1
        }

        let attackAlpha: CGFloat = voice > smoothedLevel ? 0.45 : 0.06
        smoothedLevel += (voice - smoothedLevel) * attackAlpha

        // --- Idle breath ---
        breathPhase += 0.030
        let breath = (sin(breathPhase) * 0.5 + 0.5)          // 0…1, ~0.5Hz

        // When silent → breathe gently. When speaking → full bright.
        let silentBreath  = breath * 0.5                       // 0…0.5 idle
        let combined      = min(silentBreath * (1 - smoothedLevel) + smoothedLevel, 1.0)

        // --- Shimmer rotation (faster when louder) ---
        shimmerAngle += Double(0.4 + smoothedLevel * 2.5)
        let radians = shimmerAngle * .pi / 180

        // --- Apply ---
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Border stroke width: heavy at rest, expands with voice
        let strokeW = baseStrokeWidth + (maxStrokeWidth - baseStrokeWidth) * smoothedLevel
        borderLayer?.lineWidth    = strokeW
        borderLayer?.opacity      = baseOpacity + (maxOpacity - baseOpacity) * Float(combined)
        borderLayer?.shadowOpacity = 0.5 + Float(smoothedLevel) * 0.5

        // Glow pulsates wider and brighter with voice
        glowLayer?.lineWidth     = strokeW * 4.0
        glowLayer?.opacity       = Float(combined) * 0.35
        glowLayer?.shadowOpacity = Float(smoothedLevel) * 0.8

        // Shimmer gradient rotates continuously and glows with voice
        if let shimmerMask = shimmerLayer?.mask as? CAShapeLayer {
            shimmerMask.lineWidth = strokeW * 4.0
        }
        shimmerLayer?.opacity    = Float(combined) * 0.95
        shimmerLayer?.transform  = CATransform3DMakeRotation(radians, 0, 0, 1)

        CATransaction.commit()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard isActive, borderLayer != nil else { return }
        buildLayers()
    }
}
