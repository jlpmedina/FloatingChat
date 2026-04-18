import Carbon
import Foundation

private let floatingChatHotKeyHandler: EventHandlerUPP = { _, eventRef, userData in
    guard let eventRef, let userData else { return noErr }

    var eventHotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        eventRef,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &eventHotKeyID
    )

    guard status == noErr else { return status }

    let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
    return controller.handle(eventHotKeyID)
}

final class HotKeyController {
    private let hotKeyID = EventHotKeyID(signature: OSType(0x46434854), id: 1)
    private let action: @MainActor () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    @discardableResult
    func register(keyCode: UInt32 = UInt32(kVK_Space), modifiers: UInt32 = UInt32(cmdKey | shiftKey)) -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            floatingChatHotKeyHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else { return false }

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            unregister()
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

    fileprivate func handle(_ eventHotKeyID: EventHotKeyID) -> OSStatus {
        guard eventHotKeyID.signature == hotKeyID.signature,
              eventHotKeyID.id == hotKeyID.id
        else {
            return noErr
        }

        Task { @MainActor in
            action()
        }

        return noErr
    }
}