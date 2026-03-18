//  THIS IS A WRAPPER CLASS

import UIKit
import SwiftUI

class ResultChart: UIView {
    private var hostingController: UIHostingController<BlinkBarChartView>?
    
    var chartTitle: String = ""
    //var chartDescription: String = ""
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
    
    func configureChart(title: String, data: [BlinkBarData], description: String = "") {
        self.chartTitle = title
        //self.chartDescription = description
        self.chartData = data // Triggers the didSet update
    }
    
    private func setupHostingController() {
        //let chartView = BlinkBarChartView(title: chartTitle, description: chartDescription, data: chartData)
        let chartView = BlinkBarChartView(title: chartTitle, data: chartData)
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
        hostingController?.rootView = BlinkBarChartView(title: chartTitle, data: chartData)
    }
}
