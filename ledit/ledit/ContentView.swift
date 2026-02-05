import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

// MARK: - Device Detection
struct DeviceInfo {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var hasKeyboard: Bool {
        // Check if hardware keyboard is connected
        GCKeyboard.coalesced != nil
    }
}

import GameController

// MARK: - Main IDE View
struct LeditEditorHomeView: View {
    @EnvironmentObject var appState: AppState
    let projectInfo: ProjectInfo?
    @ObservedObject var settings: AppSettings
    
    @StateObject private var project = ProjectState()
    @StateObject private var statsTracker = StatsTracker.shared
    @State private var showingNewFileSheet = false
    @State private var showingRenameAlert = false
    @State private var newFileName = ""
    @State private var fileToRename: ProjectFile?
    @State private var searchText = ""
    @State private var showingSearch = false
    @State private var editorAppeared = false
    @State private var isLiveActivityActive = false
    @State private var useiPadMode = DeviceInfo.isIPad
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(project: ProjectInfo? = nil, settings: AppSettings = AppSettings()) {
        self.projectInfo = project
        self.settings = settings
    }
    
    private var theme: EditorTheme {
        settings.theme
    }
    
    var body: some View {
        Group {
            // Use iPad mode for iPad with regular size class (full screen or large split view)
            if useiPadMode && horizontalSizeClass == .regular {
                iPadEditorView(project: project)
                    .environmentObject(appState)
                    .iPadKeyboardCommands()
            } else {
                standardEditorView
            }
        }
        .background(theme.background)
        .navigationTitle(projectInfo?.name ?? project.selectedFile?.name ?? "Ledit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingNewFileSheet) {
            NewFileSheet(project: project, isPresented: $showingNewFileSheet)
        }
        .alert("Rename File", isPresented: $showingRenameAlert) {
            TextField("New name", text: $newFileName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let file = fileToRename {
                    project.renameFile(file, to: newFileName)
                }
            }
        }
    }
    
    // MARK: - Standard Editor View (iPhone / Compact)
    private var standardEditorView: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            if isLandscape {
                // Landscape: side-by-side layout
                HStack(spacing: 0) {
                    if project.isSidebarVisible {
                        sidebarView
                            .frame(width: 220)
                        
                        Divider()
                    }
                    
                    mainEditorArea
                }
            } else {
                // Portrait: stacked layout
                VStack(spacing: 0) {
                    // Tab bar at top
                    tabBarView
                    
                    mainEditorArea
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    withAnimation {
                        project.isSidebarVisible.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                }
                
                Button {
                    showingNewFileSheet = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if DeviceInfo.isIPad {
                    Button {
                        useiPadMode.toggle()
                    } label: {
                        Image(systemName: useiPadMode ? "iphone" : "desktopcomputer")
                    }
                }
                
                Button {
                    showingSearch.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                
                Button {
                    project.runCurrentFile()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(.green)
                }
                
                Menu {
                    Section("Theme") {
                        ForEach(EditorTheme.allThemes, id: \.name) { themeOption in
                            Button {
                                withAnimation {
                                    settings.selectedTheme = themeOption.name
                                }
                            } label: {
                                    HStack {
                                        Text(themeOption.name)
                                        if themeOption.name == settings.selectedTheme {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section {
                            Button {
                                withAnimation {
                                    project.isConsoleVisible.toggle()
                                }
                            } label: {
                                Label(
                                    project.isConsoleVisible ? "Hide Console" : "Show Console",
                                    systemImage: project.isConsoleVisible ? "rectangle.bottomthird.inset.filled" : "rectangle.split.1x2"
                                )
                            }
                        }
                        
                        Section("Live Activity") {
                            if #available(iOS 16.1, *) {
                                Button {
                                    toggleLiveActivity()
                                } label: {
                                    Label(
                                        isLiveActivityActive ? "Stop Live Activity" : "Start Live Activity",
                                        systemImage: isLiveActivityActive ? "stop.circle.fill" : "play.circle.fill"
                                    )
                                }
                                
                                if isLiveActivityActive {
                                    Button {
                                        LiveActivityManager.shared.simulateBuild()
                                    } label: {
                                        Label("Simulate Build", systemImage: "hammer.fill")
                                    }
                                }
                            } else {
                                Text("Requires iOS 16.1+")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section {
                            if let file = project.selectedFile {
                                ShareLink(item: file.content, preview: SharePreview(file.name))
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingNewFileSheet) {
                NewFileSheet(project: project, isPresented: $showingNewFileSheet)
            }
            .alert("Rename File", isPresented: $showingRenameAlert) {
                TextField("File name", text: $newFileName)
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    if let file = fileToRename, !newFileName.isEmpty {
                        project.renameFile(file, to: newFileName)
                    }
                }
            }
            .overlay {
                if showingSearch {
                    SearchOverlay(
                        searchText: $searchText,
                        isPresented: $showingSearch,
                        theme: theme
                    )
                }
            }
            .onChange(of: project.selectedFile?.content) { _ in
                // Update widget stats when content changes
                if let file = project.selectedFile {
                    let lines = file.content.components(separatedBy: "\n").count
                    statsTracker.updateStats(
                        fileName: file.name,
                        language: file.language.displayName,
                        lineCount: lines,
                        characterCount: file.content.count
                    )
                    statsTracker.markTodayAsCoded()
                    
                    // Also update Live Activity
                    updateLiveActivityIfNeeded()
                }
            }
            .onChange(of: project.selectedFileId) { _ in
                // Update Live Activity when switching files
                updateLiveActivityIfNeeded()
            }
            .onAppear {
                // Refresh widgets when view appears
                WidgetCenter.shared.reloadAllTimelines()
                
                // Check Live Activity status
                if #available(iOS 16.1, *) {
                    isLiveActivityActive = LiveActivityManager.shared.isActivityActive
                }
            }
            .onDisappear {
                // End Live Activity when leaving editor
                if #available(iOS 16.1, *) {
                    Task {
                        await LiveActivityManager.shared.endActivity()
                    }
                }
            }
        .preferredColorScheme(theme.name == "Light" ? .light : .dark)
    }
    
    // MARK: - Live Activity
    private func toggleLiveActivity() {
        if #available(iOS 16.1, *) {
            if isLiveActivityActive {
                Task {
                    await LiveActivityManager.shared.endActivity()
                    await MainActor.run {
                        isLiveActivityActive = false
                    }
                }
            } else {
                let projectName = projectInfo?.name ?? "Ledit Project"
                let fileName = project.selectedFile?.name ?? "Untitled"
                let language = project.selectedFile?.language.displayName ?? "Plain Text"
                let lines = project.selectedFile?.content.components(separatedBy: "\n").count ?? 0
                let chars = project.selectedFile?.content.count ?? 0
                
                LiveActivityManager.shared.startActivity(
                    projectName: projectName,
                    fileName: fileName,
                    language: language,
                    lineCount: lines,
                    characterCount: chars
                )
                isLiveActivityActive = true
            }
        }
    }
    
    private func updateLiveActivityIfNeeded() {
        guard isLiveActivityActive, #available(iOS 16.1, *) else { return }
        
        if let file = project.selectedFile {
            LiveActivityManager.shared.updateActivity(
                fileName: file.name,
                language: file.language.displayName,
                lineCount: file.content.components(separatedBy: "\n").count,
                characterCount: file.content.count
            )
        }
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Project header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                Text(projectInfo?.name ?? "Project")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(theme.lineNumberBackground)
            
            // File list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(project.files) { file in
                        FileRowView(
                            file: file,
                            isSelected: file.id == project.selectedFileId,
                            theme: theme,
                            onTap: {
                                project.openFile(file)
                            },
                            onRename: {
                                fileToRename = file
                                newFileName = file.name
                                showingRenameAlert = true
                            },
                            onDelete: {
                                project.deleteFile(file)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            .background(theme.background)
        }
    }
    
    // MARK: - Tab Bar View
    private var tabBarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(project.openFiles) { file in
                    TabItemView(
                        file: file,
                        isSelected: file.id == project.selectedFileId,
                        theme: theme,
                        onSelect: {
                            project.selectedFileId = file.id
                        },
                        onClose: {
                            project.closeFile(file)
                        }
                    )
                }
            }
        }
        .frame(height: 36)
        .background(theme.lineNumberBackground)
    }
    
    // MARK: - Main Editor Area
    private var mainEditorArea: some View {
        VStack(spacing: 0) {
            // Editor
            if let file = project.selectedFile,
               let index = project.openFiles.firstIndex(where: { $0.id == file.id }) {
                CodeEditorView(
                    text: Binding(
                        get: { project.openFiles[index].content },
                        set: { project.updateFileContent(id: file.id, content: $0) }
                    ),
                    language: file.language,
                    theme: theme,
                    showLineNumbers: settings.showLineNumbers,
                    fontSize: settings.fontSize
                )
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(theme.lineNumberText)
                    Text("No file open")
                        .foregroundColor(theme.lineNumberText)
                    Button("Create New File") {
                        showingNewFileSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.background)
            }
            
            // Console
            if project.isConsoleVisible {
                Divider()
                ConsoleView(project: project, theme: theme)
                    .frame(height: project.consoleHeight)
            }
        }
    }
}

// MARK: - File Row View
struct FileRowView: View {
    let file: ProjectFile
    let isSelected: Bool
    let theme: EditorTheme
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: file.icon)
                    .foregroundColor(file.iconColor)
                    .frame(width: 20)
                
                Text(file.name)
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(theme.text)
                    .lineLimit(1)
                
                if file.isModified {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? theme.selection : Color.clear)
            .cornerRadius(6)
        }
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Tab Item View
struct TabItemView: View {
    let file: ProjectFile
    let isSelected: Bool
    let theme: EditorTheme
    let onSelect: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Button(action: onSelect) {
                HStack(spacing: 4) {
                    Image(systemName: file.icon)
                        .font(.system(size: 10))
                        .foregroundColor(file.iconColor)
                    
                    Text(file.name)
                        .font(.system(size: 12))
                        .foregroundColor(theme.text)
                        .lineLimit(1)
                    
                    if file.isModified {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(theme.lineNumberText)
            }
            .padding(4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? theme.background : theme.lineNumberBackground)
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.blue : Color.clear)
                .frame(height: 2),
            alignment: .bottom
        )
    }
}

// MARK: - Console View
struct ConsoleView: View {
    @ObservedObject var project: ProjectState
    let theme: EditorTheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Console header
            HStack {
                Image(systemName: "terminal")
                Text("Console")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                
                Button {
                    project.clearConsole()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.lineNumberBackground)
            .foregroundColor(theme.text)
            
            // Console output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(project.consoleMessages) { message in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: message.type.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(message.type.color)
                                    .frame(width: 14)
                                
                                Text(message.text)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(message.type.color)
                                
                                Spacer()
                                
                                Text(formatTime(message.timestamp))
                                    .font(.system(size: 9))
                                    .foregroundColor(theme.lineNumberText)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                            .id(message.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(theme.background)
                .onChange(of: project.consoleMessages.count) { _ in
                    if let lastMessage = project.consoleMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - New File Sheet
struct NewFileSheet: View {
    @ObservedObject var project: ProjectState
    @Binding var isPresented: Bool
    @State private var fileName = ""
    @State private var selectedLanguage: Language = .swift
    
    var body: some View {
        NavigationStack {
            Form {
                Section("File Name") {
                    TextField("Enter file name", text: $fileName)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                Section("Language") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section("Templates") {
                    Button("Swift View") {
                        fileName = "NewView.swift"
                        selectedLanguage = .swift
                    }
                    Button("Python Script") {
                        fileName = "script.py"
                        selectedLanguage = .python
                    }
                    Button("JavaScript") {
                        fileName = "index.js"
                        selectedLanguage = .javascript
                    }
                }
            }
            .navigationTitle("New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if !fileName.isEmpty {
                            project.createNewFile(name: fileName, language: selectedLanguage)
                            isPresented = false
                        }
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Search Overlay
struct SearchOverlay: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    let theme: EditorTheme
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.lineNumberText)
                
                TextField("Search in file...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(theme.text)
                
                Button {
                    isPresented = false
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.lineNumberText)
                }
            }
            .padding()
            .background(theme.lineNumberBackground)
            .cornerRadius(10)
            .shadow(radius: 10)
            .padding()
            
            Spacer()
        }
        .background(Color.black.opacity(0.3))
        .onTapGesture {
            isPresented = false
        }
    }
}

#Preview {
    NavigationStack {
        LeditEditorHomeView()
            .environmentObject(AppState())
    }
}

