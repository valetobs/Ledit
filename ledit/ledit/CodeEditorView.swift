import SwiftUI
import UIKit

// MARK: - Code Editor View
struct CodeEditorView: View {
    @Binding var text: String
    var language: Language
    var theme: EditorTheme
    var showLineNumbers: Bool = true
    var fontSize: CGFloat = 14
    
    @State private var lineCount: Int = 1
    @State private var scrollOffset: CGFloat = 0
    @State private var highlightedText: AttributedString = AttributedString("")
    @State private var contentHeight: CGFloat = 0
    
    private let lineHeight: CGFloat = 20
    private let lineNumberWidth: CGFloat = 44
    
    init(text: Binding<String>, language: Language = .swift, theme: EditorTheme = .dark, showLineNumbers: Bool = true, fontSize: CGFloat = 14) {
        self._text = text
        self.language = language
        self.theme = theme
        self.showLineNumbers = showLineNumbers
        self.fontSize = fontSize
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Line numbers
                if showLineNumbers {
                    LineNumbersView(
                        lineCount: lineCount,
                        lineHeight: lineHeight,
                        scrollOffset: scrollOffset,
                        theme: theme,
                        fontSize: fontSize
                    )
                    .frame(width: lineNumberWidth)
                }
                
                // Code editor
                ZStack(alignment: .topLeading) {
                    // Background
                    theme.background
                    
                    // UITextView wrapper for editing with syntax highlighting
                    HighlightedTextEditor(
                        text: $text,
                        language: language,
                        theme: theme,
                        fontSize: fontSize,
                        onScroll: { offset in
                            scrollOffset = offset
                        },
                        onTextChange: {
                            updateLineCount()
                        }
                    )
                    .padding(.horizontal, 4)
                }
            }
            .onAppear {
                updateLineCount()
            }
            .onChange(of: text) { _ in
                updateLineCount()
            }
        }
    }
    
    private func updateLineCount() {
        lineCount = max(1, text.components(separatedBy: "\n").count)
    }
}

// MARK: - Line Numbers View
struct LineNumbersView: View {
    let lineCount: Int
    let lineHeight: CGFloat
    let scrollOffset: CGFloat
    let theme: EditorTheme
    let fontSize: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1...max(1, lineCount), id: \.self) { lineNumber in
                        Text("\(lineNumber)")
                            .font(.system(size: fontSize - 1, design: .monospaced))
                            .foregroundColor(theme.lineNumberText)
                            .frame(height: lineHeight)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.top, 8)
            }
            .background(theme.lineNumberBackground)
            .disabled(true)
        }
    }
}

// MARK: - Highlighted Text Editor (UIKit wrapper)
struct HighlightedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var language: Language
    var theme: EditorTheme
    var fontSize: CGFloat
    var onScroll: (CGFloat) -> Void
    var onTextChange: () -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor(theme.background)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.spellCheckingType = .no
        textView.keyboardType = .asciiCapable
        textView.keyboardAppearance = theme.name == "Light" ? .light : .dark
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        
        // Apply highlighted text
        context.coordinator.applyHighlighting(to: textView, text: text)
        
        // Add keyboard toolbar
        let toolbar = createToolbar(for: textView, context: context)
        textView.inputAccessoryView = toolbar
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if text actually changed (to preserve cursor position)
        if uiView.text != text {
            let selectedRange = uiView.selectedRange
            context.coordinator.applyHighlighting(to: uiView, text: text)
            // Restore cursor position if valid
            if selectedRange.location <= text.count {
                uiView.selectedRange = selectedRange
            }
        }
        uiView.backgroundColor = UIColor(theme.background)
        uiView.keyboardAppearance = theme.name == "Light" ? .light : .dark
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createToolbar(for textView: UITextView, context: Context) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = theme.name == "Light" ? .default : .black
        
        let tabButton = UIBarButtonItem(title: "Tab", style: .plain, target: context.coordinator, action: #selector(Coordinator.insertTab))
        let braceButton = UIBarButtonItem(title: "{ }", style: .plain, target: context.coordinator, action: #selector(Coordinator.insertBraces))
        let bracketButton = UIBarButtonItem(title: "[ ]", style: .plain, target: context.coordinator, action: #selector(Coordinator.insertBrackets))
        let parenButton = UIBarButtonItem(title: "( )", style: .plain, target: context.coordinator, action: #selector(Coordinator.insertParens))
        let quoteButton = UIBarButtonItem(title: "\" \"", style: .plain, target: context.coordinator, action: #selector(Coordinator.insertQuotes))
        let commentButton = UIBarButtonItem(title: "//", style: .plain, target: context.coordinator, action: #selector(Coordinator.insertComment))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        
        toolbar.items = [tabButton, braceButton, bracketButton, parenButton, quoteButton, commentButton, flexSpace, doneButton]
        
        context.coordinator.textView = textView
        
        return toolbar
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: HighlightedTextEditor
        weak var textView: UITextView?
        
        init(_ parent: HighlightedTextEditor) {
            self.parent = parent
        }
        
        func applyHighlighting(to textView: UITextView, text: String) {
            let highlighter = SyntaxHighlighter(theme: parent.theme, fontSize: parent.fontSize)
            let highlighted = highlighter.highlightNS(text, language: parent.language)
            textView.attributedText = highlighted
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onTextChange()
            
            // Re-apply highlighting
            let selectedRange = textView.selectedRange
            applyHighlighting(to: textView, text: textView.text)
            // Restore cursor position
            if selectedRange.location <= textView.text.count {
                textView.selectedRange = selectedRange
            }
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.onScroll(scrollView.contentOffset.y)
        }
        
        @objc func insertTab() {
            insertText("    ")
        }
        
        @objc func insertBraces() {
            insertTextWithCursor("{\n    ", "\n}")
        }
        
        @objc func insertBrackets() {
            insertTextWithCursor("[", "]")
        }
        
        @objc func insertParens() {
            insertTextWithCursor("(", ")")
        }
        
        @objc func insertQuotes() {
            insertTextWithCursor("\"", "\"")
        }
        
        @objc func insertComment() {
            insertText("// ")
        }
        
        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }
        
        private func insertText(_ text: String) {
            guard let textView = textView else { return }
            textView.insertText(text)
        }
        
        private func insertTextWithCursor(_ before: String, _ after: String) {
            guard let textView = textView,
                  let selectedRange = textView.selectedTextRange else { return }
            
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            textView.insertText(before + after)
            
            // Move cursor between the inserted text
            if let newPosition = textView.position(from: textView.beginningOfDocument, offset: cursorPosition + before.count) {
                textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
            }
        }
    }
}

#Preview {
    CodeEditorView(
        text: .constant("""
        import SwiftUI

        struct MyView: View {
            let greeting = "Hello, world!"
            
            var body: some View {
                Text(greeting)
                    .padding()
            }
        }
        """),
        language: .swift,
        theme: .dark
    )
    .frame(height: 300)
}
