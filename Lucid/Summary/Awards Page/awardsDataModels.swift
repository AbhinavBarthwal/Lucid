//
//  awardsDataModels.swift
//  Lucid
//
//  Created by Kanishka Bansal on 12/03/26.
//

import Foundation

struct Badge  : Encodable , Decodable{
    let id: String
    let title: String
    let imageName: String
    var dateEarned: String?
    var isUnlocked: Bool
}

struct ExerciseRecord: Codable {
    var counter: Int = 0
    var time: Date? = nil
    var currentStreak: Int = 0
    
    mutating func logNewSession() {
        counter += 1
        let now = Date()
        
        if let previousTime = time {
            if Calendar.current.isDateInToday(previousTime) {
                print("Session logged. Streak maintained.")
            } else if Calendar.current.isDateInYesterday(previousTime) {
                currentStreak += 1
                print("Streak increased to \(currentStreak)!")
            } else {
                currentStreak = 1
                print("Streak reset to 1.")
            }
        } else {
            currentStreak = 1
        }
        time = now
    }
}

class ProgressManager {
    static let shared = ProgressManager()
    private let defaults = UserDefaults.standard
    

    func saveRecord(_ record: ExerciseRecord) {
        if let encoded = try? JSONEncoder().encode(record) {
            defaults.set(encoded, forKey: "userExerciseRecord")
        }
    }
    
    func loadRecord() -> ExerciseRecord {
        if let savedData = defaults.object(forKey: "userExerciseRecord") as? Data,
           let decodedRecord = try? JSONDecoder().decode(ExerciseRecord.self, from: savedData) {
            return decodedRecord
        }
        return ExerciseRecord()
    }
    
    // Save and Load the Badges
    func saveBadges(_ badges: [Badge]) {
        if let encoded = try? JSONEncoder().encode(badges) {
            defaults.set(encoded, forKey: "userBadges")
        }
    }
    
    func loadBadges() -> [Badge] {
        if let savedData = defaults.object(forKey: "userBadges") as? Data,
           let decodedBadges = try? JSONDecoder().decode([Badge].self, from: savedData) {
            return decodedBadges
        }
        
        return [
            Badge(id: "exercise_1", title: "1st Exercise", imageName: "Image", dateEarned: nil, isUnlocked: false),
            Badge(id: "streak_1", title: "1 Day Streak", imageName: "Image2", dateEarned: nil, isUnlocked: false),
            Badge(id: "test_10", title: "10th Test", imageName: "Image", dateEarned: nil, isUnlocked: false)
        ]
    }
}
