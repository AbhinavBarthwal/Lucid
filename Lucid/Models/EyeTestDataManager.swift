//
//  EyeTestDataManager.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 4/6/26.
//

import Foundation
import SwiftData

@MainActor
class EyeTestDataManager {
    static let shared = EyeTestDataManager()
    
    func saveEyeTestScore(score: Double, eye: String) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = CTestSession(score: score, eye: eye)
        
        newSession.user = user
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Saved Eye Test Score: \(score) (\(eye) Eye) for \(user.name)")
            RecommendationEngine.shared.generateRecommendations()
        } catch {
            print("❌ Eye Test Save failed: \(error)")
        }
    }
}
