//
//  HistoryRow.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import SwiftUI

struct HistoryRow: View {
    let item: ScanItem
    let isSelected: Bool
    var onDelete: (() -> Void)? = nil
    
    @State private var isHovering: Bool = false
    @State private var cachedAppIcon: NSImage? = nil
    
    // Colors from CSS
    let textMain = Color(red: 51/255, green: 51/255, blue: 51/255)
    let textMuted = Color(red: 134/255, green: 134/255, blue: 139/255)
    let accentAmber = Color(red: 245/255, green: 158/255, blue: 11/255)
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background & Selection State
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? accentAmber.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .shadow(color: isSelected ? Color.black.opacity(0.05) : Color.clear, radius: 2, y: 1)
            
            // Left Selection Indicator Bar

            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Header: Icon + Title + Time
                HStack(spacing: 6) {
                    // Icon (cached, non-interactive)
                    Group {
                        if let cachedIcon = cachedAppIcon {
                            Image(nsImage: cachedIcon)
                                .resizable()
                                .interpolation(.high)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        } else if item.iconName == "globe" {
                            Image(systemName: "globe")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: item.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .frame(width: 16, height: 16)
                        }
                    }
                    .allowsHitTesting(false)
                    
                    // Source App Name
                    Text(item.sourceApp)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(textMain)
                        .fixedSize()
                    
                    // Content type badge
                    if item.contentType == .qrcode {
                        Text("QR")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple)
                            .cornerRadius(3)
                    } else if item.contentType == .barcode {
                        Text("BC")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .cornerRadius(3)
                    }
                    
                    Spacer()
                    
                    // Fixed-size container: prevents layout shift on hover
                    ZStack(alignment: .trailing) {
                        // Time (visible when not hovering)
                        Text(timeAgo(from: item.timestamp))
                            .font(.system(size: 10))
                            .foregroundColor(textMuted)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .opacity(isHovering ? 0 : 1)
                        
                        // Delete button (visible when hovering)
                        if let onDelete = onDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red.opacity(0.6))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .opacity(isHovering ? 1 : 0)
                            .onHover { hover in
                                if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                            }
                        }
                    }
                    .frame(width: 50, alignment: .trailing)
                }
                
                // Text Preview
                Text(item.textContent)
                    .font(.system(size: 11))
                    .foregroundColor(textMuted.opacity(0.8))
                    .lineLimit(1)
                    .padding(.leading, 2) // Slight indent
            }
            .padding(12)
        }
        .frame(height: 64)
        .contentShape(Rectangle()) // Make entire area clickable
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
    
    // Simple Time Ago Helper
    func timeAgo(from date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(diff/60)m ago" }
        if diff < 86400 { return "\(diff/3600)h ago" }
        return "1d ago"
    }
}

// Custom Shape for left-side rounded corners (macOS safe)
struct LeftRoundedRectangle: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Top Right (Sharp)
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Bottom Right (Sharp)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Bottom Left (Rounded)
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius), radius: radius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        // Top Left (Rounded)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()
        return path
    }
}
