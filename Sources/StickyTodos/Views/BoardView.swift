import SwiftUI

/// The corkboard-style grid that displays all sticky notes.
struct BoardView: View {
    @Bindable var viewModel: NotesViewModel
    var filter: TaskFilter = .all
    var background: BoardBackground = .glass

    private let boardSize: CGFloat = 3000

    var body: some View {
        ZStack {
            // Background layer
            backgroundView

            if viewModel.notes.isEmpty {
                emptyStateView
            } else {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // Invisible background to enforce massive canvas size
                        Color.clear.frame(width: boardSize, height: boardSize)

                        ForEach(viewModel.notes.filter { !$0.isArchived && $0.workspace == viewModel.selectedWorkspace }) { note in
                            NoteContainer(
                                note: note,
                                viewModel: viewModel,
                                filter: filter,
                                boardSize: boardSize
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                        }
                    }
                }
                .defaultScrollAnchor(.center)

                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingAddButton
                            .padding(32)
                    }
                }
            }
        }
    }

    // MARK: - Backgrounds

    @AppStorage("customBackgroundImagePath") private var customBackgroundImagePath: String = ""

    @ViewBuilder
    private var backgroundView: some View {
        switch background {
        case .glass:
            glassBackground
        case .corkboard:
            corkboardBackground
        case .whiteboard:
            whiteboardBackground
        case .grid:
            gridBackground
        case .custom:
            customImageBackground
        }
    }

    @ViewBuilder
    private var customImageBackground: some View {
        GeometryReader { geo in
            if !customBackgroundImagePath.isEmpty,
               let nsImage = NSImage(contentsOfFile: customBackgroundImagePath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                corkboardBackground
            }
        }
        .ignoresSafeArea()
    }

    private var glassBackground: some View {
        ZStack {
            // Animated Liquid Mesh (macOS 15+)
            if #available(macOS 15.0, *) {
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.8, 0.2], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ], colors: [
                    .blue.opacity(0.4), .purple.opacity(0.3), .indigo.opacity(0.4),
                    .cyan.opacity(0.2), .blue.opacity(0.5), .purple.opacity(0.2),
                    .indigo.opacity(0.4), .blue.opacity(0.3), .cyan.opacity(0.4)
                ])
                .ignoresSafeArea()
                .blur(radius: 40)
            } else {
                // Fallback for older macOS
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Glassy reflections
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                center: .topLeading,
                startRadius: 0,
                endRadius: 800
            )
            .ignoresSafeArea()
        }
        .background(.ultraThinMaterial)
    }

    private var corkboardBackground: some View {
        ZStack {
            // Warm cork color
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.78, green: 0.65, blue: 0.48),
                    Color(red: 0.72, green: 0.58, blue: 0.42),
                    Color(red: 0.68, green: 0.55, blue: 0.40)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Cork texture pattern (subtle dots)
            Canvas { context, size in
                for x in stride(from: 0, to: size.width, by: 8) {
                    for y in stride(from: 0, to: size.height, by: 8) {
                        let randomOffset = Double((Int(x) * 31 + Int(y) * 17) % 100) / 100.0
                        if randomOffset > 0.6 {
                            let dotSize = 1.5 + randomOffset * 2.0
                            let opacity = 0.03 + randomOffset * 0.05
                            let rect = CGRect(
                                x: x + randomOffset * 4,
                                y: y + randomOffset * 4,
                                width: dotSize,
                                height: dotSize
                            )
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(Color.black.opacity(opacity))
                            )
                        }
                    }
                }
            }

            // Subtle vignette
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.15)
                ]),
                center: .center,
                startRadius: 200,
                endRadius: 800
            )
        }
        .ignoresSafeArea()
        .drawingGroup()
    }

    private var whiteboardBackground: some View {
        ZStack {
            Color(white: 0.96)
            // Subtle specular highlight
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.8), Color.clear]),
                center: .topLeading,
                startRadius: 50,
                endRadius: 600
            )
        }
        .ignoresSafeArea()
        .drawingGroup()
    }

    private var gridBackground: some View {
        ZStack {
            Color(red: 0.1, green: 0.2, blue: 0.35)
            // Grid lines
            Canvas { context, size in
                let spacing: CGFloat = 30
                var path = Path()
                
                for x in stride(from: 0, to: size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, to: size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                
                context.stroke(path, with: .color(Color.white.opacity(0.1)), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
        .drawingGroup()
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        Button(action: {
            _ = viewModel.addNote()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(Color.black.opacity(0.2))

            VStack(spacing: 8) {
                Text("Your board is empty")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.6))
                
                Text("Create a sticky note to start organizing your tasks.")
                    .font(.system(size: 15))
                    .foregroundColor(Color.black.opacity(0.4))
            }

            Button(action: {
                _ = viewModel.addNote()
            }) {
                Text("Create Sticky Note")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
    }
}

/// Helper view to isolate dragging state for performance.
struct NoteContainer: View {
    let note: StickyNote
    @Bindable var viewModel: NotesViewModel
    var filter: TaskFilter
    let boardSize: CGFloat

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        StickyNoteView(note: note, viewModel: viewModel, filter: filter)
            .frame(width: 260)
            .offset(dragOffset)
            .position(note.position ?? CGPoint(x: 1500, y: 1500))
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let current = note.position ?? CGPoint(x: 1500, y: 1500)
                        let newX = max(130, min(current.x + value.translation.width, boardSize - 130))
                        let newY = max(100, min(current.y + value.translation.height, boardSize - 100))
                        
                        // Fix bouncing bug: Reset offset and update position in one non-animated transaction
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            dragOffset = .zero
                            viewModel.updateNotePosition(note.id, position: CGPoint(x: newX, y: newY))
                        }
                    }
            )
    }
}
