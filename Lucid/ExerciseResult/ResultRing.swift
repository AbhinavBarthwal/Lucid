//
//  ResultRing.swift
//  Lucid
//
//  Created by Kanishka Bansal on 16/03/26.
//

import SwiftUI

struct RingShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Center the circle in the available space
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // small margin so the stroke doesn't clip
        let radius = min(rect.width, rect.height) / 2 - 16
        
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90), // Starts at 12 o'clock
            endAngle: .degrees(270),  // Ends at 12 o'clock (full circle)
            clockwise: false
        )
        return path
    }
}

struct RingGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Background Track
            RingShape()
                .stroke(
                    Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
            
            // Progress Track
            RingShape()
                .trim(from: 0.0, to: configuration.value)
                .stroke(
                    Color(red: 1.0, green: 0.478, blue: 0.0),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
        }
    }
}

struct RingGaugeView: View {
    var completed: Int
    var total: Int
    
    var progress: Double {
        guard total > 0 else { return 0.0 }
        return min(max(Double(completed) / Double(total), 0.0), 1.0)
    }
    
    var body: some View {
        Gauge(value: progress, in: 0...1) {
            EmptyView()
        }
        .gaugeStyle(RingGaugeStyle())
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
    }
}
