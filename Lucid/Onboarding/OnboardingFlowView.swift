import SwiftUI
internal import Combine
import AuthenticationServices

struct OnboardingDraft: Equatable {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var name: String = ""
    //var dateOfBirth: Date = Date()
    //var gender: String = ""
    var leftEyePower: String = ""
    var rightEyePower: String = ""
    var previousConditions: Set<String> = []

    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var cleanedConditions: [String] {
        previousConditions.sorted()
    }
}

enum OnboardingAuthMode {
    case create
    case login
    case undecided
}

enum EmailCheckStatus {
    case unchecked
    case checking
    case present
    case notPresent
}

struct OnboardingFlowView: View {
    enum Step: Int, CaseIterable {
        case landing = 0
        case email = 1
        case personal = 2
        case eyePower = 3
        case conditions = 4
    }

    let onFinished: (OnboardingDraft) -> Void

    @State private var step: Step = .landing
    @State private var draft = OnboardingDraft()
    @State private var authMode: OnboardingAuthMode = .undecided
    @State private var emailStatus: EmailCheckStatus = .unchecked
    @State private var didSubmit = false
    @State private var validationMessage: String?
    @State private var leftPower: Double = 0.0
    @State private var rightPower: Double = 0.0

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
            // Cosmic Deep Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.04, blue: 0.08),
                    Color(red: 0.02, green: 0.06, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Glowing ambient blobs
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.18))
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .offset(x: -80, y: 100)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .blur(radius: 70)
                        .offset(x: geo.size.width - 160, y: geo.size.height - 260)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                Group {
                    switch step {
                    case .landing:
                        LandingStep(
                            onContinue: {
                                withAnimation { step = .email }
                            },
                            onAppleSignIn: { idToken, email, fullName in
                                handleAppleSignIn(idToken: idToken, email: email, fullName: fullName)
                            }
                        )
                    case .email:
                        EmailLoginStep(
                            email: $draft.email,
                            password: $draft.password,
                            confirmPassword: $draft.confirmPassword,
                            emailStatus: $emailStatus,
                            authMode: $authMode
                        )
                    case .personal:
                        PersonalDetailsStep(
                            name: $draft.name
                        )
                    case .eyePower:
                        EyePowerStep(
                            left: $leftPower,
                            right: $rightPower
                        )
                    case .conditions:
                        ConditionsStep(
                            eyeConditions: eyeConditions,
                            bodyConditions: bodyConditions,
                            selection: $draft.previousConditions
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if let validationMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(validationMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.95))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if didSubmit {
                OnboardingLoadingOverlay()
                    .transition(.opacity)
            }
        }
        .onChange(of: draft.email) { _, _ in
            validationMessage = nil
        }
        .onChange(of: draft.password) { _, _ in
            validationMessage = nil
        }
        .onChange(of: draft.confirmPassword) { _, _ in
            validationMessage = nil
        }
    }

    private var header: some View {
        Group {
            if step != .landing {
                VStack(alignment: .leading, spacing: 10) {
                    Text(titleText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentProgressIndex ? Color.accentColor : Color.white.opacity(0.12))
                                .frame(height: 6)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var footer: some View {
        Group {
            if step != .landing {
                HStack(spacing: 16) {
                    Button("Back") { goBack() }
                        .buttonStyle(SecondaryPillButtonStyle())
                        .disabled(didSubmit)

                    Spacer()

                    Button(primaryButtonTitle) {
                        goNext()
                    }
                    .buttonStyle(PrimaryPillButtonStyle())
                    .disabled(didSubmit)
                }
                .padding(.bottom, 6)
            }
        }
    }

    private var currentProgressIndex: Int {
        min(step.rawValue, 4)
    }

    private var titleText: String {
        switch step {
        case .landing: return ""
        case .email:
            return authMode == .login ? "Welcome Back" : (authMode == .create ? "Create Account" : "Get Started")
        case .personal:
            return "Personal Details"
        case .eyePower:
            return "Eye Power"
        case .conditions:
            return "Health Profile"
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .landing:
            return "Continue"
        case .email:
            return emailStatus == .unchecked ? "Check Email" : "Continue"
        case .personal:
            return "Next"
        case .eyePower:
            return "Next"
        case .conditions:
            return "Finish"
        }
    }

    private func goBack() {
        validationMessage = nil
        if step == .email && emailStatus != .unchecked {
            withAnimation {
                emailStatus = .unchecked
                authMode = .undecided
            }
            return
        }
        // Landing is step 0, so going back from email goes to landing
        guard step.rawValue > 0, let prev = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            step = prev
        }
    }

    private func goNext() {
        validationMessage = nil
        
        if step == .email {
            if !isValidEmail(draft.normalizedEmail) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    validationMessage = "Please enter a valid email address."
                }
                return
            }
            
            switch emailStatus {
            case .unchecked:
                withAnimation {
                    emailStatus = .checking
                }
                Task {
                    let exists = await SupabaseManager.shared.checkUserExists(email: draft.normalizedEmail)
                    withAnimation {
                        if exists {
                            emailStatus = .present
                            authMode = .login
                        } else {
                            emailStatus = .notPresent
                            authMode = .create
                        }
                    }
                }
                return
            case .checking:
                return
            case .present:
                if draft.password.isEmpty {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        validationMessage = "Please enter your password to continue."
                    }
                    return
                }
                
                // Verify password: check locally or check via Supabase remote database
                let email = draft.normalizedEmail
                let pass = draft.password
                withAnimation { didSubmit = true }
                
                Task {
                    let verifiedLocal = CredentialStore.shared.verify(password: pass, for: email)
                    let verifiedRemote = await SupabaseManager.shared.verifyPassword(email: email, passwordToVerify: pass)
                    
                    if verifiedLocal || verifiedRemote {
                        draft.email = email
                        onFinished(draft)
                    } else {
                        withAnimation {
                            didSubmit = false
                            validationMessage = "Oops! That email or password doesn't match our records. Could you try again?"
                        }
                    }
                }
                return
            case .notPresent:
                if draft.password.count < 8 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        validationMessage = "Let's make sure your password is at least 8 characters long to keep your account secure."
                    }
                    return
                }
                if draft.confirmPassword.isEmpty {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        validationMessage = "Please confirm your password to continue."
                    }
                    return
                }
                if draft.password != draft.confirmPassword {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        validationMessage = "Oops! The passwords you typed don't match. Could you check them again?"
                    }
                    return
                }
                draft.email = draft.normalizedEmail
                guard let next = Step(rawValue: step.rawValue + 1) else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    step = next
                }
                return
            }
        }
        
        if let message = validationError(for: step) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                validationMessage = message
            }
            return
        }

        draft.email = draft.normalizedEmail
        draft.name = draft.trimmedName
        draft.leftEyePower = String(format: "%.2f", leftPower)
        draft.rightEyePower = String(format: "%.2f", rightPower)

//        if step == .personal {
//            if Calendar.current.isDateInToday(draft.dateOfBirth) {
//                var components = DateComponents()
//                components.year = 1950
//                components.month = 1
//                components.day = 1
//                if let fallbackDate = Calendar.current.date(from: components) {
//                    draft.dateOfBirth = fallbackDate
//                }
//            }
//            if draft.gender.isEmpty {
//                draft.gender = "Prefer not to say"
            //}
        //}

        if step == .conditions {
            withAnimation { didSubmit = true }
            onFinished(draft)
            return
        }

        guard let next = Step(rawValue: min(Step.conditions.rawValue, step.rawValue + 1)) else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            step = next
        }
    }

    private func validationError(for step: Step) -> String? {
        switch step {
        case .landing, .email:
            return nil
        case .personal:
            if draft.trimmedName.isEmpty {
                return "We'd love to know your name! Please enter it to continue."
            }
            _ = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
//            if draft.dateOfBirth > tenYearsAgo {
//                return "Lucid is designed for ages 10 and up. We look forward to welcoming you soon!"
//            }
        case .eyePower:
            return nil
        case .conditions:
            return nil
        }

        return nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func computeAge(from dateOfBirth: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return max(0, components.year ?? 0)
    }
    private func handleAppleSignIn(idToken: String, email: String, fullName: String) {
        withAnimation { didSubmit = true }
        
        Task {
            let authResult = await SupabaseManager.shared.signInWithApple(idToken: idToken)
            let authEmail = authResult.email
            let authId = authResult.uid
            
            let userEmail = !email.isEmpty ? email : (authEmail ?? "")
            let userName = fullName
            
            let localUser = SwiftDataManager.shared.getOrCreateUser()
            if let uid = authId {
                localUser.id = uid
                try? SwiftDataManager.shared.context.save()
                
                // 1. Check if user exists by ID first (most robust, works on subsequent sign-ins)
                let existsById = await SupabaseManager.shared.checkUserExists(id: uid)
                if existsById {
                    draft.email = userEmail.isEmpty ? (authEmail ?? "") : userEmail
                    _ = await SupabaseManager.shared.fetchAndApplyUser(byId: uid, to: localUser)
                    
                    await MainActor.run {
                        onFinished(draft)
                    }
                    return
                }
            }
            
            // 2. Fallback to checking by email if not matched by ID
            if !userEmail.isEmpty {
                let existsByEmail = await SupabaseManager.shared.checkUserExists(email: userEmail)
                if existsByEmail {
                    draft.email = userEmail
                    _ = await SupabaseManager.shared.fetchAndApplyUser(byEmail: userEmail, to: localUser)
                    
                    await MainActor.run {
                        onFinished(draft)
                    }
                } else {
                    // Proceed to personal details with prefilled info
                    await MainActor.run {
                        didSubmit = false
                        draft.email = userEmail
                        if !userName.isEmpty { draft.name = userName }
                        withAnimation {
                            step = .personal
                        }
                    }
                }
            } else {
                await MainActor.run {
                    didSubmit = false
                    validationMessage = "We couldn't get your email from Apple. No worries, let's try signing up manually!"
                }
            }
        }
    }
}

// MARK: - OnboardingLoadingOverlay
struct OnboardingLoadingOverlay: View {
    @State private var rotateDegree = 0.0
    @State private var statusIndex = 0
    
    let statuses = [
        "Checking your details...",
        "Saving your profile...",
        "Getting your setup ready...",
        "Checking your eye test history...",
        "Making your goals...",
        "Almost done..."
    ]
    
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Frosted glassmorphism background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Circular Glowing Spinner
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 5)
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .trim(from: 0, to: 0.35)
                        .stroke(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 72, height: 72)
                        .rotationEffect(Angle(degrees: rotateDegree))
                        .onAppear {
                            withAnimation(.linear(duration: 0.95).repeatForever(autoreverses: false)) {
                                rotateDegree = 360.0
                            }
                        }
                }
                .shadow(color: Color.accentColor.opacity(0.35), radius: 10)
                
                VStack(spacing: 10) {
                    Text(statuses[statusIndex])
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .id(statusIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    
                    // Secure Supabase text removed as requested
                }
                .padding(.horizontal, 40)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.35)) {
                statusIndex = (statusIndex + 1) % statuses.count
            }
        }
    }
}

// MARK: - LandingStep
private struct LandingStep: View {
    let onContinue: () -> Void
    let onAppleSignIn: (String, String, String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Glowing Eye Icon Logo
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.4), Color.clear, Color.accentColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 170, height: 170)
                
                Image("Luc")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 12, x: 0, y: 6)
            }
            
            Spacer()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("L U C I D")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(4)
                    
                    Text("Fixing Digital Eye Strain")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.70))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                               let identityToken = appleIDCredential.identityToken,
                               let idTokenString = String(data: identityToken, encoding: .utf8) {
                                
                                let email = appleIDCredential.email ?? ""
                                let givenName = appleIDCredential.fullName?.givenName ?? ""
                                let familyName = appleIDCredential.fullName?.familyName ?? ""
                                let fullName = [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
                                
                                onAppleSignIn(idTokenString, email, fullName)
                            }
                        case .failure(let error):
                            print("Apple Sign In failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.body.bold())
                            Text("Continue with Email")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 16)
                
                Text("By continuing, you're agreeing to Lucid's Terms & Privacy Policy")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 30)
        }
    }
}



// MARK: - EmailLoginStep
private struct EmailLoginStep: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var emailStatus: EmailCheckStatus
    @Binding var authMode: OnboardingAuthMode
    
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if authMode != .undecided {
                AccountModeBadge(authMode: authMode)
                    .padding(.bottom, 4)
            }

            // Instruction copy
            Text(instructionText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 4)
                .fixedSize(horizontal: false, vertical: true)

            // Email Field
            
            // Email Field - Fully Reworked to block accent color hijacking
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.8))
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.white.opacity(0.4))
                    
                    ZStack(alignment: .leading) {
                        // Manual placeholder layer: untouched by system accent tints
                        if email.isEmpty {
                            Text("example@apple.com")
                                .font(.system(size: 16, design: .default)) // Matches standard TextField size
                                .foregroundStyle(Color.white.opacity(0.25)) // Pure muted grey
                                .allowsHitTesting(false)
                                .tint(Color.white.opacity(0.25))
                        }
                        
                        // Clean, untinted interactive text input
                        TextField("", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                            .tint(Color.accentColor) // Keeps ONLY the blinking insertion cursor blue/accented
                            .onChange(of: email) { _, _ in
                                emailStatus = .unchecked
                                authMode = .undecided
                            }
                    }
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

            if emailStatus == .checking {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.accentColor)
                    Spacer()
                }
                .padding(.vertical, 20)
            }

            // Password Field
            if emailStatus == .present || emailStatus == .notPresent {
                VStack(alignment: .leading, spacing: 8) {
                    Text(emailStatus == .present ? "Password" : "Create Password")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(Color.white.opacity(0.4))
                        
                        if isPasswordVisible {
                            TextField(emailStatus == .present ? "Enter your password" : "At least 8 characters", text: $password)
                                .foregroundStyle(.white)
                        } else {
                            SecureField(emailStatus == .present ? "Enter your password" : "At least 8 characters", text: $password)
                                .foregroundStyle(.white)
                        }
                        
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
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
            }

            // Confirm Password Field (Create Only)
            if emailStatus == .notPresent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                    HStack {
                        Image(systemName: "lock.rotation")
                            .foregroundStyle(Color.white.opacity(0.4))
                        
                        if isConfirmPasswordVisible {
                            TextField("Re-enter password", text: $confirmPassword)
                                .foregroundStyle(.white)
                        } else {
                            SecureField("Re-enter password", text: $confirmPassword)
                                .foregroundStyle(.white)
                        }
                        
                        Button(action: { isConfirmPasswordVisible.toggle() }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
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
            }

            Text(helperCopy)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.55))
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
    }

    private var instructionText: String {
        switch emailStatus {
        case .unchecked:
            return "Let's start with your email"
        case .checking:
            return "Checking for your account..."
        case .present:
            return "Welcome back! Please enter your password to sign in."
        case .notPresent:
            return "Create a password to set up your new account."
        }
    }

    private var helperCopy: String {
        switch emailStatus {
        case .notPresent:
            return "" // to be removed
        case .present:
            return "" // to be removed
        default:
            return ""
        }
    }
}


// MARK: - AccountModeBadge
private struct AccountModeBadge: View {
    let authMode: OnboardingAuthMode

    var body: some View {
        Text(authMode == .login ? "Existing Account" : "New Account")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(authMode == .login ? Color.blue.opacity(0.25) : Color.accentColor.opacity(0.25))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(authMode == .login ? Color.blue.opacity(0.4) : Color.accentColor.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - PersonalDetailsStep
private struct PersonalDetailsStep: View {
    @Binding var name: String


    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What should we call you")
                .font(.subheadline)
                .foregroundStyle(Color.accent)
                .fixedSize(horizontal: false, vertical: true)

            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Name")
                
                HStack {
                    Image(systemName: "person")
                        .foregroundStyle(Color.white.opacity(0.4))
                    TextField("Your name", text: $name)
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
        }
        .padding(.top, 10)
    }

    private func fieldTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.white.opacity(0.8))
    }
}

// MARK: - EyePowerStep
private struct EyePowerStep: View {
    @Binding var left: Double
    @Binding var right: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add your eye power if you know it. We save it to make future reports and give better tips and recommendations")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.60))

            powerCard(title: "Left Eye", value: $left)
            powerCard(title: "Right Eye", value: $right)

            Button(action: {
                withAnimation {
                    left = 0.0
                    right = 0.0
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: (left == 0.0 && right == 0.0) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle((left == 0.0 && right == 0.0) ? Color.accentColor : Color.white.opacity(0.4))
                    Text("I do not know my eye power")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
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
}

// MARK: - ConditionsStep
private struct ConditionsStep: View {
    let eyeConditions: [String]
    let bodyConditions: [String]
    @Binding var selection: Set<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Pick any health details that apply, we save these for future reference and better recommendations")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)

                section(title: "Eye Conditions", conditions: eyeConditions)
                section(title: "General Health", conditions: bodyConditions)
            }
            .padding(.top, 10)
        }
    }

    private func section(title: String, conditions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            ConditionBubblesPicker(conditions: conditions, selection: $selection)
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

// MARK: - ConditionBubblesPicker
private struct ConditionBubblesPicker: View {
    let conditions: [String]
    @Binding var selection: Set<String>

    var body: some View {
        FlowLayout(tags: conditions) { tag in
            Text(tag)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selection.contains(tag) ? Color.accentColor : Color.white.opacity(0.08))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selection.contains(tag) ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
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

// MARK: - FlowLayout
private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    var tags: Data
    var content: (Data.Element) -> Content

    @State private var totalHeight = CGFloat.zero

    init(tags: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.tags = tags
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    func generateContent(in geo: GeometryProxy) -> some View {
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
                return Color.clear
            }
        )
    }
}

// MARK: - Button Styles
private struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.8))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
