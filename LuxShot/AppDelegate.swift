//
//  AppDelegate.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    private var statusItem: NSStatusItem!
    var popover: NSPopover!
    private var eventMonitor: Any?
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let icon = NSImage(named: "MenuBarIcon")
            icon?.isTemplate = true
            icon?.size = NSSize(width: 22, height: 22)
            button.image = icon
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        
        // Register global keyboard shortcut ⌘⇧E
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                DispatchQueue.main.async {
                    self?.closePopover()
                    ScanStore.shared.capture()
                }
            }
        }
        
        // Also monitor local events (when app is focused)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                DispatchQueue.main.async {
                    self?.closePopover()
                    ScanStore.shared.capture()
                }
                return nil
            }
            return event
        }
    }
    
    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func closePopover() {
        guard popover.isShown else { return }
        popover.animates = false
        popover.close()
        // Force close any popover windows
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            if className.contains("Popover") {
                window.orderOut(nil)
            }
        }
        popover.animates = true
    }
    
    func openMainWindow() {
        // If existing window, just show it
        if let window = mainWindow, window.isVisible == false {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new main window
        let contentView = ContentView()
            .frame(minWidth: 760, minHeight: 500)
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow = window
    }
}
