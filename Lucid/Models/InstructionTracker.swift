import Foundation

struct InstructionTracker {
    // Static dictionary to store state in memory, initialized from UserDefaults
    static var firstRunStatus: [String: Int] = {
        var status: [String: Int] = [:]
        let keys = ["PencilPushup", "SaccadicJumps", "SmoothPursuits", "PeripheralAwareness", "Figure8", "NearFar", "Blink", "CTest"]
        for key in keys {
            if let savedValue = UserDefaults.standard.object(forKey: "InstructionFirstRun_\(key)") as? Int {
                status[key] = savedValue
            } else {
                status[key] = 1 // Default to 1 (first run)
            }
        }
        return status
    }()
    
    static func isFirstRun(for exerciseKey: String) -> Bool {
        return (firstRunStatus[exerciseKey] ?? 1) == 1
    }
    
    static func markAsCompleted(for exerciseKey: String) {
        firstRunStatus[exerciseKey] = 0
        UserDefaults.standard.set(0, forKey: "InstructionFirstRun_\(exerciseKey)")
    }
}
