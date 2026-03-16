import Foundation

// The Model
struct DailyExerciseRecord: Codable {
    var date: Date
    var completedSeconds: Int
    var goalSeconds: Int
}

// The Manager
class ExerciseDataManager {
    static let shared = ExerciseDataManager()
    private let defaults = UserDefaults.standard
    private let key = "dailyExerciseData"
    
    // Preset goal of 20 minutes (1200 seconds)
    let defaultGoalSeconds = 20 * 60
    
    func addExerciseTime(seconds: Int) {
        var record = fetchTodayRecord()
        record.completedSeconds += seconds
        save(record: record)
    }
    
    func fetchTodayRecord() -> DailyExerciseRecord {
        // 1. Check if we have saved data
        if let data = defaults.data(forKey: key),
           let savedRecord = try? JSONDecoder().decode(DailyExerciseRecord.self, from: data) {
            
            // 2. Check if the saved record is from today
            if Calendar.current.isDateInToday(savedRecord.date) {
                return savedRecord
            }
        }
        
        // 3. If no data or it's a new day, return a fresh record starting at 0
        return DailyExerciseRecord(
            date: Date(),
            completedSeconds: 0,
            goalSeconds: defaultGoalSeconds
        )
    }
    
    private func save(record: DailyExerciseRecord) {
        if let encoded = try? JSONEncoder().encode(record) {
            defaults.set(encoded, forKey: key)
        }
    }
}
