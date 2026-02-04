import SwiftUI
import Combine

// MARK: - Editor Theme
struct EditorTheme {
    let name: String
    let background: Color
    let lineNumberBackground: Color
    let lineNumberText: Color
    let text: Color
    let cursor: Color
    let selection: Color
    let keyword: Color
    let type: Color
    let string: Color
    let number: Color
    let comment: Color
    let function: Color
    let property: Color
    let preprocessor: Color
    
    static let dark = EditorTheme(
        name: "Dark",
        background: Color(red: 0.11, green: 0.11, blue: 0.12),
        lineNumberBackground: Color(red: 0.13, green: 0.13, blue: 0.14),
        lineNumberText: Color(red: 0.45, green: 0.45, blue: 0.47),
        text: Color(red: 0.92, green: 0.92, blue: 0.93),
        cursor: Color.white,
        selection: Color(red: 0.25, green: 0.35, blue: 0.55),
        keyword: Color(red: 0.99, green: 0.37, blue: 0.53),
        type: Color(red: 0.67, green: 0.85, blue: 0.60),
        string: Color(red: 0.99, green: 0.56, blue: 0.37),
        number: Color(red: 0.85, green: 0.75, blue: 0.50),
        comment: Color(red: 0.45, green: 0.50, blue: 0.45),
        function: Color(red: 0.40, green: 0.72, blue: 0.87),
        property: Color(red: 0.67, green: 0.85, blue: 0.60),
        preprocessor: Color(red: 0.99, green: 0.56, blue: 0.37)
    )
    
    static let light = EditorTheme(
        name: "Light",
        background: Color(red: 1.0, green: 1.0, blue: 1.0),
        lineNumberBackground: Color(red: 0.97, green: 0.97, blue: 0.97),
        lineNumberText: Color(red: 0.55, green: 0.55, blue: 0.57),
        text: Color(red: 0.1, green: 0.1, blue: 0.1),
        cursor: Color.black,
        selection: Color(red: 0.70, green: 0.84, blue: 1.0),
        keyword: Color(red: 0.67, green: 0.05, blue: 0.57),
        type: Color(red: 0.11, green: 0.43, blue: 0.35),
        string: Color(red: 0.77, green: 0.10, blue: 0.09),
        number: Color(red: 0.11, green: 0.00, blue: 0.81),
        comment: Color(red: 0.35, green: 0.45, blue: 0.35),
        function: Color(red: 0.20, green: 0.40, blue: 0.64),
        property: Color(red: 0.11, green: 0.43, blue: 0.35),
        preprocessor: Color(red: 0.39, green: 0.22, blue: 0.13)
    )
    
    static let monokai = EditorTheme(
        name: "Monokai",
        background: Color(red: 0.15, green: 0.16, blue: 0.13),
        lineNumberBackground: Color(red: 0.17, green: 0.18, blue: 0.15),
        lineNumberText: Color(red: 0.55, green: 0.55, blue: 0.47),
        text: Color(red: 0.97, green: 0.97, blue: 0.95),
        cursor: Color.white,
        selection: Color(red: 0.29, green: 0.33, blue: 0.24),
        keyword: Color(red: 0.98, green: 0.15, blue: 0.45),
        type: Color(red: 0.40, green: 0.85, blue: 0.94),
        string: Color(red: 0.90, green: 0.86, blue: 0.45),
        number: Color(red: 0.68, green: 0.51, blue: 1.0),
        comment: Color(red: 0.46, green: 0.44, blue: 0.36),
        function: Color(red: 0.65, green: 0.89, blue: 0.18),
        property: Color(red: 0.40, green: 0.85, blue: 0.94),
        preprocessor: Color(red: 0.98, green: 0.15, blue: 0.45)
    )
    
    static let allThemes = [dark, light, monokai]
}

// MARK: - Theme Environment
class ThemeManager: ObservableObject {
    @Published var currentTheme: EditorTheme = .dark
}
