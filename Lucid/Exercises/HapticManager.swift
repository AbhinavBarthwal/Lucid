import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    // Light tick for instant "hit" confirmation
    private let selectionFeedback = UISelectionFeedbackGenerator()
    // Heavy impact for "missed dot" alert
    private let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
    
    private init() {
        selectionFeedback.prepare()
        impactFeedback.prepare()
    }
    
    func triggerTick() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }
    
    func triggerFailure() {
        impactFeedback.impactOccurred()
        impactFeedback.prepare()
    }
    
    func triggerSuccessNotification() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}
