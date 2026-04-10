// SceneDelegate.swift
import UIKit
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    

    lazy var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            ExerciseSession.self,
            CTestSession.self, OSDISession.self
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

        if let navigationController = window?.rootViewController as? UINavigationController,
           let rootVC = navigationController.viewControllers.first as? ExerciseCollectionViewController {
               
            rootVC.modelContext = sharedModelContainer.mainContext
        }
        
        
    }
    
}
