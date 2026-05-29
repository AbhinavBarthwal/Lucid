import Foundation

struct DailyExerciseRecord: Codable {
    var date: Date
    var completedSeconds: Int
    var goalSeconds: Int
}

@MainActor
class ExerciseDataManager {
    static let shared = ExerciseDataManager()
    
    let dailyGoalSeconds = 60
    
    // MARK: - Save locally (Cloud sync removed per instructions)
    func addExerciseTime(seconds: Int, type: String = "General") {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let newSession = ExerciseSession(type: type, duration: seconds)
        
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Saved \(seconds)s locally for \(user.name)")
            
            // Update today's streak status and evaluate badges
            user.updateTodayStreakStatus()
            ProgressManager.shared.evaluateAndUnlock()
            
            // Reschedule exercise reminders since the completed time changed
            NotificationManager.shared.scheduleExerciseReminders()
            
            // REMOVED syncExercise call because we are only keeping
            // exercises locally to keep the Supabase database clean.
            
        } catch {
            print("❌ Save failed: \(error)")
        }
    }
    
    func updateDailyGoal(newGoalInSeconds: Int) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        user.dailyExerciseGoal = newGoalInSeconds
        
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Daily goal updated to \(newGoalInSeconds) seconds")
            
            // We still sync the User here because the 'dailyGoal' is part
            // of the user profile you want in Supabase.
            Task {
                await SupabaseManager.shared.syncUser(user)
            }
        } catch {
            print("❌ Failed to update daily goal: \(error)")
        }
    }

    // MARK: - Fetching Logic (Remains unchanged)
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

        user.updateTodayStreakStatus()

        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let isCompleted = user.streak.first(where: { calendar.isDate($0.date, inSameDayAs: date) })?.isCompleted ?? false
            return (date: date, isCompleted: isCompleted)
        }
    }

    private func getTotalSeconds(for date: Date, user: User) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let sessions = SwiftDataManager.shared.fetchExerciseSessions()
        let filtered = sessions.filter { session in
            session.startingDate >= start && session.startingDate < end
        }
        return filtered.reduce(0) { $0 + $1.durationSeconds }
    }
}
