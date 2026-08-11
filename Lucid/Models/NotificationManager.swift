import Foundation
import UserNotifications

@MainActor
public class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    private let exerciseReminderTitles = [
        "Hey, time to rest those eyes! 👀",
        "Have you taken a screen break recently?",
        "Let's give your eyes a quick break! 🌸",
        "Ready for a quick eye stretch?",
        "Hey! Look away from that screen for a sec.",
        "Time to give your gaze a gentle rest.",
        "Just checking in! Let's pamper your eyes.",
        "A little screen-free moment for you.",
        "Time to stretch those eyes. Up we go!",
        "Let's take a quick breathing space for your vision.",
        "Are you taking care of yourself? Let's rest your eyes.",
        "A gentle nudge to look away from your screen!",
        "Step back for a second. Your eyes need it.",
        "Let's keep those eyes feeling bright and happy!",
        "Time for a quick refresh. You deserve it."
    ]
    
    private let exerciseReminderBodies = [
        "Let's take a quick screen break to refresh and stretch your eyes.",
        "Look at something far away for just 20 seconds. It helps so much!",
        "Try a few slow blinks or draw a figure-eight with your eyes to keep them moist.",
        "Let's prevent that screen fatigue. A quick exercise is just what you need.",
        "Close your eyes for a moment and let them rest in complete darkness. Ah, better.",
        "Do a minute of near-far focusing. It keeps your vision flexible and strong.",
        "Taking a small break now keeps the headaches away. Trust me on this!",
        "Give those eye muscles a gentle workout with a smooth pursuit exercise.",
        "Rest, refresh, and recharge your vision with me. You're doing great!",
        "Help your eyes stay comfortable and hydrated with a quick blink training session.",
        "Unwind your focus for just a minute. Your eyes work so hard for you.",
        "Roll your eyes gently in a circle and release all that screen tension.",
        "Let's keep your eyes feeling energized and bright all day long.",
        "You've been staring at that screen a lot. Let's give your eyes a nice break.",
        "A quick round of pencil push-ups will keep your eyes strong and focused."
    ]
    
    private let dailyEyeTipTitles = [
        "A quick eye care tip for today! 🌸",
        "Here's a simple way to care for your eyes:",
        "Just a gentle reminder to protect your vision.",
        "A little nugget of eye wisdom for you! 💕",
        "Let's make sure those eyes are feeling good today.",
        "A warm eye care tip just for you.",
        "Your daily dose of eye wellness!",
        "Take care of your vision today.",
        "A quick thought to keep your eyes happy and healthy.",
        "Here's a simple trick for your eyes:",
        "Keep those eyes glowing! Here's a tip:",
        "Just wanted to share a little eye care secret.",
        "Let's give your eyes some extra love today! 🤗",
        "A friendly reminder for your screen time.",
        "Keep your eyes feeling fresh today!"
    ]
    
    private let dailyEyeTipBodies = [
        "Every 20 minutes, look at something 20 feet away for 20 seconds. It really helps reset your eye muscles.",
        "Remember the 20-20-20 rule: pause every 20 minutes and rest your gaze on something far away.",
        "Don't forget to look away from your screen every 20 minutes. Staring at something far away works wonders.",
        "We blink much less when looking at screens. Try to blink more to keep your eyes nice and moist.",
        "Take a moment to blink fully and slowly right now. It spreads a fresh tear film across your eyes.",
        "Staring at devices dries out your eyes. Every few minutes, do 10 slow, deliberate blinks to refresh them.",
        "Keep your screen at arm's length — about 50–70 cm away. Putting it too close makes your eyes work too hard.",
        "Arm's length is the absolute sweet spot for screens. Don't force your eyes to strain by leaning in.",
        "Make sure your screen is sitting roughly 50–70 cm away. Push it back a bit if you find yourself leaning in.",
        "Try to position your screen slightly below eye level. Looking down a little keeps your eyes from drying out.",
        "Tilt your screen slightly down. It lets your eyelids cover more of your eyes and slows down dryness.",
        "Make sure your monitor is just below eye level. It really helps keep your eyes comfortable and moist.",
        "Please turn on Night Mode after sunset. Warm display tones are much gentler and help you sleep better.",
        "Reduce that harsh blue light in the evening. Enable your device's warm-color night shift mode.",
        "Switch your screen to a warmer tone after dark. It's much easier on your eyes before bedtime.",
        "Match your screen brightness to the room. A screen that's too bright in a dark room causes unnecessary strain.",
        "If your screen looks like a flashlight in your room, dim it a bit. Equal brightness makes eyes happy.",
        "Don't let your screen be the brightest thing in the room. Check the brightness and dim it if needed.",
        "Avoid working in a pitch-black room with a bright screen. The high contrast really tires your pupils out.",
        "Keep your workspace evenly lit. Big differences in light between screen and background are tough on eyes.",
        "Place a soft light behind your monitor. It reduces the glare contrast and makes everything so much softer.",
        "Try to position your screen away from window reflections. Side-lighting is so much gentler on your vision.",
        "Window glare forces your eyes to work double-time. Shift your angle or use an anti-glare screen filter.",
        "Is a window reflecting on your screen? Adjust your desk angle a tiny bit. Your eyes will thank you.",
        "Drink plenty of water today! Dehydration makes dry eyes feel so much worse.",
        "Your tears are mostly water. Sip some water throughout the day to keep your eyes well-lubricated.",
        "Have you had a glass of water recently? Keeping hydrated is a simple way to care for your eyes.",
        "If your eyes feel dry or scratchy, preservative-free eye drops are perfectly safe and gentle to use.",
        "Keep some soothing eye drops nearby. Use them before your eyes start burning from screen time.",
        "Keep preservative-free artificial tears on your desk. A quick drop keeps your eyes feeling nice and fresh.",
        "Rub your palms together until they're warm, and cup them over your closed eyes. It's so relaxing!",
        "Try palming: warm your hands and cup them over your closed eyes without pressing. It lets them relax.",
        "Take 30 seconds to palm your eyes. The warmth and darkness let your tired eye muscles finally rest.",
        "Put your screens away at least an hour before bed. Your eyes and brain need full darkness to rest.",
        "Take a real 10-minute screen break every two hours. Go for a walk or look out the window.",
        "Give yourself a genuine screen-free hour today. No phone, no computer. Just relax your eyes.",
        "If you're squinting, please make your text size larger. Squinting strains the delicate muscles around your eyes.",
        "Make your font size a bit bigger. Reading should be completely effortless for your eyes.",
        "If you're leaning closer to read, the text is too small. Make it bigger so you can sit back comfortably.",
        "Roll your eyes slowly in a circle. Up, right, down, left. Repeat both ways to loosen up tension.",
        "Focus on your finger close up, then look far across the room. Repeat it 10 times to stretch your lenses.",
        "Look up, down, left, right, holding each for 2 seconds. It's like a gentle yoga stretch for your eye muscles.",
        "Make sure you get 7–9 hours of sleep tonight. Your eyes need that time to heal and rehydrate.",
        "Sleep is when your eyes restore their moisture. Get to bed on time to protect your vision.",
        "Not sleeping enough makes dry, red eyes so much worse. Make sleep a priority for your health.",
        "Spend some time outdoors in the daylight today. Natural light is so healthy for eye development.",
        "Go take a walk outside. Natural light and focusing on distant trees is exactly what your eyes need.",
        "Get some fresh air and natural daylight. Engaging your eyes outdoors helps prevent nearsightedness.",
        "If you wear contacts, take them out if you're on screens for a long time. Give your eyes a chance to breathe.",
        "Blink more often if you have contacts in. Lenses can dry out much faster on screen sessions.",
        "Never, ever sleep in your contacts. Your eyes need oxygen, and sleeping in them is very risky.",
        "Remember to get your eyes checked by a doctor once a year. It's so important for your long-term health.",
        "Your prescription can change slowly without you realizing. An annual exam keeps it perfect.",
        "Eye exams check for more than just vision. They make sure the overall health of your eyes is in tip-top shape.",
        "Eat your leafy greens like spinach and kale! They are packed with antioxidants that protect your vision.",
        "Omega-3s from fish or walnuts are so good for your tears. Try to include them in your meals.",
        "Vitamin A is essential for your night vision. Enjoy some carrots, sweet potatoes, or eggs today.",
        "Check your posture! Slouching makes you lean too close to the screen. Sit up straight and protect your eyes.",
        "Keep your back straight and screen at a distance. Bad posture leads directly to eye strain.",
        "Adjust your chair so you sit comfortably with feet flat. Good posture keeps your neck and eyes happy.",
        "Switch your apps to Dark Mode in the evening. It emits less light and is so much cozier for your eyes.",
        "Use dark mode when the room is dim. It's much softer on tired eyes at the end of the day.",
        "Dark mode is wonderful for late-night reading. It keeps glare to a minimum so you can unwind.",
        "Please don't rub your eyes, even if they itch. It can scratch your cornea.",
        "Resist the urge to rub your eyes. Use a cool washcloth or soothing eye drops instead.",
        "Rubbing your eyes can introduce bacteria. Gently blink or use drops instead of rubbing.",
        "Wear your sunglasses when you go outside. Blocking UV rays protects against cataracts later in life.",
        "Make sure your sunglasses block 99-100% of UVA and UVB rays. Your eyes need real protection.",
        "Even on cloudy days, UV rays are out there. Keep your sunglasses handy when you're outdoors.",
        "Try not to jump between your phone and laptop constantly. It forces your eyes to keep refocusing.",
        "Stick to one screen at a time. Multitasking on multiple screens tires your eyes out so fast.",
        "Put down the phone while watching TV. Give your eyes a single distance to focus on for a change.",
        "A warm washcloth over your closed eyes for 5 minutes feels so good, and it helps your tear glands.",
        "Try a warm compress tonight. It's a wonderful, cozy way to soothe dry and tired eyes.",
        "If your eyes feel gritty, rest a warm damp cloth on them. It stimulates natural oils to keep them moist.",
        "Try writing your notes on paper instead of a screen today. It's a nice, screen-free way to work.",
        "Please don't read on your phone in a moving car. The bouncing screen causes major eye strain.",
        "Check your screen time stats today. It's good to be aware of how much time we spend on devices.",
        "Make sure kids get plenty of screen-free outdoor playtime. Their growing eyes need daylight.",
        "If you're reading a long article and your eyes are tired, use text-to-speech. Let your ears do the work.",
        "Keep your desk clean and remove bright lights near your screen. It makes focusing much easier.",
        "Gently clean your eyelids with a warm cloth if you get dry eyes often. It keeps everything clean.",
        "Allergies can make screens feel even harsher. Talk to a doctor about allergy drops if needed.",
        "Consider reading or computer glasses if you strain to see screens. They make a world of difference.",
        "If possible, use a monitor with a refresh rate of 120Hz or higher. Higher refresh rates reduce perceptible flicker.",
        "Keep your screen clean and free of dust. Fingerprints and dust make it harder to read clearly.",
        "Take a deep breath and look out the window. The world is beautiful, and your eyes need a distant view.",
        "Rest your eyes by looking at a green plant. Green is a very soothing color for our vision.",
        "If your eyes feel tired, it's okay to take a little nap. Sleep is the best medicine for eye strain.",
        "Make sure you blink when you're focused. We get so caught up in work we forget to blink!",
        "Adjust your screen contrast so text pops out clearly. You shouldn't have to strain to read.",
        "Avoid glare from overhead light bulbs. Position your lamp so it shines on your desk, not your screen.",
        "Keep some cucumber slices on your eyes for a few minutes. It's a fun and cooling treat for them!",
        "If you work on screens all day, try taking a walk at lunch. Give your eyes some outdoor distance.",
        "Be kind to your eyes. They let you see all the beauty in this world.",
        "Limit screen time before eating dinner. It helps your mind and eyes transition to relaxation.",
        "A little eye massage on your brow bone feels so nice. Just be gentle and avoid pressing on the eye itself.",
        "Try a matte screen protector if glare is bothering you. It makes reading much softer.",
        "Keep your workspace cozy but well-lit. Reading in dim light makes your eyes work much harder.",
        "You only get one pair of eyes. Please take care of them!"
    ]
    
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

        if UserDefaults.standard.bool(forKey: "eyeTips") {
            scheduleDailyEyeTipReminder()
        } else {
            cancelDailyEyeTipReminder()
        }
    }

    public func registerDefaultSettings() {
        UserDefaults.standard.register(defaults: [
            "reminder": true,
            "eyeTrend": true,
            "exerciseReminder": true,
            "badge": true,
            "eyeTips": true
        ])
    }
    
    // MARK: - Bi-weekly Test Reminder (14 days)
    public func scheduleBiWeeklyReminder() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            if requests.contains(where: { $0.identifier == "biweeklyTestReminder" }) {
                print("Lucid: Bi-weekly reminder is already scheduled. Skipping.")
                return
            }
            
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
    }
    
    public func cancelBiWeeklyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["biweeklyTestReminder"])
        print("Lucid: Bi-weekly reminder cancelled.")
    }
    
    // MARK: - Weekly Trends Reminder (7 days)
    public func scheduleWeeklyTrendsReminder() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            if requests.contains(where: { $0.identifier == "weeklyTrendsReminder" }) {
                print("Lucid: Weekly trends reminder is already scheduled. Skipping.")
                return
            }
            
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
    
    // MARK: - Exercise Reminders (Every 5 hours, 3 times a day)
    public func scheduleExerciseReminders() {
        cancelExerciseReminders()
        
        guard UserDefaults.standard.bool(forKey: "exerciseReminder") else {
            return
        }
        
        let record = ExerciseDataManager.shared.fetchTodayRecord()
        let isGoalMet = record.completedSeconds >= record.goalSeconds
        
        let calendar = Calendar.current
        let now = Date()
        let slots = [9, 14, 19] // 9:00 AM, 2:00 PM, 7:00 PM (5-hour interval, 3 times a day)
        
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
                content.title = exerciseReminderTitles.randomElement() ?? "Time to refresh your eyes!"
                content.body = exerciseReminderBodies.randomElement() ?? "Let's take a quick screen break to refresh and stretch your eyes."
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
    
    // MARK: - Daily Eye Tip Reminders (Every day at 12:00 PM noon)
    public func scheduleDailyEyeTipReminder() {
        cancelDailyEyeTipReminder()
        
        guard UserDefaults.standard.bool(forKey: "eyeTips") else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = 12
            components.minute = 0
            components.second = 0
            
            guard let scheduleDate = calendar.date(from: components) else { continue }
            
            if dayOffset == 0 && scheduleDate <= now {
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = dailyEyeTipTitles.randomElement() ?? "Daily Eye Tip"
            content.body = dailyEyeTipBodies.randomElement() ?? "Take care of your eyes today!"
            content.sound = .default
            
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: scheduleDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let identifier = "daily_eye_tip_\(dayOffset)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Lucid: Error scheduling daily eye tip reminder \(identifier): \(error)")
                }
            }
        }
        print("Lucid: Daily eye tip reminders scheduled for the next 7 days.")
    }
    
    public func cancelDailyEyeTipReminder() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToCancel = requests.filter { $0.identifier.hasPrefix("daily_eye_tip_") }.map { $0.identifier }
            if !idsToCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToCancel)
                print("Lucid: Cancelled \(idsToCancel.count) pending daily eye tip reminders.")
            }
        }
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
    
    public func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("🔔 Pending Notification Requests Count: \(requests.count)")
            for request in requests {
                let triggerDesc: String
                if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
                    triggerDesc = "Calendar (dateComponents: \(calendarTrigger.dateComponents))"
                } else if let intervalTrigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    triggerDesc = "Interval (seconds: \(intervalTrigger.timeInterval), repeats: \(intervalTrigger.repeats))"
                } else {
                    triggerDesc = "Immediate / None"
                }
                print("  - ID: \(request.identifier) | Title: \"\(request.content.title)\" | Trigger: \(triggerDesc)")
            }
        }
    }
}
