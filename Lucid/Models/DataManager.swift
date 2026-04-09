import Foundation
import SwiftData

class SwiftDataManager {
    
    static let shared = SwiftDataManager()
    
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    
    private init() {
        let schema = Schema([User.self, ExerciseSession.self, CTestSession.self, OSDISession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData init error: \(error)")
        }
    }

    // MARK: - Current User (FINAL CLEAN VERSION)
    func getCurrentUser() -> User {
        
        let userID: String
        
        if let savedID = UserDefaults.standard.string(forKey: "loggedInUserID") {
            userID = savedID
        } else {
            userID = UUID().uuidString
            UserDefaults.standard.set(userID, forKey: "loggedInUserID")
            print("🆕 New user created:", userID)
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.authUserId == userID }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        
        // Create new user if not found
        let newUser = User(
            name: "Guest User",
            age: 20,
            authUserId: userID
        )
        
        context.insert(newUser)
        
        do {
            try context.save()
        } catch {
            print("❌ Failed to save user:", error)
        }
        
        return newUser
    }
}
