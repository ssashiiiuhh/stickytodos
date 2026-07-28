# StickyTodos 🗒️✅

A premium, native macOS application that combines the tactile charm of physical sticky notes with a modern, high-performance task management system. Designed for focus and frictionless interaction.

![StickyTodos Preview](https://via.placeholder.com/1200x800.png?text=StickyTodos+Portfolio+Preview)

## 🚀 Features

- **Infinite Corkboard Canvas**: Organize your thoughts in a free-form workspace with GPU-accelerated rendering.
- **Liquid Glass Aesthetic**: A stunning, modern interface with real-time mesh gradients and glassmorphism effects.
- **Always-Ready Menu Bar Widget**: Instantly view and add tasks from your menu bar without interrupting your workflow.
- **Smart Drag & Drop**: Intuitively reorder tasks within notes or reposition notes across the board.
- **Dynamic Backgrounds**: Choose between classic Corkboard, sleek Whiteboard, Blueprint Grid, or your own custom images.
- **Intelligent Focus**: Notes automatically tilt and lift when hovered, bringing your current task to the visual forefront.
- **Persistent & Safe**: Automatic JSON persistence with a robust backup system to ensure your data is always safe.
- **Global Shortcuts**: 
    - `Control + N`: New Note
    - `Control + A`: Focus Board
    - `Control + T`: Toggle Widget

## 🛠 Tech Stack

- **Framework**: SwiftUI (100% Native)
- **Language**: Swift 6.0
- **State Management**: Observation framework (`@Observable`)
- **Persistence**: File-system based JSON storage with atomic writes.
- **Rendering**: GPU-accelerated `Canvas` and `drawingGroup` for smooth 60fps interaction.
- **Native Integration**: 
    - `UserNotifications` for task reminders and daily digests.
    - `MenuBarExtra` for background agent behavior.
    - `NSOpenPanel` for native file picker integration.

## 🏗 Architecture

StickyTodos follows a clean **MVVM (Model-View-ViewModel)** architecture:

- **Models**: Simple, Codable structures representing Notes and Tasks. Includes custom decoding logic to handle version migrations safely.
- **ViewModel**: A centralized `NotesViewModel` acting as the single source of truth. It manages state, handles debounced persistence, and caches expensive computations (like task counts) for UI performance.
- **Views**: Highly modularized SwiftUI views. Heavy rendering components (like the corkboard and note lines) are optimized using `Canvas` draw calls to minimize the view hierarchy depth.
- **Utilities**: Dedicated managers for Notifications, Persistence, and Drag-and-Drop delegates.

## 📦 Installation

1. Download the latest `StickyTodos.dmg` from the releases.
2. Drag `StickyTodos.app` to your `/Applications` folder.
3. Launch via Spotlight or your Applications folder.

---
*Created as a high-fidelity portfolio project demonstrating modern macOS development patterns and premium UI/UX design.*
