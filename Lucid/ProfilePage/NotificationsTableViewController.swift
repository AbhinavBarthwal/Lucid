import UIKit

class NotificationsViewController: UITableViewController {

    @IBOutlet weak var digitalTimeSwitch: UISwitch?
    @IBOutlet weak var reminderSwitch: UISwitch?
    @IBOutlet weak var eyeTrendSwitch: UISwitch?
    @IBOutlet weak var suggestionSwitch: UISwitch?
    @IBOutlet weak var badgeSwitch: UISwitch?
    @IBOutlet weak var exerciseReminderSwitch: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request authorization on view load
        NotificationManager.shared.requestAuthorization()
        
        loadSwitchStates()
    }

    @IBAction func digitalTimeChanged(_ sender: UISwitch) {
        saveState(key: "digitalTime", value: sender.isOn)
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

    @IBAction func suggestionChanged(_ sender: UISwitch) {
        saveState(key: "suggestion", value: sender.isOn)
    }

    @IBAction func badgeChanged(_ sender: UISwitch) {
        saveState(key: "badge", value: sender.isOn)
    }

    func saveState(key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func loadSwitchStates() {
        // Register default states as true (enabled)
        UserDefaults.standard.register(defaults: [
            "digitalTime": true,
            "reminder": true,
            "eyeTrend": true,
            "exerciseReminder": true,
            "badge": true,
            "suggestion": true
        ])
        
        digitalTimeSwitch?.isOn = UserDefaults.standard.bool(forKey: "digitalTime")
        reminderSwitch?.isOn = UserDefaults.standard.bool(forKey: "reminder")
        eyeTrendSwitch?.isOn = UserDefaults.standard.bool(forKey: "eyeTrend")
        suggestionSwitch?.isOn = UserDefaults.standard.bool(forKey: "suggestion")
        badgeSwitch?.isOn = UserDefaults.standard.bool(forKey: "badge")
        exerciseReminderSwitch?.isOn = UserDefaults.standard.bool(forKey: "exerciseReminder")
    }
}
