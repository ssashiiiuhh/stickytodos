import SwiftUI

/// The main app entry point — runs as a menu-bar-only app (no dock icon).
/// The main corkboard window can be opened on demand from the menu bar widget.
@main
struct StickyTodosApp: App {
    @State private var viewModel: NotesViewModel
    @Environment(\.openWindow) private var openWindow

    init() {
        NotificationManager.requestAuthorization()
        _viewModel = State(wrappedValue: NotesViewModel())
    }

    var body: some Scene {
        // Main window — the corkboard
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 700, minHeight: 500)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 1100, height: 750)
        .commands {
            CommandMenu("Note") {
                Button("New Note") {
                    _ = viewModel.addNote()
                }
                .keyboardShortcut("n", modifiers: .control)
                
                Button("Show Main Board") {
                    openWindow(id: "main")
                }
                .keyboardShortcut("a", modifiers: .control)
            }
        }

        // Menu bar widget — always-accessible task overview
        MenuBarExtra("StickyTodos", systemImage: "checklist") {
            MenuBarWidget(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
