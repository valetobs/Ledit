import SwiftUI
import WebKit

// MARK: - Web Preview View
struct WebPreviewView: View {
    @ObservedObject var previewManager: WebPreviewManager
    @State private var htmlContent: String
    @State private var cssContent: String
    @State private var jsContent: String
    @State private var selectedTab: String = "html"
    @State private var autoRefresh: Bool = true
    @State private var showConsole: Bool = false
    @State private var consoleLogs: [String] = []
    @State private var splitRatio: CGFloat = 0.5
    
    let project: WebProject
    let onUpdate: (WebProject) -> Void
    
    init(project: WebProject, previewManager: WebPreviewManager, onUpdate: @escaping (WebProject) -> Void) {
        self.project = project
        self._htmlContent = State(initialValue: project.htmlContent)
        self._cssContent = State(initialValue: project.cssContent)
        self._jsContent = State(initialValue: project.jsContent)
        self.previewManager = previewManager
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            if isLandscape {
                // Split view: Editor on left, Preview on right
                HStack(spacing: 0) {
                    // Editor Side
                    VStack(spacing: 0) {
                        TabView(selection: $selectedTab) {
                            TextEditor(text: $htmlContent)
                                .tag("html")
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: htmlContent) { newValue in
                                    updateProject()
                                    if autoRefresh { refreshPreview() }
                                }
                            
                            TextEditor(text: $cssContent)
                                .tag("css")
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: cssContent) { newValue in
                                    updateProject()
                                    if autoRefresh { refreshPreview() }
                                }
                            
                            TextEditor(text: $jsContent)
                                .tag("js")
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: jsContent) { newValue in
                                    updateProject()
                                    if autoRefresh { refreshPreview() }
                                }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                        // Code Editor Tabs
                        HStack(spacing: 12) {
                            ForEach(["html", "css", "js"], id: \.self) { tab in
                                Button(action: { selectedTab = tab }) {
                                    Text(tab.uppercased())
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(selectedTab == tab ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(selectedTab == tab ? .white : .primary)
                                        .cornerRadius(6)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    // Preview Side
                    VStack(spacing: 0) {
                        WebViewRepresentable(previewManager: previewManager)
                            .overlay(alignment: .center) {
                                if previewManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                }
                            }
                        
                        // Controls
                        HStack {
                            Button(action: refreshPreview) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Refresh")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            
                            Toggle("Auto", isOn: $autoRefresh)
                                .labelsHidden()
                                .font(.caption)
                            
                            Button(action: { previewManager.clearCache() }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            if let lastUpdate = previewManager.lastUpdateTime {
                                Text("Updated: \(lastUpdate.formatted(date: .omitted, time: .standard))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Portrait: Stacked view
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        TabView(selection: $selectedTab) {
                            TextEditor(text: $htmlContent)
                                .tag("html")
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: htmlContent) { newValue in
                                    updateProject()
                                    if autoRefresh { refreshPreview() }
                                }
                            
                            TextEditor(text: $cssContent)
                                .tag("css")
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: cssContent) { newValue in
                                    updateProject()
                                    if autoRefresh { refreshPreview() }
                                }
                            
                            TextEditor(text: $jsContent)
                                .tag("js")
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: jsContent) { newValue in
                                    updateProject()
                                    if autoRefresh { refreshPreview() }
                                }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                        HStack(spacing: 12) {
                            ForEach(["html", "css", "js"], id: \.self) { tab in
                                Button(action: { selectedTab = tab }) {
                                    Text(tab.uppercased())
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(selectedTab == tab ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(selectedTab == tab ? .white : .primary)
                                        .cornerRadius(4)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                    }
                    .frame(maxHeight: geometry.size.height * 0.5)
                    
                    Divider()
                    
                    VStack(spacing: 0) {
                        WebViewRepresentable(previewManager: previewManager)
                            .overlay(alignment: .center) {
                                if previewManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                }
                            }
                        
                        HStack {
                            Button(action: refreshPreview) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Refresh")
                                }
                                .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                            
                            Toggle("Auto", isOn: $autoRefresh)
                                .labelsHidden()
                                .font(.caption2)
                            
                            Button(action: { previewManager.clearCache() }) {
                                Image(systemName: "trash")
                                    .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                    }
                }
            }
        }
        .onAppear {
            refreshPreview()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section("Templates") {
                        if let framework = WebFramework(rawValue: project.framework.rawValue) {
                            ForEach(WebTemplate.templates(for: framework), id: \.name) { template in
                                Button(action: { loadTemplate(template) }) {
                                    Text(template.name)
                                }
                            }
                        }
                    }
                    
                    Section("Snippets") {
                        Menu {
                            ForEach(WebDevUtils.jsSnippets.keys.sorted(), id: \.self) { key in
                                Button(action: { insertSnippet(WebDevUtils.jsSnippets[key] ?? "") }) {
                                    Text(key)
                                }
                            }
                        } label: {
                            Label("JS Snippets", systemImage: "j.circle.fill")
                        }
                        
                        Menu {
                            ForEach(WebDevUtils.cssSnippets.keys.sorted(), id: \.self) { key in
                                Button(action: { insertSnippet(WebDevUtils.cssSnippets[key] ?? "") }) {
                                    Text(key)
                                }
                            }
                        } label: {
                            Label("CSS Snippets", systemImage: "c.circle.fill")
                        }
                    }
                    
                    Divider()
                    
                    Button(action: { previewManager.refresh() }) {
                        Label("Force Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func refreshPreview() {
        previewManager.loadHTML(htmlContent, css: cssContent, js: jsContent)
    }
    
    private func updateProject() {
        var updatedProject = project
        updatedProject.htmlContent = htmlContent
        updatedProject.cssContent = cssContent
        updatedProject.jsContent = jsContent
        updatedProject.isModified = true
        updatedProject.lastModifiedDate = Date()
        onUpdate(updatedProject)
    }
    
    private func loadTemplate(_ template: WebTemplate) {
        htmlContent = template.htmlContent
        cssContent = template.cssContent
        jsContent = template.jsContent
        selectedTab = "html"
        updateProject()
        refreshPreview()
    }
    
    private func insertSnippet(_ snippet: String) {
        // Insert snippet into the appropriate editor
        if selectedTab == "js" {
            jsContent += "\n\n" + snippet
        } else if selectedTab == "css" {
            cssContent += "\n\n" + snippet
        }
        updateProject()
        if autoRefresh { refreshPreview() }
    }
}

// MARK: - Web Projects List View
struct WebProjectsListView: View {
    @ObservedObject var projectManager: WebProjectManager
    @State private var showNewProjectSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(projectManager.projects) { project in
                    NavigationLink(destination: WebPreviewView(project: project, previewManager: WebPreviewManager()) { updated in
                        projectManager.updateProject(updated)
                    }) {
                        HStack {
                            Image(systemName: project.framework.icon)
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.headline)
                                
                                HStack(spacing: 8) {
                                    Text(project.framework.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(project.lastModifiedDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if project.isModified {
                                Image(systemName: "circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        projectManager.deleteProject(projectManager.projects[index])
                    }
                }
            }
            .navigationTitle("Web Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewProjectSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewProjectSheet) {
                NewWebProjectSheet(
                    isPresented: $showNewProjectSheet,
                    projectManager: projectManager
                )
            }
        }
    }
}

// MARK: - New Web Project Sheet
struct NewWebProjectSheet: View {
    @Binding var isPresented: Bool
    let projectManager: WebProjectManager
    var onCreated: ((WebProject) -> Void)?
    
    @State private var projectName: String = ""
    @State private var framework: WebFramework = .vanilla
    @State private var selectedTemplate: WebTemplate?
    
    private var templates: [WebTemplate] {
        WebTemplate.templates(for: framework)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $projectName)
                    
                    Picker("Framework", selection: $framework) {
                        ForEach(WebFramework.allCases, id: \.self) { fw in
                            HStack {
                                Image(systemName: fw.icon)
                                Text(fw.displayName)
                            }
                            .tag(fw)
                        }
                    }
                    .onChange(of: framework) { _ in
                        selectedTemplate = nil
                    }
                }
                
                Section(header: Text("Templates")) {
                    if templates.isEmpty {
                        Text("No templates available for this framework")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(templates, id: \.name) { template in
                            Button(action: { selectedTemplate = template }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .foregroundColor(.primary)
                                        Text(template.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedTemplate?.name == template.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Web Project")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let name = projectName.isEmpty ? "Untitled Web Project" : projectName
                        let project = projectManager.createProject(
                            name: name,
                            framework: framework,
                            using: selectedTemplate
                        )
                        onCreated?(project)
                        isPresented = false
                    }
                }
            }
        }
    }
}
