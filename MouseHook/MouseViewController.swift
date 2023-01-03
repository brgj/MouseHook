//
//  ViewController.swift
//  MouseHook
//
//  Created by Johnson, Brad on 2023-01-01.
//

import Cocoa

class MouseViewController: NSViewController {
    private var cursorImageView: NSImageView!
    private var activeMonitorObserver: NSKeyValueObservation!
    private var enabledMonitors: Set<CGDirectDisplayID> = Set<CGDirectDisplayID>()
    private var currentCursor: NSCursor = NSCursor.current
    private var lastUpdate: Date = Date(milliseconds: 0)
    
    private let hideRefreshIntervalMs = 1500
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupMouseViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMouseViewController()
    }
    
    private func setupMouseViewController() {
        activeMonitorObserver = UserDefaults.standard.observe(\.activeMonitors, options: [.initial, .new], changeHandler: { (defaults, change) in
            if let mons = defaults.activeMonitors as [CGDirectDisplayID]? {
                self.enabledMonitors = Set(mons.map { $0 })
            }
        })
        NSCursor.addObserver(self, forKeyPath: "currentSystem", options: [.new, .old], context: nil)
        cursorImageView = NSImageView()
        cursorImageView.wantsLayer = true
        cursorImageView.image = currentCursor.image
        cursorImageView.imageScaling = .scaleNone
        cursorImageView.layer?.backgroundColor = NSColor.clear.cgColor
        self.view = cursorImageView
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentSystem" {
            if let newCursor = change?[NSKeyValueChangeKey.newKey] as? NSCursor {
                self.cursorImageView.image = newCursor.image
            }
        }
    }
    
    func getFrameOrigin(_ pt: NSPoint) -> NSPoint {
        var offset: (Double, Double)
        switch (currentCursor.image.size) {
        case NSCursor.arrow.image.size:
            fallthrough
        case NSCursor.pointingHand.image.size:
            offset = (21.5, 32)
            break
        case NSCursor.iBeam.image.size:
            fallthrough
        case NSCursor.resizeLeftRight.image.size:
            fallthrough
        case NSCursor.resizeUpDown.image.size:
            offset = (24.5, 24.5)
            break
        default:
            offset = (23.5, 25.5)
        }
        
        return NSPoint(x: pt.x - offset.0, y: pt.y - offset.1)
    }
    
    func update(_ event: NSEvent) {
        currentCursor = NSCursor.currentSystem != nil ? NSCursor.currentSystem! : currentCursor
        cursorImageView.image = currentCursor.image
        
        let now = Date.now
        guard (now.millisecondsSince1970 - lastUpdate.millisecondsSince1970) > hideRefreshIntervalMs else { return }
        cursorImageView.isHidden = NSScreen.screens.reduce(true) { (result, screen) in
            // If the monitor is not enabled, return immediately with a vote to `hide`
            guard enabledMonitors.contains(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID) else { return result && true }

            let screenBounds = screen.visibleFrame
            let mousePosition = event.locationInWindow

            return result && !screenBounds.contains(mousePosition)
        }
        lastUpdate = now
    }

    deinit {
        activeMonitorObserver?.invalidate()
        NSCursor.removeObserver(self, forKeyPath: "current")
    }
}

extension Date {
    var millisecondsSince1970:Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

