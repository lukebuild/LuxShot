//
//  ScreenCaptureManager.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import Foundation
import AppKit

class ScreenCaptureManager {
    static let shared = ScreenCaptureManager()
    
    enum CaptureError: Error {
        case userCancelled
        case fileWriteFailed
        case invalidImageData
    }
    
    func capture() async throws -> (NSImage, URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "scan_\(UUID().uuidString).png"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // -i: interactive (selection)
        // -x: no sound
        // -r: do not add shadow
        task.arguments = ["-i", "-x", "-r", fileURL.path]
        
        return try await withCheckedThrowingContinuation { continuation in
            task.terminationHandler = { process in
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let image = NSImage(contentsOf: fileURL) {
                        continuation.resume(returning: (image, fileURL))
                    } else {
                        continuation.resume(throwing: CaptureError.invalidImageData)
                    }
                } else {
                    continuation.resume(throwing: CaptureError.userCancelled)
                }
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
