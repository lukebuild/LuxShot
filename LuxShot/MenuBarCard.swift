//
//  MenuBarCard.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import SwiftUI
import AppKit

struct MenuBarCard: View {
    let item: ScanItem
    @ObservedObject var store = ScanStore.shared
    
    @State private var isHovering = false
    @State private var cachedAppIcon: NSImage? = nil
    @State private var showCopied = false
    
    // Colors matching prototype
    let textMain = Color(red: 45/255, green: 51/255, blue: 48/255)
    let textMuted = Color(red: 107/255, green: 114/255, blue: 128/255)
    let warmBorder = Color(red: 232/255, green: 230/255, blue: 225/255)
    
    var body: some View {
        ZStack {
            // Card Content
            VStack(alignment: .leading, spacing: 8) {
                // Header: Icon + App Name + Badge + Time
                HStack(spacing: 6) {
                    // App Icon
                    Group {
                        if let icon = cachedAppIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .interpolation(.high)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: item.iconName)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .allowsHitTesting(false)
                    
                    Text(item.sourceApp)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(textMuted)
                    
                    // Content type badge
                    if item.contentType == .qrcode {
                        contentBadge("QR", color: .purple)
                    } else if item.contentType == .barcode {
                        contentBadge("BC", color: .orange)
                    }
                    
                    Circle()
                        .fill(textMuted.opacity(0.3))
                        .frame(width: 3, height: 3)
                    
                    Text(timeAgo(from: item.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(textMuted.opacity(0.6))
                    
                    Spacer()
                }
                
                // Text Preview (2 lines max)
                Text(item.textContent)
                    .font(.system(size: 13))
                    .foregroundColor(textMain)
                    .lineLimit(2)
                    .lineSpacing(3)
            }
            .padding(14)
            
            // Hover Overlay — Action buttons
            if isHovering {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.75))
                    .overlay(
                        HStack(spacing: 8) {
                            // Copy button
                            Button(action: copyText) {
                                HStack(spacing: 5) {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                    Text(showCopied ? "Copied!" : "Copy")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(textMain)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            
                            // TTS button
                            Button(action: { store.speak(item.textContent) }) {
                                Image(systemName: store.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            
                            // Open link (if URL detected)
                            if item.textContent.contains("http://") || item.textContent.contains("https://") || item.contentType == .qrcode {
                                Button(action: { store.detectAndOpenLinks(in: item.textContent) }) {
                                    Image(systemName: "link")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            }
                            
                            // Delete button
                            Button(action: { store.deleteItem(item) }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                        }
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                    )
                    .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(warmBorder, lineWidth: 1)
        )
        .shadow(color: isHovering ? .black.opacity(0.04) : .clear, radius: 6, y: 2)
        .contentShape(Rectangle())
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hover
            }
        }
        .onAppear {
            if cachedAppIcon == nil,
               let bundleId = item.appBundleId,
               let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                cachedAppIcon = NSWorkspace.shared.icon(forFile: appUrl.path)
            }
        }
    }
    
    private func contentBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color)
            .cornerRadius(3)
    }
    
    private func copyText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.textContent, forType: .string)
        
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopied = false }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 172800 { return "Yesterday" }
        return "\(Int(interval / 86400))d ago"
    }
}
