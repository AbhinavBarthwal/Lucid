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
        let path1 = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle*1.2,
            clockwise: true
        )

        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.1).cgColor
        trackLayer.lineWidth = 14
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round

        progressLayer.path = path1.cgPath
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



import Charts
import SwiftUI

import SwiftUI

// 1. The Custom Semi-Circle Style
struct SemiCircleGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Background Track
            Circle()
                .trim(from: 0.0, to: 0.5) // Exactly half a circle
                .stroke(
                    Color(white: 1.0, opacity: 0.1),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(180)) // Rotate flat side to the bottom
            
            // Progress Track
            Circle()
                // configuration.value is a percentage from 0.0 to 1.0.
                // Multiplying by 0.5 ensures it maps to our half-circle.
                .trim(from: 0.0, to: 0.5 * configuration.value)
                .stroke(
                    Color.orange,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(180))
        }
    }
}

// 2. The Main SwiftUI View
struct SemiCircleGaugeView: View {
    var completed: Int
    var total: Int
    
    // Safely calculate progress percentage
    var progress: Double {
        guard total > 0 else { return 0.0 }
        return min(max(Double(completed) / Double(total), 0.0), 1.0)
    }
    
    var body: some View {
        Gauge(value: progress, in: 0...1) {
            EmptyView()
        }
        .gaugeStyle(SemiCircleGaugeStyle())
        .padding(16) // Accounts for your original -16 radius inset
        // Automatically animates whenever the completed/total values change!
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
}


#Preview {
    SemiCircleGaugeView(completed: 8, total: 10)
}
