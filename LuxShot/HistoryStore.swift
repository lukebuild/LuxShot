//
//  HistoryStore.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import Foundation

class HistoryStore {
    static let shared = HistoryStore()
    
    private let fileName = "scan_history.json"
    
    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("LuxShot", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        return appDir.appendingPathComponent(fileName)
    }
    
    func save(_ items: [ScanItem]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[HistoryStore] Save failed: \(error)")
        }
    }
    
    func load() -> [ScanItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ScanItem].self, from: data)
        } catch {
            print("[HistoryStore] Load failed: \(error)")
            return []
        }
    }
}
