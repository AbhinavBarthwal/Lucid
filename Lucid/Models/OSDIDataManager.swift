//
//  OSDIDataManager.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 4/6/26.
//

import Foundation
import SwiftData

@MainActor
class OSDIDataManager {
    static let shared = OSDIDataManager()
    
    func saveOSDIScore(score: Double, severity: String) {
        let user = SwiftDataManager.shared.getCurrentUser()
        let newSession = OSDISession(score: score, severity: severity)
        
        newSession.user = user
        SwiftDataManager.shared.context.insert(newSession)
        
        do {
            try SwiftDataManager.shared.context.save()
            print("✅ Saved OSDI Score: \(score) (\(severity)) for \(user.name)")
        } catch {
            print("❌ OSDI Save failed: \(error)")
        }
    }
}
