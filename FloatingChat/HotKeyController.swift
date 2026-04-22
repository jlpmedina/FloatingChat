import AppKit
import Carbon
import Foundation

final class HotKeyController {
    private let action: @MainActor () -> Void
    private var keyCode: UInt16 = 49
    private var modifiers: NSEvent.ModifierFlags = [.command, .shift]
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeySignature: OSType = 0x46434854 // "FCHT"
    private let hotKeyId: UInt32 = 1

    private static let hotKeyHandler: EventHandlerUPP = { _, eventRef, userData in
        guard let eventRef, let userData else { return OSStatus(eventNotHandledErr) }

        let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
        var pressedHotKeyId = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &pressedHotKeyId
        )

        guard status == noErr else { return status }
        guard controller.matches(pressedHotKeyId) else { return OSStatus(eventNotHandledErr) }

        controller.triggerAction()
        return noErr
    }

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    @discardableResult
    func register(keyCode: UInt16 = 49, modifiers: NSEvent.ModifierFlags = [.command, .shift]) -> Bool {
        unregister()
        self.keyCode = keyCode
        self.modifiers = normalized(modifiers)

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.hotKeyHandler,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            return false
        }

        var registeredHotKeyId = EventHotKeyID()
        registeredHotKeyId.signature = hotKeySignature
        registeredHotKeyId.id = hotKeyId

        let registerStatus = RegisterEventHotKey(
            UInt32(keyCode),
            carbonModifiers(from: self.modifiers),
            registeredHotKeyId,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr, hotKeyRef != nil else {
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            return false
        }

        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    deinit {
        unregister()
    }

    private func matches(_ pressedHotKeyId: EventHotKeyID) -> Bool {
        pressedHotKeyId.signature == hotKeySignature && pressedHotKeyId.id == hotKeyId
    }

    private func normalized(_ flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection([.command, .shift, .option, .control])
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    private func triggerAction() {
        Task { @MainActor in
            action()
        }
    }
}
