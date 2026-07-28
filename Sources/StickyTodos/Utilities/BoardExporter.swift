import SwiftUI
import AppKit

/// A utility to render SwiftUI Views into NSImages and save them.
@MainActor
struct BoardExporter {
    
    /// Renders a specific view into an NSImage
    static func render<V: View>(view: V) -> NSImage? {
        if #available(macOS 13.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
            return renderer.nsImage
        } else {
            print("ImageRenderer requires macOS 13.0+")
            return nil
        }
    }
    
    /// Renders the view and saves it to the Desktop
    static func saveToDesktop<V: View>(view: V, filename: String = "StickyTodos_Board.png") {
        guard let image = render(view: view) else { return }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else { return }
        
        do {
            let desktopURL = try FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = desktopURL.appendingPathComponent(filename)
            try pngData.write(to: fileURL)
            
            // Trigger a quick local notification or sound to confirm save
            NSSound(named: "Glass")?.play()
            print("Successfully saved board to \(fileURL.path)")
        } catch {
            print("Failed to save board image: \(error)")
        }
    }
}
