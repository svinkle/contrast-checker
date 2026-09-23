import AppKit

func createIconImages() {
    let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
    let projectRoot = URL(fileURLWithPath: scriptDir).deletingLastPathComponent().deletingLastPathComponent().path
    let masterPngPath = "\(projectRoot)/assets/icon.png"
    let resourcesDir = "\(projectRoot)/macos/Resources"
    let iconsetDir = "\(resourcesDir)/AppIcon.iconset"
    let icnsPath = "\(resourcesDir)/AppIcon.icns"

    guard let masterImage = NSImage(contentsOfFile: masterPngPath) else {
        print("Error: Could not load master icon at \(masterPngPath)")
        exit(1)
    }

    try? FileManager.default.removeItem(atPath: iconsetDir)
    try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

    let specs: [(String, Int)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for (name, sz) in specs {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: sz,
            pixelsHigh: sz,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        masterImage.draw(in: NSRect(x: 0, y: 0, width: sz, height: sz))
        NSGraphicsContext.restoreGraphicsState()

        if let pngData = rep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
        }
    }

    // Run iconutil to create ICNS
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    task.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
    try? task.run()
    task.waitUntilExit()

    try? FileManager.default.removeItem(atPath: iconsetDir)
    print("AppIcon.icns successfully generated at \(icnsPath)")
}

createIconImages()
