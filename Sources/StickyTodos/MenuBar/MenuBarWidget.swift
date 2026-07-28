import SwiftUI

/// The content shown inside the menu bar popover when clicking the checklist icon.
/// Shows a summary of incomplete tasks grouped by note, quick-add, and app controls.
struct MenuBarWidget: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var viewModel: NotesViewModel
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            searchBarView

            Divider()

            // Task list
            if viewModel.activeNotes(matching: searchText).isEmpty {
                if searchText.isEmpty && viewModel.allIncompleteTasks.isEmpty {
                    emptyStateView
                } else {
                    noSearchResultsView
                }
            } else {
                taskListView
            }

            Divider()

            // Quick add
            QuickAddView(viewModel: viewModel)
                .padding(12)

            Divider()

            // Footer controls
            footerView
        }
        .frame(width: 300)
        .frame(maxHeight: 550)
        .clipped()
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("StickyTodos")
                    .font(.system(size: 14, weight: .bold, design: .rounded))

                Text("\(viewModel.totalIncompleteCount) tasks remaining")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Badge
            if viewModel.totalIncompleteCount > 0 {
                Text("\(viewModel.totalIncompleteCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Task List

    private var taskListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.activeNotes(matching: searchText)) { note in
                    noteSection(note)
                }
            }
            .padding(12)
        }
        .frame(height: 250)
    }

    @ViewBuilder
    private func noteSection(_ note: StickyNote) -> some View {
        let displayItems = viewModel.displayItems(for: note, matching: searchText)
        
        VStack(alignment: .leading, spacing: 6) {
            // Note header
            HStack(spacing: 6) {
                Circle()
                    .fill(note.color.dotColor)
                    .frame(width: 8, height: 8)

                Text(note.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Text("\(displayItems.count)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(note.color.textColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(note.color.color))
            }

            // Incomplete tasks
            ForEach(displayItems) { item in
                Button(action: {
                    viewModel.toggleItem(item.id, in: note.id)
                }) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(note.color.headerColor, lineWidth: 1.2)
                            .frame(width: 14, height: 14)

                        Text(item.text)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .foregroundColor(.primary)

                        Spacer()

                        if let date = item.dueDate {
                            Text(date, format: .dateTime.day().month(.defaultDigits).year(.twoDigits))
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 14)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(.green)

            Text("All done! 🎉")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var noSearchResultsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.secondary)

            Text("No tasks found")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button(action: {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow")
                    Text("Open App")
                }
                .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }
}
