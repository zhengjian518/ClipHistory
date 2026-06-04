import AppKit

extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    func thumbnail(maxHeight: CGFloat) -> NSImage {
        guard size.height > 0 else { return self }
        let ratio = maxHeight / size.height
        let newSize = NSSize(width: size.width * ratio, height: maxHeight)

        let thumb = NSImage(size: newSize)
        thumb.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        thumb.unlockFocus()
        return thumb
    }
}
