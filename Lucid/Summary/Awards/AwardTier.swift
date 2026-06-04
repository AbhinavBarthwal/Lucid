//
//  AwardTier.swift
//  Lucid
//
//  Created by Paras Suri on 4/29/26.
//


//
//  awardsDataModels.swift
//  Lucid
//
//  Created by Kanishka Bansal on 12/03/26.
//  Redesigned by Antigravity on 28/04/26.
//

import Foundation
import UIKit

// MARK: - Award Tier (controls color palette)
enum AwardTier: String, Codable {
    case bronze   // Rank 1 / Entry milestones
    case silver   // Rank 5–10
    case gold     // Rank 10–20
    case platinum // Rank 50+
    case diamond  // Rank 100+ / Top scores

    /// Gradient colours for the badge card
    var gradientColors: [UIColor] {
        switch self {
        case .bronze:
            return [UIColor(red: 0.72, green: 0.45, blue: 0.20, alpha: 1),
                    UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)]
        case .silver:
            return [UIColor(red: 0.75, green: 0.75, blue: 0.80, alpha: 1),
                    UIColor(red: 0.50, green: 0.50, blue: 0.56, alpha: 1)]
        case .gold:
            return [UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 1),
                    UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1)]
        case .platinum:
            return [UIColor(red: 0.40, green: 0.75, blue: 0.95, alpha: 1),
                    UIColor(red: 0.12, green: 0.47, blue: 0.71, alpha: 1)]
        case .diamond:
            return [UIColor(red: 0.76, green: 0.36, blue: 1.00, alpha: 1),
                    UIColor(red: 0.36, green: 0.07, blue: 0.69, alpha: 1)]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 0.72, green: 0.45, blue: 0.20, alpha: 0.6)
        case .silver:   return UIColor(red: 0.75, green: 0.75, blue: 0.80, alpha: 0.6)
        case .gold:     return UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 0.6)
        case .platinum: return UIColor(red: 0.40, green: 0.75, blue: 0.95, alpha: 0.6)
        case .diamond:  return UIColor(red: 0.76, green: 0.36, blue: 1.00, alpha: 0.6)
        }
    }

    var contrastColor: UIColor {
        switch self {
        case .bronze, .diamond:
            return .white
        case .silver, .gold, .platinum:
            return .black
        }
    }
}

// MARK: - Award Category
enum AwardCategory: String, Codable {
    case exerciseMilestone  // Nth exercise session
    case testMilestone      // Nth eye test
    case exerciseScore      // High accuracy in exercise
    case testScore          // High score in C-Test
    case streak             // Consecutive day streaks
}

// MARK: - Award Definition (the blueprint, never changes)
struct AwardDefinition {
    let id: String
    let title: String
    let detail: String         // Long description for popup
    let sfSymbol: String       // SF Symbol name
    let tier: AwardTier
    let category: AwardCategory
    let targetValue: Int       // The number to unlock (count or score %)
    let progressKey: String    // Key used to check current progress value
}

// MARK: - Badge (persisted)
struct Badge: Codable {
    let id: String
    let title: String
    let imageName: String
    var dateEarned: String?
    var isUnlocked: Bool
    var progressValue: Int     // Current progress toward this badge
    var targetValue: Int       // Max needed
}

// MARK: - All Award Definitions
enum AwardCatalog {

    // MARK: Exercise Milestone badges (1, 5, 10, 20, 50, 100, 200, 500, 1000)
    static let exerciseMilestones: [AwardDefinition] = [
        AwardDefinition(
            id: "exercise_1",
            title: "First Mover",
            detail: "You completed your very first exercise. Every journey begins with one step — this is yours.",
            sfSymbol: "eye",
            tier: .bronze,
            category: .exerciseMilestone,
            targetValue: 1,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_5",
            title: "Getting Warmed Up",
            detail: "Five exercises done! Your eyes are starting to thank you. Keep building that healthy habit.",
            sfSymbol: "eye.circle",
            tier: .bronze,
            category: .exerciseMilestone,
            targetValue: 5,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_10",
            title: "Eye Enthusiast",
            detail: "10 exercises completed. You are officially an eye-care enthusiast. The results are showing.",
            sfSymbol: "eye.fill",
            tier: .silver,
            category: .exerciseMilestone,
            targetValue: 10,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_20",
            title: "Vision Builder",
            detail: "20 sessions! You have built a real routine. Your consistency is your superpower.",
            sfSymbol: "star.fill",
            tier: .silver,
            category: .exerciseMilestone,
            targetValue: 20,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_50",
            title: "Focus Master",
            detail: "50 exercises — you are halfway to triple digits. Your dedication to eye health is remarkable.",
            sfSymbol: "eye.circle.fill",
            tier: .gold,
            category: .exerciseMilestone,
            targetValue: 50,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_100",
            title: "Century Vision",
            detail: "100 exercises! You have built a strong eye care habit.",
            sfSymbol: "medal.fill",
            tier: .gold,
            category: .exerciseMilestone,
            targetValue: 100,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_200",
            title: "Elite Trainer",
            detail: "200 sessions — you have surpassed what most people will ever achieve. Elite status unlocked.",
            sfSymbol: "trophy.fill",
            tier: .platinum,
            category: .exerciseMilestone,
            targetValue: 200,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_500",
            title: "Legendary Eyes",
            detail: "500 exercises. You are a legend in the world of eye wellness. Truly extraordinary.",
            sfSymbol: "crown.fill",
            tier: .diamond,
            category: .exerciseMilestone,
            targetValue: 500,
            progressKey: "totalExerciseSessions"
        ),
        AwardDefinition(
            id: "exercise_1000",
            title: "Grand Vision Master",
            detail: "1000 exercises! You have shown amazing care for your eyes.",
            sfSymbol: "sparkles",
            tier: .diamond,
            category: .exerciseMilestone,
            targetValue: 1000,
            progressKey: "totalExerciseSessions"
        ),
    ]

    // MARK: Eye Test Milestone badges (1, 5, 10, 20, 50, 100)
    static let testMilestones: [AwardDefinition] = [
        AwardDefinition(
            id: "test_1",
            title: "First Scan",
            detail: "Your first Landolt C-Test is complete. You have taken the first step toward understanding your vision.",
            sfSymbol: "eye.circle.fill",
            tier: .bronze,
            category: .testMilestone,
            targetValue: 1,
            progressKey: "totalTestSessions"
        ),
        AwardDefinition(
            id: "test_5",
            title: "Regular Checker",
            detail: "5 eye tests done! Monitoring your vision regularly is one of the best things you can do for your health.",
            sfSymbol: "eye.square",
            tier: .bronze,
            category: .testMilestone,
            targetValue: 5,
            progressKey: "totalTestSessions"
        ),
        AwardDefinition(
            id: "test_10",
            title: "Vision Vigilant",
            detail: "10 eye tests completed. You take your visual health seriously — and it shows.",
            sfSymbol: "binoculars.fill",
            tier: .silver,
            category: .testMilestone,
            targetValue: 10,
            progressKey: "totalTestSessions"
        ),
        AwardDefinition(
            id: "test_20",
            title: "Sight Guardian",
            detail: "20 tests in. Your eyes are in the hands of someone who truly cares. That someone is you.",
            sfSymbol: "eye.square.fill",
            tier: .silver,
            category: .testMilestone,
            targetValue: 20,
            progressKey: "totalTestSessions"
        ),
        AwardDefinition(
            id: "test_50",
            title: "Optometry Pro",
            detail: "50 eye tests — you practically have a doctorate in eye-checking. Incredible commitment.",
            sfSymbol: "rosette",
            tier: .gold,
            category: .testMilestone,
            targetValue: 50,
            progressKey: "totalTestSessions"
        ),
        AwardDefinition(
            id: "test_100",
            title: "Master Diagnostician",
            detail: "100 eye tests! You have a strong record of checking your eyes.",
            sfSymbol: "medal.fill",
            tier: .platinum,
            category: .testMilestone,
            targetValue: 100,
            progressKey: "totalTestSessions"
        ),
    ]

    // MARK: Exercise Score badges (accuracy %)
    static let exerciseScores: [AwardDefinition] = [
        AwardDefinition(
            id: "exscore_70",
            title: "Sharp Starter",
            detail: "You averaged 70% or more accuracy across your exercises. A solid foundation for better vision.",
            sfSymbol: "eye",
            tier: .bronze,
            category: .exerciseScore,
            targetValue: 70,
            progressKey: "averageExerciseAccuracy"
        ),
        AwardDefinition(
            id: "exscore_80",
            title: "Precision Seeker",
            detail: "80%+ accuracy maintained! Your eye-hand coordination is genuinely impressive.",
            sfSymbol: "viewfinder.circle.fill",
            tier: .silver,
            category: .exerciseScore,
            targetValue: 80,
            progressKey: "averageExerciseAccuracy"
        ),
        AwardDefinition(
            id: "exscore_90",
            title: "Eagle-Eyed",
            detail: "90%+ average accuracy — your eyes are performing like an eagle's. Remarkable precision.",
            sfSymbol: "crown",
            tier: .gold,
            category: .exerciseScore,
            targetValue: 90,
            progressKey: "averageExerciseAccuracy"
        ),
        AwardDefinition(
            id: "exscore_95",
            title: "Perfect Focus",
            detail: "95%+ accuracy! You have achieved near-perfect eye control. An extraordinary feat.",
            sfSymbol: "party.popper.fill",
            tier: .diamond,
            category: .exerciseScore,
            targetValue: 95,
            progressKey: "averageExerciseAccuracy"
        ),
    ]

    // MARK: C-Test Score badges (score is raw points 0–6 per eye)
    static let testScores: [AwardDefinition] = [
        AwardDefinition(
            id: "testscore_3",
            title: "Vision Awakened",
            detail: "You scored 3+ points on the C Test. Your clear vision is improving.",
            sfSymbol: "eye.circle",
            tier: .bronze,
            category: .testScore,
            targetValue: 3,
            progressKey: "bestTestScore"
        ),
        AwardDefinition(
            id: "testscore_4",
            title: "Clear Sight",
            detail: "Score of 4+ on the C Test! Your eyes are seeing the targets well.",
            sfSymbol: "eye.square",
            tier: .silver,
            category: .testScore,
            targetValue: 4,
            progressKey: "bestTestScore"
        ),
        AwardDefinition(
            id: "testscore_5",
            title: "Crystal Vision",
            detail: "5+ C-Test score — your vision is crystal clear. You are performing at a top-tier level.",
            sfSymbol: "star",
            tier: .gold,
            category: .testScore,
            targetValue: 5,
            progressKey: "bestTestScore"
        ),
        AwardDefinition(
            id: "testscore_6",
            title: "Flawless Vision",
            detail: "Perfect 6/6 on the C Test! Your eyes saw every target clearly.",
            sfSymbol: "star.circle.fill",
            tier: .diamond,
            category: .testScore,
            targetValue: 6,
            progressKey: "bestTestScore"
        ),
    ]

    // MARK: Streak badges
    static let streaks: [AwardDefinition] = [
        AwardDefinition(
            id: "streak_3",
            title: "3-Day Streak",
            detail: "Three days in a row! Consistency is the key to long-term eye health. Great start.",
            sfSymbol: "face.smiling",
            tier: .bronze,
            category: .streak,
            targetValue: 3,
            progressKey: "currentStreak"
        ),
        AwardDefinition(
            id: "streak_7",
            title: "Week Warrior",
            detail: "Seven consecutive days! A full week of eye-care dedication. You are building a life habit.",
            sfSymbol: "face.smiling.fill",
            tier: .silver,
            category: .streak,
            targetValue: 7,
            progressKey: "currentStreak"
        ),
        AwardDefinition(
            id: "streak_14",
            title: "Fortnight Focus",
            detail: "Two weeks strong! Your eyes are adapting and your routine is cementing itself beautifully.",
            sfSymbol: "sun.max.fill",
            tier: .gold,
            category: .streak,
            targetValue: 14,
            progressKey: "currentStreak"
        ),
        AwardDefinition(
            id: "streak_30",
            title: "Monthly Maven",
            detail: "30 days in a row — a full month! You have made eye health a true part of your life.",
            sfSymbol: "rosette",
            tier: .platinum,
            category: .streak,
            targetValue: 30,
            progressKey: "currentStreak"
        ),
        AwardDefinition(
            id: "streak_60",
            title: "Unstoppable",
            detail: "60-day streak! Your commitment is unstoppable. You are an inspiration to eye health.",
            sfSymbol: "trophy",
            tier: .diamond,
            category: .streak,
            targetValue: 60,
            progressKey: "currentStreak"
        ),
    ]

    static var all: [AwardDefinition] {
        exerciseMilestones + testMilestones + exerciseScores + testScores + streaks
    }
}

// MARK: - Progress Manager (persistence + evaluation)
class ProgressManager {
    static let shared = ProgressManager()
    private let defaults = UserDefaults.standard

    // MARK: - Legacy record (kept for backward compat)
    func saveRecord(_ record: ExerciseRecord) {
        if let encoded = try? JSONEncoder().encode(record) {
            defaults.set(encoded, forKey: "userExerciseRecord")
        }
    }

    func loadRecord() -> ExerciseRecord {
        if let savedData = defaults.object(forKey: "userExerciseRecord") as? Data,
           let decodedRecord = try? JSONDecoder().decode(ExerciseRecord.self, from: savedData) {
            return decodedRecord
        }
        return ExerciseRecord()
    }

    // MARK: - Badge persistence
    func saveBadges(_ badges: [Badge]) {
        if let encoded = try? JSONEncoder().encode(badges) {
            defaults.set(encoded, forKey: "userBadgesV3")
        }
    }

    func loadBadges() -> [Badge] {
        if let savedData = defaults.object(forKey: "userBadgesV3") as? Data,
           let decodedBadges = try? JSONDecoder().decode([Badge].self, from: savedData) {
            return decodedBadges
        }
        // First launch — generate from catalog
        return AwardCatalog.all.map { def in
            Badge(id: def.id,
                  title: def.title,
                  imageName: def.sfSymbol,
                  dateEarned: nil,
                  isUnlocked: false,
                  progressValue: 0,
                  targetValue: def.targetValue)
        }
    }

    // MARK: - Evaluate & unlock badges (call after any progress change)
    @discardableResult
    @MainActor
    func evaluateAndUnlock() -> [String] {
        let allExercises = SwiftDataManager.shared.fetchExerciseSessions()
        let allTests = SwiftDataManager.shared.fetchCTestSessions()

        let exerciseCount = allExercises.count
        let testCount     = allTests.count

        // ── Average accuracy across all exercise sessions that have a score ──
        let accuracySessions = allExercises.compactMap { $0.accuracyScore }
        let avgAccuracy: Int = accuracySessions.isEmpty
            ? 0
            : Int(Double(accuracySessions.reduce(0, +)) / Double(accuracySessions.count))

        // ── Best C-test score (stored as raw points 0–6, max = 6) ──
        let bestTest  = Int(allTests.map { $0.score }.max() ?? 0)

        // ── Streak via User model ──
        let user       = SwiftDataManager.shared.getOrCreateUser()
        let streakCount = user.currentStreak

        print("📊 Awards eval — exercises: \(exerciseCount), tests: \(testCount), avgAcc: \(avgAccuracy)%, bestTest: \(bestTest), streak: \(streakCount)")

        var badges = loadBadges()
        var newlyUnlocked: [String] = []

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let today = formatter.string(from: Date())

        for i in badges.indices {
            guard let def = AwardCatalog.all.first(where: { $0.id == badges[i].id }) else { continue }

            let progress: Int
            switch def.category {
            case .exerciseMilestone: progress = exerciseCount
            case .testMilestone:     progress = testCount
            case .exerciseScore:     progress = avgAccuracy
            case .testScore:         progress = bestTest
            case .streak:            progress = streakCount
            }

            badges[i].progressValue = min(progress, def.targetValue)
            badges[i].targetValue   = def.targetValue

            if !badges[i].isUnlocked && progress >= def.targetValue {
                badges[i].isUnlocked = true
                badges[i].dateEarned = today
                newlyUnlocked.append(def.id)
                print("🏅 Unlocked: \(def.title)")
                NotificationManager.shared.sendBadgeUnlockedNotification(badgeTitle: def.title)
            }
        }

        saveBadges(badges)
        return newlyUnlocked
    }

    // Convenience: definition for a badge id
    func definition(for id: String) -> AwardDefinition? {
        AwardCatalog.all.first { $0.id == id }
    }
}


// MARK: - Legacy ExerciseRecord (kept for backward compatibility)
struct ExerciseRecord: Codable {
    var counter: Int = 0
    var time: Date? = nil
    var currentStreak: Int = 0

    mutating func logNewSession() {
        counter += 1
        let now = Date()

        if let previousTime = time {
            if Calendar.current.isDateInToday(previousTime) {
                print("Session logged. Streak maintained.")
            } else if Calendar.current.isDateInYesterday(previousTime) {
                currentStreak += 1
                print("Streak increased to \(currentStreak)!")
            } else {
                currentStreak = 1
                print("Streak reset to 1.")
            }
        } else {
            currentStreak = 1
        }
        time = now
    }
}
