//
//  FullRing.swift
//  Lucid
//
//  Created by Kanishka Bansal on 16/03/26.
//

import UIKit
import SwiftUI

class FullRingGauge: UIView {
    
    private var hostingController: UIHostingController<RingGaugeView>?
    
    var progress: CGFloat = 0 {
        didSet {
            updateSwiftUIView()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHostingController()
    }
    
    // MARK: - Setup
    private func setupHostingController() {
        self.backgroundColor = .clear
        
        let swiftUIView = RingGaugeView(completed: 0, total: 100)
        let host = UIHostingController(rootView: swiftUIView)
        
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
    
    // MARK: - Actions
    func setProgress(_ value: CGFloat) {
        self.progress = min(max(value, 0), 1)
    }
    
    private func updateSwiftUIView() {
        let completedValue = Int(progress * 100)
        hostingController?.rootView = RingGaugeView(completed: completedValue, total: 100)
    }
}
