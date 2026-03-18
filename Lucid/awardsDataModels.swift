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

class ProgressManager {
    static let shared = ProgressManager()
    private let defaults = UserDefaults.standard
    
    // Save and Load the Exercise Record
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
        return ExerciseRecord() // Returns a blank record if it's their first time
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
        
        // If it's their first time opening the app, give them the default locked badges
        return [
            Badge(id: "exercise_1", title: "1st Exercise", imageName: "Image", dateEarned: nil, isUnlocked: false),
            Badge(id: "streak_1", title: "1 Day Streak", imageName: "Image2", dateEarned: nil, isUnlocked: false),
            Badge(id: "test_10", title: "10th Test", imageName: "Image", dateEarned: nil, isUnlocked: false)
        ]
    }
}
