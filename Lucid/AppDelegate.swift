//
//  AppDelegate.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 1/12/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let appearance = UINavigationBarAppearance()

  
        let expandedFont = UIFont                                                                        .systemFont(ofSize: 20, weight: .bold, width: .expanded)
        let largeExpandedFont = UIFont.systemFont(ofSize: 34, weight: .bold, width: .expanded)


        appearance.titleTextAttributes = [
            .font: expandedFont,
            .foregroundColor: UIColor.white
        ]
        
        appearance.largeTitleTextAttributes = [
            .font: largeExpandedFont,
            .foregroundColor: UIColor.white
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


@IBDesignable
class ExpandedLabel: UILabel {
    @IBInspectable var isExpanded: Bool = true {
        didSet {
            updateFont()
        }
    }

    private func updateFont() {
        self.font = .systemFont(ofSize: self.font.pointSize,
                                 weight: .medium,
                                 width: .expanded)
    }
    
    override func prepareForInterfaceBuilder() {
        updateFont()
    }
}
