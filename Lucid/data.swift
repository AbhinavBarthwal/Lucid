import Foundation
import SwiftData

@Model
final class MedicalProfile {
    
    var gender: String?
    
    var leftEyePower: Double?
    var rightEyePower: Double?
    
    var previousConditions: [String]
    
    init(
        gender: String? = nil,
        leftEyePower: Double? = nil,
        rightEyePower: Double? = nil,
        previousConditions: [String] = []
    ) {
        self.gender = gender
        self.leftEyePower = leftEyePower
        self.rightEyePower = rightEyePower
        self.previousConditions = previousConditions
    }
}

@Model
final class NotificationSettings {
    
    var remindersEnabled: Bool
    var reminderTime: Date?
    
    var exerciseReminders: Bool
    var eyeTestReminders: Bool
    
    init(
        remindersEnabled: Bool = true,
        reminderTime: Date? = nil,
        exerciseReminders: Bool = true,
        eyeTestReminders: Bool = true
    ) {
        self.remindersEnabled = remindersEnabled
        self.reminderTime = reminderTime
        self.exerciseReminders = exerciseReminders
        self.eyeTestReminders = eyeTestReminders
    }
}

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var authUserId: String
    var name: String
    var age: Int
    var createdAt: Date
<<<<<<< Updated upstream:Lucid/data.swift
<<<<<<< Updated upstream:Lucid/data.swift
    
    @Relationship
    var medicalProfile: MedicalProfile
    
    var notifications: NotificationSettings = NotificationSettings()
    
    @Relationship(deleteRule: .cascade, inverse: \EyeTestSession.user) var eyeTestSessions: [EyeTestSession] = []
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSession.user) var exerciseSessions: [ExerciseSession] = []

    init(name: String, age: Int) {
=======
    var dailyExerciseGoal: Int
    
=======
    var dailyExerciseGoal: Int
    
>>>>>>> Stashed changes:Lucid/Models/Model.swift
    var leftEyePower: Double?
    var rightEyePower: Double?
    var gender: String?
    var conditions: [String]?
    
    @Relationship(deleteRule: .cascade, inverse: \CTestSession.user)
    var eyeTestSessions: [CTestSession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSession.user)
    var exerciseSessions: [ExerciseSession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \OSDISession.user)
    var osdiSessions: [OSDISession] = []

    init(name: String, age: Int, authUserId: String, dailyGoal: Int = 900) {
<<<<<<< Updated upstream:Lucid/data.swift
>>>>>>> Stashed changes:Lucid/Models/Model.swift
=======
>>>>>>> Stashed changes:Lucid/Models/Model.swift
        self.id = UUID()
        self.authUserId = authUserId
        self.name = name
        self.age = age
        self.createdAt = Date()
<<<<<<< Updated upstream:Lucid/data.swift
        self.medicalProfile = MedicalProfile() 
=======
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
        
        // If today's goal not met, start from yesterday
        if (dayTotals[today] ?? 0) < dailyExerciseGoal {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        }
        
        while let total = dayTotals[checkDate], total >= dailyExerciseGoal {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
>>>>>>> Stashed changes:Lucid/Models/Model.swift
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
    
    // Meaningful Data Points extracted from your ViewControllers
    var accuracyScore: Int? // For Pencil Pushups (1 - average error)
    var averageBlinkIntensity: Float? // Derived from blinkTraining peaks
    var errorCount: Int? // Tracking lapses in focus or incorrect blinks
    var headMovementDegrees: Float?    // Average head rotation during exercise -> smooth pursuits, saccadic jumps, figure 8, pencil pushups
    
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
