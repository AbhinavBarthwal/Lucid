import Foundation

@MainActor
class RecommendationEngine {
    static let shared = RecommendationEngine()
    
    func generateRecommendations() {
        let user = SwiftDataManager.shared.getOrCreateUser()
        
        // 1. Explicitly empty the array before calculating new ones
        user.recommendedExercises.removeAll()
        
        var newRecommendations: Set<String> = []
        
        // 2. Evaluate OSDI (Dry Eye) Mapping
        if let latestOSDI = user.osdiSessions.sorted(by: { $0.date > $1.date }).first {
            let osdiScore = latestOSDI.score
            if osdiScore <= 12 {
                newRecommendations.insert("SmoothPursuit")
                newRecommendations.insert("Figure8")
            } else if osdiScore <= 32 {
                newRecommendations.insert("Blink")
                newRecommendations.insert("PeripheralAwareness")
            } else {
                newRecommendations.insert("Blink")
                newRecommendations.insert("NearFar")
            }
        }
        
        // 3. Evaluate Eye Test (C-Test) Mapping
        if let latestEyeTest = user.eyeTestSessions.sorted(by: { $0.startingTime > $1.startingTime }).first {
            let cTestScore = latestEyeTest.score
            if cTestScore <= 2 {
                newRecommendations.insert("NearFar")
                newRecommendations.insert("SaccadicJump")
            } else if cTestScore <= 4 {
                newRecommendations.insert("NearFar")
                newRecommendations.insert("SmoothPursuit")
            } else {
                newRecommendations.insert("SaccadicJump")
                newRecommendations.insert("Figure8")
            }
        }
        
        // 4. Fallbacks
        if newRecommendations.isEmpty {
            newRecommendations.insert("SmoothPursuit")
            newRecommendations.insert("Blink")
        }
        
        // 5. Update user model
        user.recommendedExercises = Array(newRecommendations)
        
        let exerciseTimes: [String: Int] = [
            "SmoothPursuit": 135,
            "SaccadicJump": 70,
            "PencilPushup": 60,
            "Figure8": 90,
            "Blink": 90,
            "PeripheralAwareness": 75,
            "NearFar": 60
        ]
        let sumOfRecommendedExercises = newRecommendations.compactMap { exerciseTimes[$0] }.reduce(0, +)
        user.dailyExerciseGoal = sumOfRecommendedExercises
        
        // 6. Save and Sync
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Locally saved recommendations: \(user.recommendedExercises)")
            
            // Sync to Supabase
            Task {
                await SupabaseManager.shared.syncUser(user)
            }
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
}
