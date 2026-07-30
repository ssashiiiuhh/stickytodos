import SwiftUI

/// A single to-do item row with an animated checkbox and editable text.
struct TodoItemRow: View {
    let item: TodoItem
    let noteColor: NoteColor
    var viewModel: NotesViewModel? = nil
    var currentNoteID: UUID? = nil
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onTextChange: (String) -> Void
    let onDateChange: (Date?) -> Void

    @State private var editableText: String = ""
    @State private var isHovered: Bool = false
    @State private var isShowingDatePicker: Bool = false
    @State private var tempDate: Date = Date()
    @FocusState private var isFocused: Bool

    private var isShared: Bool {
        viewModel?.isTaskShared(item) ?? false
    }

    private var sharedNoteNames: String {
        guard let vm = viewModel else { return "" }
        let names = vm.sharedNotes(for: item).map(\.title)
        return names.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(noteColor.textColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.isCompleted ? noteColor.textColor : Color.white.opacity(0.001))
                        )

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isCompleted)

            // Text (Markdown Rendering)
            ZStack(alignment: .leading) {
                TextField("Task…", text: $editableText)
                    .onSubmit {
                        onTextChange(editableText)
                    }
                .textFieldStyle(.plain)
                .focused($isFocused)
                .opacity(isFocused ? 1.0 : 0.0)
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        onTextChange(editableText)
                    }
                }
                
                if !isFocused {
                    let markdownOptions = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                    let attrString = (try? AttributedString(markdown: item.text, options: markdownOptions)) ?? AttributedString(item.text)
                    
                    Text(attrString)
                        .allowsHitTesting(false)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(
                item.isCompleted ? noteColor.textColor.opacity(0.65) :
                item.isArchived ? noteColor.textColor.opacity(0.4) :
                item.blockedBy != nil ? .orange :
                noteColor.textColor.opacity(1.0)
            )
            .strikethrough(item.isCompleted || item.isArchived, color: noteColor.textColor.opacity(0.65))

            // Shared Link Indicator Badge
            if isShared {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(noteColor.textColor.opacity(0.75))
                    .help("Shared across: \(sharedNoteNames)")
            }

            Spacer()

            // Due Date / Calendar Button
            if let date = item.dueDate {
                let isOverdue = date < Date() && !item.isCompleted
                Text(date, format: .dateTime.day().month().year())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(item.isCompleted ? noteColor.textColor.opacity(0.6) : (isOverdue ? .red : noteColor.textColor.opacity(0.85)))
            }

            if isHovered || isShowingDatePicker {
                Button(action: {
                    tempDate = item.dueDate ?? Date()
                    isShowingDatePicker = true
                }) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(noteColor.textColor.opacity(0.8))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isShowingDatePicker, arrowEdge: .trailing) {
                    VStack {
                        DatePicker("Due Date", selection: $tempDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .padding()
                        HStack {
                            if item.dueDate != nil {
                                Button("Clear") {
                                    onDateChange(nil)
                                    isShowingDatePicker = false
                                }
                                .foregroundColor(.red)
                            }
                            Spacer()
                            Button("Done") {
                                onDateChange(tempDate)
                                isShowingDatePicker = false
                            }
                            .keyboardShortcut(.defaultAction)
                        }
                        .padding([.horizontal, .bottom])
                    }
                    .frame(width: 300)
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(noteColor.textColor.opacity(0.6))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .contextMenu {
            Button("Set Due Date...") {
                tempDate = item.dueDate ?? Date()
                isShowingDatePicker = true
            }
            if item.dueDate != nil {
                Button("Clear Due Date") {
                    onDateChange(nil)
                }
            }

            Divider()

            if let vm = viewModel, let noteID = currentNoteID {
                let otherNotes = vm.notes.filter { $0.id != noteID && !$0.isArchived }
                if !otherNotes.isEmpty {
                    Menu("Share to Note...") {
                        ForEach(otherNotes) { targetNote in
                            Button(targetNote.title) {
                                vm.shareTask(item, to: targetNote.id)
                            }
                        }
                    }
                }
            }

            if isShared {
                Button("Unlink from this Note", role: .destructive) {
                    onDelete()
                }
                Button("Delete Task Everywhere", role: .destructive) {
                    viewModel?.deleteSharedTaskEverywhere(item.sharedTaskID)
                }
            } else {
                Button("Delete Task", role: .destructive, action: onDelete)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onAppear {
            editableText = item.text
        }
        .onChange(of: item.text) { _, newValue in
            editableText = newValue
        }
    }
}
