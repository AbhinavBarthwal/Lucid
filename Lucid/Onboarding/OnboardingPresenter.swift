import UIKit
import Security
import SwiftUI
import AVFoundation
import Speech
import UserNotifications

enum OnboardingGate {
    static let hasCompletedKey = "hasCompletedLoginOnboarding"
    
    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: hasCompletedKey)
    }
    
    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: hasCompletedKey)
    }
}

final class CredentialStore {
    static let shared = CredentialStore()

    private let service = "com.lucid.saved-password"

    private init() {}

    func hasPassword(for email: String) -> Bool {
        password(for: email) != nil
    }

    func password(for email: String) -> String? {
        let normalizedEmail = normalize(email)
        guard !normalizedEmail.isEmpty else { return nil }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: normalizedEmail,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func verify(password candidate: String, for email: String) -> Bool {
        password(for: email) == candidate
    }

    @discardableResult
    func save(password: String, for email: String) -> Bool {
        let normalizedEmail = normalize(email)
        guard !normalizedEmail.isEmpty, !password.isEmpty else { return false }

        let data = Data(password.utf8)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: normalizedEmail,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]

        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        attributes[kSecAttrSynchronizable as String] = kCFBooleanTrue

        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

@MainActor
final class OnboardingPresenter {
    private static var isPresenting = false
    private static var activeTestsCoordinator: MandatoryTestsCoordinator?
    private static let hostingIdentifier = "Lucid.OnboardingHosting"
    
    static func presentIfNeeded(on window: UIWindow?) {
        guard shouldPresent, let window, let root = window.rootViewController else { return }
        guard !isPresenting else { return }
        isPresenting = true
        
        let topVC = topViewController(from: root)
        if topVC.restorationIdentifier == hostingIdentifier || topVC is OSDIViewController || topVC is LandoltCViewController {
            isPresenting = false
            return
        }
        
        let user = SwiftDataManager.shared.getOrCreateUser()
        let hasCompletedDetails = !(user.email ?? "").isEmpty
        
        if hasCompletedDetails {
            presentMandatoryTestsAlert(on: topVC, window: window) {
                requestAllPermissions {
                    let coordinator = MandatoryTestsCoordinator(presenter: topVC)
                    activeTestsCoordinator = coordinator
                    coordinator.start {
                        activeTestsCoordinator = nil
                        showSettingUpAndFinish(window: window, presenter: topVC)
                    }
                }
            }
        } else {
            let hosting = UIHostingController(rootView: AnyView(EmptyView()))
            hosting.restorationIdentifier = hostingIdentifier
            hosting.rootView = AnyView(OnboardingFlowView { draft in
                Task { @MainActor in
                    await handleOnboardingSubmitted(draft: draft, window: window, presenter: hosting)
                }
            })
            
            hosting.modalPresentationStyle = .fullScreen
            hosting.modalTransitionStyle = .crossDissolve
            
            topVC.present(hosting, animated: true)
        }
    }
    
    private static var shouldPresent: Bool {
        OnboardingGate.shouldShow
    }
    
    private static func handleOnboardingSubmitted(draft: OnboardingDraft, window: UIWindow, presenter: UIViewController) async {
        await saveDraft(draft)
        
        let user = SwiftDataManager.shared.getOrCreateUser()
        let hasOSDI = !user.osdiSessions.isEmpty
        let hasCTest = !user.eyeTestSessions.isEmpty
        
        if hasOSDI && hasCTest {
            print("🚀 Recurring user detected with full test history. Bypassing mandatory tests.")
            showSettingUpAndFinish(window: window, presenter: presenter)
        } else {
            presentMandatoryTestsAlert(on: presenter, window: window) {
                requestAllPermissions {
                    let coordinator = MandatoryTestsCoordinator(presenter: presenter)
                    activeTestsCoordinator = coordinator
                    coordinator.start {
                        activeTestsCoordinator = nil
                        showSettingUpAndFinish(window: window, presenter: presenter)
                    }
                }
            }
        }
    }
    
    private static func requestAllPermissions(completion: @escaping () -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { _ in
                    SFSpeechRecognizer.requestAuthorization { _ in
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                            if let error {
                                print("Lucid: Notification permission error: \(error)")
                            }
                            DispatchQueue.main.async {
                                completion()
                            }
                        }
                    }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { _ in
                    SFSpeechRecognizer.requestAuthorization { _ in
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                            if let error {
                                print("Lucid: Notification permission error: \(error)")
                            }
                            DispatchQueue.main.async {
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }

    private static func saveDraft(_ draft: OnboardingDraft) async {
        let user = SwiftDataManager.shared.getOrCreateUser()
        
        // Attempt to fetch existing profile from Supabase first
        _ = await SupabaseManager.shared.fetchAndApplyUser(byEmail: draft.normalizedEmail, to: user)
        
        user.email = draft.normalizedEmail
        if !draft.password.isEmpty { user.password = draft.password }
        
        // If draft has name, it's a new signup or the user went through details, overwrite with draft
        if !draft.trimmedName.isEmpty {
            user.name = draft.trimmedName
            user.dateOfBirth = draft.dateOfBirth
            user.age = computeAge(from: draft.dateOfBirth)
            user.gender = draft.gender.isEmpty ? "Prefer not to say" : draft.gender
            user.leftEyePower = Double(draft.leftEyePower.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            user.rightEyePower = Double(draft.rightEyePower.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            user.previousConditions = draft.cleanedConditions
        }

        if let email = user.email, !email.isEmpty, !draft.password.isEmpty {
            let didSavePassword = CredentialStore.shared.save(password: draft.password, for: email)
            if !didSavePassword {
                print("Onboarding password save failed for \(email)")
            }
        }
        
        do {
            try SwiftDataManager.shared.context.save()
            await SupabaseManager.shared.syncUser(user)
        } catch {
            // Non-blocking: still allow the user into the app.
            print("Onboarding save failed: \(error)")
        }
    }
    
    private static func presentMandatoryTestsAlert(on presenter: UIViewController, window: UIWindow, start: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Let's check your vision!",
            message: "We'll start with a couple of quick, easy tests to customize Lucid for your eyes. Note: The C Test will require you to speak the numbers out loud.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Let's Start!", style: .default) { _ in
            DispatchQueue.main.async {
                start()
            }
        })
        alert.addAction(UIAlertAction(title: "Skip for Now", style: .cancel) { _ in
            DispatchQueue.main.async {
                showSettingUpAndFinish(window: window, presenter: presenter)
            }
        })
        presenter.present(alert, animated: true)
    }
    
    private static func showSettingUpAndFinish(window: UIWindow, presenter: UIViewController) {
        if let hosting = presenter as? UIHostingController<AnyView> {
            hosting.rootView = AnyView(SettingThingsUpView())
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            finalize(window: window, presenter: presenter)
        }
    }
    
    private static func finalize(window: UIWindow, presenter: UIViewController) {
        OnboardingGate.markCompleted()
        
        blurTransition(window: window) {
            presenter.dismiss(animated: false) {
                isPresenting = false
            }
        }
    }
    
    private static func blurTransition(window: UIWindow, completion: @escaping () -> Void) {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
        blurView.frame = window.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = 0
        window.addSubview(blurView)
        
        UIView.animate(withDuration: 0.20, animations: {
            blurView.alpha = 1
        }, completion: { _ in
            completion()
            UIView.animate(withDuration: 0.35, delay: 0.05, options: [.curveEaseOut], animations: {
                blurView.alpha = 0
            }, completion: { _ in
                blurView.removeFromSuperview()
            })
        })
    }
    
    private static func computeAge(from dateOfBirth: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return max(0, components.year ?? 0)
    }
    
    private static func topViewController(from root: UIViewController) -> UIViewController {
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        
        if let nav = current as? UINavigationController {
            return nav.visibleViewController ?? nav
        }
        if let tab = current as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        
        return current
    }
}

@MainActor
private final class MandatoryTestsCoordinator {
    private weak var presenter: UIViewController?
    private let storyboard = UIStoryboard(name: "Main", bundle: nil)
    private var navigationController: UINavigationController?
    private var onFinished: (() -> Void)?
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func start(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        
        guard let osdiVC = storyboard.instantiateViewController(withIdentifier: "OSDIViewController") as? OSDIViewController else {
            assertionFailure("OSDIViewController storyboardIdentifier is missing or mismatched.")
            onFinished()
            return
        }
        
        osdiVC.shouldShowResultUI = false
        osdiVC.onTestCompleted = { [weak self] _, _ in
            self?.showLandoltC()
        }
        osdiVC.navigationItem.hidesBackButton = true
        
        let nav = UINavigationController(rootViewController: osdiVC)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        nav.isModalInPresentation = true
        nav.interactivePopGestureRecognizer?.isEnabled = false
        
        navigationController = nav
        presenter?.present(nav, animated: true)
    }
    
    private func showLandoltC() {
        guard let nav = navigationController else { return }

        // Show a friendly transition screen for 2.5s before pushing LandoltC
        let transitionVC = TestTransitionViewController()
        transitionVC.navigationItem.hidesBackButton = true
        nav.setNavigationBarHidden(true, animated: false)
        nav.pushViewController(transitionVC, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self, weak nav] in
            guard let self, let nav else { return }

            guard let landoltVC = storyboard.instantiateViewController(withIdentifier: "LandoltCViewController") as? LandoltCViewController else {
                assertionFailure("LandoltCViewController storyboardIdentifier is missing or mismatched.")
                self.finish()
                return
            }

            landoltVC.shouldShowCompletionSummary = false
            landoltVC.onTestCompleted = { [weak self] in
                self?.finish()
            }
            landoltVC.navigationItem.hidesBackButton = true

            nav.pushViewController(landoltVC, animated: true)
        }
    }
    
    private func finish() {
        guard let nav = navigationController else {
            onFinished?()
            return
        }
        
        nav.dismiss(animated: true) { [weak self] in
            self?.onFinished?()
        }
    }
}

private struct SettingThingsUpView: View {
    @State private var rotateDegree = 0.0
    
    var body: some View {
        ZStack {
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
            
            VStack(spacing: 28) {
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
                    Text("Setting things up for you")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Configuring workspace...")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - OSDI → C-Test Transition Screen

final class TestTransitionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let emoji = UILabel()


        let title = UILabel()
        title.text = "Nice work!"
        title.font = .systemFont(ofSize: 30, weight: .bold)
        title.textColor = .white
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "OSDI done!\nNow let's check how sharp your eyes are with a quick C Test.\n\nYou will need to say the matching numbers out loud!"
        subtitle.font = .systemFont(ofSize: 17, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [ title, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36)
        ])

        stack.alpha = 0
        UIView.animate(withDuration: 0.5) { stack.alpha = 1 }
    }
}
