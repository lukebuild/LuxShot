//
//  ScanStore.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import Foundation
import Combine
import SwiftUI
import AppKit
import AVFoundation

class ScanStore: ObservableObject {
    static let shared = ScanStore()
    
    @Published var scanItems: [ScanItem] = [] {
        didSet {
            HistoryStore.shared.save(scanItems)
        }
    }
    
    @Published var selectedScanId: UUID?
    
    // Feature toggles
    @Published var keepLineBreaks: Bool = true
    @Published var autoOpenLinks: Bool = false
    
    // Text-to-Speech
    private let speechSynth = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    
    private init() {
        scanItems = HistoryStore.shared.load()
        if let first = scanItems.first {
            selectedScanId = first.id
        }
    }
    
    func addScan(text: String, sourceApp: String, bundleId: String?, imagePath: URL?, contentType: OCRManager.ContentType = .text) {
        let titleCandidate = text.components(separatedBy: "\n").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Scan"
        let validTitle = titleCandidate.isEmpty ? "Scan \(Date().formatted(date: .numeric, time: .shortened))" : titleCandidate
        
        let iconName: String
        switch contentType {
        case .qrcode: iconName = "qrcode"
        case .barcode: iconName = "barcode"
        case .text: iconName = "viewfinder"
        }
        
        let newItem = ScanItem(
            id: UUID(),
            title: String(validTitle.prefix(30)),
            timestamp: Date(),
            textContent: text,
            sourceApp: sourceApp,
            appBundleId: bundleId,
            imagePath: imagePath,
            iconName: iconName,
            contentType: contentType
        )
        
        withAnimation {
            scanItems.insert(newItem, at: 0)
            selectedScanId = newItem.id
        }
    }
    
    func deleteItem(_ item: ScanItem) {
        guard let index = scanItems.firstIndex(where: { $0.id == item.id }) else { return }
        let wasSelected = selectedScanId == item.id
        
        _ = withAnimation {
            scanItems.remove(at: index)
        }
        
        if wasSelected {
            if scanItems.isEmpty {
                selectedScanId = nil
            } else {
                let newIndex = min(index, scanItems.count - 1)
                selectedScanId = scanItems[newIndex].id
            }
        }
    }
    
    func clearAll() {
        withAnimation {
            scanItems.removeAll()
            selectedScanId = nil
        }
    }
    
    // MARK: - Text Processing
    
    func processedText(_ text: String) -> String {
        if keepLineBreaks {
            return text
        }
        // Replace line breaks with spaces, collapse multiple spaces
        return text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Text-to-Speech
    
    func speak(_ text: String) {
        if speechSynth.isSpeaking {
            speechSynth.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynth.speak(utterance)
        isSpeaking = true
        
        // Monitor when speaking finishes
        DispatchQueue.global().async { [weak self] in
            while self?.speechSynth.isSpeaking == true {
                Thread.sleep(forTimeInterval: 0.2)
            }
            DispatchQueue.main.async {
                self?.isSpeaking = false
            }
        }
    }
    
    func stopSpeaking() {
        speechSynth.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // MARK: - Link Detection
    
    func detectAndOpenLinks(in text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        for match in matches {
            if let url = match.url {
                NSWorkspace.shared.open(url)
                return // Open first link only
            }
        }
    }
    
    // MARK: - Scan
    
    func performScan(autoCopy: Bool = false, showMainWindow: Bool = false) {
        Task { @MainActor in
            // 1. Close popover if open
            AppDelegate.shared?.closePopover()
            
            // 2. Hide windows
            NSApplication.shared.hide(nil)
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // Capture source app info
            let frontApp = NSWorkspace.shared.frontmostApplication
            let sourceAppName = frontApp?.localizedName ?? "Screen"
            let sourceBundleId = frontApp?.bundleIdentifier
            
            do {
                let (image, url) = try await ScreenCaptureManager.shared.captureRegion()
                
                // Full scan: OCR + QR/barcode detection
                let result = try await OCRManager.shared.fullScan(from: image)
                
                // Determine the text to save
                let rawText = result.primaryContent
                let finalText = processedText(rawText)
                
                addScan(
                    text: finalText,
                    sourceApp: sourceAppName,
                    bundleId: sourceBundleId,
                    imagePath: url,
                    contentType: result.contentType
                )
                
                // Auto-Copy
                if autoCopy {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(finalText, forType: .string)
                }
                
                // Auto-open links if enabled
                if autoOpenLinks {
                    detectAndOpenLinks(in: finalText)
                }
                
                // Show result in the appropriate UI
                if showMainWindow {
                    NSApplication.shared.unhide(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                } else {
                    AppDelegate.shared?.togglePopover()
                }
            } catch {
                if showMainWindow {
                    NSApplication.shared.unhide(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}
