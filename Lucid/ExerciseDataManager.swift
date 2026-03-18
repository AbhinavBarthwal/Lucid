import Foundation
import SwiftData
// The Model
struct DailyExerciseRecord: Codable {
    var date: Date
    var completedSeconds: Int
    var goalSeconds: Int
}

@MainActor
class ExerciseDataManager {
    static let shared = ExerciseDataManager()
    
    // Default goal if user doesn't have one set (20 mins)
    let dailyGoalSeconds = 1200

    // MARK: - Save Session
    func addExerciseTime(seconds: Int, type: String = "General") {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(type: type, duration: seconds)
        
        // Link session to user
        newSession.user = user
        
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Saved \(seconds)s for \(user.name)")
        } catch {
            print("❌ Save failed: \(error)")
        }
    }

    // MARK: - Fetch Data for Gauge
    func fetchTodayRecord() -> DailyExerciseRecord {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let totalSeconds = getTotalSeconds(for: Date(), user: user)
        
        return DailyExerciseRecord(
            date: Date(),
            completedSeconds: totalSeconds,
            goalSeconds: user.dailyExerciseGoal
        )
    }

    // MARK: - Fetch Data for Streak
    func fetchWeeklyStreak() -> [(date: Date, isCompleted: Bool)] {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate Monday start
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday == 1) ? 6 : (weekday - 2)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else { return [] }

        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let total = getTotalSeconds(for: date, user: user)
            return (date: date, isCompleted: total >= user.dailyExerciseGoal)
        }
    }

    // MARK: - Helper Logic
    private func getTotalSeconds(for date: Date, user: User) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let userId = user.id
        let predicate = #Predicate<ExerciseSession> { session in
            session.startingDate >= start &&
            session.startingDate < end &&
            session.user?.id == userId
        }
        
        let descriptor = FetchDescriptor<ExerciseSession>(predicate: predicate)
        
        do {
            let sessions = try SwiftDataManager.shared.context.fetch(descriptor)
            return sessions.reduce(0) { $0 + $1.durationSeconds }
        } catch {
            return 0
        }
    }
}
