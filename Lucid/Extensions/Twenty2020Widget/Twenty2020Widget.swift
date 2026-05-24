import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *)
public struct Twenty2020ActivityWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: Twenty2020ActivityAttributes.self) { context in
            // Lock Screen UI Banner
            Twenty2020LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Image(systemName: "eye.fill")
                            .font(.title2)
                            .foregroundColor(.emerald)
                        Spacer()
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text("\(context.state.secondsRemaining)s")
                            .font(.system(.title2, design: .rounded))
                            .bold()
                            .foregroundColor(.emerald)
                        Spacer()
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text("20-20-20 Eye Break")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Screen time: \(context.state.hoursElapsed) hour(s)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        Text("Look 20 feet away for 20 seconds")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            // Pulsating breathing scale/focus guide
                            EyeExerciseGuideView(secondsRemaining: context.state.secondsRemaining)
                            
                            // Done Link styled as a Button
                            Link(destination: URL(string: "lucid://twenty2020/done")!) {
                                Text("Done")
                                    .font(.system(.subheadline, design: .rounded))
                                    .bold()
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.emerald)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            } compactLeading: {
                Image(systemName: "eye.fill")
                    .foregroundColor(.emerald)
            } compactTrailing: {
                Text("\(context.state.secondsRemaining)s")
                    .foregroundColor(.emerald)
                    .bold()
            } minimal: {
                Image(systemName: "eye.fill")
                    .foregroundColor(.emerald)
            }
        }
    }
}

// Color extensions for emerald tone
extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
}

// Eye relaxation exercise guides (animates a pulsating circle mimicking breathing or focal shifting)
@available(iOS 16.1, *)
struct EyeExerciseGuideView: View {
    let secondsRemaining: Int
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.emerald.opacity(0.3), lineWidth: 4)
                .frame(width: 32, height: 32)
            
            Circle()
                .fill(Color.emerald)
                .frame(width: 20, height: 20)
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        scale = 1.4
                    }
                }
        }
    }
}

// Lock Screen View Banner
@available(iOS 16.1, *)
struct Twenty2020LockScreenView: View {
    let context: ActivityViewContext<Twenty2020ActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                    .font(.title2)
                    .foregroundColor(.emerald)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("20-20-20 Eye Break")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Screen Time limit met: \(context.state.hoursElapsed) hour(s).")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(context.state.secondsRemaining)s")
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .foregroundColor(.emerald)
                Text("remaining")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
    }
}
#endif
