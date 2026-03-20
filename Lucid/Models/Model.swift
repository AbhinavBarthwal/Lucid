import Foundation
import SwiftData
import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var createdAt: Date
    var dailyExerciseGoal: Int 
    
    @Relationship(deleteRule: .cascade, inverse: \EyeTestSession.user) var eyeTestSessions: [EyeTestSession] = []
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSession.user) var exerciseSessions: [ExerciseSession] = []

    init(name: String, age: Int, dailyGoal: Int = 900) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.createdAt = Date()
        self.dailyExerciseGoal = dailyGoal
    }


    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dayTotals = Dictionary(grouping: exerciseSessions) {
            calendar.startOfDay(for: $0.startingDate)
        }.mapValues { sessions in
            sessions.reduce(0) { $0 + $1.durationSeconds }
        }
        
        var streak = 0
        var checkDate = today
        
        // If today isn't done, start checking from yesterday
        if (dayTotals[today] ?? 0) < dailyExerciseGoal {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        }
        
        while let total = dayTotals[checkDate], total >= dailyExerciseGoal {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
    }
}


enum EyeDirection: String, CaseIterable, Codable {
    case top, topRight, right, bottomRight, bottom, bottomLeft, left, topLeft
}

// MARK: - Exercise Sessions
@Model
final class ExerciseSession {
    var id: UUID
    var startingDate: Date
    var startingTime: Date
    var endingTime: Date
    var type: String // "Blink", "PencilPushup", "SmoothPursuit", "Figure8", "NearFar"
    var durationSeconds: Int
    
   
    var accuracyScore: Int?
    var averageBlinkIntensity: Float? // Derived from blinkTraining
    var errorCount: Int? // Tracking lapses in focus or incorrect blinks
    var headMovementDegrees: Float?  // Average head rotation during exercise -> smooth pursuits, saccadic jumps, figure 8, pencil pushups
    
    // Using String keys because SwiftData dictionaries require String or Int keys
    var directionErrors: [String: Double]? // Errors in a particular direction -> smooth pursuits, saccadic jumps
    
    var errorsPerSession: [Int]? // Number errors which occurs in each phase/rep -> pencilPushups, figure 8, near far focus, blink
    var nearPointOfConvergence: Float? // faceTransform -> At what point user couldnt see the dot -> pencil pushups, near far focus
    var paceScore: Double? // Time taken by user to complete 1 rep of exercise/ full exercise -> pencil pushups
    
    var rightEyeBlinks: Int? // blinks by right eye -> Blink training
    var leftEyeBlinks: Int? // blinks by left eye -> Blink training
    var responsivenessScore: Double? // blink training
    
    var user: User?

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

// MARK: - Vision Tests & Surveys
@Model
final class EyeTestSession {
    var id: UUID
    var startingTime: Date
    var endingTime : Date
    var score: Double // Landolt C scale reached
    var eyeTested: String // "Left", "Right", or "Both"
    
    var user: User?

    init(score: Double, eye: String) {
        self.id = UUID()
        self.startingTime = Date()
        self.endingTime = Date()
        self.score = score
        self.eyeTested = eye
    }
}

@Model
final class OSDIResult {
    var id: UUID
    var date: Date
    var rawScore: Double
    var severity: String // "Normal", "Mild", "Moderate", "Severe"
    
    var user: User?

    init(score: Double, severity: String) {
        self.id = UUID()
        self.date = Date()
        self.rawScore = score
        self.severity = severity
    }
}
