import AppKit
import SwiftUI
import Combine

public final class ColorModel: ObservableObject {
    @Published public var backgroundColor: NSColor {
        didSet { updateHexValues() }
    }
    @Published public var foregroundColor: NSColor {
        didSet { updateHexValues() }
    }

    @Published public private(set) var bgHex: String = "#000000"
    @Published public private(set) var fgHex: String = "#FFFFFF"
    @Published public var copiedMessage: String? = nil

    private var copiedTimer: Timer? = nil

    public init(
        background: NSColor = ColorModel.color(fromHex: "#000000") ?? .black,
        foreground: NSColor = ColorModel.color(fromHex: "#FFFFFF") ?? .white
    ) {
        self.backgroundColor = ColorModel.quantizedSRGBColor(from: background)
        self.foregroundColor = ColorModel.quantizedSRGBColor(from: foreground)
        updateHexValues()
    }

    private func updateHexValues() {
        bgHex = ColorModel.hexString(from: backgroundColor)
        fgHex = ColorModel.hexString(from: foregroundColor)
    }

    public func setBackgroundColor(_ color: NSColor) {
        self.backgroundColor = ColorModel.quantizedSRGBColor(from: color)
    }

    public func setForegroundColor(_ color: NSColor) {
        self.foregroundColor = ColorModel.quantizedSRGBColor(from: color)
    }

    public func setBackgroundHex(_ hex: String) {
        if let color = ColorModel.color(fromHex: hex) {
            self.backgroundColor = color
        }
    }

    public func setForegroundHex(_ hex: String) {
        if let color = ColorModel.color(fromHex: hex) {
            self.foregroundColor = color
        }
    }

    // MARK: - WCAG Contrast Calculation (cstrobbe/contrast-ratio parity)

    public static func floor(_ number: Double, decimals: Int = 0) -> Double {
        let multiplier = pow(10.0, Double(decimals))
        return Foundation.floor(number * multiplier) / multiplier
    }

    public var preciseContrastRatio: Double {
        let l1 = ColorModel.relativeLuminance(of: backgroundColor) + 0.05
        let l2 = ColorModel.relativeLuminance(of: foregroundColor) + 0.05
        var ratio = l1 / l2
        if l2 > l1 {
            ratio = 1.0 / ratio
        }
        return ratio
    }

    public var contrastRatio: Double {
        return ColorModel.floor(preciseContrastRatio, decimals: 2)
    }

    public var contrastRatioString: String {
        return "\(contrastRatioValueOnly):1"
    }

    public var contrastRatioValueOnly: String {
        let cents = Int(Foundation.floor(preciseContrastRatio * 100.0))
        if cents % 100 == 0 {
            return "\(cents / 100)"
        } else if cents % 10 == 0 {
            return "\(cents / 100).\((cents % 100) / 10)"
        } else {
            return String(format: "%d.%02d", cents / 100, cents % 100)
        }
    }

    public static func relativeLuminance(of color: NSColor) -> Double {
        let (r, g, b) = rgbComponents(of: color)

        let rLin = sRGBtoLinear(Double(r) / 255.0)
        let gLin = sRGBtoLinear(Double(g) / 255.0)
        let bLin = sRGBtoLinear(Double(b) / 255.0)

        return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin
    }

    private static func sRGBtoLinear(_ val: Double) -> Double {
        let clamped = max(0.0, min(1.0, val))
        if clamped < 0.03928 {
            return clamped / 12.92
        } else {
            return pow((clamped + 0.055) / 1.055, 2.4)
        }
    }

    // MARK: - HEX & 8-Bit sRGB Quantization Helpers

    public static func rgbComponents(of color: NSColor) -> (r: Int, g: Int, b: Int) {
        guard let srgb = color.usingColorSpace(.sRGB) else {
            return (0, 0, 0)
        }
        let r = Int(round(max(0, min(1, srgb.redComponent)) * 255.0))
        let g = Int(round(max(0, min(1, srgb.greenComponent)) * 255.0))
        let b = Int(round(max(0, min(1, srgb.blueComponent)) * 255.0))
        return (r, g, b)
    }

    public static func quantizedSRGBColor(from color: NSColor) -> NSColor {
        let (r, g, b) = rgbComponents(of: color)
        return NSColor(
            srgbRed: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }

    public static func hexString(from color: NSColor) -> String {
        let (r, g, b) = rgbComponents(of: color)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    public static func color(fromHex hex: String) -> NSColor? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }

        // Support 3-char shorthand: "FFF" -> "FFFFFF"
        if cleanHex.count == 3 {
            cleanHex = cleanHex.map { "\($0)\($0)" }.joined()
        }

        guard cleanHex.count == 6, let rgbValue = UInt64(cleanHex, radix: 16) else {
            return nil
        }

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    }

    // MARK: - Clipboard Copy

    public func copyValue(_ text: String, label: String) {
        ColorModel.copyToClipboard(text)
        let announcement = "Copied \(label)"
        copiedMessage = announcement
        ColorModel.postAccessibilityAnnouncement(announcement)
        copiedTimer?.invalidate()
        copiedTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.copiedMessage = nil
            }
        }
    }

    public static func postAccessibilityAnnouncement(_ message: String) {
        guard let app = NSApp else { return }
        let userInfo: [NSAccessibility.NotificationUserInfoKey: Any] = [
            .announcement: message,
            .priority: NSAccessibilityPriorityLevel.high.rawValue
        ]
        NSAccessibility.post(
            element: app,
            notification: .announcementRequested,
            userInfo: userInfo
        )
    }

    public static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
