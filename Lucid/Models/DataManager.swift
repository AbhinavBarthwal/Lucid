import Foundation

struct LocalDatabase: Codable {
    var user: User
    var exerciseSessions: [ExerciseSession] = []
    var eyeTestSessions: [CTestSession] = []
    var osdiSessions: [OSDISession] = []
}

@MainActor
class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    private let fileURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("local_database.json")
    }()
    
    private var cachedDatabase: LocalDatabase?
    
    // API compatibility property: returns self so other code calling context.save() compiles
    var context: SwiftDataManager { self }
    
    private init() {
        loadDatabase()
    }
    
    private func loadDatabase() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let defaultUser = User(name: "", age: 0)
            self.cachedDatabase = LocalDatabase(user: defaultUser)
            saveInternal()
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let db = try decoder.decode(LocalDatabase.self, from: data)
            self.cachedDatabase = db
        } catch {
            print("❌ Failed to load local JSON database: \(error)")
            let defaultUser = User(name: "", age: 0)
            self.cachedDatabase = LocalDatabase(user: defaultUser)
            saveInternal()
        }
    }
    
    private func saveInternal() {
        guard let db = cachedDatabase else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(db)
            try data.write(to: fileURL, options: .atomic)
            print("💾 Database saved to \(fileURL.lastPathComponent)")
        } catch {
            print("❌ Failed to save local JSON database: \(error)")
        }
    }
    
    func save() throws {
        saveInternal()
    }
    
    func getOrCreateUser() -> User {
        if let user = cachedDatabase?.user {
            return user
        }
        let newUser = User(name: "", age: 0)
        cachedDatabase = LocalDatabase(user: newUser)
        saveInternal()
        return newUser
    }
    
    func insert(_ session: ExerciseSession) {
        cachedDatabase?.exerciseSessions.append(session)
        saveInternal()
        UserDefaults.standard.set(true, forKey: "summary.dailyExercises.lastLaunchSuccess")
    }
    
    func insert(_ session: CTestSession) {
        cachedDatabase?.eyeTestSessions.append(session)
        saveInternal()
    }
    
    func insert(_ session: OSDISession) {
        cachedDatabase?.osdiSessions.append(session)
        saveInternal()
    }
    
    func fetchExerciseSessions() -> [ExerciseSession] {
        return cachedDatabase?.exerciseSessions ?? []
    }
    
    func fetchCTestSessions() -> [CTestSession] {
        return cachedDatabase?.eyeTestSessions ?? []
    }
    
    func fetchOSDISessions() -> [OSDISession] {
        return cachedDatabase?.osdiSessions ?? []
    }
    
    func clearAllSessions() {
        cachedDatabase?.exerciseSessions.removeAll()
        cachedDatabase?.eyeTestSessions.removeAll()
        cachedDatabase?.osdiSessions.removeAll()
        saveInternal()
    }
    
    func clearTestSessions() {
        cachedDatabase?.eyeTestSessions.removeAll()
        cachedDatabase?.osdiSessions.removeAll()
        saveInternal()
    }
    
    func importOSDISessions(_ sessions: [OSDISession]) {
        guard var db = cachedDatabase else { return }
        for session in sessions {
            if !db.osdiSessions.contains(where: { $0.id == session.id }) {
                db.osdiSessions.append(session)
            }
        }
        cachedDatabase = db
        saveInternal()
    }
    
    func importCTestSessions(_ sessions: [CTestSession]) {
        guard var db = cachedDatabase else { return }
        for session in sessions {
            if !db.eyeTestSessions.contains(where: { $0.id == session.id }) {
                db.eyeTestSessions.append(session)
            }
        }
        cachedDatabase = db
        saveInternal()
    }
}
