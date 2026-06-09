import UIKit

class NotificationsViewController: UITableViewController {


    @IBOutlet weak var reminderSwitch: UISwitch?
    @IBOutlet weak var eyeTrendSwitch: UISwitch?

    @IBOutlet weak var badgeSwitch: UISwitch?
    @IBOutlet weak var exerciseReminderSwitch: UISwitch?
    @IBOutlet weak var eyeTipsSwitch: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()

        loadSwitchStates()

        NotificationManager.shared.requestAuthorization { granted in
            guard granted else { return }
            NotificationManager.shared.refreshScheduledNotificationsFromDefaults()
        }
    }



    @IBAction func eyeTipsChanged(_ sender: UISwitch) {
        saveState(key: "eyeTips", value: sender.isOn)
        if sender.isOn {
            NotificationManager.shared.scheduleDailyEyeTipReminder()
        } else {
            NotificationManager.shared.cancelDailyEyeTipReminder()
        }
    }

    @IBAction func reminderChanged(_ sender: UISwitch) {
        saveState(key: "reminder", value: sender.isOn)
        if sender.isOn {
            NotificationManager.shared.scheduleBiWeeklyReminder()
        } else {
            NotificationManager.shared.cancelBiWeeklyReminder()
        }
    }

    @IBAction func eyeTrendChanged(_ sender: UISwitch) {
        saveState(key: "eyeTrend", value: sender.isOn)
        if sender.isOn {
            NotificationManager.shared.scheduleWeeklyTrendsReminder()
        } else {
            NotificationManager.shared.cancelWeeklyTrendsReminder()
        }
    }

    @IBAction func exerciseReminderChanged(_ sender: UISwitch) {
        saveState(key: "exerciseReminder", value: sender.isOn)
        if sender.isOn {
            NotificationManager.shared.scheduleExerciseReminders()
        } else {
            NotificationManager.shared.cancelExerciseReminders()
        }
    }



    @IBAction func badgeChanged(_ sender: UISwitch) {
        saveState(key: "badge", value: sender.isOn)
    }

    func saveState(key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func loadSwitchStates() {
        NotificationManager.shared.registerDefaultSettings()
        

        reminderSwitch?.isOn = UserDefaults.standard.bool(forKey: "reminder")
        eyeTrendSwitch?.isOn = UserDefaults.standard.bool(forKey: "eyeTrend")

        badgeSwitch?.isOn = UserDefaults.standard.bool(forKey: "badge")
        exerciseReminderSwitch?.isOn = UserDefaults.standard.bool(forKey: "exerciseReminder")
        eyeTipsSwitch?.isOn = UserDefaults.standard.bool(forKey: "eyeTips")
    }
}
