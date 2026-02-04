//
//  leditApp.swift
//  ledit
//
//  Created by vale on 2/4/26.
//

import SwiftUI
import Combine

@main
struct leditApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State (Global)
class AppState: ObservableObject {
    @Published var settings: AppSettings
    @Published var showSplash = true
    
    init() {
        self.settings = AppSettings()
    }
    
    var theme: EditorTheme {
        settings.theme
    }
}

// MARK: - Root View with Splash
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            if showContent {
                HomeScreen()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            if appState.showSplash {
                SplashScreen {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showContent = true
                    }
                    withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                        appState.showSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(appState.theme.name == "Light" ? .light : .dark)
    }
}
