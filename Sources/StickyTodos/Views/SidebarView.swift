import SwiftUI

/// Sidebar listing all notes with colored indicator dots.
struct SidebarView: View {
    @Bindable var viewModel: NotesViewModel
    @Binding var selectedNoteID: UUID?

    var body: some View {
        List(selection: $selectedNoteID) {
            // Workspace Selector
            Section("Workspace") {
                Picker("", selection: $viewModel.selectedWorkspace) {
                    ForEach(viewModel.availableWorkspaces, id: \.self) { ws in
                        Text(ws).tag(ws)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            // Overview section
            Section("Overview") {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                    Text("All Notes")
                    Spacer()
                    let count = viewModel.notes.filter { $0.workspace == viewModel.selectedWorkspace }.count
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
                .tag(nil as UUID?)
            }

            // Notes section
            Section("Notes") {
                ForEach(viewModel.notes.filter { !$0.isArchived && $0.workspace == viewModel.selectedWorkspace }) { note in
                    noteRow(note)
                }
            }

            // Archived section
            let archived = viewModel.archivedNotes().filter { $0.workspace == viewModel.selectedWorkspace }
            if !archived.isEmpty {
                Section("Archived") {
                    ForEach(archived) { note in
                        noteRow(note)
                            .opacity(0.6)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                
                Toggle(isOn: Bindable(viewModel).syncToReminders) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13))
                        Text("Sync to Reminders")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                // Add note button at bottom of sidebar
                Button(action: {
                    selectedNoteID = viewModel.addNote()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("New Note")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .background(.bar)
        }
    }

    @ViewBuilder
    private func noteRow(_ note: StickyNote) -> some View {
        HStack(spacing: 10) {
            // Colored dot
            Circle()
                .fill(note.color.dotColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                if note.totalCount > 0 {
                    Text("\(note.completedCount)/\(note.totalCount) tasks")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Incomplete badge
            if note.incompleteItems.count > 0 {
                Text("\(note.incompleteItems.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(note.color.headerColor))
            }
        }
        .tag(note.id as UUID?)
        .contextMenu {
            Button(note.isArchived ? "Unarchive Note" : "Archive Note") {
                viewModel.toggleArchiveNote(note.id)
            }
            
            Divider()

            Button("Delete Note", role: .destructive) {
                viewModel.deleteNote(note)
                if selectedNoteID == note.id {
                    selectedNoteID = viewModel.notes.first?.id
                }
            }
        }
    }
}
