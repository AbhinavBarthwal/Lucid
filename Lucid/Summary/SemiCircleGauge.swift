import SwiftUI

// MARK: - Custom Shape
struct SemiCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Matches your exact UIKit layout math to completely fill the bounds
        let center = CGPoint(x: rect.midX, y: rect.height - 10)
        let radius = min(rect.width / 2, rect.height) - 16
        
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(140),
            endAngle: .degrees(400),
            clockwise: false
        )
        return path
    }
}

// MARK: - Custom Gauge Style
struct SemiCircleGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Background Track
            SemiCircleShape()
                .stroke(
                    Color(white: 1.0, opacity: 0.1),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
            
            // Progress Track
            SemiCircleShape()
                .trim(from: 0.0, to: configuration.value)
                .stroke(
                    Color.orange,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
        }
    }
}

// MARK: - Main SwiftUI View
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
        .padding(.bottom , 16)
        .gaugeStyle(SemiCircleGaugeStyle())
        // Automatically animates whenever the completed/total values change
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
}



import UIKit
import SwiftUI

class SemiCircleGauge: UIView {
    
    // The hosting controller that bridges UIKit and SwiftUI
    private var hostingController: UIHostingController<SemiCircleGaugeView>?
    
    var progress: CGFloat = 0 {
        didSet {
            updateSwiftUIView()
        }
    }
    
    // MARK: - Initialization
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHostingController()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }
    
    // MARK: - Setup
    
    private func setupHostingController() {
        self.backgroundColor = .clear
        
        // Initialize the SwiftUI View (Starting at 0%)
        let swiftUIView = SemiCircleGaugeView(completed: 0, total: 100)
        let host = UIHostingController(rootView: swiftUIView)
        
        // Make the hosting view's background clear so it blends perfectly
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(host.view)
        
        // Pin the SwiftUI view to the exact edges of this UIView so it fills the space
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: topAnchor),
            host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        self.hostingController = host
    }
    
    // MARK: - Actions
    
    func setProgress(_ value: CGFloat, animated: Bool = true, duration: CFTimeInterval = 0.8) {
        // Clamp the value to ensure it stays between 0.0 and 1.0
        let clamped = min(max(value, 0), 1)
        
        // Setting the property triggers `didSet` which calls `updateSwiftUIView()`
        self.progress = clamped
    }
    
    func reset() {
        self.progress = 0
    }
    
    // MARK: - State Updates
    
    private func updateSwiftUIView() {
        // Convert the 0.0...1.0 CGFloat progress into completed/total integers
        let completedValue = Int(progress * 100)
        let totalValue = 100
        
        // Re-assigning the rootView automatically triggers SwiftUI's reactive updates
        hostingController?.rootView = SemiCircleGaugeView(completed: completedValue, total: totalValue)
    }
}
