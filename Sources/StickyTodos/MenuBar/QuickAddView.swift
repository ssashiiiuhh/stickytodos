import SwiftUI

/// Inline quick-add task field used in the menu bar popover.
struct QuickAddView: View {
    @Bindable var viewModel: NotesViewModel
    @State private var taskText: String = ""
    @State private var selectedNoteID: UUID?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Note selector
            if !viewModel.notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Picker("", selection: $selectedNoteID) {
                        ForEach(viewModel.notes) { note in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(note.color.dotColor)
                                    .frame(width: 6, height: 6)
                                Text(note.title)
                                    .lineLimit(1)
                            }
                            .tag(note.id as UUID?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }

                // Text input
                HStack(spacing: 8) {
                    TextField("Quick add task…", text: $taskText)
                        .focused($isFocused)
                        .onSubmit {
                            addTask()
                        }
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))

                    Button(action: addTask) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(taskText.isEmpty ? .secondary.opacity(0.3) : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(taskText.isEmpty)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
            }
        }
        .onAppear {
            if selectedNoteID == nil {
                selectedNoteID = viewModel.lastAddedNoteID ?? viewModel.notes.first?.id
            }
        }
    }

    private func addTask() {
        let textToAdd = taskText.trimmingCharacters(in: .whitespaces)
        guard !textToAdd.isEmpty,
              let noteID = selectedNoteID else { return }
        viewModel.addItem(to: noteID, text: textToAdd)
        
        taskText = ""
        isFocused = false
        DispatchQueue.main.async {
            taskText = ""
            isFocused = true
        }
    }
}
