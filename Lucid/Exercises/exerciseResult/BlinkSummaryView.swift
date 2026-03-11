import SwiftUI
import Charts

struct BlinkData: Identifiable {
    let id = UUID()
    let index: Int
    let intensity: Float
    let eye: String
}

struct BlinkSummaryView: View {
    let leftPeaks: [Float]
    let rightPeaks: [Float]
    let totalErrors: Int
    var onDismiss: () -> Void

    var leftAverage: Int {
        guard !leftPeaks.isEmpty else { return 0 }
        return Int((leftPeaks.reduce(0, +) / Float(leftPeaks.count)) * 100)
    }
    
    var rightAverage: Int {
        guard !rightPeaks.isEmpty else { return 0 }
        return Int((rightPeaks.reduce(0, +) / Float(rightPeaks.count)) * 100)
    }

    var totalScore: Int {
        let all = leftPeaks + rightPeaks
        guard !all.isEmpty else { return 0 }
        return Int((all.reduce(0, +) / Float(all.count)) * 100)
    }

    var chartData: [BlinkData] {
        var data: [BlinkData] = []
        for (i, val) in leftPeaks.enumerated() {
            data.append(BlinkData(index: i + 1, intensity: min(max(val, 0), 1), eye: "Left"))
        }
        for (i, val) in rightPeaks.enumerated() {
            data.append(BlinkData(index: i + 1, intensity: min(max(val, 0), 1), eye: "Right"))
        }
        return data
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Performance Report")
                    .font(.system(size: 34, weight: .medium, design: .default).width(.expanded))                
                // Overall Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: CGFloat(totalScore) / 100)
                        .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(totalScore)")
                            .font(.system(size: 50, weight: .black))
                        Text("OVERALL")
                            .font(.caption.bold())
                            .tracking(2)
                    }
                }
                .frame(width: 150, height: 150)
                .foregroundColor(.white)

                // Stats Breakdown Row
                HStack(spacing: 15) {
                    StatBox(title: "Left Eye", value: "\(leftAverage)%", color: .blue)
                    StatBox(title: "Right Eye", value: "\(rightAverage)%", color: .cyan)
                    StatBox(title: "Errors", value: "\(totalErrors)", color: .red)
                }

                // Clustered Bar Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Blink Intensity Mapping")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    
                    Chart(chartData) { item in
                        BarMark(
                            x: .value("Blink #", "\(item.index)"), // Discrete string prevents overlap
                            y: .value("Intensity", item.intensity)
                        )
                        .foregroundStyle(by: .value("Eye", item.eye))
                        .position(by: .value("Eye", item.eye)) // Side-by-side
                    }
                    .chartYScale(domain: 0...1.0)
                    .chartYAxis {
                        AxisMarks(values: [0, 0.5, 1.0]) { value in
                            AxisGridLine().foregroundStyle(.white.opacity(0.1))
                            AxisValueLabel().foregroundStyle(.gray)
                        }
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Button(action: onDismiss) {
                    Text("Finish Training")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                }
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct StatBox: View {
    let title: String; let value: String; let color: Color
    var body: some View {
        VStack {
            Text(title).font(.caption2).foregroundColor(.gray)
            Text(value).font(.title3.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color.white.opacity(0.05)).cornerRadius(12)
    }
}

#Preview {
    // Randomized data for Canvas testing
    BlinkSummaryView(
        leftPeaks: (0..<15).map { _ in Float.random(in: 0.6...0.98) },
        rightPeaks: (0..<15).map { _ in Float.random(in: 0.5...0.92) },
        totalErrors: Int.random(in: 5...15),
        onDismiss: {}
    )
}
