//
//  ResultView.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import SwiftUI

struct ResultView: View {
    let item: ScanItem
    @ObservedObject var store = ScanStore.shared
    
    // CSS Colors
    let textMain = Color(red: 51/255, green: 51/255, blue: 51/255)
    let textMuted = Color(red: 134/255, green: 134/255, blue: 139/255)
    let accentAmber = Color(red: 245/255, green: 158/255, blue: 11/255)
    let accentAmberHover = Color(red: 251/255, green: 191/255, blue: 36/255)
    let borderColor = Color.black.opacity(0.08)
    
    @State private var editedText: String = ""
    @State private var isHoveringCopy: Bool = false
    @State private var isCopied: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. Top Bar: Source Info + Tags + Actions
            HStack(spacing: 0) {
                // Left: Source Info
                HStack(spacing: 12) {
                    // Image Source (Thumbnail)
                    if let imagePath = item.imagePath, let nsImage = NSImage(contentsOf: imagePath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 24, height: 24)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                            .onTapGesture {
                                NSWorkspace.shared.open(imagePath)
                            }
                            .onHover { hover in
                                if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                            }
                    } else if let bundleId = item.appBundleId,
                              let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: appUrl.path))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    } else if item.iconName == "globe" {
                        Circle().fill(Color.blue.opacity(0.1))
                            .frame(width: 24, height: 24)
                            .overlay(Image(systemName: "globe").font(.system(size: 14)).foregroundColor(.blue))
                    } else {
                        Circle().fill(Color.gray.opacity(0.1))
                            .frame(width: 24, height: 24)
                            .overlay(Image(systemName: item.iconName).font(.system(size: 14)).foregroundColor(.gray))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(item.sourceApp.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(textMuted)
                                .tracking(0.5)
                            
                            // Content type badge
                            if item.contentType == .qrcode {
                                contentBadge("QR CODE", color: .purple)
                            } else if item.contentType == .barcode {
                                contentBadge("BARCODE", color: .orange)
                            }
                        }
                        Text(item.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textMain)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right: Action Buttons
                HStack(spacing: 8) {
                    // TTS Button
                    actionButton(
                        icon: store.isSpeaking ? "stop.fill" : "speaker.wave.2.fill",
                        tooltip: store.isSpeaking ? "Stop Speaking" : "Read Aloud",
                        color: .blue
                    ) {
                        store.speak(editedText)
                    }
                    
                    // Open Link Button (if text contains URLs)
                    if editedText.contains("http://") || editedText.contains("https://") || item.contentType == .qrcode {
                        actionButton(
                            icon: "link",
                            tooltip: "Open Link",
                            color: .green
                        ) {
                            store.detectAndOpenLinks(in: editedText)
                        }
                    }
                    
                    // Copy Button
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(editedText, forType: .string)
                        
                        withAnimation { isCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isCopied = false }
                        }
                    }) {
                        ZStack {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(width: 12)
                                Text("Copy")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .opacity(isCopied ? 0 : 1)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(width: 12)
                                Text("Copied")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .opacity(isCopied ? 1 : 0)
                        }
                        .foregroundColor(isCopied ? Color(red: 34/255, green: 197/255, blue: 94/255) : (isHoveringCopy ? .white : Color(red: 254/255, green: 243/255, blue: 199/255)))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 51/255, green: 51/255, blue: 51/255))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                        .scaleEffect(isHoveringCopy ? 1.02 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut("c", modifiers: .command)
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHoveringCopy = hover
                        }
                        if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 56)
            .background(Color.white.opacity(0.5))
            .background(.ultraThinMaterial)
            
            Divider()
            
            // 2. Editor Area
            ZStack(alignment: .topLeading) {
                Color(red: 253/255, green: 251/255, blue: 247/255).opacity(0.5)
                
                if #available(macOS 14.0, *) {
                    TextEditor(text: $editedText)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(textMain)
                        .padding(24)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.never)
                        .background(Color.clear)
                        .lineSpacing(6)
                } else {
                    TextEditor(text: $editedText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(textMain)
                        .padding(24)
                }
            }
            .background(Color(red: 253/255, green: 251/255, blue: 247/255))
        }
        .task(id: item.id) {
            editedText = item.textContent
        }
    }
    
    // MARK: - Helpers
    
    private func contentBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(3)
    }
    
    private func actionButton(icon: String, tooltip: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
        .onHover { hover in
            if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

// Helper View for Icon Buttons
struct IconButton: View {
    let icon: String
    let tooltip: String
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isHovering ? Color(red: 51/255, green: 51/255, blue: 51/255) : Color.gray)
                .frame(width: 28, height: 28)
                .background(isHovering ? Color.black.opacity(0.05) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
        .onHover { isHovering = $0 }
    }
}
