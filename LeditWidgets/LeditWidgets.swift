import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Shared Data Model for Widgets
struct CodingStats: Codable {
    var totalLines: Int
    var totalFiles: Int
    var lastFileName: String
    var lastLanguage: String
    var lastEditedDate: Date
    var todayLines: Int
    var streak: Int
    
    static let placeholder = CodingStats(
        totalLines: 1250,
        totalFiles: 8,
        lastFileName: "Main.swift",
        lastLanguage: "Swift",
        lastEditedDate: Date(),
        todayLines: 156,
        streak: 5
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
        }
    }
}

// MARK: - Live Activity Attributes
struct LeditActivityAttributes: ActivityAttributes {
    // Static data that doesn't change
    public struct ContentState: Codable, Hashable {
        // Dynamic data that can be updated
        var fileName: String
        var language: String
        var lineCount: Int
        var characterCount: Int
        var lastSaved: Date
        var buildStatus: BuildStatus
        
        enum BuildStatus: String, Codable, Hashable {
            case idle
            case building
            case success
            case failed
        }
    }
    
    var projectName: String
}

// MARK: - Live Activity Widget
struct LeditLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeditActivityAttributes.self) { context in
            // Lock Screen / Banner presentation
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: languageIcon(context.state.language))
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(languageColor(context.state.language))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.language)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(context.attributes.projectName)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        buildStatusView(context.state.buildStatus)
                        Text(timeAgo(context.state.lastSaved))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.fileName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 24) {
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text("\(context.state.lineCount)")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Text("Lines")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 28)
                        
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "character.cursor.ibeam")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text(formatCount(context.state.characterCount))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Text("Chars")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact leading - language icon
                Image(systemName: languageIcon(context.state.language))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(languageColor(context.state.language))
            } compactTrailing: {
                // Compact trailing - line count or build status
                if context.state.buildStatus == .building {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                } else {
                    Text("\(context.state.lineCount)L")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
            } minimal: {
                // Minimal presentation
                ZStack {
                    if context.state.buildStatus == .building {
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(.white)
                    } else if context.state.buildStatus == .success {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    } else if context.state.buildStatus == .failed {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func buildStatusView(_ status: LeditActivityAttributes.ContentState.BuildStatus) -> some View {
        switch status {
        case .idle:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("Ready")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }
        case .building:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(.orange)
                Text("Building")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
            }
        case .success:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                Text("Success")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
            }
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                Text("Failed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LeditActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Language icon
            ZStack {
                Circle()
                    .fill(languageColor(context.state.language).opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: languageIcon(context.state.language))
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(languageColor(context.state.language))
            }
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.fileName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(context.state.lineCount) lines", systemImage: "text.line.first.and.arrowtriangle.forward")
                    Label(formatCount(context.state.characterCount), systemImage: "character.cursor.ibeam")
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Build status
            VStack(alignment: .trailing, spacing: 4) {
                buildStatusIcon(context.state.buildStatus)
                Text(timeAgo(context.state.lastSaved))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    func buildStatusIcon(_ status: LeditActivityAttributes.ContentState.BuildStatus) -> some View {
        switch status {
        case .idle:
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.blue)
        case .building:
            ProgressView()
                .tint(.orange)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.red)
        }
    }
}

// MARK: - Timeline Provider
struct CodingStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> CodingStatsEntry {
        CodingStatsEntry(date: Date(), stats: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CodingStatsEntry) -> Void) {
        let entry = CodingStatsEntry(date: Date(), stats: CodingStats.load())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CodingStatsEntry>) -> Void) {
        let entry = CodingStatsEntry(date: Date(), stats: CodingStats.load())
        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CodingStatsEntry: TimelineEntry {
    let date: Date
    let stats: CodingStats
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: CodingStatsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Ledit")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(entry.stats.streak) day streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("\(entry.stats.todayLines)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("lines today")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: CodingStatsEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    Text("Ledit")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.stats.todayLines)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("lines today")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.stats.streak) day streak")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Right side - Recent file
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: languageIcon(entry.stats.lastLanguage))
                        .font(.system(size: 20))
                        .foregroundColor(languageColor(entry.stats.lastLanguage))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.stats.lastFileName)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Text(entry.stats.lastLanguage)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(timeAgo(entry.stats.lastEditedDate))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: CodingStatsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Ledit")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.stats.streak)")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            
            Divider()
            
            // Stats grid
            HStack(spacing: 16) {
                StatBox(title: "Today", value: "\(entry.stats.todayLines)", subtitle: "lines", icon: "calendar", color: .blue)
                StatBox(title: "Total", value: formatNumber(entry.stats.totalLines), subtitle: "lines", icon: "text.alignleft", color: .green)
                StatBox(title: "Files", value: "\(entry.stats.totalFiles)", subtitle: "created", icon: "doc.fill", color: .purple)
            }
            
            Divider()
            
            // Recent file
            VStack(alignment: .leading, spacing: 8) {
                Text("Last Edited")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(languageColor(entry.stats.lastLanguage).opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: languageIcon(entry.stats.lastLanguage))
                            .font(.system(size: 20))
                            .foregroundColor(languageColor(entry.stats.lastLanguage))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.stats.lastFileName)
                            .font(.system(size: 15, weight: .semibold))
                        
                        HStack(spacing: 8) {
                            Text(entry.stats.lastLanguage)
                            Text("•")
                            Text(timeAgo(entry.stats.lastEditedDate))
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Quick action hint
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12))
                Text("Tap to open Ledit")
                    .font(.system(size: 12))
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Stat Box Component
struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Lock Screen Widgets
struct LockScreenCircularView: View {
    let entry: CodingStatsEntry
    
    var body: some View {
        Gauge(value: Double(min(entry.stats.todayLines, 500)) / 500.0) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
        } currentValueLabel: {
            Text("\(entry.stats.todayLines)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct LockScreenRectangularView: View {
    let entry: CodingStatsEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 20, weight: .medium))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.stats.todayLines) lines today")
                    .font(.system(size: 14, weight: .semibold))
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(entry.stats.streak) day streak")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LockScreenInlineView: View {
    let entry: CodingStatsEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
            Text("\(entry.stats.todayLines) lines")
            Text("•")
            Image(systemName: "flame.fill")
            Text("\(entry.stats.streak)d")
        }
    }
}

// MARK: - Helper Functions
func languageIcon(_ language: String) -> String {
    switch language.lowercased() {
    case "swift": return "swift"
    case "python": return "chevron.left.forwardslash.chevron.right"
    case "javascript", "js": return "j.square.fill"
    case "json": return "curlybraces"
    case "markdown": return "doc.text.fill"
    default: return "doc.fill"
    }
}

func languageColor(_ language: String) -> Color {
    switch language.lowercased() {
    case "swift": return .orange
    case "python": return .blue
    case "javascript", "js": return .yellow
    case "json": return .green
    case "markdown": return .purple
    default: return .gray
    }
}

func timeAgo(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

func formatNumber(_ number: Int) -> String {
    if number >= 1000 {
        return String(format: "%.1fK", Double(number) / 1000.0)
    }
    return "\(number)"
}

// MARK: - Widget Configurations
struct LeditStatsWidget: Widget {
    let kind: String = "LeditStatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodingStatsProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Coding Stats")
        .description("Track your daily coding progress")
        .supportedFamilies([.systemSmall])
    }
}

struct LeditMediumWidget: Widget {
    let kind: String = "LeditMediumWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodingStatsProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Coding Overview")
        .description("View your stats and recent files")
        .supportedFamilies([.systemMedium])
    }
}

struct LeditLargeWidget: Widget {
    let kind: String = "LeditLargeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodingStatsProvider()) { entry in
            LargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Full Dashboard")
        .description("Complete coding dashboard with stats")
        .supportedFamilies([.systemLarge])
    }
}

struct LeditLockScreenWidget: Widget {
    let kind: String = "LeditLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodingStatsProvider()) { entry in
            switch WidgetFamily.accessoryCircular {
            default:
                LockScreenCircularView(entry: entry)
            }
        }
        .configurationDisplayName("Quick Stats")
        .description("See your coding stats at a glance")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Widget Bundle
@main
struct LeditWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LeditStatsWidget()
        LeditMediumWidget()
        LeditLargeWidget()
        LeditLockScreenWidget()
        LeditLiveActivity()
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    LeditStatsWidget()
} timeline: {
    CodingStatsEntry(date: Date(), stats: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    LeditMediumWidget()
} timeline: {
    CodingStatsEntry(date: Date(), stats: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    LeditLargeWidget()
} timeline: {
    CodingStatsEntry(date: Date(), stats: .placeholder)
}
