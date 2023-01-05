//
//  ViewController.swift
//  MouseHook
//
//  Created by Johnson, Brad on 2023-01-01.
//

import Cocoa
import CommonCrypto

class MouseViewController: NSViewController {
    private var cursorImageView: NSImageView!
    private var enabledMonitorObserver: NSKeyValueObservation!
    private var cursorObserver: NSKeyValueObservation!
    private var enabledMonitors: Set<CGDirectDisplayID> = Set<CGDirectDisplayID>()
    private var currentMonitor: NSScreen?
    
    @objc private dynamic var currentCursor: NSCursor = NSCursor.current
    
    private let pointingHandHash: String? = NSCursor.pointingHand.image.tiffRepresentation?.sha256
    private let openHandHash: String? = NSCursor.openHand.image.tiffRepresentation?.sha256
    private let closedHandHash: String? = NSCursor.closedHand.image.tiffRepresentation?.sha256
    private let hideRefreshIntervalSecs = 1.5
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupMouseViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMouseViewController()
    }
    
    deinit {
        enabledMonitorObserver?.invalidate()
        cursorObserver?.invalidate()
    }
    
    private func setupMouseViewController() {
        cursorImageView = NSImageView()
        cursorImageView.wantsLayer = true
        cursorImageView.image = currentCursor.image
        cursorImageView.imageScaling = .scaleNone
        cursorImageView.layer?.backgroundColor = NSColor.clear.cgColor
        self.view = cursorImageView
        
        setupObservers()
    }
    
    private func setupObservers() {
        enabledMonitorObserver = UserDefaults.standard.observe(\.activeMonitors, options: [.initial, .new], changeHandler: { (defaults, change) in
            if let mons = defaults.activeMonitors as [CGDirectDisplayID]? {
                self.enabledMonitors = Set(mons.map { $0 })
            }
        })
        cursorObserver = self.observe(\.currentCursor, options: [.initial, .new], changeHandler: { (this, change) in
            self.cursorImageView.image = this.currentCursor.image
        })
    }
    
    /** These magic numbers work for the default mouse cursor at the default size on MacOS Monterey.
     I can't guarantee it will work for custom mouse cursors or different OS versions, but I think it'll be pretty close. **/
    func getFrameOrigin(_ pt: NSPoint) -> NSPoint {
        var offset: (Double, Double)
        
        // There is no simple way to check the exact image of a cursor, but size is cheap, easy, and works in most cases to determine the offset.
        switch (currentCursor.image.size) {
        case NSCursor.arrow.image.size:
            offset = (21, 32)
        case NSCursor.pointingHand.image.size:
            // There are representations that match the size of pointingHand but not the offset, so check the hash of the image
            switch (currentCursor.image.tiffRepresentation?.sha256) {
            case pointingHandHash:
                offset = (21.5, 32)
            case openHandHash:
                offset = (24.5, 24.5)
            case closedHandHash:
                offset = (24.5, 25)
            default:
                // It is likely a type of iBeam
                offset = (24, 28)
            }
        case NSCursor.iBeam.image.size:
            fallthrough
        case NSCursor.resizeLeftRight.image.size:
            offset = (24.5, 24.5)
        case NSCursor.disappearingItem.image.size:
            offset = (16.5, 38.5)
        case NSCursor.dragLink.image.size:
            offset = (28, 32)
        default:
            offset = (23.5, 25.5)
        }
        
        return NSPoint(x: pt.x - offset.0, y: pt.y - offset.1)
    }
    
    
    override func viewDidLoad() {
        let aCursor = NSCursor.resizeUpDown
        view.addCursorRect(view.bounds, cursor: aCursor)
        aCursor.set()
        view.addTrackingRect(view.bounds, owner: aCursor, userData: nil, assumeInside: true)
        
    }
    
    func resetCurrentMonitor(_ mousePosition: NSPoint? = nil) {
        if (mousePosition != nil) {
            currentMonitor = NSScreen.screens.first(where: { $0.frame.contains(mousePosition!) })
        }
        cursorImageView.isHidden = !enabledMonitors.contains(currentMonitor?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? kCGNullDirectDisplay)
    }
    
    func update(_ event: NSEvent) -> Bool {
        if (NSCursor.currentSystem != nil) {
            currentCursor = NSCursor.currentSystem!
        }
        
        let screenBounds = currentMonitor?.frame
        // Apply a small transform to the y axis to avoid it going out of bounds along the top axis
        let mousePosition = event.locationInWindow.applying(CGAffineTransform(translationX: 0.0, y: -0.00001))
        if (screenBounds?.contains(mousePosition) != true) {
            resetCurrentMonitor(mousePosition)
        }
        
        return !cursorImageView.isHidden
    }
}

extension Data {
    public var sha256:String {
        get {
            return hexStringFromData(input: digest(input: self as NSData))
        }
    }

    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }

        return hexString
    }
}
