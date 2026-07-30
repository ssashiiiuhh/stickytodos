import SwiftUI

/// A single sticky note card — the hero visual component.
/// Features a colored background with gradient, slight rotation, drop shadow,
/// a decorative folded corner, inline-editable title, and a list of tasks.
struct StickyNoteView: View {
    let note: StickyNote
    @Bindable var viewModel: NotesViewModel
    var filter: TaskFilter = .all

    @State private var isHovered: Bool = false
    @State private var newItemText: String = ""
    @State private var editableTitle: String = ""
    @State private var draggedItem: TodoItem?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNewItemFocused: Bool
    @State private var showCompleted: Bool = false

    private var filteredItems: [TodoItem] {
        switch filter {
        case .all: return note.items
        case .active: return note.items.filter { !$0.isCompleted }
        case .completed: return note.items.filter { $0.isCompleted }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header strip
            headerView

            // Tasks list
            tasksView

            // Add new task inline
            addTaskField

            // Footer with progress
            if note.totalCount > 0 {
                footerView
            }
        }
        .background(noteBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(foldedCorner, alignment: .topTrailing)
        .shadow(
            color: Color.black.opacity(isHovered ? 0.25 : 0.15),
            radius: isHovered ? 12 : 8,
            x: 2, y: 3
        )
        .rotationEffect(.degrees(isHovered ? 0 : note.rotation))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            editableTitle = note.title
        }
        .onChange(of: note.title) { _, newValue in
            editableTitle = newValue
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            TextField("Title", text: $editableTitle)
                .onSubmit {
                    viewModel.updateNoteTitle(note.id, title: editableTitle)
                }
            .textFieldStyle(.plain)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(note.color.textColor)
            .focused($isTitleFocused)
            .onChange(of: isTitleFocused) { _, focused in
                if !focused {
                    viewModel.updateNoteTitle(note.id, title: editableTitle)
                }
            }

            Spacer()

            // Color picker button
            Menu {
                ForEach(NoteColor.allCases) { color in
                    Button(action: {
                        viewModel.updateNoteColor(note.id, color: color)
                    }) {
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 12, height: 12)
                            Text(color.displayName)
                            if color == note.color {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 12))
                    .foregroundColor(note.color.textColor.opacity(0.85))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 22)

            // Archive button
            Button(action: {
                viewModel.toggleArchiveNote(note.id)
            }) {
                Image(systemName: note.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill")
                    .font(.system(size: 12))
                    .foregroundColor(note.color.textColor.opacity(isHovered ? 0.85 : 0.0))
            }
            .buttonStyle(.plain)
            .help(note.isArchived ? "Unarchive Note" : "Archive Note")
            .opacity(isHovered ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)

            // Delete button
            Button(action: {
                viewModel.deleteNote(note)
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(note.color.textColor.opacity(isHovered ? 0.85 : 0.0))
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(note.color.headerColor.opacity(0.55))
    }

    // MARK: - Tasks

    private var tasksView: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Active Tasks
            ForEach(filteredItems.filter { !$0.isCompleted }) { item in
                taskRow(item)
            }
            
            // Completed Tasks (Collapsible)
            let completed = filteredItems.filter { $0.isCompleted }
            if !completed.isEmpty {
                Button(action: { withAnimation { showCompleted.toggle() } }) {
                    HStack {
                        Text(showCompleted ? "Hide Completed" : "Show Completed (\(completed.count))")
                        Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(note.color.textColor.opacity(0.75))
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)
                
                if showCompleted {
                    ForEach(completed) { item in
                        taskRow(item)
                    }
                }
            }
            
            // Blocked Tasks Indicator (Visualizing Dependencies)
            let blocked = filteredItems.filter { $0.blockedBy != nil }
            if !blocked.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Blocked Tasks").font(.system(size: 10, weight: .bold)).foregroundColor(.orange)
                    ForEach(blocked) { item in
                        taskRow(item)
                    }
                }.padding(.top, 8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
    }

    @ViewBuilder
    private func taskRow(_ item: TodoItem) -> some View {
        TodoItemRow(
            item: item,
            noteColor: note.color,
            viewModel: viewModel,
            currentNoteID: note.id,
            onToggle: { viewModel.toggleItem(item.id, in: note.id) },
            onDelete: { viewModel.deleteItem(item.id, from: note.id) },
            onTextChange: { newText in viewModel.updateItemText(item.id, in: note.id, text: newText) },
            onDateChange: { newDate in viewModel.updateItemDueDate(item.id, in: note.id, date: newDate) }
        )
        .onDrag {
            self.draggedItem = item
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .onDrop(of: [.plainText], delegate: DragRelocateDelegate(item: item, noteID: note.id, viewModel: viewModel, draggedItem: $draggedItem))
    }

    // MARK: - Add Task Field

    private var addTaskField: some View {
        HStack(spacing: 8) {
            Button(action: { isNewItemFocused = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(note.color.textColor.opacity(0.75))
            }
            .buttonStyle(.plain)

            TextField("Add task…", text: $newItemText)
                .focused($isNewItemFocused)
                .onSubmit {
                    let textToAdd = newItemText.trimmingCharacters(in: .whitespaces)
                    guard !textToAdd.isEmpty else { return }
                    viewModel.addItem(to: note.id, text: textToAdd)
                    
                    newItemText = ""
                    isNewItemFocused = false
                    DispatchQueue.main.async {
                        newItemText = ""
                        isNewItemFocused = true
                    }
                }
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundColor(note.color.textColor.opacity(0.85))
            .focused($isNewItemFocused)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 6) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(note.color.textColor.opacity(0.2))
                        .frame(height: 3)

                    Capsule()
                        .fill(note.color.textColor.opacity(0.75))
                        .frame(width: max(0, geo.size.width * note.progress), height: 3)
                        .animation(.spring(response: 0.4), value: note.progress)
                }
            }
            .frame(height: 3)

            Text("\(note.completedCount)/\(note.totalCount)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(note.color.textColor.opacity(0.75))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .padding(.top, 4)
    }

    // MARK: - Background

    private var noteBackground: some View {
        ZStack {
            // Base color
            note.color.color

            // Subtle paper-like noise effect via gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.clear,
                    Color.black.opacity(0.03)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Optimized lines using Canvas
            Canvas { context, size in
                let lineSpacing: CGFloat = 22
                let topPadding: CGFloat = 40
                let lineCount = Int((size.height - topPadding) / lineSpacing)
                
                for i in 0..<lineCount {
                    let y = topPadding + CGFloat(i) * lineSpacing
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(note.color.textColor.opacity(0.04)), lineWidth: 0.5)
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Folded Corner

    private var foldedCorner: some View {
        Canvas { context, size in
            let cornerSize: CGFloat = 18
            var path = Path()
            path.move(to: CGPoint(x: size.width - cornerSize, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: cornerSize))
            path.addLine(to: CGPoint(x: size.width - cornerSize, y: cornerSize))
            path.closeSubpath()
            context.fill(path, with: .color(note.color.headerColor.opacity(0.4)))

            var shadow = Path()
            shadow.move(to: CGPoint(x: size.width - cornerSize, y: 0))
            shadow.addLine(to: CGPoint(x: size.width, y: cornerSize))
            shadow.addLine(to: CGPoint(x: size.width, y: 0))
            shadow.closeSubpath()
            context.fill(shadow, with: .color(Color.black.opacity(0.06)))
        }
        .allowsHitTesting(false)
    }
}
