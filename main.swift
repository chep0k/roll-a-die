import AppKit

class RollADieApp: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var quitMenu: NSMenu!
    
    // Timer for handling single click delay
    var clickTimer: Timer?
    
    // Cache for dice images to avoid symbol lookup during animation
    var diceImages = [Int: NSImage]()
    
    // Rolling animation state
    var isRolling = false
    var currentDiceValue = 1
    
    // Preview window components
    var previewWindow: NSWindow?
    var previewDiceImageView: NSImageView?
    var aboutWindow: NSWindow?
    
    // Distributed notification name for reopening the window from terminal/duplicate launches
    let reopenNotificationName = Notification.Name("com.mk.RollADie.reopen")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce Singleton Instance
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.mk.RollADie")
        let otherInstances = runningApps.filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        
        if !otherInstances.isEmpty {
            // Post a distributed notification to tell the running instance to reopen its window
            DistributedNotificationCenter.default().postNotificationName(
                reopenNotificationName,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            // Terminate this duplicate instance immediately
            NSApp.terminate(nil)
            return
        }
        
        // Listen for reopen notifications from duplicate instances
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleExternalReopen),
            name: reopenNotificationName,
            object: nil
        )
        
        // Pre-cache all 6 dice face images
        for i in 1...6 {
            let symbolName = "die.face.\(i)"
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Dice value \(i)") {
                image.isTemplate = true
                diceImages[i] = image
            }
        }
        
        // Create status item in the menu bar with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Set initial dice image
            updateDiceImage(value: 1)
            
            // Configure click handling
            button.target = self
            button.action = #selector(handleButtonAction(_:))
            button.sendAction(on: [.leftMouseUp])
        }
        
        // Setup context menu
        quitMenu = NSMenu()
        quitMenu.delegate = self
        
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAboutWindow), keyEquivalent: "i")
        aboutItem.keyEquivalentModifierMask = [.control]
        aboutItem.target = self
        quitMenu.addItem(aboutItem)
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        quitMenu.addItem(quitItem)
        
        // Always open the preview window on launch
        showPreviewWindow()
    }
    
    // Handle double-clicking the app bundle in Finder when it's already running
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPreviewWindow()
        return true
    }
    
    @objc func handleExternalReopen() {
        // Run on main thread to ensure UI operations are safe
        DispatchQueue.main.async { [weak self] in
            self?.showPreviewWindow()
        }
    }
    
    func showPreviewWindow() {
        // If window is already created, just bring it to front
        if let window = previewWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let rect = NSRect(x: 0, y: 0, width: 340, height: 240)
        let window = NSWindow(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: false)
        window.title = "Roll a Die"
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false
        
        let container = NSView(frame: rect)
        window.contentView = container
        
        // Dice Face Preview (Big Image View)
        let imageView = NSImageView(frame: NSRect(x: 120, y: 110, width: 100, height: 100))
        imageView.image = diceImages[currentDiceValue]
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.contentTintColor = NSColor.labelColor
        container.addSubview(imageView)
        self.previewDiceImageView = imageView
        
        // Instructions Text
        let descLabel = NSTextField(labelWithString: "Click Menu Bar icon to roll.\nDouble click it to open menu.")
        descLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        descLabel.frame = NSRect(x: 20, y: 55, width: 300, height: 36)
        descLabel.alignment = .center
        descLabel.isEditable = false
        descLabel.isSelectable = false
        descLabel.isBezeled = false
        descLabel.drawsBackground = false
        descLabel.textColor = NSColor.labelColor
        container.addSubview(descLabel)
        
        // Tip Text
        let tipLabel = NSTextField(labelWithString: "Closing this window keeps the app running in the Menu Bar.")
        tipLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        tipLabel.frame = NSRect(x: 20, y: 20, width: 300, height: 20)
        tipLabel.alignment = .center
        tipLabel.textColor = NSColor.secondaryLabelColor
        tipLabel.isEditable = false
        tipLabel.isSelectable = false
        tipLabel.isBezeled = false
        tipLabel.drawsBackground = false
        container.addSubview(tipLabel)
        
        self.previewWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // NSWindowDelegate method to intercept close button and hide instead of closing/releasing
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false // Do not close or deallocate the window
    }
    
    // Explicitly prevent application from terminating when the window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func updateDiceImage(value: Int) {
        // Update Menu Bar icon
        if let button = statusItem.button {
            button.image = diceImages[value]
        }
        // Update Preview Window icon if open
        if let imageView = previewDiceImageView {
            imageView.image = diceImages[value]
        }
    }
    
    @objc func handleButtonAction(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        let clicks = event.clickCount
        if clicks == 1 {
            // Schedule the single click (roll) action after the system double-click interval
            clickTimer?.invalidate()
            clickTimer = Timer.scheduledTimer(withTimeInterval: NSEvent.doubleClickInterval, repeats: false) { [weak self] _ in
                self?.performRoll()
            }
        } else if clicks >= 2 {
            // Cancel the pending single click action
            clickTimer?.invalidate()
            clickTimer = nil
            // Immediately open the quit menu
            showMenu()
        }
    }
    
    func performRoll() {
        guard !isRolling else { return }
        isRolling = true
        animateRollFrame(frameIndex: 0)
    }
    
    private func animateRollFrame(frameIndex: Int) {
        let totalFrames = 8
        
        guard isRolling else { return }
        
        if frameIndex < totalFrames {
            var nextVal = Int.random(in: 1...6)
            while nextVal == currentDiceValue {
                nextVal = Int.random(in: 1...6)
            }
            currentDiceValue = nextVal
            updateDiceImage(value: currentDiceValue)
            
            let baseDelay = 0.035
            let progress = Double(frameIndex) / Double(totalFrames - 1)
            let delay = baseDelay + (0.185 * progress * progress) // quadratic easing out
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.animateRollFrame(frameIndex: frameIndex + 1)
            }
        } else {
            currentDiceValue = Int.random(in: 1...6)
            updateDiceImage(value: currentDiceValue)
            isRolling = false
        }
    }
    
    func showMenu() {
        if isRolling {
            isRolling = false
        }
        
        guard let button = statusItem.button else { return }
        let popupLocation = NSPoint(x: 0, y: -5)
        quitMenu.popUp(positioning: nil, at: popupLocation, in: button)
    }
    
    @objc func showAboutWindow() {
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let rect = NSRect(x: 0, y: 0, width: 300, height: 120)
        let window = NSWindow(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: false)
        window.title = "About Roll a Die"
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false
        
        let container = NSView(frame: rect)
        window.contentView = container
        
        let attrString = NSMutableAttributedString(string: "2026 chep0k | MIT License")
        let fullRange = NSRange(location: 0, length: attrString.length)
        attrString.addAttribute(.font, value: NSFont.systemFont(ofSize: 13, weight: .medium), range: fullRange)
        attrString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        
        let chep0kRange = (attrString.string as NSString).range(of: "chep0k")
        attrString.addAttribute(.link, value: "https://github.com/chep0k", range: chep0kRange)
        
        let label = NSTextField(labelWithString: "")
        label.attributedStringValue = attrString
        label.allowsEditingTextAttributes = true
        label.isSelectable = true
        label.frame = NSRect(x: 20, y: 65, width: 260, height: 24)
        label.alignment = .center
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        container.addSubview(label)
        
        let linkButton = NSButton(frame: NSRect(x: 30, y: 25, width: 240, height: 28))
        linkButton.title = "github.com/chep0k/roll-a-die"
        linkButton.bezelStyle = .inline
        linkButton.isBordered = false
        linkButton.contentTintColor = NSColor.linkColor
        linkButton.target = self
        linkButton.action = #selector(openGitHubPage)
        container.addSubview(linkButton)
        
        self.aboutWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openChep0kGitHub() {
        if let url = URL(string: "https://github.com/chep0k") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func openGitHubPage() {
        if let url = URL(string: "https://github.com/chep0k/roll-a-die") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// Start the application
let app = NSApplication.shared
let delegate = RollADieApp()
app.delegate = delegate
// Keep it in background mode (.accessory) the entire time to avoid menu bar recreation bugs
app.setActivationPolicy(.accessory)
app.run()
