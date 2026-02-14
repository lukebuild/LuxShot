//
//  ScanModel.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import Foundation
import SwiftUI

struct ScanItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let timestamp: Date
    let textContent: String
    let sourceApp: String
    let appBundleId: String?
    let imagePath: URL?
    let iconName: String
    let contentType: OCRManager.ContentType
    
    // Backward-compat init with default contentType
    init(id: UUID, title: String, timestamp: Date, textContent: String, sourceApp: String, appBundleId: String?, imagePath: URL?, iconName: String, contentType: OCRManager.ContentType = .text) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.textContent = textContent
        self.sourceApp = sourceApp
        self.appBundleId = appBundleId
        self.imagePath = imagePath
        self.iconName = iconName
        self.contentType = contentType
    }
    
    // Mock Data Helper
    static var mocks: [ScanItem] {
        [
            ScanItem(id: UUID(), title: "github.com/project/utils.ts", timestamp: Date(), textContent: "function calculateTotal(items) {\n  return items.reduce((acc, item) => {\n    return acc + (item.price * item.quantity);\n  }, 0);\n}", sourceApp: "Chrome", appBundleId: nil, imagePath: nil, iconName: "globe"),
            ScanItem(id: UUID(), title: "System Preview", timestamp: Date().addingTimeInterval(-900), textContent: "Invoice #2024-001\nDue Date: March 15, 2024\nTotal: $450.00", sourceApp: "Preview", appBundleId: nil, imagePath: nil, iconName: "doc.text"),
            ScanItem(id: UUID(), title: "Safari Snippet", timestamp: Date().addingTimeInterval(-3600), textContent: "The rapid brown fox jumped over the lazy dog.", sourceApp: "Safari", appBundleId: nil, imagePath: nil, iconName: "safari")
        ]
    }
}
