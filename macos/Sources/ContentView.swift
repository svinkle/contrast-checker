import SwiftUI
import AppKit

public struct ContentView: View {
    @ObservedObject var model: ColorModel
    @ObservedObject var sampler: ColorSamplerManager
    var onClose: (() -> Void)?

    public init(model: ColorModel, sampler: ColorSamplerManager, onClose: (() -> Void)? = nil) {
        self.model = model
        self.sampler = sampler
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Top Region (Background Color with Foreground Text as Sample)
                ZStack(alignment: .topTrailing) {
                    Color(nsColor: model.backgroundColor)

                    // Subtle close button in the top-right corner
                    Button(action: {
                        if let onClose = onClose {
                            onClose()
                        } else {
                            NSApp.keyWindow?.orderOut(nil)
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(nsColor: model.foregroundColor).opacity(0.65))
                            .frame(width: 22, height: 22)
                            .background(Color(nsColor: model.foregroundColor).opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close window (⌘W)")
                    .padding(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()

                        // Contrast Ratio acting as live sample text (no copy icon)
                        Button(action: {
                            model.copyValue(model.contrastRatioString, label: model.contrastRatioString)
                        }) {
                            Text(model.contrastRatioString)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(Color(nsColor: model.foregroundColor))
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Click to copy contrast ratio (\(model.contrastRatioString))")

                        Text("Contrast Ratio")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(nsColor: model.foregroundColor).opacity(0.75))

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                }
                .frame(height: 130)

                // MARK: - Bottom Region (Background & Foreground Color Pickers)
                VStack(spacing: 12) {
                    // Background Color Row
                    ColorItemRow(
                        title: "Background",
                        hex: model.bgHex,
                        color: model.backgroundColor,
                        onPick: {
                            sampler.pickBackgroundColor(into: model)
                        },
                        onCopy: {
                            model.copyValue(model.bgHex, label: model.bgHex)
                        }
                    )

                    Divider()
                        .opacity(0.25)

                    // Foreground Color Row
                    ColorItemRow(
                        title: "Foreground",
                        hex: model.fgHex,
                        color: model.foregroundColor,
                        onPick: {
                            sampler.pickForegroundColor(into: model)
                        },
                        onCopy: {
                            model.copyValue(model.fgHex, label: model.fgHex)
                        }
                    )
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )

            // MARK: - Copied Toast Overlay
            if let message = model.copiedMessage {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13, weight: .bold))
                        Text(message)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
                .padding(.top, 14)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.copiedMessage)
            }
        }
        .frame(width: 340, height: 260)
    }
}

// MARK: - Color Item Row

struct ColorItemRow: View {
    let title: String
    let hex: String
    let color: NSColor
    let onPick: () -> Void
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Eyedropper Button for OS-level sampling
            Button(action: onPick) {
                Image(systemName: "scope")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Pick \(title.lowercased()) color from anywhere on screen")

            // Color Swatch Circle
            Circle()
                .fill(Color(nsColor: color))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)

            // HEX Code (Clickable to Copy, no copy icon)
            Button(action: onCopy) {
                Text(hex)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Click to copy \(title.lowercased()) HEX (\(hex))")

            Spacer()

            // Indicator label
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}
