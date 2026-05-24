import SwiftUI

struct MedicalProfileView: View {
    @ObservedObject var model: MedicalProfileDataModel
    
    // Developer testing state
    @State private var isActivityRunning = false
    @State private var testSecondsLeft = 20
    @State private var testStatusText = "Ready"
    @State private var testStatusColor = Color.white.opacity(0.5)
    @State private var countdownTimer: Timer? = nil
    
    private let genderOptions = ["Female", "Male", "Non-binary", "Prefer not to say"]
    private let eyeConditions = [
        "Digital Eye Strain",
        "Dry Eyes",
        "Blurry Vision",
        "Eye Fatigue",
        "Convergence Issues",
        "Lazy Eye",
        "Astigmatism",
        "Presbyopia",
        "Crossed Eyes",
        "Light Sensitivity",
        "Other"
    ]
    private let bodyConditions = [
        "Diabetes",
        "High Blood Pressure",
        "Thyroid Issues",
        "Migraine",
        "Autoimmune Disease",
        "Neurological Issues"
    ]
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 12/255)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        fieldTitle("Name")
                        
                        HStack {
                            Image(systemName: "person")
                                .foregroundStyle(Color.white.opacity(0.4))
                            TextField("Your name", text: $model.name)
                                .textInputAutocapitalization(.words)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // DOB Field
                    VStack(alignment: .leading, spacing: 8) {
                        fieldTitle("Date of Birth")
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.white.opacity(0.4))
                            
                            DatePicker(
                                "",
                                selection: $model.dateOfBirth,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.accentColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Gender Selector
                    VStack(alignment: .leading, spacing: 10) {
                        fieldTitle("Gender")
                        
                        FlowLayout(tags: genderOptions) { option in
                            let isSelected = (model.gender == option)
                            let bgColor = isSelected ? Color.accentColor : Color.white.opacity(0.08)
                            let strokeColor = isSelected ? Color.white.opacity(0.3) : Color.clear
                            
                            return Text(option)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(bgColor)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(strokeColor, lineWidth: 1)
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        model.gender = option
                                    }
                                }
                        }
                    }
                    
                    // Eye Power Card Section
                    VStack(alignment: .leading, spacing: 14) {
                        fieldTitle("Eye Power Settings")
                        
                        powerCard(title: "Left Eye", value: $model.leftPower)
                        powerCard(title: "Right Eye", value: $model.rightPower)
                    }
                    
                    // Conditions Section
                    VStack(alignment: .leading, spacing: 20) {
                        fieldTitle("Previous Conditions")
                        
                        section(title: "Eye Conditions", conditions: eyeConditions)
                        section(title: "General Health", conditions: bodyConditions)
                    }
                    .padding(.bottom, 20)
                    
                    // Developer Testing Section
                    VStack(alignment: .leading, spacing: 14) {
                        fieldTitle("Developer Testing")
                        
                        // Status card
                        HStack(spacing: 12) {
                            Circle()
                                .fill(testStatusColor)
                                .frame(width: 10, height: 10)
                                .shadow(color: testStatusColor, radius: isActivityRunning ? 6 : 0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActivityRunning)
                            
                            Text(testStatusText)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(testStatusColor)
                            
                            Spacer()
                            
                            if isActivityRunning {
                                Text("\(testSecondsLeft)s")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 16/255, green: 185/255, blue: 129/255))
                                    .contentTransition(.numericText(countsDown: true))
                                    .animation(.default, value: testSecondsLeft)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(testStatusColor.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        // Launch button
                        Button(action: launchLiveActivityTest) {
                            HStack(spacing: 10) {
                                Image(systemName: isActivityRunning ? "eye.fill" : "play.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text(isActivityRunning ? "Running on Dynamic Island…" : "Launch 20-20-20 Live Activity")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                isActivityRunning
                                    ? Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.7)
                                    : Color(red: 16/255, green: 185/255, blue: 129/255)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isActivityRunning)
                        
                        // Stop button — only visible while running
                        if isActivityRunning {
                            Button(action: stopLiveActivityTest) {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Stop & Dismiss")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(14)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.red.opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isActivityRunning)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Test Helpers
    
    private func launchLiveActivityTest() {
        guard !isActivityRunning else { return }
        
        isActivityRunning = true
        testSecondsLeft = 20
        testStatusText = "Live Activity active"
        testStatusColor = Color(red: 16/255, green: 185/255, blue: 129/255)
        
        // Mirror countdown in-app
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if testSecondsLeft > 0 {
                testSecondsLeft -= 1
            } else {
                timer.invalidate()
            }
        }
        
        if #available(iOS 16.1, *) {
            Twenty2020Manager.shared.startLiveActivityWithCountdown(hoursElapsed: 1) {
                countdownTimer?.invalidate()
                isActivityRunning = false
                testSecondsLeft = 20
                testStatusText = "Completed ✓"
                testStatusColor = Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.6)
                
                // Reset to ready after 3s
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    testStatusText = "Ready"
                    testStatusColor = Color.white.opacity(0.5)
                }
            }
        } else if #available(iOS 15.0, *) {
            Twenty2020Manager.shared.startLiveActivity(hoursElapsed: 1)
        }
    }
    
    private func stopLiveActivityTest() {
        countdownTimer?.invalidate()
        isActivityRunning = false
        testSecondsLeft = 20
        testStatusText = "Stopped"
        testStatusColor = Color.orange.opacity(0.8)
        
        if #available(iOS 15.0, *) {
            Twenty2020Manager.shared.endLiveActivity()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            testStatusText = "Ready"
            testStatusColor = Color.white.opacity(0.5)
        }
    }
    
    private func fieldTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.8))
    }
    
    private func powerCard(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            
            HStack {
                Text(String(format: "%.2f D", value.wrappedValue))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        if value.wrappedValue > -20.0 {
                            value.wrappedValue -= 0.25
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        if value.wrappedValue < 20.0 {
                            value.wrappedValue += 0.25
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func section(title: String, conditions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            
            ConditionBubblesPicker(conditions: conditions, selection: $model.selectedConditions)
        }
        .padding(18)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ConditionBubblesPicker: View {
    let conditions: [String]
    @Binding var selection: Set<String>
    
    var body: some View {
        FlowLayout(tags: conditions) { tag in
            let isSelected = selection.contains(tag)
            let bgColor = isSelected ? Color.accentColor : Color.white.opacity(0.08)
            let strokeColor = isSelected ? Color.white.opacity(0.3) : Color.clear
            
            return Text(tag)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bgColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(strokeColor, lineWidth: 1)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        toggle(tag)
                    }
                }
        }
    }
    
    private func toggle(_ tag: String) {
        if selection.contains(tag) {
            selection.remove(tag)
        } else {
            selection.insert(tag)
        }
    }
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let tags: Data
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(tags), id: \.self) { tag in
                content(tag)
                    .padding(4)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geo.size.width {
                            width = 0
                            height -= dimension.height
                        }

                        let result = width

                        if tag == tags.last {
                            width = 0
                        } else {
                            width -= dimension.width
                        }

                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height

                        if tag == tags.last {
                            height = 0
                        }

                        return result
                    }
            }
        }
        .background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    totalHeight = geo.size.height
                }
                return .clear
            }
        )
    }
}
