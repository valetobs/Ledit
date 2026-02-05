import SwiftUI
import WebKit
import Combine

// MARK: - Web Preview Manager
class WebPreviewManager: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    private var webView: WKWebView?
    
    func setupWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    }
    
    func loadHTML(_ htmlContent: String, css: String = "", js: String = "") {
        guard let webView = webView else { return }
        
        isLoading = true
        errorMessage = nil
        
        var processedHTML = htmlContent
        
        // Remove external CSS link references and inject inline CSS
        processedHTML = processedHTML.replacingOccurrences(
            of: "<link rel=\"stylesheet\" href=\"style.css\">",
            with: ""
        )
        processedHTML = processedHTML.replacingOccurrences(
            of: "</head>",
            with: "<style>\(css)</style></head>"
        )
        
        // Check if this is a React/Babel template (needs type="text/babel")
        let isBabelTemplate = processedHTML.contains("text/babel") || processedHTML.contains("@babel")
        
        // Remove external JS script references
        processedHTML = processedHTML.replacingOccurrences(
            of: "<script src=\"script.js\"></script>",
            with: ""
        )
        processedHTML = processedHTML.replacingOccurrences(
            of: "<script type=\"text/babel\" src=\"script.js\"></script>",
            with: ""
        )
        
        // Inject JS with correct type for React/Babel templates
        if isBabelTemplate && !js.isEmpty {
            processedHTML = processedHTML.replacingOccurrences(
                of: "</body>",
                with: "<script type=\"text/babel\">\(js)</script></body>"
            )
        } else if !js.isEmpty {
            processedHTML = processedHTML.replacingOccurrences(
                of: "</body>",
                with: "<script>\(js)</script></body>"
            )
        }
        
        webView.loadHTMLString(processedHTML, baseURL: URL(string: "https://localhost"))
        lastUpdateTime = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    func refresh() {
        webView?.reload()
    }
    
    func clearCache() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler: {})
    }
    
    func executeJavaScript(_ script: String, completion: @escaping (Any?) -> Void) {
        webView?.evaluateJavaScript(script, completionHandler: { result, error in
            if let error = error {
                self.errorMessage = "JS Error: \(error.localizedDescription)"
                completion(nil)
            } else {
                completion(result)
            }
        })
    }
}

// MARK: - Web View Representable
struct WebViewRepresentable: UIViewRepresentable {
    @ObservedObject var previewManager: WebPreviewManager
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        previewManager.setupWebView(webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // View updates handled by manager
    }
}

// MARK: - Live Code Editor with Preview
struct WebLiveEditor: View {
    @ObservedObject var previewManager: WebPreviewManager
    @State private var htmlContent: String = ""
    @State private var cssContent: String = ""
    @State private var jsContent: String = ""
    @State private var selectedTab: WebEditorTab = .html
    @State private var showPreview: Bool = true
    @State private var autoRefresh: Bool = true
    
    enum WebEditorTab {
        case html
        case css
        case js
        case preview
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("HTML").tag(WebEditorTab.html)
                    Text("CSS").tag(WebEditorTab.css)
                    Text("JS").tag(WebEditorTab.js)
                    Text("Preview").tag(WebEditorTab.preview)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Editor/Preview area
                if showPreview && selectedTab == .preview {
                    ZStack {
                        WebViewRepresentable(previewManager: previewManager)
                        
                        if previewManager.isLoading {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.white.opacity(0.8))
                        }
                    }
                } else {
                    codeEditorView
                }
                
                // Controls
                HStack {
                    Button(action: updatePreview) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Refresh Preview")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Toggle("Auto Refresh", isOn: $autoRefresh)
                        .onChange(of: autoRefresh) { newValue in
                            if newValue {
                                updatePreview()
                            }
                        }
                    
                    Spacer()
                    
                    Button(action: { previewManager.clearCache() }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .onChange(of: htmlContent) { _ in
            if autoRefresh { updatePreview() }
        }
        .onChange(of: cssContent) { _ in
            if autoRefresh { updatePreview() }
        }
        .onChange(of: jsContent) { _ in
            if autoRefresh { updatePreview() }
        }
        .onAppear {
            updatePreview()
        }
    }
    
    @ViewBuilder
    private var codeEditorView: some View {
        switch selectedTab {
        case .html:
            TextEditor(text: $htmlContent)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.systemGray6))
        case .css:
            TextEditor(text: $cssContent)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.systemGray6))
        case .js:
            TextEditor(text: $jsContent)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.systemGray6))
        case .preview:
            ZStack {
                WebViewRepresentable(previewManager: previewManager)
                
                if previewManager.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.8))
                }
            }
        }
    }
    
    private func updatePreview() {
        previewManager.loadHTML(htmlContent, css: cssContent, js: jsContent)
    }
}

// MARK: - Web Project Manager
class WebProjectManager: NSObject, ObservableObject {
    @Published var projects: [WebProject] = []
    @Published var currentProject: WebProject?
    
    override init() {
        super.init()
        loadProjects()
    }
    
    func createProject(name: String, framework: WebFramework, using template: WebTemplate? = nil) -> WebProject {
        var project = WebProject(
            name: name,
            framework: framework,
            htmlContent: template?.htmlContent ?? "",
            cssContent: template?.cssContent ?? "",
            jsContent: template?.jsContent ?? ""
        )
        
        projects.append(project)
        currentProject = project
        saveProjects()
        return project
    }
    
    func updateProject(_ project: WebProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            if currentProject?.id == project.id {
                currentProject = project
            }
            saveProjects()
        }
    }
    
    func deleteProject(_ project: WebProject) {
        projects.removeAll { $0.id == project.id }
        if currentProject?.id == project.id {
            currentProject = nil
        }
        saveProjects()
    }
    
    private func loadProjects() {
        // TODO: Load from UserDefaults or file storage
    }
    
    private func saveProjects() {
        // TODO: Save to UserDefaults or file storage
    }
}

// MARK: - Web Project Model
struct WebProject: Identifiable, Codable {
    let id: UUID
    var name: String
    var frameworkRawValue: String
    var htmlContent: String
    var cssContent: String
    var jsContent: String
    var createdDate: Date
    var lastModifiedDate: Date
    var isModified: Bool = false
    
    var framework: WebFramework {
        get { WebFramework(rawValue: frameworkRawValue) ?? .vanilla }
        set { frameworkRawValue = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        framework: WebFramework,
        htmlContent: String = "",
        cssContent: String = "",
        jsContent: String = "",
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.frameworkRawValue = framework.rawValue
        self.htmlContent = htmlContent
        self.cssContent = cssContent
        self.jsContent = jsContent
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, frameworkRawValue, htmlContent, cssContent, jsContent, createdDate, lastModifiedDate
    }
}
