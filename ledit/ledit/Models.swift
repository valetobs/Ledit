import SwiftUI
import Combine

// MARK: - File Model
struct ProjectFile: Identifiable, Hashable {
    let id: UUID
    var name: String
    var content: String
    var language: Language
    var isModified: Bool = false
    
    init(id: UUID = UUID(), name: String, content: String = "", language: Language = .swift) {
        self.id = id
        self.name = name
        self.content = content
        self.language = language
    }
    
    var icon: String {
        switch language {
        case .swift: return "swift"
        case .python: return "p.circle.fill"
        case .javascript: return "j.circle.fill"
        case .json: return "curlybraces"
        case .markdown: return "doc.text"
        case .html: return "h.circle.fill"
        case .css: return "c.circle.fill"
        case .plain: return "doc"
        }
    }
    
    var iconColor: Color {
        switch language {
        case .swift: return .orange
        case .python: return .blue
        case .javascript: return .yellow
        case .json: return .green
        case .markdown: return .purple
        case .html: return Color(red: 1.0, green: 0.67, blue: 0.0) // Orange for HTML
        case .css: return Color(red: 0.2, green: 0.66, blue: 0.99) // Blue for CSS
        case .plain: return .gray
        }
    }
}

// MARK: - Language
enum Language: String, CaseIterable {
    case swift = "Swift"
    case python = "Python"
    case javascript = "JavaScript"
    case json = "JSON"
    case markdown = "Markdown"
    case html = "HTML"
    case css = "CSS"
    case plain = "Plain Text"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .swift: return "swift"
        case .python: return "p.circle.fill"
        case .javascript: return "j.circle.fill"
        case .json: return "curlybraces"
        case .markdown: return "doc.text"
        case .html: return "h.circle.fill"
        case .css: return "c.circle.fill"
        case .plain: return "doc"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .swift: return .orange
        case .python: return .blue
        case .javascript: return .yellow
        case .json: return .green
        case .markdown: return .purple
        case .html: return Color(red: 1.0, green: 0.67, blue: 0.0) // Orange for HTML
        case .css: return Color(red: 0.2, green: 0.66, blue: 0.99) // Blue for CSS
        case .plain: return .gray
        }
    }
    
    static func detect(from filename: String) -> Language {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return .swift
        case "py": return .python
        case "js", "jsx", "ts", "tsx": return .javascript
        case "json": return .json
        case "md", "markdown": return .markdown
        case "html", "htm": return .html
        case "css": return .css
        default: return .plain
        }
    }
}

// MARK: - Console Message
struct ConsoleMessage: Identifiable {
    let id = UUID()
    let text: String
    let type: MessageType
    let timestamp: Date
    
    enum MessageType {
        case output
        case error
        case warning
        case info
        
        var color: Color {
            switch self {
            case .output: return .primary
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .output: return "chevron.right"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}

// MARK: - Project State
class ProjectState: ObservableObject {
    @Published var files: [ProjectFile] = []
    @Published var openFiles: [ProjectFile] = []
    @Published var selectedFileId: UUID?
    @Published var consoleMessages: [ConsoleMessage] = []
    @Published var isConsoleVisible: Bool = true
    @Published var isSidebarVisible: Bool = true
    @Published var consoleHeight: CGFloat = 150
    
    var selectedFile: ProjectFile? {
        guard let id = selectedFileId else { return nil }
        return openFiles.first { $0.id == id }
    }
    
    init() {
        // Create default files
        let mainFile = ProjectFile(
            name: "Main.swift",
            content: """
            import Foundation

            // MARK: - Main Application
            struct App {
                let name: String
                let version: String
                
                init(name: String, version: String = "1.0.0") {
                    self.name = name
                    self.version = version
                }
                
                func run() {
                    print("🚀 \\(name) v\\(version) is running!")
                    greet(name: "Developer")
                }
                
                func greet(name: String) {
                    let message = "Hello, \\(name)!"
                    print(message)
                }
            }

            // Create and run the app
            let myApp = App(name: "Ledit", version: "2.0.0")
            myApp.run()
            """,
            language: .swift
        )
        
        let utilsFile = ProjectFile(
            name: "Utils.swift",
            content: """
            import Foundation

            // MARK: - Utility Functions
            
            /// Formats a date to a readable string
            func formatDate(_ date: Date) -> String {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }

            /// Validates an email address
            func isValidEmail(_ email: String) -> Bool {
                let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,64}"
                let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
                return predicate.evaluate(with: email)
            }

            /// Calculates factorial recursively
            func factorial(_ n: Int) -> Int {
                guard n > 1 else { return 1 }
                return n * factorial(n - 1)
            }

            // Example usage
            print("5! = \\(factorial(5))")
            print("Current time: \\(formatDate(Date()))")
            """,
            language: .swift
        )
        
        let readmeFile = ProjectFile(
            name: "README.md",
            content: """
            # Ledit IDE
            
            A modern, lightweight code editor for iOS.
            
            ## Features
            
            - 📝 Syntax highlighting for Swift, Python, JavaScript
            - 📁 File browser with project management
            - 🎨 Multiple color themes
            - 📋 Console output panel
            - ⌨️ Code-optimized keyboard
            
            ## Getting Started
            
            1. Create a new file or open an existing one
            2. Start coding!
            3. Use the Run button to execute your code
            
            ## Keyboard Shortcuts
            
            - **Tab**: Insert indentation
            - **{}**: Auto-close brackets
            
            ---
            *Built with SwiftUI*
            """,
            language: .markdown
        )
        
        files = [mainFile, utilsFile, readmeFile]
        openFiles = [mainFile]
        selectedFileId = mainFile.id
        
        log("Welcome to Ledit IDE!", type: .info)
    }
    
    func openFile(_ file: ProjectFile) {
        if !openFiles.contains(where: { $0.id == file.id }) {
            openFiles.append(file)
        }
        selectedFileId = file.id
    }
    
    func closeFile(_ file: ProjectFile) {
        openFiles.removeAll { $0.id == file.id }
        if selectedFileId == file.id {
            selectedFileId = openFiles.last?.id
        }
    }
    
    func createNewFile(name: String, language: Language = .swift) {
        let file = ProjectFile(name: name, content: "", language: language)
        files.append(file)
        openFile(file)
        log("Created new file: \(name)", type: .info)
    }
    
    func updateFileContent(id: UUID, content: String) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            files[index].content = content
            files[index].isModified = true
        }
        if let index = openFiles.firstIndex(where: { $0.id == id }) {
            openFiles[index].content = content
            openFiles[index].isModified = true
        }
    }
    
    func deleteFile(_ file: ProjectFile) {
        closeFile(file)
        files.removeAll { $0.id == file.id }
        log("Deleted file: \(file.name)", type: .warning)
    }
    
    func renameFile(_ file: ProjectFile, to newName: String) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index].name = newName
            files[index].language = Language.detect(from: newName)
        }
        if let index = openFiles.firstIndex(where: { $0.id == file.id }) {
            openFiles[index].name = newName
            openFiles[index].language = Language.detect(from: newName)
        }
        log("Renamed to: \(newName)", type: .info)
    }
    
    func log(_ message: String, type: ConsoleMessage.MessageType = .output) {
        let msg = ConsoleMessage(text: message, type: type, timestamp: Date())
        consoleMessages.append(msg)
    }
    
    func clearConsole() {
        consoleMessages.removeAll()
    }
    
    func runCurrentFile() {
        guard let file = selectedFile else {
            log("No file selected", type: .error)
            return
        }
        
        log("▶ Running \(file.name)...", type: .info)
        
        // Simulate running - extract print statements
        let lines = file.content.components(separatedBy: "\n")
        var outputCount = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("print(") {
                // Extract string from print statement
                if let startQuote = trimmed.firstIndex(of: "\""),
                   let endQuote = trimmed.lastIndex(of: "\""),
                   startQuote < endQuote {
                    let start = trimmed.index(after: startQuote)
                    let content = String(trimmed[start..<endQuote])
                    // Handle simple string interpolation display
                    log(content, type: .output)
                    outputCount += 1
                }
            }
        }
        
        if outputCount == 0 {
            log("(No output)", type: .info)
        }
        
        log("✓ Finished", type: .info)
    }
}
