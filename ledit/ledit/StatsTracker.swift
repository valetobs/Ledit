import Foundation
import WidgetKit
import Combine

// MARK: - Coding Stats (Shared with Widget)
struct CodingStats: Codable {
    var totalLines: Int
    var totalFiles: Int
    var lastFileName: String
    var lastLanguage: String
    var lastEditedDate: Date
    var todayLines: Int
    var streak: Int
    
    static let placeholder = CodingStats(
        totalLines: 0,
        totalFiles: 0,
        lastFileName: "Untitled",
        lastLanguage: "Plain Text",
        lastEditedDate: Date(),
        todayLines: 0,
        streak: 0
    )
    
    static func load() -> CodingStats {
        if let data = UserDefaults(suiteName: "group.com.ledit.app")?.data(forKey: "codingStats"),
           let stats = try? JSONDecoder().decode(CodingStats.self, from: data) {
            return stats
        }
        return .placeholder
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults(suiteName: "group.com.ledit.app")?.set(data, forKey: "codingStats")
            // Tell widgets to refresh
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - Stats Tracker
class StatsTracker: ObservableObject {
    static let shared = StatsTracker()
    
    @Published var stats: CodingStats
    
    private let defaults = UserDefaults(suiteName: "group.com.ledit.app")
    private var lastLineCount: Int = 0
    private var lastDate: String = ""
    
    private init() {
        self.stats = CodingStats.load()
        checkStreak()
    }
    
    // Update stats when file is edited
    func updateStats(fileName: String, language: String, lineCount: Int, characterCount: Int) {
        let today = dateString(Date())
        
        // Check if it's a new day
        if today != lastDate {
            if lastDate.isEmpty {
                // First time
                lastDate = today
            } else {
                // New day - reset today's lines
                stats.todayLines = 0
                lastDate = today
                lastLineCount = lineCount
            }
        }
        
        // Calculate lines added
        let linesAdded = max(0, lineCount - lastLineCount)
        if linesAdded > 0 && lastLineCount > 0 {
            stats.todayLines += linesAdded
            stats.totalLines += linesAdded
        }
        lastLineCount = lineCount
        
        // Update file info
        stats.lastFileName = fileName
        stats.lastLanguage = language
        stats.lastEditedDate = Date()
        
        // Save and update widgets
        stats.save()
    }
    
    // Called when a new file is created
    func fileCreated() {
        stats.totalFiles += 1
        stats.save()
    }
    
    // Check and update streak
    private func checkStreak() {
        let lastEditDateString = dateString(stats.lastEditedDate)
        let today = dateString(Date())
        let yesterday = dateString(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        if lastEditDateString == today {
            // Already coded today, streak maintained
        } else if lastEditDateString == yesterday {
            // Last coded yesterday, increment streak on first edit today
            // Streak will be incremented on first save today
        } else if lastEditDateString != today {
            // Streak broken
            stats.streak = 0
            stats.todayLines = 0
        }
    }
    
    // Mark today as coded (increments streak if needed)
    func markTodayAsCoded() {
        let lastEditDateString = dateString(stats.lastEditedDate)
        let today = dateString(Date())
        let yesterday = dateString(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        if lastEditDateString != today {
            if lastEditDateString == yesterday {
                stats.streak += 1
            } else {
                stats.streak = 1
            }
            stats.save()
        }
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
