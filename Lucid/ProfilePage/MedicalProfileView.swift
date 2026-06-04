import SwiftUI

struct MedicalProfileView: View {
    @ObservedObject var model: MedicalProfileDataModel
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
                    
                    // Eye Power Card Section
                    VStack(alignment: .leading, spacing: 14) {
                        fieldTitle("Eye Power Settings")
                        
                        powerCard(title: "Left Eye", value: $model.leftPower)
                        powerCard(title: "Right Eye", value: $model.rightPower)

                        Button(action: {
                            withAnimation {
                                model.leftPower = 0.0
                                model.rightPower = 0.0
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: (model.leftPower == 0.0 && model.rightPower == 0.0) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle((model.leftPower == 0.0 && model.rightPower == 0.0) ? Color.accentColor : Color.white.opacity(0.4))
                                Text("I do not know my eye power")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Conditions Section
                    VStack(alignment: .leading, spacing: 20) {
                        fieldTitle("Previous Conditions")
                        
                        section(title: "Eye Conditions", conditions: eyeConditions)
                        section(title: "General Health", conditions: bodyConditions)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
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
