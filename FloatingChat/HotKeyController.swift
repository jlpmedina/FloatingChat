import AppKit
import Foundation

final class HotKeyController {
    private let action: @MainActor () -> Void
    private var keyCode: UInt16 = 49
    private var modifiers: NSEvent.ModifierFlags = [.command, .shift]
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    @discardableResult
    func register(keyCode: UInt16 = 49, modifiers: NSEvent.ModifierFlags = [.command, .shift]) -> Bool {
        unregister()
        self.keyCode = keyCode
        self.modifiers = normalized(modifiers)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.matches(event) else { return event }
            self.triggerAction()
            return nil
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.matches(event) else { return }
            self.triggerAction()
        }

        return localMonitor != nil || globalMonitor != nil
    }

    func unregister() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    deinit {
        unregister()
    }

    private func matches(_ event: NSEvent) -> Bool {
        event.keyCode == keyCode && normalized(event.modifierFlags) == modifiers
    }

    private func normalized(_ flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection([.command, .shift, .option, .control])
    }

    private func triggerAction() {
        Task { @MainActor in
            action()
        }
    }
}
