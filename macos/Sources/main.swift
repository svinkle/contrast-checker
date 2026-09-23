import AppKit
import SwiftUI
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var statusItem: NSStatusItem!
    var statusMenu: NSMenu!

    let model = ColorModel()
    let sampler = ColorSamplerManager()
    let hotKeyManager = HotKeyManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        setupStatusItem()
        setupMenu()
        setupGlobalHotKeys()

        // Show app initially on launch
        showApp()
    }

    // MARK: - Window Setup

    private func setupWindow() {
        let contentView = ContentView(model: model, sampler: sampler, onClose: { [weak self] in
            self?.hideApp()
        })

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 260),
            styleMask: [
                .titled,
                .closable,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        win.center()
        win.level = .floating // Always floats on top of all OS windows & VMs
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.isMovableByWindowBackground = true
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.isReleasedWhenClosed = false
        win.delegate = self

        // Hide standard macOS traffic light buttons
        win.standardWindowButton(.closeButton)?.isHidden = true
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true

        win.contentView = NSHostingView(rootView: contentView)
        self.window = win
    }

    // MARK: - Status Bar Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scope", accessibilityDescription: "Contrast Checker")
            button.image?.isTemplate = true
            button.toolTip = "Contrast Checker (⌃⌥C)"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Build right-click context menu
        statusMenu = NSMenu(title: "Contrast Checker")

        let toggleItem = NSMenuItem(title: "Toggle Contrast Checker", action: #selector(toggleAppVisibility), keyEquivalent: "c")
        toggleItem.keyEquivalentModifierMask = [.control, .option]
        toggleItem.target = self
        statusMenu.addItem(toggleItem)

        statusMenu.addItem(NSMenuItem.separator())

        let pickBgItem = NSMenuItem(title: "Pick Background Color", action: #selector(pickBackground), keyEquivalent: "b")
        pickBgItem.keyEquivalentModifierMask = [.control, .option]
        pickBgItem.target = self
        statusMenu.addItem(pickBgItem)

        let pickFgItem = NSMenuItem(title: "Pick Foreground Color", action: #selector(pickForeground), keyEquivalent: "f")
        pickFgItem.keyEquivalentModifierMask = [.control, .option]
        pickFgItem.target = self
        statusMenu.addItem(pickFgItem)

        statusMenu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "About Contrast Checker", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        statusMenu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit Contrast Checker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        statusMenu.addItem(quitItem)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem.menu = statusMenu
            statusItem.button?.performClick(nil)
            // Reset menu so left-click continues to toggle visibility directly
            statusItem.menu = nil
        } else {
            toggleAppVisibility()
        }
    }

    // MARK: - Global Hotkeys Setup (Ctrl + Opt)

    private func setupGlobalHotKeys() {
        let ctrlOpt = UInt32(controlKey | optionKey)

        // 1. Toggle Show/Hide: Ctrl + Opt + C
        hotKeyManager.register(id: 1, keyCode: UInt32(kVK_ANSI_C), modifiers: ctrlOpt) { [weak self] in
            Task { @MainActor in
                self?.toggleAppVisibility()
            }
        }

        // 2. Pick Background: Ctrl + Opt + B
        hotKeyManager.register(id: 2, keyCode: UInt32(kVK_ANSI_B), modifiers: ctrlOpt) { [weak self] in
            Task { @MainActor in
                self?.pickBackground()
            }
        }

        // 3. Pick Foreground: Ctrl + Opt + F
        hotKeyManager.register(id: 3, keyCode: UInt32(kVK_ANSI_F), modifiers: ctrlOpt) { [weak self] in
            Task { @MainActor in
                self?.pickForeground()
            }
        }
    }

    // MARK: - App Visibility Management

    @objc public func showApp() {
        NSApp.setActivationPolicy(.regular) // Shows in Dock and ⌘Tab
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func hideApp() {
        window.orderOut(nil)
        NSApp.setActivationPolicy(.accessory) // Hides from Dock and ⌘Tab
    }

    @objc public func toggleAppVisibility() {
        if window.isVisible {
            hideApp()
        } else {
            showApp()
        }
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideApp()
        return false // Do not destroy window; keep running in menu bar
    }

    // MARK: - Application Main Menu

    private func setupMenu() {
        let mainMenu = NSMenu()

        // 1. Application Menu ("Contrast Checker")
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Contrast Checker")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let aboutItem = NSMenuItem(title: "About Contrast Checker", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)

        appMenu.addItem(NSMenuItem.separator())

        let hideItem = NSMenuItem(title: "Hide Contrast Checker", action: #selector(hideApp), keyEquivalent: "w")
        hideItem.target = self
        appMenu.addItem(hideItem)

        let pickBgItem = NSMenuItem(title: "Pick Background Color", action: #selector(pickBackground), keyEquivalent: "b")
        pickBgItem.keyEquivalentModifierMask = [.control, .option]
        pickBgItem.target = self
        appMenu.addItem(pickBgItem)

        let pickFgItem = NSMenuItem(title: "Pick Foreground Color", action: #selector(pickForeground), keyEquivalent: "f")
        pickFgItem.keyEquivalentModifierMask = [.control, .option]
        pickFgItem.target = self
        appMenu.addItem(pickFgItem)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Contrast Checker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        appMenu.addItem(quitItem)

        // 2. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        let closeItem = NSMenuItem(title: "Close Window", action: #selector(hideApp), keyEquivalent: "w")
        closeItem.target = self
        windowMenu.addItem(closeItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Actions

    @objc private func showAbout() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let credits = NSMutableAttributedString()

        let bodyText = """
        A native macOS utility for measuring color contrast anywhere across the operating system.

        Global Shortcuts:
        • ⌃⌥C: Toggle Contrast Checker
        • ⌃⌥B: Pick Background Color
        • ⌃⌥F: Pick Foreground Color

        WCAG 2.2 relative luminance calculation.


        """
        credits.append(NSAttributedString(
            string: bodyText,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: paragraph
            ]
        ))

        let url = URL(string: "https://github.com/svinkle/contrast-checker")!
        let linkAttr = NSAttributedString(
            string: "github.com/svinkle/contrast-checker",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.linkColor,
                .link: url,
                .paragraphStyle: paragraph
            ]
        )
        credits.append(linkAttr)

        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.1"
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "Contrast Checker",
            .applicationVersion: versionString,
            .version: versionString,
            .credits: credits
        ]

        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func pickBackground() {
        if !window.isVisible {
            showApp()
        }
        sampler.pickBackgroundColor(into: model)
    }

    @objc private func pickForeground() {
        if !window.isVisible {
            showApp()
        }
        sampler.pickForegroundColor(into: model)
    }

    @objc private func copyContrast() {
        model.copyValue(model.contrastRatioString, label: model.contrastRatioString)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in menu bar
    }
}

// Entry Point
@main
struct ContrastCheckerApp {
    @MainActor
    static let delegate = AppDelegate()

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}
