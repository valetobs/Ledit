import SwiftUI
import Combine

// MARK: - App Settings
class AppSettings: ObservableObject {
    @Published var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var selectedTheme: String {
        didSet { UserDefaults.standard.set(selectedTheme, forKey: "selectedTheme") }
    }
    @Published var showLineNumbers: Bool {
        didSet { UserDefaults.standard.set(showLineNumbers, forKey: "showLineNumbers") }
    }
    @Published var autoSave: Bool {
        didSet { UserDefaults.standard.set(autoSave, forKey: "autoSave") }
    }
    @Published var tabSize: Int {
        didSet { UserDefaults.standard.set(tabSize, forKey: "tabSize") }
    }
    
    var theme: EditorTheme {
        EditorTheme.allThemes.first { $0.name == selectedTheme } ?? .dark
    }
    
    init() {
        self.fontSize = UserDefaults.standard.object(forKey: "fontSize") as? CGFloat ?? 14
        self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
        self.showLineNumbers = UserDefaults.standard.object(forKey: "showLineNumbers") as? Bool ?? true
        self.autoSave = UserDefaults.standard.object(forKey: "autoSave") as? Bool ?? true
        self.tabSize = UserDefaults.standard.object(forKey: "tabSize") as? Int ?? 4
    }
}

// MARK: - Project Info
struct ProjectInfo: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var lastOpened: Date
    var iconName: String
    var colorHex: String
    
    init(id: UUID = UUID(), name: String, path: String = "", lastOpened: Date = Date(), iconName: String = "folder.fill", colorHex: String = "007AFF") {
        self.id = id
        self.name = name
        self.path = path
        self.lastOpened = lastOpened
        self.iconName = iconName
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Projects Manager
class ProjectsManager: ObservableObject {
    @Published var recentProjects: [ProjectInfo] = []
    
    private let projectsKey = "recentProjects"
    
    init() {
        loadProjects()
    }
    
    func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let projects = try? JSONDecoder().decode([ProjectInfo].self, from: data) {
            recentProjects = projects.sorted { $0.lastOpened > $1.lastOpened }
        } else {
            // Add some sample projects for demo
            recentProjects = [
                ProjectInfo(name: "My App", iconName: "app.fill", colorHex: "FF6B6B"),
                ProjectInfo(name: "Website", iconName: "globe", colorHex: "4ECDC4"),
                ProjectInfo(name: "API Server", iconName: "server.rack", colorHex: "45B7D1")
            ]
        }
    }
    
    func saveProjects() {
        if let data = try? JSONEncoder().encode(recentProjects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
    }
    
    func addProject(_ project: ProjectInfo) {
        recentProjects.insert(project, at: 0)
        saveProjects()
    }
    
    func updateLastOpened(_ project: ProjectInfo) {
        if let index = recentProjects.firstIndex(where: { $0.id == project.id }) {
            recentProjects[index].lastOpened = Date()
            recentProjects.sort { $0.lastOpened > $1.lastOpened }
            saveProjects()
        }
    }
    
    func deleteProject(_ project: ProjectInfo) {
        recentProjects.removeAll { $0.id == project.id }
        saveProjects()
    }
}

// MARK: - Home Screen
struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var projectsManager = ProjectsManager()
    @StateObject private var webProjectManager = WebProjectManager()
    @State private var showingNewProject = false
    @State private var showingNewWebProject = false
    @State private var showingCloneRepo = false
    @State private var showingSettings = false
    @State private var selectedProject: ProjectInfo?
    @State private var selectedWebProject: WebProject?
    @State private var navigateToEditor = false
    @State private var navigateToWebEditor = false
    @State private var appeared = false
    @State private var headerAppeared = false
    @State private var actionsAppeared = false
    @State private var projectsAppeared = false
    
    private var theme: EditorTheme {
        appState.theme
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                        .opacity(headerAppeared ? 1 : 0)
                        .offset(y: headerAppeared ? 0 : -20)
                    
                    // Quick Actions
                    quickActionsView
                        .opacity(actionsAppeared ? 1 : 0)
                        .offset(y: actionsAppeared ? 0 : 20)
                    
                    // Recent Projects
                    recentProjectsView
                        .opacity(projectsAppeared ? 1 : 0)
                        .offset(y: projectsAppeared ? 0 : 20)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(theme.background)
            .navigationTitle("Ledit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .symbolEffect(.rotate, value: showingSettings)
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectSheet(projectsManager: projectsManager, onCreated: { project in
                    selectedProject = project
                    navigateToEditor = true
                })
                .environmentObject(appState)
            }
            .sheet(isPresented: $showingNewWebProject) {
                NewWebProjectSheet(
                    isPresented: $showingNewWebProject,
                    projectManager: webProjectManager,
                    onCreated: { project in
                        selectedWebProject = project
                        navigateToWebEditor = true
                    }
                )
            }
            .sheet(isPresented: $showingCloneRepo) {
                CloneRepoSheet(projectsManager: projectsManager, onCloned: { project in
                    selectedProject = project
                    navigateToEditor = true
                })
                .environmentObject(appState)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: appState.settings)
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $navigateToEditor) {
                if let project = selectedProject {
                    LeditEditorHomeView(project: project, settings: appState.settings)
                        .environmentObject(appState)
                }
            }
            .navigationDestination(isPresented: $navigateToWebEditor) {
                if let webProject = selectedWebProject {
                    WebPreviewView(
                        project: webProject,
                        previewManager: WebPreviewManager(),
                        onUpdate: { updated in
                            webProjectManager.updateProject(updated)
                        }
                    )
                }
            }
            .onAppear {
                animateIn()
            }
        }
        .preferredColorScheme(theme.name == "Light" ? .light : .dark)
    }
    
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            headerAppeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            actionsAppeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            projectsAppeared = true
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Text("Welcome to Ledit")
                .font(.title2.bold())
                .foregroundColor(theme.text)
            
            Text("A modern code editor for iOS")
                .font(.subheadline)
                .foregroundColor(theme.lineNumberText)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Quick Actions
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(theme.text)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    icon: "plus.rectangle.fill",
                    title: "New Project",
                    color: .blue,
                    theme: theme
                ) {
                    showingNewProject = true
                }
                
                QuickActionCard(
                    icon: "arrow.down.circle.fill",
                    title: "Clone Repo",
                    color: .green,
                    theme: theme
                ) {
                    showingCloneRepo = true
                }
                
                QuickActionCard(
                    icon: "doc.fill",
                    title: "New File",
                    color: .orange,
                    theme: theme
                ) {
                    let project = ProjectInfo(name: "Untitled", iconName: "doc.fill", colorHex: "FF9500")
                    projectsManager.addProject(project)
                    selectedProject = project
                    navigateToEditor = true
                }
                
                QuickActionCard(
                    icon: "globe",
                    title: "Web Project",
                    color: Color(red: 1.0, green: 0.67, blue: 0.0),
                    theme: theme
                ) {
                    showingNewWebProject = true
                }
            }
        }
    }
    
    // MARK: - Recent Projects
    private var recentProjectsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Projects")
                    .font(.headline)
                    .foregroundColor(theme.text)
                Spacer()
                if !projectsManager.recentProjects.isEmpty {
                    Button("Clear All") {
                        withAnimation(.easeOut(duration: 0.3)) {
                            projectsManager.recentProjects.removeAll()
                            projectsManager.saveProjects()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(theme.lineNumberText)
                }
            }
            .padding(.horizontal, 4)
            
            if projectsManager.recentProjects.isEmpty {
                emptyProjectsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(projectsManager.recentProjects.enumerated()), id: \.element.id) { index, project in
                        ProjectRow(project: project, theme: theme) {
                            projectsManager.updateLastOpened(project)
                            selectedProject = project
                            navigateToEditor = true
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    projectsManager.deleteProject(project)
                                }
                            } label: {
                                Label("Remove from Recent", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyProjectsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(theme.lineNumberText)
            Text("No recent projects")
                .font(.subheadline)
                .foregroundColor(theme.lineNumberText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(theme.lineNumberBackground)
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let theme: EditorTheme
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .symbolEffect(.bounce, value: isPressed)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(theme.lineNumberBackground)
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .simultaneousGesture(
            TapGesture().onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    action()
                }
            }
        )
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: ProjectInfo
    let theme: EditorTheme
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                // Project icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(project.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: project.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(project.color)
                }
                
                // Project info
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.body.weight(.medium))
                        .foregroundColor(theme.text)
                    
                    Text(timeAgo(from: project.lastOpened))
                        .font(.caption)
                        .foregroundColor(theme.lineNumberText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.lineNumberText)
            }
            .padding(12)
            .background(theme.lineNumberBackground)
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
        .simultaneousGesture(
            TapGesture().onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    onTap()
                }
            }
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - New Project Sheet
struct NewProjectSheet: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var projectsManager: ProjectsManager
    var onCreated: (ProjectInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var selectedTemplate = "empty"
    @State private var selectedColor = "007AFF"
    
    let templates = [
        ("empty", "Empty Project", "folder"),
        ("swift", "Swift App", "swift"),
        ("web", "Web Project", "globe"),
        ("python", "Python Script", "terminal")
    ]
    
    let colors = ["007AFF", "FF6B6B", "4ECDC4", "45B7D1", "96CEB4", "FFEAA7", "DDA0DD", "FF9500"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Name") {
                    TextField("My Awesome Project", text: $projectName)
                        .autocorrectionDisabled()
                }
                
                Section("Template") {
                    ForEach(templates, id: \.0) { template in
                        HStack {
                            Image(systemName: template.2)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text(template.1)
                            Spacer()
                            if selectedTemplate == template.0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTemplate = template.0
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == colorHex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = colorHex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let icon = templates.first { $0.0 == selectedTemplate }?.2 ?? "folder"
                        let project = ProjectInfo(
                            name: projectName.isEmpty ? "Untitled" : projectName,
                            iconName: icon,
                            colorHex: selectedColor
                        )
                        projectsManager.addProject(project)
                        dismiss()
                        onCreated(project)
                    }
                }
            }
        }
    }
}

// MARK: - Clone Repo Sheet
struct CloneRepoSheet: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var projectsManager: ProjectsManager
    var onCloned: (ProjectInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var repoURL = ""
    @State private var isCloning = false
    @State private var cloneProgress: Double = 0
    @State private var errorMessage: String?
    
    let popularRepos = [
        ("apple/swift", "The Swift Programming Language"),
        ("github/gitignore", "Collection of .gitignore templates"),
        ("onevcat/Kingfisher", "Image downloading and caching library"),
        ("Alamofire/Alamofire", "HTTP networking library")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                        TextField("https://github.com/user/repo.git", text: $repoURL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                } header: {
                    Text("Repository URL")
                } footer: {
                    Text("Enter a Git repository URL to clone")
                }
                
                if isCloning {
                    Section {
                        VStack(spacing: 12) {
                            ProgressView(value: cloneProgress)
                            Text("Cloning repository...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
                
                Section("Popular Repositories") {
                    ForEach(popularRepos, id: \.0) { repo in
                        Button {
                            repoURL = "https://github.com/\(repo.0).git"
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    Text(repo.0)
                                        .font(.body.weight(.medium))
                                }
                                Text(repo.1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Clone Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        cloneRepository()
                    }
                    .disabled(repoURL.isEmpty || isCloning)
                }
            }
        }
    }
    
    private func cloneRepository() {
        guard !repoURL.isEmpty else { return }
        
        isCloning = true
        errorMessage = nil
        
        // Extract repo name from URL
        let repoName = extractRepoName(from: repoURL)
        
        // Simulate cloning progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            cloneProgress += 0.05
            
            if cloneProgress >= 1.0 {
                timer.invalidate()
                isCloning = false
                
                let project = ProjectInfo(
                    name: repoName,
                    path: repoURL,
                    iconName: "arrow.triangle.branch",
                    colorHex: "6E5494"
                )
                projectsManager.addProject(project)
                dismiss()
                onCloned(project)
            }
        }
    }
    
    private func extractRepoName(from url: String) -> String {
        let cleaned = url
            .replacingOccurrences(of: ".git", with: "")
            .trimmingCharacters(in: .init(charactersIn: "/"))
        
        if let lastComponent = cleaned.split(separator: "/").last {
            return String(lastComponent)
        }
        return "Cloned Repo"
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Editor") {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(settings.fontSize))pt")
                            .foregroundColor(.secondary)
                            .contentTransition(.numericText())
                    }
                    Slider(value: $settings.fontSize, in: 10...24, step: 1)
                        .tint(.blue)
                    
                    Picker("Theme", selection: $settings.selectedTheme) {
                        ForEach(EditorTheme.allThemes, id: \.name) { theme in
                            HStack {
                                Circle()
                                    .fill(theme.background)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(theme.text, lineWidth: 1)
                                    )
                                Text(theme.name)
                            }
                            .tag(theme.name)
                        }
                    }
                    
                    Toggle("Show Line Numbers", isOn: $settings.showLineNumbers)
                    
                    Picker("Tab Size", selection: $settings.tabSize) {
                        Text("2 spaces").tag(2)
                        Text("4 spaces").tag(4)
                        Text("8 spaces").tag(8)
                    }
                }
                
                Section("General") {
                    Toggle("Auto Save", isOn: $settings.autoSave)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2026.02.04")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset to Defaults")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset Settings", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    withAnimation {
                        settings.fontSize = 14
                        settings.selectedTheme = "Dark"
                        settings.showLineNumbers = true
                        settings.autoSave = true
                        settings.tabSize = 4
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all settings to their default values.")
            }
        }
        .preferredColorScheme(appState.theme.name == "Light" ? .light : .dark)
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    HomeScreen()
        .environmentObject(AppState())
}
