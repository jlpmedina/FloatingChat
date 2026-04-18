import SwiftUI
import AppKit

extension Notification.Name {
    static let floatingChatShouldFocusInput = Notification.Name("floatingChatShouldFocusInput")
}

@main
struct FloatingChatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Sin ventana principal — solo el panel flotante
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelAutosaveName = "FloatingChatPanelFrame"
    var panel: NSPanel!
    var statusItem: NSStatusItem!
    var hotKeyController: HotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Oculta ícono del Dock

        setupPanel()
        setupStatusBarItem()

        hotKeyController = HotKeyController { [weak self] in
            self?.togglePanel()
        }

        if hotKeyController?.register() == false {
            NSLog("No se pudo registrar el atajo global Cmd + Shift + Space.")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController?.unregister()
    }

    private func setupPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 560),
            styleMask: [
                .titled,
                .closable,
                .resizable,
                .nonactivatingPanel,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )
        panel.title = ""
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 320, height: 400)
        panel.setFrameAutosaveName(panelAutosaveName)

        let hostingView = NSHostingView(rootView: ContentView())
        panel.contentView = hostingView
        if panel.setFrameUsingName(panelAutosaveName) == false {
            panel.center()
        }
        panel.makeKeyAndOrderFront(nil)
    }

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left.and.bubble.right.fill",
                                   accessibilityDescription: "FloatingChat")
        }
        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Mostrar / Ocultar  ⌘⇧Space", action: #selector(togglePanel), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = NSApp
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    @objc func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .floatingChatShouldFocusInput, object: nil)
        }
    }
}
