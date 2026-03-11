//
//  TrendCardView.swift
//  Lucid
//
//  Created by Kanishka Bansal on 11/02/26.
//

import SwiftUI
import Charts

struct TrendData: Identifiable {
    let id = UUID()
    let month: String
    let value: Double
}

struct TrendCardView: View {
    let title: String
    let averageScore: String
    let data: [TrendData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flask.fill")
                    .foregroundColor(.orange)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average Score")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    Text(averageScore)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Value", item.value),
                            width: .fixed(10) // THIN BARS
                        )
                        .foregroundStyle(Color(white: 1.0, opacity: 0.5))
                        .cornerRadius(5)
                    }
                    
                    RuleMark(y: .value("Goal", 65))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
                .frame(width: 160, height: 100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                    }
                }
                .chartYAxis(.hidden)
            }
        }
//        .padding(20)
//        .background(Color(white: 1.0, opacity: 0.08))
//        .cornerRadius(24)
//        .overlay(
//            RoundedRectangle(cornerRadius: 24)
//                .stroke(Color.white.opacity(0.1), lineWidth: 1)
//        )
        
    }
}



