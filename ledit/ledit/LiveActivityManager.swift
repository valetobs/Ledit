import Foundation
import ActivityKit
import SwiftUI
import Combine

// MARK: - Activity Attributes (Must match Widget Extension)
struct LeditActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
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

// MARK: - Live Activity Manager
@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published private(set) var currentActivity: Activity<LeditActivityAttributes>?
    @Published var isActivityActive: Bool = false
    
    private init() {}
    
    // Check if Live Activities are available
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // Start a new Live Activity
    func startActivity(projectName: String, fileName: String, language: String, lineCount: Int, characterCount: Int) {
        guard areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity first
        Task {
            await endActivity()
        }
        
        let attributes = LeditActivityAttributes(projectName: projectName)
        let initialState = LeditActivityAttributes.ContentState(
            fileName: fileName,
            language: language,
            lineCount: lineCount,
            characterCount: characterCount,
            lastSaved: Date(),
            buildStatus: .idle
        )
        
        let content = ActivityContent(state: initialState, staleDate: nil)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            
            DispatchQueue.main.async {
                self.currentActivity = activity
                self.isActivityActive = true
            }
            
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    // Update the Live Activity
    func updateActivity(
        fileName: String? = nil,
        language: String? = nil,
        lineCount: Int? = nil,
        characterCount: Int? = nil,
        buildStatus: LeditActivityAttributes.ContentState.BuildStatus? = nil
    ) {
        guard let activity = currentActivity else { return }
        
        Task {
            let currentState = activity.content.state
            let updatedState = LeditActivityAttributes.ContentState(
                fileName: fileName ?? currentState.fileName,
                language: language ?? currentState.language,
                lineCount: lineCount ?? currentState.lineCount,
                characterCount: characterCount ?? currentState.characterCount,
                lastSaved: Date(),
                buildStatus: buildStatus ?? currentState.buildStatus
            )
            
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await activity.update(content)
        }
    }
    
    // Simulate a build
    func simulateBuild() {
        updateActivity(buildStatus: .building)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            let success = Bool.random()
            self?.updateActivity(buildStatus: success ? .success : .failed)
            
            // Reset after showing result
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                self?.updateActivity(buildStatus: .idle)
            }
        }
    }
    
    // End the Live Activity
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = activity.content.state
        let content = ActivityContent(state: finalState, staleDate: nil)
        
        await activity.end(content, dismissalPolicy: .immediate)
        
        await MainActor.run {
            self.currentActivity = nil
            self.isActivityActive = false
        }
        
        print("Ended Live Activity")
    }
}

// MARK: - Fallback for older iOS versions
class LiveActivityManagerFallback: ObservableObject {
    static let shared = LiveActivityManagerFallback()
    @Published var isActivityActive: Bool = false
    
    var areActivitiesEnabled: Bool { false }
    
    func startActivity(projectName: String, fileName: String, language: String, lineCount: Int, characterCount: Int) {}
    func updateActivity(fileName: String? = nil, language: String? = nil, lineCount: Int? = nil, characterCount: Int? = nil) {}
    func simulateBuild() {}
    func endActivity() async {}
}
