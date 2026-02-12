import UIKit

class SemiCircleGauge: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var didSetup = false

    var progress: CGFloat = 0 {
        didSet {
            setProgress(progress, animated: true)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        
        if !didSetup {
            setupLayers()
            didSetup = true
        }
    }

    private func setupLayers() {
        // Move center to the bottom to create a true semi-circle
        let center = CGPoint(x: bounds.midX, y: bounds.height - 10)
        let radius = min(bounds.width / 2, bounds.height) - 16

        let startAngle: CGFloat = .pi
        let endAngle: CGFloat = 2 * .pi

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.1).cgColor
        trackLayer.lineWidth = 14
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.systemOrange.cgColor
        progressLayer.lineWidth = 14
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
    }

    func setProgress(_ value: CGFloat, animated: Bool = true, duration: CFTimeInterval = 0.8) {
        let clamped = min(max(value, 0), 1)

        if animated {
            animateProgress(to: clamped, duration: duration)
        } else {
            progressLayer.strokeEnd = clamped
        }
    }
    
    private func animateProgress(to value: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        animation.fromValue = progressLayer.presentation()?.strokeEnd ?? 0
        animation.toValue = value
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        progressLayer.strokeEnd = value
        progressLayer.add(animation, forKey: "progress")
    }
    
    func reset() {
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 0
    }
}
