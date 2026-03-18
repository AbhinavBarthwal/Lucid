//
//  nearFarDataModel.swift
//  Lucid
//
//  Created by Kanishka Bansal on 12/03/26.
//

//No. of single and double blinks -> For blink training

import Foundation

struct ExerciseRecord: Codable {
    var counter: Int = 0
    var time: Date? = nil
    var currentStreak: Int = 0
    
    // The logic to update the streak when an exercise is finished
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
