import Foundation

@MainActor
class OSDIDataManager {
    static let shared = OSDIDataManager()
    
    func saveOSDIScore(score: Double, severity: String) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = OSDISession(score: score, severity: severity)
        newSession.user = user
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            
            // Call the new append function
            Task {
                await SupabaseManager.shared.appendOSDIScore(score: score, severity: severity)
            }
            
            RecommendationEngine.shared.generateRecommendations()
        } catch {
            print("❌ OSDI Save failed: \(error)")
        }
    }
    
    func fetchRecentOSDISessions(limit: Int = 5) -> [OSDISession] {
        let sessions = SwiftDataManager.shared.fetchOSDISessions()
        let sorted = sessions.sorted { $0.date > $1.date }
        return Array(sorted.prefix(limit))
    }
}
