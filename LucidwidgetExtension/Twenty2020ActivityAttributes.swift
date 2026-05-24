import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *)
public struct Twenty2020ActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var hoursElapsed: Int
        public var secondsRemaining: Int
        public var isCompleted: Bool
        
        public init(hoursElapsed: Int, secondsRemaining: Int, isCompleted: Bool = false) {
            self.hoursElapsed = hoursElapsed
            self.secondsRemaining = secondsRemaining
            self.isCompleted = isCompleted
        }
    }
    
    public init() {}
}
#endif
