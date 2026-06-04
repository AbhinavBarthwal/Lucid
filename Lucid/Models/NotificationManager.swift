import Foundation
import UserNotifications

@MainActor
public class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        registerDefaultSettings()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Lucid: Notification permission granted")
            } else if let error = error {
                print("Lucid: Notification permission error: \(error)")
            }
            Task { @MainActor in
                completion?(granted)
            }
        }
    }

    public func refreshScheduledNotificationsFromDefaults() {
        registerDefaultSettings()

        if UserDefaults.standard.bool(forKey: "reminder") {
            scheduleBiWeeklyReminder()
        } else {
            cancelBiWeeklyReminder()
        }

        if UserDefaults.standard.bool(forKey: "eyeTrend") {
            scheduleWeeklyTrendsReminder()
        } else {
            cancelWeeklyTrendsReminder()
        }

        if UserDefaults.standard.bool(forKey: "exerciseReminder") {
            scheduleExerciseReminders()
        } else {
            cancelExerciseReminders()
        }
    }

    public func registerDefaultSettings() {
        UserDefaults.standard.register(defaults: [
            "digitalTime": true,
            "reminder": true,
            "eyeTrend": true,
            "exerciseReminder": true,
            "badge": true,
            "suggestion": true
        ])
    }
    
    // MARK: - Bi-weekly Test Reminder (14 days)
    public func scheduleBiWeeklyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Time for a quick vision check!"
        content.body = "It's time for your biweekly eye check-up! Let's see how your eyes are feeling today."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 14 * 24 * 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "biweeklyTestReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Lucid: Error scheduling bi-weekly reminder: \(error)")
            } else {
                print("Lucid: Bi-weekly reminder scheduled successfully.")
            }
        }
    }
    
    public func cancelBiWeeklyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["biweeklyTestReminder"])
        print("Lucid: Bi-weekly reminder cancelled.")
    }
    
    // MARK: - Weekly Trends Reminder (7 days)
    public func scheduleWeeklyTrendsReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Your weekly eye health trends are ready!"
        content.body = "Take a peek at your eye health summary from this past week!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7 * 24 * 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyTrendsReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Lucid: Error scheduling weekly trends reminder: \(error)")
            } else {
                print("Lucid: Weekly trends reminder scheduled successfully.")
            }
        }
    }
    
    public func cancelWeeklyTrendsReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weeklyTrendsReminder"])
        print("Lucid: Weekly trends reminder cancelled.")
    }
    
    // MARK: - Badge Unlocked Notification (Immediate)
    public func sendBadgeUnlockedNotification(badgeTitle: String) {
        guard UserDefaults.standard.bool(forKey: "badge") else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Badge Unlocked! 🏅"
        content.body = "Hooray! You've earned the '\(badgeTitle)' badge. Keep up the wonderful work!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "badge_unlocked_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Lucid: Error sending badge notification: \(error)")
            }
        }
    }
    
    // MARK: - Exercise Reminders (Every 3 hours, 9:00 AM - 10:00 PM)
    public func scheduleExerciseReminders() {
        cancelExerciseReminders()
        
        guard UserDefaults.standard.bool(forKey: "exerciseReminder") else {
            return
        }
        
        let record = ExerciseDataManager.shared.fetchTodayRecord()
        let isGoalMet = record.completedSeconds >= record.goalSeconds
        
        let calendar = Calendar.current
        let now = Date()
        let slots = [9, 12, 15, 18, 21] // 9:00 AM, 12:00 PM, 3:00 PM, 6:00 PM, 9:00 PM (10 PM limit)
        
        for dayOffset in 0..<7 {
            if dayOffset == 0 && isGoalMet {
                continue
            }
            
            guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            for hour in slots {
                var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
                components.hour = hour
                components.minute = 0
                components.second = 0
                
                guard let scheduleDate = calendar.date(from: components) else { continue }
                
                if dayOffset == 0 && scheduleDate <= now {
                    continue
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Time to refresh your eyes!"
                content.body = "Let's take a quick screen break to refresh and stretch your eyes."
                content.sound = .default
                
                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: scheduleDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                
                let identifier = "exercise_reminder_\(dayOffset)_\(hour)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Lucid: Error scheduling exercise reminder \(identifier): \(error)")
                    }
                }
            }
        }
        print("Lucid: Exercise reminders scheduled for the next 7 days.")
    }
    
    public func cancelExerciseReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToCancel = requests.filter { $0.identifier.hasPrefix("exercise_reminder_") }.map { $0.identifier }
            if !idsToCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToCancel)
                print("Lucid: Cancelled \(idsToCancel.count) pending exercise reminders.")
            }
        }
    }
}
