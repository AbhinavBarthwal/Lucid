import Foundation
import SwiftData

@MainActor
class SwiftDataManager {
    static let shared = SwiftDataManager()
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    
    private init() {
        let schema = Schema([User.self, ExerciseSession.self, EyeTestSession.self, OSDIResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    func getOrCreateUser() -> User {
        let descriptor = FetchDescriptor<User>()
        let users = (try? context.fetch(descriptor)) ?? []
        if let user = users.first { return user }
        
        let newUser = User(name: "Abhinav", age: 21)
        context.insert(newUser)
        return newUser
    }
}
