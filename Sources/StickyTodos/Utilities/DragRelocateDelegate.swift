import SwiftUI
import UniformTypeIdentifiers

struct DragRelocateDelegate: DropDelegate {
    let item: TodoItem
    let noteID: UUID
    let viewModel: NotesViewModel
    @Binding var draggedItem: TodoItem?

    func dropEntered(info: DropInfo) {
        guard let current = draggedItem else { return }
        guard item != current else { return }

        guard let noteIdx = viewModel.notes.firstIndex(where: { $0.id == noteID }) else { return }
        let items = viewModel.notes[noteIdx].items

        guard let from = items.firstIndex(of: current),
              let to = items.firstIndex(of: item) else { return }

        if items[to].id != current.id {
            viewModel.moveItem(from: IndexSet(integer: from), to: to > from ? to + 1 : to, in: noteID)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.draggedItem = nil
        return true
    }
}
