import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var eyeTestSessions: [EyeTestSession]
    @Relationship(deleteRule: .cascade) var exerciseSessions: [ExerciseSession]

    init(name: String, age: Int) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.createdAt = Date()
        self.eyeTestSessions = []
        self.exerciseSessions = []
    }
}

// MARK: - Exercise Sessions
@Model
final class ExerciseSession {
    var id: UUID
    var date: Date
    var type: String // "Blink", "PencilPushup", "NearFar"
    var durationSeconds: Int
    
    // Meaningful Data Points extracted from your ViewControllers
    var accuracyScore: Double? // For Pencil Pushups (1 - average error)
    var averageBlinkIntensity: Float? // Derived from blinkTraining peaks
    var errorCount: Int? // Tracking lapses in focus or incorrect blinks
    
    var user: User?

    init(type: String, duration: Int, accuracy: Double? = nil, intensity: Float? = nil, errors: Int? = 0) {
        self.id = UUID()
        self.date = Date()
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
