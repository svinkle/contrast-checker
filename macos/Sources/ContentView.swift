import SwiftUI
import AppKit

// MARK: - Focus Navigation Field

public enum FocusField: Hashable, CaseIterable {
    case close
    case contrastRatio
    case bgPicker
    case bgHex
    case fgPicker
    case fgHex
}

// MARK: - Accessible Focus Ring Modifier

struct FocusRingModifier: ViewModifier {
    let isFocused: Bool
    let isCircle: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isFocused {
                        if isCircle {
                            Circle()
                                .stroke(Color.black.opacity(0.4), lineWidth: 3.5)
                                .overlay(
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: 2)
                                )
                                .padding(-3)
                        } else {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.black.opacity(0.4), lineWidth: 3.5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.accentColor, lineWidth: 2)
                                )
                                .padding(-4)
                        }
                    }
                }
            )
    }
}

extension View {
    func focusRing(isFocused: Bool, isCircle: Bool = false) -> some View {
        self.modifier(FocusRingModifier(isFocused: isFocused, isCircle: isCircle))
    }
}

public struct ContentView: View {
    @ObservedObject var model: ColorModel
    @ObservedObject var sampler: ColorSamplerManager
    var onClose: (() -> Void)?
    @StateObject private var navManager = KeyboardNavigationManager()

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
                    .focusRing(isFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .close, isCircle: true)
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
                        .focusRing(isFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .contrastRatio, isCircle: false)
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
                        isPickerFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .bgPicker,
                        isHexFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .bgHex,
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
                        isPickerFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .fgPicker,
                        isHexFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .fgHex,
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(message)
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
        .onAppear {
            navManager.startMonitoring(
                onAction: { field in
                    activateField(field)
                },
                onClose: onClose
            )
        }
        .onDisappear {
            navManager.stopMonitoring()
        }
    }

    private func activateField(_ field: FocusField) {
        switch field {
        case .close:
            if let onClose = onClose {
                onClose()
            } else {
                NSApp.keyWindow?.orderOut(nil)
            }
        case .contrastRatio:
            model.copyValue(model.contrastRatioString, label: model.contrastRatioString)
        case .bgPicker:
            sampler.pickBackgroundColor(into: model)
        case .bgHex:
            model.copyValue(model.bgHex, label: model.bgHex)
        case .fgPicker:
            sampler.pickForegroundColor(into: model)
        case .fgHex:
            model.copyValue(model.fgHex, label: model.fgHex)
        }
    }
}

// MARK: - Color Item Row

struct ColorItemRow: View {
    let title: String
    let hex: String
    let color: NSColor
    var isPickerFocused: Bool = false
    var isHexFocused: Bool = false
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
            .focusRing(isFocused: isPickerFocused, isCircle: true)
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
            .focusRing(isFocused: isHexFocused, isCircle: false)
            .help("Click to copy \(title.lowercased()) HEX (\(hex))")

            Spacer()

            // Indicator label
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Keyboard Navigation Manager

@MainActor
final class KeyboardNavigationManager: ObservableObject {
    @Published var currentFocus: FocusField? = nil
    @Published var isKeyboardNavigating: Bool = false

    private var keyMonitor: Any?
    private var mouseMonitor: Any?
    private var resignMonitor: NSObjectProtocol?

    func startMonitoring(onAction: @escaping (FocusField) -> Void, onClose: (() -> Void)?) {
        stopMonitoring()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            guard let keyWindow = NSApp.keyWindow, keyWindow.isKeyWindow else { return event }

            if event.keyCode == 48 { // Tab key
                self.isKeyboardNavigating = true
                let isShift = event.modifierFlags.contains(.shift)
                self.moveFocus(reverse: isShift)
                return nil
            } else if (event.keyCode == 49 || event.keyCode == 36) && self.isKeyboardNavigating && self.currentFocus != nil {
                // Space (49) or Return (36)
                if let focus = self.currentFocus {
                    onAction(focus)
                }
                return nil
            } else if event.keyCode == 53 { // Escape
                if self.currentFocus != nil {
                    self.currentFocus = nil
                    self.isKeyboardNavigating = false
                    return nil
                }
                return event
            }
            return event
        }

        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.isKeyboardNavigating = false
            self?.currentFocus = nil
            return event
        }

        resignMonitor = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isKeyboardNavigating = false
                self?.currentFocus = nil
            }
        }
    }

    func stopMonitoring() {
        if let km = keyMonitor {
            NSEvent.removeMonitor(km)
            keyMonitor = nil
        }
        if let mm = mouseMonitor {
            NSEvent.removeMonitor(mm)
            mouseMonitor = nil
        }
        if let rm = resignMonitor {
            NotificationCenter.default.removeObserver(rm)
            resignMonitor = nil
        }
    }

    private func moveFocus(reverse: Bool) {
        let allFields = FocusField.allCases
        guard !allFields.isEmpty else { return }

        guard let current = currentFocus, let currentIndex = allFields.firstIndex(of: current) else {
            currentFocus = reverse ? allFields.last : allFields.first
            return
        }

        if reverse {
            let prevIndex = (currentIndex - 1 + allFields.count) % allFields.count
            currentFocus = allFields[prevIndex]
        } else {
            let nextIndex = (currentIndex + 1) % allFields.count
            currentFocus = allFields[nextIndex]
        }
    }
}
