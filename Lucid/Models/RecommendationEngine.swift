import Foundation
import SwiftData

@MainActor
class RecommendationEngine {
    static let shared = RecommendationEngine()
    
    func generateRecommendations() {
        let user = SwiftDataManager.shared.getOrCreateUser()
        
        // 1. Explicitly empty the array before calculating new ones
        user.recommendedExercises.removeAll()
        print("🧹 Cleared old recommendations. Current array: \(user.recommendedExercises)")
        
        var newRecommendations: Set<String> = []
        
        // 2. Evaluate OSDI (Dry Eye) Mapping
        if let latestOSDI = user.osdiSessions.sorted(by: { $0.date > $1.date }).first {
            let osdiScore = latestOSDI.score
            
            if osdiScore <= 12 {
                // 0-12: Normal
                newRecommendations.insert("SmoothPursuit")
                newRecommendations.insert("Figure8")
            } else if osdiScore <= 32 {
                // 13-32: Mild to Moderate
                newRecommendations.insert("Blink")
                newRecommendations.insert("PeripheralAwareness")
            } else {
                // 33-100: Severe
                newRecommendations.insert("Blink")
                newRecommendations.insert("DigitalBreak")
            }
        }
        
        // 3. Evaluate Eye Test (C-Test) Mapping
        if let latestEyeTest = user.eyeTestSessions.sorted(by: { $0.startingTime > $1.startingTime }).first {
            let cTestScore = latestEyeTest.score
            
            if cTestScore <= 2 {
                // 0-2: Poor
                newRecommendations.insert("NearFar")
                newRecommendations.insert("SaccadicJump")
            } else if cTestScore <= 4 {
                // 3-4: Standard
                newRecommendations.insert("NearFar")
                newRecommendations.insert("SmoothPursuit")
            } else {
                // 5-6: Perfect
                newRecommendations.insert("SaccadicJump")
                newRecommendations.insert("Figure8")
            }
        }
        
        // 4. Fallbacks (If no tests have been taken yet)
        if newRecommendations.isEmpty {
            newRecommendations.insert("SmoothPursuit")
            newRecommendations.insert("Blink")
        }
        
        // 5. Update the user model with the newly generated array
        user.recommendedExercises = Array(newRecommendations)
        
        // 6. Print the updated array so you can verify it in the console
        print("🎯 New recommendations assigned: \(user.recommendedExercises)")
        
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Successfully saved context with recommendations: \(user.recommendedExercises)")
        } catch {
            print("❌ Failed to save recommendations: \(error)")
        }
    }
}
