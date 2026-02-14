//
//  MenuBarView.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var store = ScanStore.shared
    @State private var isHoveringNewScan = false
    
    // Colors matching prototype
    let primaryGreen = Color(red: 48/255, green: 232/255, blue: 122/255)
    let primaryGreenHover = Color(red: 40/255, green: 207/255, blue: 107/255)
    let bgDark = Color(red: 17/255, green: 33/255, blue: 23/255)
    let textMain = Color(red: 45/255, green: 51/255, blue: 48/255)
    let textMuted = Color(red: 107/255, green: 114/255, blue: 128/255)
    let warmBorder = Color(red: 232/255, green: 230/255, blue: 225/255)
    let bgLight = Color(red: 253/255, green: 252/255, blue: 250/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header — New Scan Button
            VStack(spacing: 0) {
                Button(action: {
                    store.performScan()
                }) {
                    HStack {
                        HStack(spacing: 10) {
                            // Icon
                            Image(systemName: "crop")
                                .font(.system(size: 16, weight: .medium))
                                .padding(4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)
                            
                            Text("New Scan")
                                .font(.system(size: 17, weight: .medium))
                                .tracking(-0.2)
                        }
                        
                        Spacer()
                        
                        // Shortcut badges
                        HStack(spacing: 4) {
                            shortcutBadge("⌘")
                            shortcutBadge("⇧")
                            shortcutBadge("E")
                        }
                        .opacity(isHoveringNewScan ? 0.8 : 0.6)
                    }
                    .foregroundColor(bgDark)
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isHoveringNewScan ? primaryGreenHover : primaryGreen)
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hover in
                    withAnimation(.easeInOut(duration: 0.15)) { isHoveringNewScan = hover }
                    if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                .padding(16)
                .padding(.bottom, -8)
            }
            
            // Scrollable Card List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    // Section Header
                    Text("RECENT CAPTURES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(textMuted.opacity(0.6))
                        .tracking(1.2)
                        .padding(.leading, 2)
                        .padding(.top, 4)
                    
                    if store.scanItems.isEmpty {
                        // Empty State
                        VStack(spacing: 12) {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 36, weight: .thin))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No captures yet")
                                .font(.system(size: 13))
                                .foregroundColor(textMuted.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(store.scanItems) { item in
                            MenuBarCard(item: item)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            // Feature Toggles
            Divider()
            VStack(spacing: 6) {
                miniToggle("Keep Line Breaks", isOn: $store.keepLineBreaks, icon: "text.alignleft")
                miniToggle("Auto-Open Links", isOn: $store.autoOpenLinks, icon: "link")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Footer
            Divider()
            HStack {
                // Open Full Library
                Button(action: openFullLibrary) {
                    HStack(spacing: 4) {
                        Text("Open Full Library")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(textMain)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hover in
                    if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                
                Spacer()
                
                // Quit button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 14))
                        .foregroundColor(textMuted)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hover in
                    if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.5))
        }
        .frame(width: 360, height: 520)
        .background(bgLight)
    }
    
    private func shortcutBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(bgDark)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.1))
            .cornerRadius(3)
    }
    
    private func openFullLibrary() {
        if let delegate = AppDelegate.shared {
            delegate.closePopover()
        }
        
        for window in NSApp.windows {
            if window.level == .normal && window.styleMask.contains(.titled) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        if let delegate = AppDelegate.shared {
            delegate.openMainWindow()
        }
    }
    
    private func miniToggle(_ label: String, isOn: Binding<Bool>, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(textMuted)
                .frame(width: 14)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(textMain)
            
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOn.wrappedValue ? Color(red: 245/255, green: 158/255, blue: 11/255) : Color.gray.opacity(0.2))
                    .frame(width: 28, height: 16)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: isOn.wrappedValue ? 6 : -6)
                    .shadow(color: .black.opacity(0.1), radius: 1)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isOn.wrappedValue.toggle()
                }
            }
        }
    }
}
