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
    let betterDirection: Int // 0 = lower is better, 1 = higher is better
    
    var averageValue: Double {
        let validValues = data.map { $0.value }.filter { $0 >= 0 }
        guard !validValues.isEmpty else { return -1 }
        return validValues.reduce(0, +) / Double(validValues.count)
    }
    
    var hasAverageData: Bool {
        return averageValue >= 0
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
                    Text(hasAverageData ? averageScore : "--")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    Text(betterDirection == 1 ? "Higher is better" : "Lower is better")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if hasAverageData {
                    Chart {
                        ForEach(data) { item in
                            if item.value >= 0 {
                                BarMark(
                                    x: .value("Month", item.month),
                                    y: .value("Value", item.value),
                                    width: .fixed(10)
                                )
                                .foregroundStyle(Color(white: 1.0, opacity: 0.5))
                                .cornerRadius(5)
                            }
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
                } else {
                    VStack(alignment: .center) {
                        Text("No data found")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 160, height: 120)
                }
            }
        }
    }
}
