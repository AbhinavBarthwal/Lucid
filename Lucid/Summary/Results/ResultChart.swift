import UIKit
import SwiftUI

class ResultChart: UIView {
    private var hostingController: UIHostingController<BlinkBarChartView>?
    
    // Updated to accept the 3-bar data array
    var chartData: [BlinkBarData] = [] {
        didSet { updateChart() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHostingController()
    }
    
    private func setupHostingController() {
        let chartView = BlinkBarChartView(data: chartData)
        let host = UIHostingController(rootView: chartView)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: topAnchor),
            host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        self.hostingController = host
    }
    
    private func updateChart() {
        hostingController?.rootView = BlinkBarChartView(data: chartData)
    }
}
