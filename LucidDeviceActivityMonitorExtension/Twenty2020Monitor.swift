import DeviceActivity
import FamilyControls
import UserNotifications
import Foundation

@available(iOS 15.0, *)
class Twenty2020Monitor: DeviceActivityMonitor {
    
    nonisolated required override init() {
        super.init()
    }
    
    // Automatically called at midnight (when the schedule interval starts)
    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Reset screen time hours to 0 for the new day
        let sharedDefaults = UserDefaults(suiteName: "group.com.lucid")
        sharedDefaults?.set(0, forKey: "screenTimeHours")
        
        // Reset monitoring threshold back to 1 hour
        resetThreshold(for: 1)
        print("Lucid Monitor: Daily interval started. Reset threshold to 1 hour.")
    }
    
    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Retrieve and increment elapsed screen time hours
        let sharedDefaults = UserDefaults(suiteName: "group.com.lucid")
        let currentHours = sharedDefaults?.integer(forKey: "screenTimeHours") ?? 0
        let newHours = currentHours + 1
        sharedDefaults?.set(newHours, forKey: "screenTimeHours")
        
        // Send notification inviting the user to take a 20-20-20 break
        sendNotification(hours: newHours)
        
        // Reset monitoring threshold for the next hour inline
        resetThreshold(for: newHours + 1)
    }
    
    nonisolated private func sendNotification(hours: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a 20-20-20 Break!"
        content.body = "You have used your screen for \(hours) hour(s). Look at something 20 feet away for 20 seconds."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "com.lucid.twenty2020.alert",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Lucid: Error posting screen time alert: \(error)")
            }
        }
    }
    
    nonisolated private func resetThreshold(for hours: Int) {
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName("com.lucid.twenty2020.activity")
        center.stopMonitoring([activityName])
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let eventName = DeviceActivityEvent.Name("com.lucid.twenty2020.event")
        let event = DeviceActivityEvent(
            applications: [],
            categories: [],
            webDomains: [],
            threshold: DateComponents(hour: hours)
        )
        
        do {
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            print("Lucid: Reset threshold monitoring for \(hours) hour(s)")
        } catch {
            print("Lucid: Failed to reset monitoring: \(error)")
        }
    }
}
