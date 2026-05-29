// SceneDelegate.swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var guidanceOverlayRetryWorkItem: DispatchWorkItem?
    

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        Task { @MainActor in
            OnboardingPresenter.presentIfNeeded(on: self.window)
            self.scheduleGuidanceOverlayCheck()
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        Task { @MainActor in
            OnboardingPresenter.presentIfNeeded(on: self.window)
            self.scheduleGuidanceOverlayCheck()
            
            if !OnboardingGate.shouldShow {
                NotificationManager.shared.scheduleExerciseReminders()
            }
        }
    }

    private func scheduleGuidanceOverlayCheck(after delay: TimeInterval = 0.8) {
        guidanceOverlayRetryWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.presentGuidanceOverlayIfPossible()
        }
        guidanceOverlayRetryWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    @MainActor
    private func presentGuidanceOverlayIfPossible() {
        guard UIApplication.shared.applicationState == .active else { return }
        guard !OnboardingGate.shouldShow else {
            scheduleGuidanceOverlayCheck(after: 1.0)
            return
        }
        guard !UserDefaults.standard.bool(forKey: GuidanceOverlayViewController.lastShownBuildKey) else { return }
        guard let rootViewController = window?.rootViewController else { return }
        guard GuidanceOverlayViewController.canPresent(from: rootViewController) else {
            scheduleGuidanceOverlayCheck(after: 1.0)
            return
        }

        let presenter = topViewController(from: rootViewController)
        guard !(presenter is GuidanceOverlayViewController) else { return }
        guard presenter.presentedViewController == nil else {
            scheduleGuidanceOverlayCheck(after: 1.0)
            return
        }

        let overlayViewController = GuidanceOverlayViewController()
        overlayViewController.modalPresentationStyle = .overFullScreen
        overlayViewController.modalTransitionStyle = .crossDissolve
        presenter.present(overlayViewController, animated: true)
    }

    private func topViewController(from root: UIViewController) -> UIViewController {
        if let navigationController = root as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController ?? navigationController)
        }
        if let tabBarController = root as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController ?? tabBarController)
        }
        if let presentedViewController = root.presentedViewController {
            return topViewController(from: presentedViewController)
        }
        return root
    }
}
