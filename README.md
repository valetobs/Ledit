# Ledit

A modern, lightweight code editor for iOS and iPadOS built with SwiftUI.

---

## Overview

Ledit is a native iOS code editor designed for developers who want to code on the go. With syntax highlighting, live web preview, and full keyboard support, Ledit brings a desktop-class editing experience to your mobile devices.

---

## Features

### Code Editing
- Syntax highlighting for Swift, Python, JavaScript, HTML, CSS, JSON, and Markdown
- Line numbers with customizable display
- Multiple color themes (Dark, Light, Monokai, Dracula, Solarized, Nord, One Dark)
- Tab management with modified file indicators
- Code-optimized keyboard with quick-access symbols

### Web Development
- Live HTML/CSS/JS preview with auto-refresh
- Framework templates for React, Vue.js, Angular, Svelte, Next.js, and more
- Inline CSS and JavaScript injection
- Responsive preview for testing layouts

### iPad Pro Features
- Desktop-class interface with resizable panels
- Magic Keyboard support with full shortcut mappings
- Quick Open file search (Cmd+P)
- Find and Replace panel (Cmd+F)
- Integrated console output
- Split view and Stage Manager compatible

### Project Management
- Recent projects with quick access
- File browser with context menus
- Create, rename, and delete files
- Multiple files open simultaneously

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd + N | New File |
| Cmd + P | Quick Open |
| Cmd + S | Save |
| Cmd + B | Toggle Sidebar |
| Cmd + J | Toggle Console |
| Cmd + F | Find |
| Cmd + R | Run |

---

## Requirements

- iOS 16.0+ / iPadOS 16.0+
- Xcode 15.0+
- Swift 5.9+

---

## Installation

1. Clone the repository
```
git clone https://github.com/yourusername/ledit.git
```

2. Open the project in Xcode
```
cd ledit
open ledit.xcodeproj
```

3. Build and run on your device or simulator

---

## Project Structure

```
ledit/
    leditApp.swift          # App entry point
    ContentView.swift       # Main editor interface
    HomeScreen.swift        # Home screen and project management
    Models.swift            # Data models (ProjectFile, Language, etc.)
    Theme.swift             # Editor color themes
    SyntaxHighlighter.swift # Language-specific highlighting
    CodeEditorView.swift    # Text editor component
    WebDevFeatures.swift    # Web framework templates
    WebPreviewManager.swift # Live preview engine
    WebPreviewView.swift    # Web editor interface
    iPadSupport.swift       # iPad-optimized components
    StatsTracker.swift      # Usage statistics
    LiveActivityManager.swift # Dynamic Island support
    SplashScreen.swift      # Launch animation
```

---

## Supported Languages

| Language | Extensions | Features |
|----------|------------|----------|
| Swift | .swift | Keywords, types, strings, comments |
| Python | .py | Keywords, strings, comments |
| JavaScript | .js, .jsx, .ts, .tsx | Keywords, strings, template literals |
| HTML | .html, .htm | Tags, attributes, strings |
| CSS | .css | Selectors, properties, values |
| JSON | .json | Keys, strings, numbers |
| Markdown | .md | Headers, bold, code blocks, links |

---

## Web Templates

### Vanilla JavaScript
- Hello World
- Responsive Landing Page
- Modern ES6+ App

### React
- Counter Component (with hooks)

### Vue.js
- Todo Application

---

## Themes

| Theme | Style |
|-------|-------|
| Dark | Default dark theme with blue accents |
| Light | Clean light theme |
| Monokai | Classic dark theme with vibrant colors |
| Dracula | Purple-tinted dark theme |
| Solarized Dark | Low contrast dark theme |
| Nord | Arctic-inspired color palette |
| One Dark | Atom-inspired dark theme |

---

## Architecture

Ledit follows a SwiftUI-first architecture with:

- **ObservableObject** classes for state management
- **Environment objects** for app-wide settings
- **Combine** for reactive updates
- **WKWebView** for live web preview
- **NSAttributedString** for performant syntax highlighting

---

## Contributing

Contributions are welcome. Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

MIT License. See LICENSE for details.

---

## Acknowledgments

Built with SwiftUI and a passion for mobile development tools.
