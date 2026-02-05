import SwiftUI
import UIKit
import Combine

// MARK: - Keyboard Shortcuts Manager
class KeyboardShortcutsManager: ObservableObject {
    static let shared = KeyboardShortcutsManager()
    
    @Published var lastCommand: KeyboardCommand?
    
    enum KeyboardCommand: String {
        case newFile = "New File"
        case newWebProject = "New Web Project"
        case save = "Save"
        case saveAll = "Save All"
        case closeFile = "Close File"
        case find = "Find"
        case findReplace = "Find & Replace"
        case toggleSidebar = "Toggle Sidebar"
        case toggleConsole = "Toggle Console"
        case run = "Run"
        case build = "Build"
        case togglePreview = "Toggle Preview"
        case goToLine = "Go to Line"
        case formatDocument = "Format Document"
        case undo = "Undo"
        case redo = "Redo"
        case settings = "Settings"
        case quickOpen = "Quick Open"
    }
}

// MARK: - iPad Optimized Editor View
struct iPadEditorView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var project: ProjectState
    @StateObject private var keyboardManager = KeyboardShortcutsManager.shared
    
    @State private var showSidebar = true
    @State private var showConsole = true
    @State private var showQuickOpen = false
    @State private var showFindPanel = false
    @State private var showGoToLine = false
    @State private var sidebarWidth: CGFloat = 260
    @State private var consoleHeight: CGFloat = 200
    @State private var focusedPane: EditorPane = .editor
    
    enum EditorPane: Hashable {
        case sidebar
        case editor
        case console
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar
                if showSidebar {
                    iPadSidebarView(project: project)
                        .frame(width: sidebarWidth)
                        .background(appState.theme.lineNumberBackground)
                    
                    // Resizable divider
                    iPadDivider(isVertical: true) { delta in
                        sidebarWidth = max(200, min(400, sidebarWidth + delta))
                    }
                }
                
                // Main content
                VStack(spacing: 0) {
                    // Toolbar
                    iPadToolbar(
                        showSidebar: $showSidebar,
                        showConsole: $showConsole,
                        showQuickOpen: $showQuickOpen,
                        showFindPanel: $showFindPanel,
                        project: project
                    )
                    
                    // Tab bar
                    iPadTabBar(project: project)
                    
                    // Editor area
                    if let file = project.selectedFile {
                        iPadCodeEditor(
                            file: file,
                            project: project,
                            theme: appState.theme,
                            showFindPanel: $showFindPanel
                        )
                    } else {
                        iPadWelcomeView()
                    }
                    
                    // Console
                    if showConsole {
                        iPadDivider(isVertical: false) { delta in
                            consoleHeight = max(100, min(400, consoleHeight - delta))
                        }
                        
                        iPadConsoleView(project: project)
                            .frame(height: consoleHeight)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if showQuickOpen {
                QuickOpenPanel(
                    isPresented: $showQuickOpen,
                    project: project
                )
                .padding(.top, 100)
            }
        }
        .overlay(alignment: .center) {
            if showGoToLine {
                GoToLinePanel(
                    isPresented: $showGoToLine,
                    project: project
                )
            }
        }
        .onReceive(keyboardManager.$lastCommand) { command in
            handleCommand(command)
        }
    }
    
    private func handleCommand(_ command: KeyboardShortcutsManager.KeyboardCommand?) {
        guard let command = command else { return }
        
        switch command {
        case .toggleSidebar:
            withAnimation(.easeInOut(duration: 0.2)) {
                showSidebar.toggle()
            }
        case .toggleConsole:
            withAnimation(.easeInOut(duration: 0.2)) {
                showConsole.toggle()
            }
        case .quickOpen:
            showQuickOpen = true
        case .goToLine:
            showGoToLine = true
        case .find:
            showFindPanel = true
        default:
            break
        }
    }
}

// MARK: - iPad Toolbar
struct iPadToolbar: View {
    @Binding var showSidebar: Bool
    @Binding var showConsole: Bool
    @Binding var showQuickOpen: Bool
    @Binding var showFindPanel: Bool
    @ObservedObject var project: ProjectState
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side
            HStack(spacing: 12) {
                Button(action: { withAnimation { showSidebar.toggle() } }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 16))
                        .foregroundColor(showSidebar ? .accentColor : .secondary)
                }
                .keyboardShortcut("b", modifiers: .command)
                
                Divider().frame(height: 20)
                
                Button(action: { /* New file */ }) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 16))
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            Spacer()
            
            // Center - Quick Open
            Button(action: { showQuickOpen = true }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Quick Open")
                        .font(.system(size: 13))
                    Text("⌘P")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("p", modifiers: .command)
            
            Spacer()
            
            // Right side
            HStack(spacing: 12) {
                Button(action: { showFindPanel.toggle() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button(action: { project.runCurrentFile() }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider().frame(height: 20)
                
                Button(action: { withAnimation { showConsole.toggle() } }) {
                    Image(systemName: "terminal")
                        .font(.system(size: 16))
                        .foregroundColor(showConsole ? .accentColor : .secondary)
                }
                .keyboardShortcut("j", modifiers: .command)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
}

// MARK: - iPad Sidebar
struct iPadSidebarView: View {
    @ObservedObject var project: ProjectState
    @State private var hoveredFileId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("EXPLORER")
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { /* Add file */ }) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Divider()
            
            // File list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(project.files) { file in
                        iPadFileRow(
                            file: file,
                            isSelected: project.selectedFileId == file.id,
                            isHovered: hoveredFileId == file.id
                        )
                        .onTapGesture {
                            project.openFile(file)
                        }
                        .contextMenu {
                            Button("Rename") { }
                            Button("Duplicate") { }
                            Divider()
                            Button("Delete", role: .destructive) {
                                project.deleteFile(file)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - iPad File Row
struct iPadFileRow: View {
    let file: ProjectFile
    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: file.icon)
                .font(.system(size: 14))
                .foregroundColor(file.iconColor)
                .frame(width: 20)
            
            Text(file.name)
                .font(.system(size: 13))
                .lineLimit(1)
            
            Spacer()
            
            if file.isModified {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - iPad Tab Bar
struct iPadTabBar: View {
    @ObservedObject var project: ProjectState
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(project.openFiles) { file in
                    iPadTab(
                        file: file,
                        isSelected: project.selectedFileId == file.id,
                        onSelect: { project.selectedFileId = file.id },
                        onClose: { project.closeFile(file) }
                    )
                }
                Spacer()
            }
        }
        .frame(height: 36)
        .background(Color(.systemGray6))
    }
}

// MARK: - iPad Tab
struct iPadTab: View {
    let file: ProjectFile
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: file.icon)
                .font(.system(size: 12))
                .foregroundColor(file.iconColor)
            
            Text(file.name)
                .font(.system(size: 12))
                .lineLimit(1)
            
            Button(action: onClose) {
                Image(systemName: file.isModified ? "circle.fill" : "xmark")
                    .font(.system(size: file.isModified ? 6 : 8))
                    .foregroundColor(file.isModified ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isSelected ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isSelected ? Color(.systemBackground) : (isHovered ? Color(.systemGray5) : Color.clear)
        )
        .overlay(alignment: .bottom) {
            if isSelected {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - iPad Code Editor
struct iPadCodeEditor: View {
    let file: ProjectFile
    @ObservedObject var project: ProjectState
    let theme: EditorTheme
    @Binding var showFindPanel: Bool
    
    @State private var cursorPosition: (line: Int, column: Int) = (1, 1)
    
    var body: some View {
        VStack(spacing: 0) {
            // Find panel
            if showFindPanel {
                iPadFindPanel(isPresented: $showFindPanel)
            }
            
            // Editor
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: Binding(
                    get: { file.content },
                    set: { project.updateFileContent(id: file.id, content: $0) }
                ))
                .font(.system(size: 14, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(theme.background)
                
                // Status bar
                iPadStatusBar(
                    file: file,
                    cursorPosition: cursorPosition
                )
            }
        }
    }
}

// MARK: - iPad Status Bar
struct iPadStatusBar: View {
    let file: ProjectFile
    let cursorPosition: (line: Int, column: Int)
    
    var body: some View {
        HStack(spacing: 16) {
            Text("Ln \(cursorPosition.line), Col \(cursorPosition.column)")
                .font(.system(size: 11, design: .monospaced))
            
            Divider()
                .frame(height: 12)
            
            Text(file.language.displayName)
                .font(.system(size: 11))
            
            Divider()
                .frame(height: 12)
            
            Text("UTF-8")
                .font(.system(size: 11))
            
            Spacer()
            
            if file.isModified {
                Text("Modified")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .foregroundColor(.secondary)
    }
}

// MARK: - iPad Console View
struct iPadConsoleView: View {
    @ObservedObject var project: ProjectState
    
    var body: some View {
        VStack(spacing: 0) {
            // Console header
            HStack {
                Text("CONSOLE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { project.clearConsole() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Console content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(project.consoleMessages) { message in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: message.type.icon)
                                .font(.system(size: 10))
                                .foregroundColor(message.type.color)
                                .frame(width: 14)
                            
                            Text(message.text)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(message.type.color)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    }
                }
            }
            .background(Color.black.opacity(0.9))
        }
    }
}

// MARK: - iPad Divider (Resizable)
struct iPadDivider: View {
    let isVertical: Bool
    let onDrag: (CGFloat) -> Void
    
    @State private var isHovered = false
    @GestureState private var isDragging = false
    
    var body: some View {
        Rectangle()
            .fill(isHovered || isDragging ? Color.accentColor : Color(.separator))
            .frame(width: isVertical ? 4 : nil, height: isVertical ? nil : 4)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        onDrag(isVertical ? value.translation.width : value.translation.height)
                    }
            )
    }
}

// MARK: - Quick Open Panel
struct QuickOpenPanel: View {
    @Binding var isPresented: Bool
    @ObservedObject var project: ProjectState
    
    @State private var searchText = ""
    @State private var selectedIndex = 0
    
    private var filteredFiles: [ProjectFile] {
        if searchText.isEmpty {
            return project.files
        }
        return project.files.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Go to file...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if filteredFiles.indices.contains(selectedIndex) {
                            project.openFile(filteredFiles[selectedIndex])
                            isPresented = false
                        }
                    }
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(.systemGray5))
            
            Divider()
            
            // Results
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredFiles.enumerated()), id: \.element.id) { index, file in
                        HStack {
                            Image(systemName: file.icon)
                                .foregroundColor(file.iconColor)
                                .frame(width: 20)
                            
                            Text(file.name)
                                .font(.system(size: 13))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(index == selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear)
                        .onTapGesture {
                            project.openFile(file)
                            isPresented = false
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 500)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}

// MARK: - Go to Line Panel
struct GoToLinePanel: View {
    @Binding var isPresented: Bool
    @ObservedObject var project: ProjectState
    
    @State private var lineNumber = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Go to Line")
                .font(.headline)
            
            TextField("Line number", text: $lineNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .onSubmit {
                    isPresented = false
                }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("Go") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 250)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}

// MARK: - iPad Find Panel
struct iPadFindPanel: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var showReplace = false
    @State private var caseSensitive = false
    @State private var wholeWord = false
    @State private var useRegex = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    
                    TextField("Find", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                
                // Options
                HStack(spacing: 4) {
                    OptionButton(icon: "textformat", isActive: $caseSensitive, tooltip: "Match Case")
                    OptionButton(icon: "textformat.abc", isActive: $wholeWord, tooltip: "Whole Word")
                    OptionButton(icon: "asterisk", isActive: $useRegex, tooltip: "Regex")
                }
                
                // Navigation
                Button(action: { /* Previous */ }) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.bordered)
                
                Button(action: { /* Next */ }) {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.bordered)
                
                // Toggle replace
                Button(action: { showReplace.toggle() }) {
                    Image(systemName: showReplace ? "chevron.up.square" : "chevron.down.square")
                }
                .buttonStyle(.bordered)
                
                // Close
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
            }
            
            if showReplace {
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.triangle.swap")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        
                        TextField("Replace", text: $replaceText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                    }
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                    
                    Button("Replace") { }
                        .buttonStyle(.bordered)
                    
                    Button("Replace All") { }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let icon: String
    @Binding var isActive: Bool
    let tooltip: String
    
    var body: some View {
        Button(action: { isActive.toggle() }) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .frame(width: 24, height: 24)
                .background(isActive ? Color.accentColor : Color.clear)
                .foregroundColor(isActive ? .white : .secondary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iPad Welcome View
struct iPadWelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Text("Ledit")
                .font(.largeTitle.bold())
            
            VStack(alignment: .leading, spacing: 12) {
                KeyboardShortcutRow(keys: ["⌘", "N"], description: "New File")
                KeyboardShortcutRow(keys: ["⌘", "P"], description: "Quick Open")
                KeyboardShortcutRow(keys: ["⌘", "S"], description: "Save")
                KeyboardShortcutRow(keys: ["⌘", "B"], description: "Toggle Sidebar")
                KeyboardShortcutRow(keys: ["⌘", "J"], description: "Toggle Console")
                KeyboardShortcutRow(keys: ["⌘", "F"], description: "Find")
                KeyboardShortcutRow(keys: ["⌘", "R"], description: "Run")
            }
            .padding(24)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Keyboard Shortcut Row
struct KeyboardShortcutRow: View {
    let keys: [String]
    let description: String
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray4))
                        .cornerRadius(4)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Keyboard Commands Modifier
struct iPadKeyboardCommandsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func iPadKeyboardCommands() -> some View {
        modifier(iPadKeyboardCommandsModifier())
    }
}
