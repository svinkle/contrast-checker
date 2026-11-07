import SwiftUI
import AppKit

// MARK: - Focus Navigation Field

public enum FocusField: Hashable, CaseIterable {
    case close
    case contrastRatio
    case bgPicker
    case bgSwatch
    case bgHex
    case fgPicker
    case fgSwatch
    case fgHex
}

public enum EditingTarget: Hashable {
    case background
    case foreground
}

// MARK: - Accessible Focus Ring Modifier

struct FocusRingModifier: ViewModifier {
    let isFocused: Bool
    let isCircle: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let decorated = content
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
        if #available(macOS 14.0, *) {
            decorated.focusEffectDisabled()
        } else {
            decorated
        }
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
                        commitCurrentEditIfNeeded()
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
                            commitCurrentEditIfNeeded()
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
                        isEditing: navManager.editingTarget == .background,
                        editingText: navManager.editingText,
                        focusTrigger: navManager.editFocusTrigger,
                        isPickerFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .bgPicker,
                        isSwatchFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .bgSwatch,
                        isHexFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .bgHex,
                        onPick: {
                            commitCurrentEditIfNeeded()
                            sampler.pickBackgroundColor(into: model)
                        },
                        onStartEdit: {
                            startEditing(.background)
                        },
                        onLiveChange: { newText in
                            navManager.editingText = newText
                            applyLiveHexIfComplete(newText, for: .background)
                        },
                        onCommitEdit: {
                            commitEdit(for: .background)
                        },
                        onCancelEdit: {
                            cancelEdit(for: .background)
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
                        isEditing: navManager.editingTarget == .foreground,
                        editingText: navManager.editingText,
                        focusTrigger: navManager.editFocusTrigger,
                        isPickerFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .fgPicker,
                        isSwatchFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .fgSwatch,
                        isHexFocused: navManager.isKeyboardNavigating && navManager.currentFocus == .fgHex,
                        onPick: {
                            commitCurrentEditIfNeeded()
                            sampler.pickForegroundColor(into: model)
                        },
                        onStartEdit: {
                            startEditing(.foreground)
                        },
                        onLiveChange: { newText in
                            navManager.editingText = newText
                            applyLiveHexIfComplete(newText, for: .foreground)
                        },
                        onCommitEdit: {
                            commitEdit(for: .foreground)
                        },
                        onCancelEdit: {
                            cancelEdit(for: .foreground)
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

    private func startEditing(_ target: EditingTarget) {
        if navManager.editingTarget != nil && navManager.editingTarget != target {
            commitCurrentEditIfNeeded()
        }
        let currentHex = (target == .background) ? model.bgHex : model.fgHex
        navManager.editingInitialHex = currentHex
        navManager.editingText = currentHex
        navManager.editingTarget = target
        navManager.editFocusTrigger &+= 1
    }

    private func applyLiveHexIfComplete(_ text: String, for target: EditingTarget) {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let color = ColorModel.color(fromHex: cleaned) else {
            return
        }
        if target == .background {
            model.setBackgroundColor(color)
        } else {
            model.setForegroundColor(color)
        }
    }

    private func commitCurrentEditIfNeeded() {
        if let active = navManager.editingTarget {
            commitEdit(for: active)
        }
    }

    private func commitEdit(for target: EditingTarget) {
        guard navManager.editingTarget == target else { return }
        if let color = ColorModel.color(fromHex: navManager.editingText) {
            if target == .background {
                model.setBackgroundColor(color)
            } else {
                model.setForegroundColor(color)
            }
        } else {
            if target == .background {
                model.setBackgroundHex(navManager.editingInitialHex)
            } else {
                model.setForegroundHex(navManager.editingInitialHex)
            }
        }
        navManager.editingTarget = nil
    }

    private func cancelEdit(for target: EditingTarget) {
        guard navManager.editingTarget == target else { return }
        if target == .background {
            model.setBackgroundHex(navManager.editingInitialHex)
        } else {
            model.setForegroundHex(navManager.editingInitialHex)
        }
        navManager.editingTarget = nil
    }

    private func activateField(_ field: FocusField) {
        switch field {
        case .close:
            commitCurrentEditIfNeeded()
            if let onClose = onClose {
                onClose()
            } else {
                NSApp.keyWindow?.orderOut(nil)
            }
        case .contrastRatio:
            commitCurrentEditIfNeeded()
            model.copyValue(model.contrastRatioString, label: model.contrastRatioString)
        case .bgPicker:
            commitCurrentEditIfNeeded()
            sampler.pickBackgroundColor(into: model)
        case .bgSwatch:
            startEditing(.background)
        case .bgHex:
            commitCurrentEditIfNeeded()
            model.copyValue(model.bgHex, label: model.bgHex)
        case .fgPicker:
            commitCurrentEditIfNeeded()
            sampler.pickForegroundColor(into: model)
        case .fgSwatch:
            startEditing(.foreground)
        case .fgHex:
            commitCurrentEditIfNeeded()
            model.copyValue(model.fgHex, label: model.fgHex)
        }
    }
}

// MARK: - Inline AppKit HEX Text Field

struct HexEditField: NSViewRepresentable {
    let text: String
    let focusTrigger: Int
    let title: String
    let onLiveChange: (String) -> Void
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField(string: text)
        tf.delegate = context.coordinator
        tf.font = .monospacedSystemFont(ofSize: 15, weight: .bold)
        tf.textColor = .labelColor
        tf.backgroundColor = .textBackgroundColor
        tf.drawsBackground = true
        tf.isBordered = true
        tf.isBezeled = true
        tf.bezelStyle = .roundedBezel
        tf.focusRingType = .exterior
        tf.lineBreakMode = .byClipping
        tf.cell?.isScrollable = true
        tf.cell?.usesSingleLineMode = true
        tf.setAccessibilityLabel("Edit \(title.lowercased()) HEX value")
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self
        if nsView.window?.firstResponder !== nsView.currentEditor() && nsView.stringValue != text {
            nsView.stringValue = text
        }
        if context.coordinator.lastFocusTrigger != focusTrigger {
            context.coordinator.lastFocusTrigger = focusTrigger
            context.coordinator.didFinish = false
            nsView.stringValue = text
            DispatchQueue.main.async {
                guard let window = nsView.window else { return }
                window.makeFirstResponder(nsView)
                nsView.currentEditor()?.selectAll(nil)
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: HexEditField
        var lastFocusTrigger: Int = -1
        var didFinish = false

        init(_ parent: HexEditField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            let val = tf.stringValue
            parent.onLiveChange(val)
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard !didFinish else { return }
            didFinish = true
            parent.onCommit()
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                didFinish = true
                parent.onCommit()
                control.window?.makeFirstResponder(nil)
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                didFinish = true
                parent.onCancel()
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

// MARK: - Color Item Row

struct ColorItemRow: View {
    let title: String
    let hex: String
    let color: NSColor
    var isEditing: Bool = false
    var editingText: String = ""
    var focusTrigger: Int = 0
    var isPickerFocused: Bool = false
    var isSwatchFocused: Bool = false
    var isHexFocused: Bool = false
    let onPick: () -> Void
    let onStartEdit: () -> Void
    let onLiveChange: (String) -> Void
    let onCommitEdit: () -> Void
    let onCancelEdit: () -> Void
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

            // Color Swatch Circle (Click to edit HEX value)
            Button(action: onStartEdit) {
                Circle()
                    .fill(Color(nsColor: color))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .focusRing(isFocused: isSwatchFocused, isCircle: true)
            .help("Click to edit \(title.lowercased()) HEX (\(hex))")
            .accessibilityLabel("Edit \(title.lowercased()) HEX value")

            if isEditing {
                HexEditField(
                    text: editingText,
                    focusTrigger: focusTrigger,
                    title: title,
                    onLiveChange: onLiveChange,
                    onCommit: onCommitEdit,
                    onCancel: onCancelEdit
                )
                .frame(width: 98, height: 24)
            } else {
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
            }

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
    @Published var editingTarget: EditingTarget? = nil
    @Published var editingText: String = ""
    @Published var editFocusTrigger: Int = 0
    var editingInitialHex: String = ""

    private var keyMonitor: Any?
    private var mouseMonitor: Any?
    private var resignMonitor: NSObjectProtocol?

    func startMonitoring(onAction: @escaping (FocusField) -> Void, onClose: (() -> Void)?) {
        stopMonitoring()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            guard let keyWindow = NSApp.keyWindow, keyWindow.isKeyWindow else { return event }

            // Let active HEX text field handle its own key events (typing, Return, Escape, Paste)
            if keyWindow.firstResponder is NSText {
                if event.keyCode == 48 { // Tab key while editing: end editing and move focus
                    keyWindow.makeFirstResponder(nil)
                    self.isKeyboardNavigating = true
                    let isShift = event.modifierFlags.contains(.shift)
                    self.moveFocus(reverse: isShift)
                    return nil
                }
                return event
            }

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
