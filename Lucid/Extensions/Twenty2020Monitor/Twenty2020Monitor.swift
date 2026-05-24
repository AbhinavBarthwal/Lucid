import DeviceActivity
import FamilyControls
import UserNotifications
import Foundation

@available(iOS 15.0, *)
class Twenty2020Monitor: DeviceActivityMonitor {
    
    nonisolated required override init() {
        super.init()
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
        
        // Reset monitoring parameters for the next hour threshold
        Twenty2020Manager.shared.resetThresholdMonitoring(for: newHours + 1)
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
}
