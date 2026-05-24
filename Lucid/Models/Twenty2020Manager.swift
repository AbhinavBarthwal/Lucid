import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings
import UserNotifications
#if canImport(ActivityKit)
import ActivityKit
#endif

@available(iOS 15.0, *)
public class Twenty2020Manager {
    public static let shared = Twenty2020Manager()
    
    private let center = DeviceActivityCenter()
    
    private init() {}
    
    // Request permission for screen time monitoring and notification
    public func requestAuthorization() {
        // Request Notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Lucid: Notification permission granted")
            } else if let error = error {
                print("Lucid: Notification permission failed: \(error)")
            }
        }
        
        // Request FamilyControls permission (physical device only)
        #if !targetEnvironment(simulator)
        if #available(iOS 16.0, *) {
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    print("Lucid: DeviceActivity authorization successful")
                } catch {
                    print("Lucid: DeviceActivity authorization failed: \(error.localizedDescription)")
                }
            }
        }
        #else
        print("Lucid: FamilyControls authorization skipped on Simulator.")
        #endif
    }
    
    // Start monitoring the screen time hourly
    public func startMonitoring(for hours: Int = 1) {
        #if targetEnvironment(simulator)
        print("Lucid: DeviceActivity monitoring is not supported on the Simulator (sandbox restriction). Run on a real device.")
        return
        #endif
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        // Setup threshold
        let eventName = DeviceActivityEvent.Name("com.lucid.twenty2020.event")
        let event = DeviceActivityEvent(
            applications: [], // All applications
            categories: [],   // All categories
            webDomains: [],   // All domains
            threshold: DateComponents(hour: hours)
        )
        
        let activityName = DeviceActivityName("com.lucid.twenty2020.activity")
        
        do {
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            print("Lucid: Started monitoring screen time for threshold: \(hours) hour(s)")
        } catch {
            print("Lucid: Failed to start monitoring: \(error)")
        }
    }
    
    public func stopMonitoring() {
        let activityName = DeviceActivityName("com.lucid.twenty2020.activity")
        center.stopMonitoring([activityName])
        print("Lucid: Stopped monitoring screen time")
    }
    
    // Reset/increment threshold after an alert is shown
    public func resetThresholdMonitoring(for hours: Int) {
        stopMonitoring()
        startMonitoring(for: hours)
    }
}

// MARK: - Live Activity Management
extension Twenty2020Manager {
    
    /// Starts a Live Activity and auto-drives the 20-second countdown on the Dynamic Island.
    /// - Parameters:
    ///   - hoursElapsed: Screen time hours that triggered the break.
    ///   - onComplete: Called when the 20-second countdown finishes (runs on main queue).
    @discardableResult
    public func startLiveActivityWithCountdown(hoursElapsed: Int, onComplete: (() -> Void)? = nil) -> Any? {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            #if targetEnvironment(simulator)
            print("Lucid: Live Activities are not supported on the Simulator. Run on a real device.")
            return nil
            #endif
            
            endLiveActivity()
            
            let attributes = Twenty2020ActivityAttributes()
            let initialState = Twenty2020ActivityAttributes.ContentState(
                hoursElapsed: hoursElapsed,
                secondsRemaining: 20
            )
            
            do {
                let activity = try Activity<Twenty2020ActivityAttributes>.request(
                    attributes: attributes,
                    contentState: initialState,
                    pushType: nil
                )
                print("Lucid: Live Activity started: \(activity.id)")
                
                // Drive the countdown — tick every second
                var secondsLeft = 19
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                    guard let self else { timer.invalidate(); return }
                    
                    if secondsLeft <= 0 {
                        timer.invalidate()
                        self.updateLiveActivity(secondsRemaining: 0, isCompleted: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.endLiveActivity()
                            onComplete?()
                        }
                    } else {
                        self.updateLiveActivity(secondsRemaining: secondsLeft)
                        secondsLeft -= 1
                    }
                }
                
                return activity
            } catch {
                print("Lucid: Error starting Live Activity: \(error.localizedDescription)")
            }
        }
        #endif
        return nil
    }
    
    /// Starts a Live Activity without an auto-countdown (manual update mode).
    @discardableResult
    public func startLiveActivity(hoursElapsed: Int) -> Any? {
        return startLiveActivityWithCountdown(hoursElapsed: hoursElapsed)
    }
    
    public func updateLiveActivity(secondsRemaining: Int, isCompleted: Bool = false) {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            Task {
                for activity in Activity<Twenty2020ActivityAttributes>.activities {
                    let updatedState = Twenty2020ActivityAttributes.ContentState(
                        hoursElapsed: activity.contentState.hoursElapsed,
                        secondsRemaining: secondsRemaining,
                        isCompleted: isCompleted
                    )
                    await activity.update(using: updatedState)
                }
            }
        }
        #endif
    }
    
    public func endLiveActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            Task {
                for activity in Activity<Twenty2020ActivityAttributes>.activities {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
        #endif
    }
}
