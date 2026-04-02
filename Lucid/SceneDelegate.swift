// SceneDelegate.swift
import UIKit
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    // Create the container (do this once)
    lazy var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            ExerciseSession.self,
            EyeTestSession.self,
            OSDIResult.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        // Inject the context into the ROOT view controller
        if let navigationController = window?.rootViewController as? UINavigationController,
           let rootVC = navigationController.viewControllers.first as? ExerciseTableViewController {
               
            rootVC.modelContext = sharedModelContainer.mainContext
        }
        
        ExerciseDataManager.shared.updateDailyGoal(newGoalInSeconds: 180)
    }
    
}
