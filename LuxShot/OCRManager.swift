//
//  OCRManager.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import Foundation
import Vision
import AppKit

class OCRManager {
    static let shared = OCRManager()
    
    enum OCRError: Error {
        case imagePropertiesMissing
        case processingFailed
    }
    
    struct Result {
        let text: String
        let codes: [Barcode]
        let hasQR: Bool
        
        var content: String {
            if !codes.isEmpty { return codes.map { $0.payload }.joined(separator: "\n") }
            return text
        }
        
        var type: ContentType {
            if hasQR { return .qrcode }
            if !codes.isEmpty { return .barcode }
            return .text
        }
    }
    
    struct Barcode {
        let payload: String
        let type: VNBarcodeSymbology
    }
    
    enum ContentType: String, Codable {
        case text, qrcode, barcode
    }
    
    func process(_ image: NSImage) async throws -> Result {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.processingFailed
        }
        
        async let text = recognize(cgImage)
        async let codes = detectCodes(cgImage)
        
        let t = try await text
        let c = try await codes
        let qr = c.contains { $0.type == .qr }
        
        return Result(text: t, codes: c, hasQR: qr)
    }
    
    private func recognize(_ cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let req = VNRecognizeTextRequest { req, err in
                if let err = err { return continuation.resume(throwing: err) }
                guard let res = req.results as? [VNRecognizedTextObservation] else { return continuation.resume(returning: "") }
                
                let text = res.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }
            
            req.recognitionLevel = .accurate
            req.usesLanguageCorrection = true
            req.automaticallyDetectsLanguage = true
            if #available(macOS 14.0, *) { req.revision = VNRecognizeTextRequestRevision3 }
            
            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([req])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectCodes(_ cgImage: CGImage) async throws -> [Barcode] {
        try await withCheckedThrowingContinuation { continuation in
            let req = VNDetectBarcodesRequest { req, err in
                if let err = err { return continuation.resume(throwing: err) }
                guard let res = req.results as? [VNBarcodeObservation] else { return continuation.resume(returning: []) }
                
                let codes = res.compactMap { obs -> Barcode? in
                    guard let load = obs.payloadStringValue else { return nil }
                    return Barcode(payload: load, type: obs.symbology)
                }
                continuation.resume(returning: codes)
            }
            
            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([req])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
