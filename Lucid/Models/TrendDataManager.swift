//
//  TrendDataManager.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 4/4/26.
//

import Foundation
import SwiftData

@MainActor
class TrendDataManager {
    static let shared = TrendDataManager()
    
    /// Generates the last `count` months up to the current date.
    /// Returns a tuple of the Date (for comparison) and the String (for the Chart label).
    private func getLastMonths(count: Int) -> [(date: Date, name: String)] {
        var months: [(Date, String)] = []
        let calendar = Calendar.current
        let today = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM" // Formats as "Jan", "Feb", etc.
        
        // Loop backwards to get past months, then reverse it so chronological order is maintained
        for i in (0..<count).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: today) {
                months.append((date, formatter.string(from: date)))
            }
        }
        return months
    }
    
    // MARK: - Exercise Accuracy Trends
    func getExerciseAccuracyTrends(months: Int = 6) -> (average: String, data: [TrendData]) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let calendar = Calendar.current
        
        let targetMonths = getLastMonths(count: months)
        
        // Determine the start date of our timeframe to optimize the fetch
        guard let firstMonth = targetMonths.first?.date,
              let startDate = calendar.dateInterval(of: .month, for: firstMonth)?.start else {
            return ("0", [])
        }
        
        let userId = user.id
        // Only fetch sessions from the start date onwards
        let predicate = #Predicate<ExerciseSession> { session in
            session.startingDate >= startDate && session.user?.id == userId
        }
        
        let descriptor = FetchDescriptor<ExerciseSession>(predicate: predicate)
        let sessions = (try? SwiftDataManager.shared.context.fetch(descriptor)) ?? []
        
        return processTrends(
            sessions: sessions,
            targetMonths: targetMonths,
            dateExtractor: { $0.startingDate },
            valueExtractor: { session in
                // Only return a value if accuracyScore exists
                session.accuracyScore.map { Double($0) }
            }
        )
    }
    
    // MARK: - Eye Test Score Trends
    func getEyeTestTrends(months: Int = 6) -> (average: String, data: [TrendData]) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let calendar = Calendar.current
        
        let targetMonths = getLastMonths(count: months)
        
        guard let firstMonth = targetMonths.first?.date,
              let startDate = calendar.dateInterval(of: .month, for: firstMonth)?.start else {
            return ("0", [])
        }
        
        let userId = user.id
        let predicate = #Predicate<CTestSession> { session in
            session.startingTime >= startDate && session.user?.id == userId
        }
        
        let descriptor = FetchDescriptor<CTestSession>(predicate: predicate)
        let sessions = (try? SwiftDataManager.shared.context.fetch(descriptor)) ?? []
        
        return processTrends(
            sessions: sessions,
            targetMonths: targetMonths,
            dateExtractor: { $0.startingTime },
            valueExtractor: { $0.score }
        )
    }
    
    // MARK: - Generic Trend Processor
    private func processTrends<T>(
        sessions: [T],
        targetMonths: [(date: Date, name: String)],
        dateExtractor: (T) -> Date,
        valueExtractor: (T) -> Double?
    ) -> (average: String, data: [TrendData]) {
        let calendar = Calendar.current
        
        // Group values by Year and Month
        var monthlyValues: [DateComponents: [Double]] = [:]
        
        for session in sessions {
            let date = dateExtractor(session)
            guard let val = valueExtractor(session) else { continue }
            
            let components = calendar.dateComponents([.year, .month], from: date)
            monthlyValues[components, default: []].append(val)
        }
        
        var trendData: [TrendData] = []
        var allValues: [Double] = []
        
        // Iterate through our target months to ensure every month has an entry (0 if empty)
        for monthInfo in targetMonths {
            let components = calendar.dateComponents([.year, .month], from: monthInfo.date)
            let valuesForMonth = monthlyValues[components] ?? []
            
            let averageValue: Double
            if valuesForMonth.isEmpty {
                averageValue = 0.0 // Set to 0 if no data
            } else {
                averageValue = valuesForMonth.reduce(0, +) / Double(valuesForMonth.count)
                allValues.append(contentsOf: valuesForMonth) // Track all values for overall average
            }
            
            trendData.append(TrendData(month: monthInfo.name, value: averageValue))
        }
        
        // Calculate total average across all valid sessions in the timeframe
        let overallAverage: Double = allValues.isEmpty ? 0 : allValues.reduce(0, +) / Double(allValues.count)
        let formattedAverage = String(format: "%.1f", overallAverage)
        
        return (formattedAverage, trendData)
    }
    

    func getOSDITrends(months: Int = 6) -> (average: String, data: [TrendData]) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let calendar = Calendar.current
        
        let targetMonths = getLastMonths(count: months) // Uses your existing private method
        
        guard let firstMonth = targetMonths.first?.date,
              let startDate = calendar.dateInterval(of: .month, for: firstMonth)?.start else {
            return ("0", [])
        }
        
        let userId = user.id
        let predicate = #Predicate<OSDISession> { session in
            session.date >= startDate && session.user?.id == userId
        }
        
        let descriptor = FetchDescriptor<OSDISession>(predicate: predicate)
        let sessions = (try? SwiftDataManager.shared.context.fetch(descriptor)) ?? []
        
        return processTrends(
            sessions: sessions,
            targetMonths: targetMonths,
            dateExtractor: { $0.date },
            valueExtractor: { $0.score }
        )
    }
}
