import Foundation
import SwiftData


struct DailyExerciseRecord: Codable {
    var date: Date
    var completedSeconds: Int
    var goalSeconds: Int
}

@MainActor
class ExerciseDataManager {
    static let shared = ExerciseDataManager()
    
    let dailyGoalSeconds = 1200

    
    func addExerciseTime(seconds: Int, type: String = "General") {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(type: type, duration: seconds)

        newSession.user = user
        
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Saved \(seconds)s for \(user.name)")
        } catch {
            print("❌ Save failed: \(error)")
        }
    }
    
    func updateDailyGoal(newGoalInSeconds: Int) {
            let user = SwiftDataManager.shared.getOrCreateUser()
            user.dailyExerciseGoal = newGoalInSeconds
            
            do {
                try SwiftDataManager.shared.context.save()
                print("✅ Daily goal updated to \(newGoalInSeconds) seconds for \(user.name)")
            } catch {
                print("❌ Failed to update daily goal: \(error)")
            }
        }

    func fetchTodayRecord() -> DailyExerciseRecord {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let totalSeconds = getTotalSeconds(for: Date(), user: user)
        
        return DailyExerciseRecord(
            date: Date(),
            completedSeconds: totalSeconds,
            goalSeconds: user.dailyExerciseGoal
        )
    }


    func fetchWeeklyStreak() -> [(date: Date, isCompleted: Bool)] {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday == 1) ? 6 : (weekday - 2)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else { return [] }

        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let total = getTotalSeconds(for: date, user: user)
            return (date: date, isCompleted: total >= user.dailyExerciseGoal)
        }
    }

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
