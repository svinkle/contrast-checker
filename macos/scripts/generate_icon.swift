import AppKit

func renderIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.2237 // Standard macOS squircle radius
    let insetRect = rect.insetBy(dx: s * 0.04, dy: s * 0.04)
    let squircle = NSBezierPath(roundedRect: insetRect, xRadius: cornerRadius, yRadius: cornerRadius)

    let midY = s / 2.0
    let topHalfRect = NSRect(x: 0, y: midY, width: s, height: s - midY)
    let bottomHalfRect = NSRect(x: 0, y: 0, width: s, height: midY)

    // 1. Draw top half background (Black)
    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    NSColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0).setFill()
    topHalfRect.fill()

    // 2. Draw bottom half background (White)
    NSColor.white.setFill()
    bottomHalfRect.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Helper to draw the target icon
    func drawTarget(strokeColor: NSColor) {
        strokeColor.setStroke()
        strokeColor.setFill()

        let cx = s / 2.0
        let cy = s / 2.0
        let outerRadius = s * 0.23
        let strokeWidth = max(1.0, s * 0.032)

        // Outer ring
        let circlePath = NSBezierPath(ovalIn: NSRect(x: cx - outerRadius, y: cy - outerRadius, width: outerRadius * 2, height: outerRadius * 2))
        circlePath.lineWidth = strokeWidth
        circlePath.stroke()

        // Crosshair ticks
        let tickInner = outerRadius * 0.65
        let tickOuter = outerRadius * 1.35

        // Top tick
        let topTick = NSBezierPath()
        topTick.move(to: NSPoint(x: cx, y: cy + tickInner))
        topTick.line(to: NSPoint(x: cx, y: cy + tickOuter))
        topTick.lineWidth = strokeWidth
        topTick.lineCapStyle = .round
        topTick.stroke()

        // Bottom tick
        let bottomTick = NSBezierPath()
        bottomTick.move(to: NSPoint(x: cx, y: cy - tickInner))
        bottomTick.line(to: NSPoint(x: cx, y: cy - tickOuter))
        bottomTick.lineWidth = strokeWidth
        bottomTick.lineCapStyle = .round
        bottomTick.stroke()

        // Left tick
        let leftTick = NSBezierPath()
        leftTick.move(to: NSPoint(x: cx - tickOuter, y: cy))
        leftTick.line(to: NSPoint(x: cx - tickInner, y: cy))
        leftTick.lineWidth = strokeWidth
        leftTick.lineCapStyle = .round
        leftTick.stroke()

        // Right tick
        let rightTick = NSBezierPath()
        rightTick.move(to: NSPoint(x: cx + tickInner, y: cy))
        rightTick.line(to: NSPoint(x: cx + tickOuter, y: cy))
        rightTick.lineWidth = strokeWidth
        rightTick.lineCapStyle = .round
        rightTick.stroke()

        // Center crosshair / plus
        let centerCrossArm = outerRadius * 0.28
        let centerH = NSBezierPath()
        centerH.move(to: NSPoint(x: cx - centerCrossArm, y: cy))
        centerH.line(to: NSPoint(x: cx + centerCrossArm, y: cy))
        centerH.lineWidth = strokeWidth * 0.9
        centerH.lineCapStyle = .round
        centerH.stroke()

        let centerV = NSBezierPath()
        centerV.move(to: NSPoint(x: cx, y: cy - centerCrossArm))
        centerV.line(to: NSPoint(x: cx, y: cy + centerCrossArm))
        centerV.lineWidth = strokeWidth * 0.9
        centerV.lineCapStyle = .round
        centerV.stroke()
    }

    // Draw target on top half (White on Black)
    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    let topClip = NSBezierPath(rect: topHalfRect)
    topClip.addClip()
    drawTarget(strokeColor: NSColor.white)
    NSGraphicsContext.restoreGraphicsState()

    // Draw target on bottom half (Black on White)
    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    let bottomClip = NSBezierPath(rect: bottomHalfRect)
    bottomClip.addClip()
    drawTarget(strokeColor: NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0))
    NSGraphicsContext.restoreGraphicsState()

    // Subtle outer squircle outline
    NSGraphicsContext.saveGraphicsState()
    squircle.lineWidth = max(1.0, s * 0.008)
    NSColor(white: 0.0, alpha: 0.15).setStroke()
    squircle.stroke()
    NSGraphicsContext.restoreGraphicsState()

    image.unlockFocus()
    return image
}

let iconsetDir = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for sz in sizes {
    let img = renderIcon(size: sz)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let name = sz == 1024 ? "icon_512x512@2x.png" : "icon_\(sz)x\(sz).png"
        try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
        if sz <= 512 && sz > 16 {
            let half = sz / 2
            let name2x = "icon_\(half)x\(half)@2x.png"
            try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name2x)"))
        }
    }
}

// Generate ICNS
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", "Resources/AppIcon.icns"]
try? task.run()
task.waitUntilExit()

try? FileManager.default.removeItem(atPath: iconsetDir)
print("AppIcon.icns generated at Resources/AppIcon.icns")

