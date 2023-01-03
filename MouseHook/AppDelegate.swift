//
//  AppDelegate.swift
//  MouseHook
//
//  Created by Johnson, Brad on 2023-01-01.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var mouseController: MouseViewController!
    private let userDefaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("mousehook-menubar"))
        }
        
        mouseController = MouseViewController()
        setupMouseHook()
        setupMenu()
        statusItem.menu = menu
    }
    
    func setupMouseHook() {
        let mouseWindow = NSWindow(contentViewController: mouseController)
        mouseWindow.styleMask = [.borderless]
        mouseWindow.ignoresMouseEvents = true
        mouseWindow.setFrame(NSRect(x: 0, y: 0, width: 50, height: 50), display: false)
        mouseWindow.backgroundColor = .clear
        mouseWindow.level = .screenSaver
        mouseWindow.orderFront(nil)
        
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) { (event) in
            let mouseLocation = event.locationInWindow
            mouseWindow.setFrameOrigin(self.mouseController.getFrameOrigin(mouseLocation))
            self.mouseController.update(event)
        }
    }
    
    func setupMenu() {
        menu = NSMenu(title: "Status Bar Menu")
        menu.delegate = self
        
        var menuItem = NSMenuItem.separator()
        menuItem.tag=100
        
        menu.addItem(menuItem)
        
        menuItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menuItem.tag=100
        
        menu.addItem(menuItem)
    }
    
    @objc func menuNeedsUpdate(_ menu: NSMenu) {
        menu.items.forEach({
            if ($0.tag != 100) {
                menu.removeItem($0)
            }
        })
        
        var i = 0
        
        NSScreen
            .screens
            .reduce(into: [CGDirectDisplayID: String]()) { $0[$1.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID] = $1.localizedName }
            .sorted(by: { $0.0 < $1.0 })
            .forEach {
                let enabled = userDefaults.activeMonitors?.contains($0.key) == true
                let menuItem = NSMenuItem(title: enabled ? "✅\($0.value)" : "❌\($0.value)", action: #selector(menuItemClicked(item:)), keyEquivalent: String(i+1))
                menuItem.identifier = NSUserInterfaceItemIdentifier(String($0.key))
                menuItem.isEnabled = enabled
                menu.insertItem(menuItem, at: i)
                i += 1
            }
    }
    
    @objc func menuItemClicked(item: NSMenuItem) {
        updateEnabledMonitors(CGDirectDisplayID(item.identifier!.rawValue)!)
    }
    
    func updateEnabledMonitors(_ toUpdate: CGDirectDisplayID) {
        var enabledMonitors: [CGDirectDisplayID]
        
        if let actual = userDefaults.activeMonitors as [CGDirectDisplayID]? {
            enabledMonitors = actual
        } else {
            enabledMonitors = [UInt32]()
        }
        
        if let i = enabledMonitors.firstIndex(of: toUpdate) as Int? {
            enabledMonitors.remove(at: i)
        } else {
            enabledMonitors.insert(toUpdate, at: 0)
        }
        
        userDefaults.setActiveMonitors(enabledMonitors)
    }

}

extension UserDefaults {
    @objc dynamic var activeMonitors: [CGDirectDisplayID]? {
        return array(forKey: "enabledMonitors") as? [CGDirectDisplayID]
    }
    
    
    @objc func setActiveMonitors(_ enabledMonitors: [CGDirectDisplayID]) {
        set(enabledMonitors, forKey: "enabledMonitors")
    }
}

