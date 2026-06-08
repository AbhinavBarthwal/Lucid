import Foundation

enum EyeDirection: String, CaseIterable, Codable {
    case top, topRight, right, bottomRight, bottom, bottomLeft, left, topLeft
}

struct StreakDay: Codable {
    var date: Date
    var isCompleted: Bool
}

// MARK: - User
final class User: Codable {
    var id: UUID
    var name: String
    var age: Int
    var email: String?
    var password: String?
    var dateOfBirth: Date?
    var gender: String?
    var leftEyePower: Double
    var rightEyePower: Double
    var createdAt: Date
    var dailyExerciseGoal: Int 
    var recommendedExercises: [String] = []
    var previousConditions: [String] = []
    private var streakData: [StreakDay]?
    
    var streak: [StreakDay] {
        get { streakData ?? [] }
        set { streakData = newValue }
    }
    
    init(name: String, age: Int, dailyGoal: Int = 150) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.email = nil
        self.password = nil
        self.dateOfBirth = nil
        self.gender = nil
        self.leftEyePower = 0
        self.rightEyePower = 0
        self.createdAt = Date()
        self.dailyExerciseGoal = dailyGoal
        self.streakData = []
    }

    var exerciseSessions: [ExerciseSession] {
        SwiftDataManager.shared.fetchExerciseSessions()
    }
    
    var eyeTestSessions: [CTestSession] {
        SwiftDataManager.shared.fetchCTestSessions()
    }
    
    var osdiSessions: [OSDISession] {
        SwiftDataManager.shared.fetchOSDISessions()
    }

    func calculateDailyGoalFromRecommendations() -> Int {
        let exerciseTimes: [String: Int] = [
            "SmoothPursuit": 135,
            "SaccadicJump": 70,
            "PencilPushup": 60,
            "Figure8": 90,
            "Blink": 90,
            "NearFar": 110
        ]
        let currentRecs = recommendedExercises.isEmpty ? ["SmoothPursuit", "Blink"] : recommendedExercises
        let sum = currentRecs.compactMap { exerciseTimes[$0] }.reduce(0, +)
        let minutes = Int(ceil(Double(sum) / 60.0))
        return minutes * 60
    }

    func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if streakData == nil {
            streakData = []
        }
        
        if !streak.contains(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            self.dailyExerciseGoal = calculateDailyGoalFromRecommendations()
            
            let completedSeconds = getTotalSeconds(for: today)
            let isCompleted = (completedSeconds / 60) >= (dailyExerciseGoal / 60)
            self.streak.append(StreakDay(date: today, isCompleted: isCompleted))
            self.streak.sort(by: { $0.date < $1.date })
            
            try? SwiftDataManager.shared.context.save()
        }
    }

    func updateTodayStreakStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        checkDailyReset()
        
        let completedSeconds = getTotalSeconds(for: today)
        let isCompleted = (completedSeconds / 60) >= (dailyExerciseGoal / 60)
        
        if let index = streak.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            streak[index].isCompleted = isCompleted
        } else {
            streak.append(StreakDay(date: today, isCompleted: isCompleted))
        }
        
        try? SwiftDataManager.shared.context.save()
    }

    func getTotalSeconds(for date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let dailySessions = exerciseSessions.filter {
            $0.startingDate >= start && $0.startingDate < end
        }
        return dailySessions.reduce(0) { $0 + $1.durationSeconds }
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedStreak = streak.sorted(by: { $0.date > $1.date })
        
        var count = 0
        var checkDate = today
        
        let todayEntry = sortedStreak.first(where: { calendar.isDate($0.date, inSameDayAs: today) })
        let todayCompleted = todayEntry?.isCompleted ?? false
        
        if !todayCompleted {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDate = yesterday
        }
        
        while true {
            let entry = sortedStreak.first(where: { calendar.isDate($0.date, inSameDayAs: checkDate) })
            if let entry = entry, entry.isCompleted {
                count += 1
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDate
            } else {
                break
            }
        }
        return count
    }
}

// MARK: - ExerciseSession
final class ExerciseSession: Codable {
    var id: UUID
    var startingDate: Date
    var startingTime: Date
    var endingTime: Date
    var type: String // "Blink", "PencilPushup", "SmoothPursuit", "Figure8", "NearFar"
    var durationSeconds: Int
    
    var accuracyScore: Int?
    var averageBlinkIntensity: Float?
    var errorCount: Int?
    var headMovementDegrees: Float?
    var directionErrors: [String: Double]?
    var errorsPerSession: [Int]?
    var nearPointOfConvergence: Float?
    var paceScore: Double?
    var rightEyeBlinks: Int?
    var leftEyeBlinks: Int?
    var responsivenessScore: Double?
    
    var user: User? {
        get { SwiftDataManager.shared.getOrCreateUser() }
        set { }
    }

    init(type: String, duration: Int, accuracy: Int? = nil, intensity: Float? = nil, errors: Int? = 0) {
        self.id = UUID()
        self.startingDate = Date()
        self.startingTime = Date()
        self.endingTime = Date()
        self.type = type
        self.durationSeconds = duration
        self.accuracyScore = accuracy
        self.averageBlinkIntensity = intensity
        self.errorCount = errors
    }
}

// MARK: - CTestSession
final class CTestSession: Codable {
    var id: UUID
    var startingTime: Date
    var endingTime: Date
    var score: Double
    var eyeTested: String // "Left", "Right", or "Both"
    
    var user: User? {
        get { SwiftDataManager.shared.getOrCreateUser() }
        set { }
    }

    init(score: Double, eye: String) {
        self.id = UUID()
        self.startingTime = Date()
        self.endingTime = Date()
        self.score = score
        self.eyeTested = eye
    }
}

// MARK: - OSDISession
final class OSDISession: Codable {
    var id: UUID
    var date: Date
    var score: Double
    var severity: String // "Normal", "Mild", "Moderate", "Severe"
    
    var user: User? {
        get { SwiftDataManager.shared.getOrCreateUser() }
        set { }
    }

    init(score: Double, severity: String) {
        self.id = UUID()
        self.date = Date()
        self.score = score
        self.severity = severity
    }
}
