import AppKit
import Carbon

public final class HotKeyManager {
    public static let shared = HotKeyManager()

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var actions: [UInt32: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var isHandlerInstalled = false

    private init() {}

    private func ensureHandlerInstalled() {
        guard !isHandlerInstalled else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, theEvent, userData) -> OSStatus in
                guard let userData = userData, let event = theEvent else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if err == noErr {
                    let id = hotKeyID.id
                    DispatchQueue.main.async {
                        manager.actions[id]?()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        if status == noErr {
            isHandlerInstalled = true
        }
    }

    /// Registers a global system-wide hotkey using Carbon Events.
    public func register(
        id: UInt32,
        keyCode: UInt32,
        modifiers: UInt32 = UInt32(controlKey | optionKey),
        action: @escaping () -> Void
    ) {
        ensureHandlerInstalled()
        actions[id] = action

        let hotKeyID = EventHotKeyID(signature: OSType(0x43434B52), id: id) // "CCKR"
        var ref: EventHotKeyRef?
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if regStatus == noErr, let ref = ref {
            hotKeyRefs[id] = ref
        } else {
            print("Failed to register Carbon global hotkey id \(id): \(regStatus)")
        }
    }

    public func unregisterAll() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        actions.removeAll()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
            isHandlerInstalled = false
        }
    }

    deinit {
        unregisterAll()
    }
}
