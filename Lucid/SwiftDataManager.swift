//
//  SwiftDataManager.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 3/18/26.
//

import Foundation
import SwiftData

@MainActor
class SwiftDataManager {
    // 1. Creates a single shared instance of the manager
    static let shared = SwiftDataManager()
    
    let container: ModelContainer
    
    // 2. Easy access to the context
    var context: ModelContext {
        container.mainContext
    }
    
    private init() {
        // 3. Register all your models here
        let schema = Schema([
            User.self,
            ExerciseSession.self,
            EyeTestSession.self,
            OSDIResult.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}


