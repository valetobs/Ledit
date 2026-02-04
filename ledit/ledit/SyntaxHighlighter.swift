import SwiftUI
import UIKit

struct SyntaxHighlighter {
    let theme: EditorTheme
    let fontSize: CGFloat
    
    // Swift keywords
    private let swiftKeywords: Set<String> = [
        "import", "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
        "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
        "return", "break", "continue", "throw", "throws", "rethrows", "try", "catch",
        "async", "await", "actor", "nonisolated", "isolated", "some", "any",
        "public", "private", "internal", "fileprivate", "open", "final", "static",
        "override", "mutating", "nonmutating", "lazy", "weak", "unowned",
        "init", "deinit", "subscript", "typealias", "associatedtype",
        "where", "in", "is", "as", "self", "Self", "super", "nil", "true", "false",
        "get", "set", "willSet", "didSet", "inout", "defer", "fallthrough"
    ]
    
    // Swift built-in types
    private let swiftTypes: Set<String> = [
        "String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set",
        "Optional", "Result", "Error", "Void", "Any", "AnyObject", "Never",
        "Character", "Data", "Date", "URL", "UUID", "CGFloat", "CGPoint", "CGSize", "CGRect",
        "View", "Text", "Image", "Button", "VStack", "HStack", "ZStack", "List", "ForEach",
        "NavigationView", "NavigationStack", "NavigationLink", "ScrollView", "Form", "Section",
        "Color", "Font", "Binding", "State", "Published", "ObservableObject",
        "App", "Scene", "WindowGroup", "ContentView"
    ]
    
    init(theme: EditorTheme, fontSize: CGFloat = 14) {
        self.theme = theme
        self.fontSize = fontSize
    }
    
    func highlightNS(_ text: String, language: Language) -> NSAttributedString {
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(theme.text)
        ]
        
        let result = NSMutableAttributedString(string: text, attributes: attributes)
        
        guard !text.isEmpty else { return result }
        
        switch language {
        case .swift:
            highlightSwiftNS(text: text, in: result)
        case .python:
            highlightPythonNS(text: text, in: result)
        case .javascript:
            highlightJavaScriptNS(text: text, in: result)
        case .json:
            highlightJSONNS(text: text, in: result)
        case .markdown:
            highlightMarkdownNS(text: text, in: result)
        case .plain:
            break
        }
        
        return result
    }
    
    private func highlightSwiftNS(text: String, in attributedString: NSMutableAttributedString) {
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // Track ranges that are already highlighted (comments, strings)
        var highlightedRanges: [NSRange] = []
        
        // 1. Single-line comments
        if let regex = try? NSRegularExpression(pattern: "//.*$", options: .anchorsMatchLines) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.comment), range: match.range)
                highlightedRanges.append(match.range)
            }
        }
        
        // 2. Multi-line comments
        if let regex = try? NSRegularExpression(pattern: "/\\*[\\s\\S]*?\\*/", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.comment), range: match.range)
                highlightedRanges.append(match.range)
            }
        }
        
        // 3. String literals (including multi-line)
        if let regex = try? NSRegularExpression(pattern: "\"\"\"[\\s\\S]*?\"\"\"|\"(?:[^\"\\\\]|\\\\.)*\"", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if !isInHighlightedRange(match.range, highlightedRanges: highlightedRanges) {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.string), range: match.range)
                    highlightedRanges.append(match.range)
                }
            }
        }
        
        // 4. Numbers
        if let regex = try? NSRegularExpression(pattern: "\\b\\d+\\.?\\d*\\b", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if !isInHighlightedRange(match.range, highlightedRanges: highlightedRanges) {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.number), range: match.range)
                }
            }
        }
        
        // 5. Attributes (@something)
        if let regex = try? NSRegularExpression(pattern: "@\\w+", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if !isInHighlightedRange(match.range, highlightedRanges: highlightedRanges) {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.preprocessor), range: match.range)
                }
            }
        }
        
        // 6. Keywords and types
        if let regex = try? NSRegularExpression(pattern: "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if !isInHighlightedRange(match.range, highlightedRanges: highlightedRanges) {
                    let word = nsString.substring(with: match.range)
                    if swiftKeywords.contains(word) {
                        attributedString.addAttribute(.foregroundColor, value: UIColor(theme.keyword), range: match.range)
                    } else if swiftTypes.contains(word) || (word.first?.isUppercase == true && word.count > 1) {
                        attributedString.addAttribute(.foregroundColor, value: UIColor(theme.type), range: match.range)
                    }
                }
            }
        }
        
        // 7. Function calls (word followed by parenthesis)
        if let regex = try? NSRegularExpression(pattern: "\\b([a-z_][a-zA-Z0-9_]*)\\s*(?=\\()", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if match.numberOfRanges > 1 {
                    let funcRange = match.range(at: 1)
                    if !isInHighlightedRange(funcRange, highlightedRanges: highlightedRanges) {
                        let word = nsString.substring(with: funcRange)
                        if !swiftKeywords.contains(word) {
                            attributedString.addAttribute(.foregroundColor, value: UIColor(theme.function), range: funcRange)
                        }
                    }
                }
            }
        }
    }
    
    private func highlightPythonNS(text: String, in attributedString: NSMutableAttributedString) {
        let pythonKeywords: Set<String> = [
            "and", "as", "assert", "async", "await", "break", "class", "continue",
            "def", "del", "elif", "else", "except", "finally", "for", "from",
            "global", "if", "import", "in", "is", "lambda", "nonlocal", "not",
            "or", "pass", "raise", "return", "try", "while", "with", "yield",
            "True", "False", "None", "self"
        ]
        
        highlightGenericNS(text: text, in: attributedString, keywords: pythonKeywords, commentPattern: "#.*$")
    }
    
    private func highlightJavaScriptNS(text: String, in attributedString: NSMutableAttributedString) {
        let jsKeywords: Set<String> = [
            "async", "await", "break", "case", "catch", "class", "const", "continue",
            "debugger", "default", "delete", "do", "else", "export", "extends",
            "finally", "for", "function", "if", "import", "in", "instanceof",
            "let", "new", "return", "static", "super", "switch", "this", "throw",
            "try", "typeof", "var", "void", "while", "with", "yield",
            "true", "false", "null", "undefined"
        ]
        
        highlightGenericNS(text: text, in: attributedString, keywords: jsKeywords, commentPattern: "//.*$")
    }
    
    private func highlightJSONNS(text: String, in attributedString: NSMutableAttributedString) {
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // String keys (before colon)
        if let regex = try? NSRegularExpression(pattern: "\"([^\"]+)\"\\s*:", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if match.numberOfRanges > 1 {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.property), range: match.range(at: 1))
                }
            }
        }
        
        // String values (after colon)
        if let regex = try? NSRegularExpression(pattern: ":\\s*\"([^\"]+)\"", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if match.numberOfRanges > 1 {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.string), range: match.range(at: 1))
                }
            }
        }
        
        // Numbers
        if let regex = try? NSRegularExpression(pattern: ":\\s*(\\d+\\.?\\d*)", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if match.numberOfRanges > 1 {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.number), range: match.range(at: 1))
                }
            }
        }
        
        // Booleans and null
        if let regex = try? NSRegularExpression(pattern: "\\b(true|false|null)\\b", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.keyword), range: match.range)
            }
        }
    }
    
    private func highlightMarkdownNS(text: String, in attributedString: NSMutableAttributedString) {
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // Headers
        if let regex = try? NSRegularExpression(pattern: "^#{1,6}\\s+.*$", options: .anchorsMatchLines) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.keyword), range: match.range)
            }
        }
        
        // Bold
        if let regex = try? NSRegularExpression(pattern: "\\*\\*[^*]+\\*\\*|__[^_]+__", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.type), range: match.range)
            }
        }
        
        // Inline code
        if let regex = try? NSRegularExpression(pattern: "`[^`]+`", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.string), range: match.range)
            }
        }
        
        // Links
        if let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^)]+\\)", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.function), range: match.range)
            }
        }
    }
    
    private func highlightGenericNS(text: String, in attributedString: NSMutableAttributedString, keywords: Set<String>, commentPattern: String) {
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        var highlightedRanges: [NSRange] = []
        
        // Comments
        if let regex = try? NSRegularExpression(pattern: commentPattern, options: .anchorsMatchLines) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: UIColor(theme.comment), range: match.range)
                highlightedRanges.append(match.range)
            }
        }
        
        // Strings
        if let regex = try? NSRegularExpression(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if !isInHighlightedRange(match.range, highlightedRanges: highlightedRanges) {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.string), range: match.range)
                    highlightedRanges.append(match.range)
                }
            }
        }
        
        // Numbers
        if let regex = try? NSRegularExpression(pattern: "\\b\\d+\\.?\\d*\\b", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if !isInHighlightedRange(match.range, highlightedRanges: highlightedRanges) {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(theme.number), range: match.range)
                }
            }
        }
        
        // Keywords
        if let regex = try? NSRegularExpression(pattern: "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b", options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if !isInHighlightedRange(match.range, highlightedRanges: highlightedRanges) {
                    let word = nsString.substring(with: match.range)
                    if keywords.contains(word) {
                        attributedString.addAttribute(.foregroundColor, value: UIColor(theme.keyword), range: match.range)
                    }
                }
            }
        }
    }
    
    private func isInHighlightedRange(_ range: NSRange, highlightedRanges: [NSRange]) -> Bool {
        for highlighted in highlightedRanges {
            if range.location >= highlighted.location &&
               range.location + range.length <= highlighted.location + highlighted.length {
                return true
            }
        }
        return false
    }
    
    // Keep old method for SwiftUI compatibility if needed
    func highlight(_ text: String, language: Language) -> AttributedString {
        let nsAttrString = highlightNS(text, language: language)
        return AttributedString(nsAttrString)
    }
}
