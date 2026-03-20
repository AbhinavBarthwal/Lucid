import UIKit

class NotificationsViewController: UITableViewController {

    @IBOutlet weak var digitalTimeSwitch: UISwitch!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var eyeTrendSwitch: UISwitch!
    @IBOutlet weak var exerciseReminderSwitch: UISwitch!
    @IBOutlet weak var suggestionSwitch: UISwitch!
    @IBOutlet weak var badgeSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSwitchStates()
    }

    @IBAction func digitalTimeChanged(_ sender: UISwitch) {
        saveState(key: "digitalTime", value: sender.isOn)
    }

    @IBAction func reminderChanged(_ sender: UISwitch) {
        saveState(key: "reminder", value: sender.isOn)
    }

    @IBAction func eyeTrendChanged(_ sender: UISwitch) {
        saveState(key: "eyeTrend", value: sender.isOn)
    }

    @IBAction func exerciseReminderChanged(_ sender: UISwitch) {
        saveState(key: "exerciseReminder", value: sender.isOn)
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
        digitalTimeSwitch.isOn = UserDefaults.standard.bool(forKey: "digitalTime")
        reminderSwitch.isOn = UserDefaults.standard.bool(forKey: "reminder")
        eyeTrendSwitch.isOn = UserDefaults.standard.bool(forKey: "eyeTrend")
        exerciseReminderSwitch.isOn = UserDefaults.standard.bool(forKey: "exerciseReminder")
        suggestionSwitch.isOn = UserDefaults.standard.bool(forKey: "suggestion")
        badgeSwitch.isOn = UserDefaults.standard.bool(forKey: "badge")
    }
}
