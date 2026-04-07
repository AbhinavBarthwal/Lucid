//
//  TrendCardView.swift
//  Lucid
//
//  Created by Kanishka Bansal on 11/02/26.

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
    let yAxisMax: Double // 👈 New property
    
    var averageValue: Double {
        let nonZeroValues = data.map { $0.value }.filter { $0 != 0 }
        guard !nonZeroValues.isEmpty else { return 0 }
        return nonZeroValues.reduce(0, +) / Double(nonZeroValues.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "flask.fill")
                    .foregroundColor(.accent)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.accent)
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
                            width: .fixed(10)
                        )
                        .foregroundStyle(Color(white: 1.0, opacity: 0.5))
                        .cornerRadius(5)
                    }
                    

                        RuleMark(y: .value("\(yAxisMax)", yAxisMax))
                            .foregroundStyle(.gray)
                            .lineStyle(StrokeStyle(lineWidth: 1))
                    
                    RuleMark(y: .value("", 0.0))
                        .foregroundStyle(.gray)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                
                }
                .frame(width: 160, height: 120)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                    }
                }
                .chartYAxis(.hidden)
                .chartYScale(domain: 0...yAxisMax)
            }
        }
    }
}
