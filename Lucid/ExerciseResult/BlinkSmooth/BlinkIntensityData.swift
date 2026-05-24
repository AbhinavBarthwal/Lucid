import SwiftUI
import Charts

struct BlinkBarData: Identifiable {
    let id = UUID()
    let timeSecond: Int
    let performed: Int
    let total: Int
    
    var completionRatio: Double {
        guard total > 0 else { return 0.0 }
        return Double(performed) / Double(total)
    }
}

struct BlinkBarChartView: View {
    var title: String
    //var description: String
    var data: [BlinkBarData]
//    var barColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.478, blue: 0.0))
            
            Chart {
                // 1. BARS (Rendered FIRST)
                ForEach(data) { item in
                    BarMark(
                        x: .value("Blink", item.timeSecond),
                        y: .value("Ratio", item.completionRatio)
                    )
                    .foregroundStyle(item.completionRatio >= 0.75 ? Color.white.opacity(0.78) : Color(red: 1.0, green: 0.35, blue: 0.29).opacity(0.82))
                    .cornerRadius(4)
                }
                
                // 2. TARGET LINE (Rendered SECOND and forced to the FRONT)
                RuleMark(y: .value("Threshold", 0.75))
                    .foregroundStyle(Color(red: 1.0, green: 0.478, blue: 0.0))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Optimal")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 1.0, green: 0.478, blue: 0.0))
                    }
                    .zIndex(1)
            }
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 0.75, 1.0]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel() {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.2f", doubleValue))
                                .foregroundColor(doubleValue == 0.75 ? Color(red: 1.0, green: 0.478, blue: 0.0) : .gray)
                        }
                    }
                }
            }
            .chartXAxis {
                // 3. Explicitly show only the 1st and Last numbers
                let edgeValues = data.isEmpty ? [] : [1, data.count]
                
                AxisMarks(values: edgeValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                    
                    AxisValueLabel(anchor: .top) { // Centers the label under the tick
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.gray)
                        }
                    }
                }
            }
            
            // EDGE-TO-EDGE SCALING
            .chartXScale(
                domain: 0.5 ... max(1.5, Double(data.count) + 0.5),
                range: .plotDimension(padding: 20)
            )
            .chartYScale(domain: 0...1.1)
            .frame(height: 200)
            
//            Text(description)
//                .font(.caption).font(.system(size: 12, weight: .semibold))
//                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.clear)
    }
}
