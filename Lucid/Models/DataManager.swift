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
        
        // 1. Mark the exercise as completed in daily completed list
        let exerciseId = getExerciseId(from: session.type)
        markExerciseCompletedInUserDefaults(exerciseId: exerciseId)
        
        // 2. Update user's streak status
        let user = getOrCreateUser()
        user.updateTodayStreakStatus()
        
        // 3. Evaluate and unlock badges
        ProgressManager.shared.evaluateAndUnlock()
        
        // 4. Reschedule exercise reminders
        NotificationManager.shared.scheduleExerciseReminders()
    }
    
    private func getExerciseId(from sessionType: String) -> String {
        switch sessionType {
        case "SaccadicJumps":
            return "SaccadicJump"
        default:
            return sessionType
        }
    }
    
    private func markExerciseCompletedInUserDefaults(exerciseId: String) {
        let stamp = dayStamp()
        let existing = UserDefaults.standard.string(forKey: "summary.dailyExercises.dayStamp")
        var completed: [String] = []
        if existing == stamp {
            completed = UserDefaults.standard.stringArray(forKey: "summary.dailyExercises.completedIds") ?? []
        } else {
            UserDefaults.standard.set(stamp, forKey: "summary.dailyExercises.dayStamp")
            UserDefaults.standard.removeObject(forKey: "summary.dailyExercises.lastLaunchExerciseId")
            UserDefaults.standard.removeObject(forKey: "summary.dailyExercises.lastLaunchCompletedSeconds")
            let user = getOrCreateUser()
            user.checkDailyReset()
        }
        if !completed.contains(exerciseId) {
            completed.append(exerciseId)
            UserDefaults.standard.set(completed, forKey: "summary.dailyExercises.completedIds")
        }
    }
    
    private func dayStamp(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
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
