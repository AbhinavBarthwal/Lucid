import Foundation

@MainActor
class EyeTestDataManager {
    static let shared = EyeTestDataManager()
    
    func saveEyeTestScore(score: Double, eye: String) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = CTestSession(score: score, eye: eye)
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            
            // Call the new append function
            Task {
                await SupabaseManager.shared.appendCTestScore(score: score, eye: eye)
            }
            
            RecommendationEngine.shared.generateRecommendations()
        } catch {
            print("❌ Eye Test Save failed: \(error)")
        }
    }


    func fetchRecentEyeTestSessions(for eye: String? = nil, limit: Int = 6) -> [CTestSession] {
        let sessions = SwiftDataManager.shared.fetchCTestSessions()
        let filtered = sessions.filter { session in
            eye == nil || session.eyeTested == eye
        }
        let sorted = filtered.sorted { $0.startingTime > $1.startingTime }
        return Array(sorted.prefix(limit))
    }
}

