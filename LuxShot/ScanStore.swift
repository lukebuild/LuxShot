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
    
    @Published var keepLineBreaks: Bool = false
    @Published var autoOpenLinks: Bool = false
    @Published var autoCopy: Bool = true
    
    private let speechSynth = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    
    private init() {
        scanItems = HistoryStore.shared.load()
        if let first = scanItems.first {
            selectedScanId = first.id
        }
    }
    
    func add(_ text: String, app: String, bundleId: String?, image: URL?, type: OCRManager.ContentType = .text) {
        let lines = text.components(separatedBy: "\n")
        let title = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let finalTitle = title.isEmpty ? "Scan \(Date().formatted(date: .numeric, time: .shortened))" : title
        
        let icon: String
        switch type {
        case .qrcode: icon = "qrcode"
        case .barcode: icon = "barcode"
        case .text: icon = "viewfinder"
        }
        
        let item = ScanItem(
            id: UUID(),
            title: String(finalTitle.prefix(30)),
            timestamp: Date(),
            textContent: text,
            sourceApp: app,
            appBundleId: bundleId,
            imagePath: image,
            iconName: icon,
            contentType: type
        )
        
        withAnimation {
            scanItems.insert(item, at: 0)
            selectedScanId = item.id
        }
    }
    
    func delete(_ item: ScanItem) {
        guard let idx = scanItems.firstIndex(where: { $0.id == item.id }) else { return }
        let wasSelected = selectedScanId == item.id
        
        _ = withAnimation {
            scanItems.remove(at: idx)
        }
        
        if wasSelected {
            selectedScanId = scanItems.first?.id
        }
    }
    
    func clear() {
        withAnimation {
            scanItems.removeAll()
            selectedScanId = nil
        }
    }
    
    // MARK: - Actions
    
    private func clean(_ text: String) -> String {
        if keepLineBreaks { return text }
        return text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    func speak(_ text: String) {
        if speechSynth.isSpeaking {
            speechSynth.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        
        let ut = AVSpeechUtterance(string: text)
        ut.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynth.speak(ut)
        isSpeaking = true
        
        DispatchQueue.global().async { [weak self] in
            while self?.speechSynth.isSpeaking == true { Thread.sleep(forTimeInterval: 0.2) }
            DispatchQueue.main.async { self?.isSpeaking = false }
        }
    }
    
    func openLinks(in text: String) {
        let types = NSTextCheckingResult.CheckingType.link.rawValue
        guard let detector = try? NSDataDetector(types: types) else { return }
        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        if let url = matches.first?.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    func capture(showMain: Bool = false) {
        Task { @MainActor in
            AppDelegate.shared?.closePopover()
            NSApplication.shared.hide(nil)
            
            // Wait for UI to hide
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            let app = NSWorkspace.shared.frontmostApplication
            let appName = app?.localizedName ?? "Screen"
            
            do {
                let (img, url) = try await ScreenCaptureManager.shared.capture()
                let result = try await OCRManager.shared.process(img)
                
                let text = clean(result.content)
                
                add(text, app: appName, bundleId: app?.bundleIdentifier, image: url, type: result.type)
                
                if autoCopy {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                
                if autoOpenLinks { openLinks(in: text) }
                
                if showMain {
                    NSApplication.shared.unhide(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                } else {
                    AppDelegate.shared?.togglePopover()
                }
            } catch {
                if showMain { NSApplication.shared.unhide(nil) }
            }
        }
    }
}
