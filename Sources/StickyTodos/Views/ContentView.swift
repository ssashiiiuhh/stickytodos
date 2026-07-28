import SwiftUI
import UniformTypeIdentifiers

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    var id: String { self.rawValue }
}

/// The main content view combining sidebar navigation and the corkboard.
struct ContentView: View {
    @Bindable var viewModel: NotesViewModel
    @State private var selectedNoteID: UUID?
    @State private var filter: TaskFilter = .all
    @AppStorage("boardBackground") private var boardBackground: BoardBackground = .glass
    @AppStorage("customBackgroundImagePath") private var customBackgroundImagePath: String = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel, selectedNoteID: $selectedNoteID)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            BoardView(viewModel: viewModel, filter: filter, background: boardBackground)
        }
        .onChange(of: boardBackground) { _, newValue in
            if newValue == .custom {
                selectCustomImage()
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .navigationTitle("StickyTodos")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Task filter
                Picker("Filter tasks", selection: $filter) {
                    ForEach(TaskFilter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                // Background picker
                Menu {
                    Picker("Background", selection: $boardBackground) {
                        ForEach(BoardBackground.allCases) { bg in
                            Text(bg.rawValue).tag(bg)
                        }
                    }
                } label: {
                    Image(systemName: "photo")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .menuIndicator(.hidden)
                .help("Change Background")
                
                // Auto-Tidy button
                Button(action: {
                    viewModel.autoTidy()
                }) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .help("Auto-Tidy Board")
                
                // Export/Share button
                Button(action: {
                    // Render a standalone canvas for exporting to ensure full 3000x3000 rendering
                    let exportView = ZStack {
                        if boardBackground == .corkboard {
                            // Simple fallback for exporter if needed, or use the real background
                            Color(nsColor: .windowBackgroundColor)
                        } else {
                            Color.clear // Glass needs context, so we'll just export notes on clear/solid background
                        }
                        
                        ForEach(viewModel.notes.filter { !$0.isArchived && $0.workspace == viewModel.selectedWorkspace }) { note in
                            StickyNoteView(note: note, viewModel: viewModel, filter: filter)
                                .position(note.position ?? CGPoint(x: 1500, y: 1500))
                                .rotationEffect(.degrees(note.rotation))
                        }
                    }
                    .frame(width: 3000, height: 3000)
                    
                    BoardExporter.saveToDesktop(view: exportView, filename: "StickyTodos_\(viewModel.selectedWorkspace).png")
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .help("Export Board to Desktop")
            }
        }
    }

    private func selectCustomImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            customBackgroundImagePath = url.path
        } else {
            // Revert if they canceled and no previous image exists
            if customBackgroundImagePath.isEmpty {
                boardBackground = .corkboard
            }
        }
    }
}
