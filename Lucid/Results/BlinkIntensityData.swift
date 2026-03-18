import SwiftUI
import Charts

// MARK: - New Data Model
struct BlinkBarData: Identifiable {
    let id = UUID()
    let category: String // e.g., "Left", "Right", "Both"
    let performed: Int
    let total: Int
    
    // Calculates the ratio for the 0.0 to 1.0 Y-Axis scale
    var completionRatio: Double {
        guard total > 0 else { return 0.0 }
        return Double(performed) / Double(total)
    }
}

// MARK: - Updated Chart View
struct BlinkBarChartView: View {
    var data: [BlinkBarData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Blink Completion")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Category", item.category),
                        y: .value("Ratio", item.completionRatio)
                    )
                    .foregroundStyle(Color.orange)
                    .cornerRadius(4) // Rounds the top of the bars
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1.0]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel() {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.1f", doubleValue))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            // Styles the X-Axis labels (Left, Right, Both)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.gray)
                }
            }
            .chartYScale(domain: 0...1.1) // Padding at the top
            .frame(height: 200)
        }
        .padding()
        .background(Color(white: 0.05))
        .cornerRadius(12)
    }
}
