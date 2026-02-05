import SwiftUI

// MARK: - Web Project Types
enum WebFramework: String, CaseIterable {
    case vanilla = "Vanilla JS"
    case react = "React"
    case vue = "Vue.js"
    case angular = "Angular"
    case svelte = "Svelte"
    case nextjs = "Next.js"
    case nuxt = "Nuxt"
    case sveltekit = "SvelteKit"
    case astro = "Astro"
    case solid = "Solid.js"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .vanilla: return "js.circle.fill"
        case .react: return "atom"
        case .vue: return "v.circle.fill"
        case .angular: return "a.circle.fill"
        case .svelte: return "s.circle.fill"
        case .nextjs: return "n.circle.fill"
        case .nuxt: return "n.circle.fill"
        case .sveltekit: return "s.square.fill"
        case .astro: return "star.fill"
        case .solid: return "square.fill"
        }
    }
}

// MARK: - HTML/CSS/JS Templates
struct WebTemplate {
    let name: String
    let framework: WebFramework
    let description: String
    let htmlContent: String
    let cssContent: String
    let jsContent: String
    
    static let templates: [WebTemplate] = [
        // Vanilla JS Templates
        WebTemplate(
            name: "Hello World",
            framework: .vanilla,
            description: "Simple Hello World project",
            htmlContent: """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Hello World</title>
                <link rel="stylesheet" href="style.css">
            </head>
            <body>
                <div class="container">
                    <h1>👋 Hello World!</h1>
                    <p id="message">Welcome to web development</p>
                    <button onclick="greet()">Click Me</button>
                </div>
                <script src="script.js"></script>
            </body>
            </html>
            """,
            cssContent: """
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
            }
            
            .container {
                background: white;
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
                text-align: center;
                max-width: 500px;
            }
            
            h1 {
                color: #333;
                margin-bottom: 20px;
                font-size: 2.5em;
            }
            
            p {
                color: #666;
                margin-bottom: 30px;
                font-size: 1.1em;
            }
            
            button {
                background: #667eea;
                color: white;
                border: none;
                padding: 12px 30px;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1em;
                transition: all 0.3s ease;
            }
            
            button:hover {
                background: #764ba2;
                transform: scale(1.05);
            }
            """,
            jsContent: """
            function greet() {
                const message = document.getElementById('message');
                message.textContent = 'Thanks for clicking! 🎉';
                message.style.color = '#667eea';
            }
            
            console.log('Web development is awesome!');
            """
        ),
        
        // React Template
        WebTemplate(
            name: "React Counter",
            framework: .react,
            description: "Interactive counter component",
            htmlContent: """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>React Counter</title>
                <link rel="stylesheet" href="style.css">
                <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
                <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
                <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
            </head>
            <body>
                <div id="root"></div>
                <script type="text/babel" src="script.js"></script>
            </body>
            </html>
            """,
            cssContent: """
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                margin: 0;
                display: flex;
                justify-content: center;
                align-items: center;
            }
            
            #root {
                width: 100%;
                display: flex;
                justify-content: center;
                align-items: center;
            }
            
            .counter-app {
                background: white;
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
                text-align: center;
            }
            
            .counter-display {
                font-size: 3em;
                color: #667eea;
                margin: 20px 0;
                font-weight: bold;
            }
            
            button {
                background: #667eea;
                color: white;
                border: none;
                padding: 10px 20px;
                margin: 5px;
                border-radius: 5px;
                cursor: pointer;
                font-size: 1em;
                transition: all 0.3s ease;
            }
            
            button:hover {
                background: #764ba2;
                transform: scale(1.05);
            }
            """,
            jsContent: """
            const { useState } = React;
            
            function Counter() {
                const [count, setCount] = useState(0);
                
                return (
                    <div className="counter-app">
                        <h1>React Counter 🧮</h1>
                        <div className="counter-display">{count}</div>
                        <button onClick={() => setCount(count + 1)}>+ Increment</button>
                        <button onClick={() => setCount(count - 1)}>- Decrement</button>
                        <button onClick={() => setCount(0)}>Reset</button>
                    </div>
                );
            }
            
            ReactDOM.createRoot(document.getElementById('root')).render(<Counter />);
            """
        ),
        
        // Vue Template
        WebTemplate(
            name: "Vue Todo App",
            framework: .vue,
            description: "Todo list application with Vue.js",
            htmlContent: """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Vue Todo App</title>
                <link rel="stylesheet" href="style.css">
                <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
            </head>
            <body>
                <div id="app">
                    <div class="todo-container">
                        <h1>📝 My Todo List</h1>
                        <div class="input-area">
                            <input v-model="newTodo" @keyup.enter="addTodo" placeholder="Add a new task...">
                            <button @click="addTodo">Add</button>
                        </div>
                        <ul class="todo-list">
                            <li v-for="(todo, index) in todos" :key="index" :class="{completed: todo.done}">
                                <input type="checkbox" v-model="todo.done">
                                <span>{{ todo.text }}</span>
                                <button @click="removeTodo(index)">×</button>
                            </li>
                        </ul>
                    </div>
                </div>
                <script src="script.js"></script>
            </body>
            </html>
            """,
            cssContent: """
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                margin: 0;
                padding: 20px;
            }
            
            .todo-container {
                max-width: 500px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            }
            
            h1 {
                text-align: center;
                color: #333;
                margin-bottom: 30px;
            }
            
            .input-area {
                display: flex;
                gap: 10px;
                margin-bottom: 20px;
            }
            
            input {
                flex: 1;
                padding: 10px;
                border: 1px solid #ddd;
                border-radius: 5px;
                font-size: 1em;
            }
            
            button {
                background: #667eea;
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 5px;
                cursor: pointer;
                transition: all 0.3s ease;
            }
            
            button:hover {
                background: #764ba2;
            }
            
            .todo-list {
                list-style: none;
                padding: 0;
            }
            
            li {
                display: flex;
                align-items: center;
                padding: 12px;
                border-bottom: 1px solid #eee;
                transition: all 0.3s ease;
            }
            
            li:hover {
                background: #f5f5f5;
            }
            
            li input {
                width: auto;
                margin-right: 10px;
                cursor: pointer;
            }
            
            li span {
                flex: 1;
                color: #333;
            }
            
            li.completed span {
                text-decoration: line-through;
                color: #999;
            }
            
            li button {
                background: #ff6b6b;
                padding: 5px 10px;
                width: auto;
            }
            """,
            jsContent: """
            const { createApp } = Vue;
            
            createApp({
                data() {
                    return {
                        todos: [
                            { text: 'Learn Vue.js', done: false },
                            { text: 'Build a project', done: false },
                            { text: 'Master web development', done: false }
                        ],
                        newTodo: ''
                    };
                },
                methods: {
                    addTodo() {
                        if (this.newTodo.trim()) {
                            this.todos.push({ text: this.newTodo, done: false });
                            this.newTodo = '';
                        }
                    },
                    removeTodo(index) {
                        this.todos.splice(index, 1);
                    }
                }
            }).mount('#app');
            """
        ),
        
        // Responsive Design Template
        WebTemplate(
            name: "Responsive Landing Page",
            framework: .vanilla,
            description: "Mobile-first responsive landing page",
            htmlContent: """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Landing Page</title>
                <link rel="stylesheet" href="style.css">
            </head>
            <body>
                <nav class="navbar">
                    <div class="container">
                        <h2>MyBrand</h2>
                        <ul class="nav-links">
                            <li><a href="#home">Home</a></li>
                            <li><a href="#features">Features</a></li>
                            <li><a href="#contact">Contact</a></li>
                        </ul>
                    </div>
                </nav>
                
                <section id="home" class="hero">
                    <div class="container">
                        <h1>Welcome to Our Platform</h1>
                        <p>Create amazing web experiences with modern technologies</p>
                        <button class="cta-button">Get Started</button>
                    </div>
                </section>
                
                <section id="features" class="features">
                    <div class="container">
                        <h2>Features</h2>
                        <div class="feature-grid">
                            <div class="feature-card">
                                <h3>⚡ Fast</h3>
                                <p>Blazingly fast performance</p>
                            </div>
                            <div class="feature-card">
                                <h3>🎨 Beautiful</h3>
                                <p>Modern and responsive design</p>
                            </div>
                            <div class="feature-card">
                                <h3>🔒 Secure</h3>
                                <p>Enterprise-grade security</p>
                            </div>
                        </div>
                    </div>
                </section>
                
                <footer id="contact">
                    <div class="container">
                        <p>&copy; 2024 MyBrand. All rights reserved.</p>
                    </div>
                </footer>
                <script src="script.js"></script>
            </body>
            </html>
            """,
            cssContent: """
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                color: #333;
            }
            
            .container {
                max-width: 1200px;
                margin: 0 auto;
                padding: 0 20px;
            }
            
            .navbar {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 1rem 0;
                position: sticky;
                top: 0;
                z-index: 100;
            }
            
            .navbar .container {
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            
            .nav-links {
                display: flex;
                list-style: none;
                gap: 2rem;
            }
            
            .nav-links a {
                color: white;
                text-decoration: none;
                transition: opacity 0.3s;
            }
            
            .nav-links a:hover {
                opacity: 0.8;
            }
            
            .hero {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 100px 0;
                text-align: center;
            }
            
            .hero h1 {
                font-size: 3em;
                margin-bottom: 20px;
            }
            
            .hero p {
                font-size: 1.3em;
                margin-bottom: 30px;
            }
            
            .cta-button {
                background: white;
                color: #667eea;
                border: none;
                padding: 12px 30px;
                border-radius: 5px;
                font-size: 1em;
                cursor: pointer;
                transition: all 0.3s;
                font-weight: bold;
            }
            
            .cta-button:hover {
                transform: scale(1.05);
                box-shadow: 0 5px 20px rgba(0, 0, 0, 0.2);
            }
            
            .features {
                padding: 80px 0;
            }
            
            .features h2 {
                text-align: center;
                font-size: 2.5em;
                margin-bottom: 50px;
            }
            
            .feature-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 30px;
            }
            
            .feature-card {
                background: #f5f5f5;
                padding: 30px;
                border-radius: 10px;
                text-align: center;
                transition: all 0.3s;
            }
            
            .feature-card:hover {
                transform: translateY(-10px);
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
            }
            
            .feature-card h3 {
                font-size: 1.5em;
                margin-bottom: 10px;
            }
            
            footer {
                background: #333;
                color: white;
                text-align: center;
                padding: 20px 0;
            }
            
            @media (max-width: 768px) {
                .nav-links {
                    gap: 1rem;
                    font-size: 0.9em;
                }
                
                .hero h1 {
                    font-size: 2em;
                }
                
                .hero p {
                    font-size: 1em;
                }
                
                .features h2 {
                    font-size: 1.8em;
                }
            }
            """,
            jsContent: """
            document.querySelector('.cta-button').addEventListener('click', () => {
                alert('Thanks for your interest! 🚀');
            });
            
            // Smooth scrolling
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {
                anchor.addEventListener('click', (e) => {
                    e.preventDefault();
                    const target = document.querySelector(anchor.getAttribute('href'));
                    if (target) {
                        target.scrollIntoView({ behavior: 'smooth' });
                    }
                });
            });
            """
        ),
        
        // TypeScript/ES6+ Template
        WebTemplate(
            name: "Modern ES6+ App",
            framework: .vanilla,
            description: "Modern JavaScript with ES6+ features",
            htmlContent: """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>ES6+ App</title>
                <link rel="stylesheet" href="style.css">
            </head>
            <body>
                <div class="container">
                    <h1>⚡ Modern JavaScript App</h1>
                    <div id="app"></div>
                </div>
                <script src="script.js"></script>
            </body>
            </html>
            """,
            cssContent: """
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                margin: 0;
                padding: 20px;
            }
            
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            }
            
            h1 {
                text-align: center;
                color: #333;
            }
            
            #app {
                margin-top: 20px;
            }
            """,
            jsContent: """
            // ES6+ Modern JavaScript
            const app = {
                name: 'Modern JS App',
                version: '1.0.0',
                
                init() {
                    console.log(`${this.name} v${this.version} initialized`);
                    this.render();
                },
                
                render() {
                    const appDiv = document.getElementById('app');
                    const items = ['Learn ES6+', 'Use modern features', 'Build awesome apps'];
                    
                    appDiv.innerHTML = `
                        <ul class="items">
                            ${items.map((item, i) => `<li>${i + 1}. ${item}</li>`).join('')}
                        </ul>
                    `;
                }
            };
            
            document.addEventListener('DOMContentLoaded', () => app.init());
            """
        )
    ]
    
    static func template(for framework: WebFramework, named name: String) -> WebTemplate? {
        return templates.first { $0.framework == framework && $0.name == name }
    }
    
    static func templates(for framework: WebFramework) -> [WebTemplate] {
        return templates.filter { $0.framework == framework }
    }
}

// MARK: - Web Development Utilities
struct WebDevUtils {
    static let jsSnippets: [String: String] = [
        "fetch API": """
        fetch('https://api.example.com/data')
            .then(response => response.json())
            .then(data => console.log(data))
            .catch(error => console.error('Error:', error));
        """,
        
        "async/await": """
        async function fetchData() {
            try {
                const response = await fetch('https://api.example.com/data');
                const data = await response.json();
                console.log(data);
            } catch (error) {
                console.error('Error:', error);
            }
        }
        """,
        
        "event listener": """
        document.addEventListener('DOMContentLoaded', () => {
            console.log('DOM is loaded');
        });
        """,
        
        "local storage": """
        // Save
        localStorage.setItem('myKey', 'myValue');
        
        // Retrieve
        const value = localStorage.getItem('myKey');
        
        // Remove
        localStorage.removeItem('myKey');
        """,
        
        "array methods": """
        const numbers = [1, 2, 3, 4, 5];
        const doubled = numbers.map(n => n * 2);
        const evens = numbers.filter(n => n % 2 === 0);
        const sum = numbers.reduce((a, b) => a + b, 0);
        """,
        
        "destructuring": """
        const person = { name: 'John', age: 30, city: 'NYC' };
        const { name, age } = person;
        
        const colors = ['red', 'green', 'blue'];
        const [first, second] = colors;
        """
    ]
    
    static let cssSnippets: [String: String] = [
        "flexbox layout": """
        .container {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 20px;
        }
        """,
        
        "grid layout": """
        .container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        """,
        
        "gradient": """
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        """,
        
        "box shadow": """
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
        """,
        
        "transition": """
        transition: all 0.3s ease;
        """,
        
        "media query": """
        @media (max-width: 768px) {
            .container {
                flex-direction: column;
            }
        }
        """
    ]
}
