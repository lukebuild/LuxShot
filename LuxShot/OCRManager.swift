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
    
    struct ScanResult {
        let text: String
        let barcodes: [BarcodeResult]
        let hasQRCode: Bool
        
        var primaryContent: String {
            if !barcodes.isEmpty {
                return barcodes.map { $0.payload }.joined(separator: "\n")
            }
            return text
        }
        
        var contentType: ContentType {
            if hasQRCode { return .qrcode }
            if !barcodes.isEmpty { return .barcode }
            return .text
        }
    }
    
    struct BarcodeResult {
        let payload: String
        let type: VNBarcodeSymbology
        let isURL: Bool
        
        init(payload: String, type: VNBarcodeSymbology) {
            self.payload = payload
            self.type = type
            self.isURL = payload.hasPrefix("http://") || payload.hasPrefix("https://")
        }
    }
    
    enum ContentType: String, Codable {
        case text
        case qrcode
        case barcode
    }
    
    // MARK: - Full Scan (OCR + Barcode)
    
    func fullScan(from image: NSImage) async throws -> ScanResult {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.imagePropertiesMissing
        }
        
        // Run OCR and barcode detection in parallel
        async let textResult = recognizeTextFromCG(cgImage)
        async let barcodeResult = detectBarcodes(cgImage)
        
        let text = try await textResult
        let barcodes = try await barcodeResult
        
        let hasQR = barcodes.contains { $0.type == .qr }
        
        return ScanResult(text: text, barcodes: barcodes, hasQRCode: hasQR)
    }
    
    // MARK: - Text Recognition
    
    func recognizeText(from image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.imagePropertiesMissing
        }
        return try await recognizeTextFromCG(cgImage)
    }
    
    private func recognizeTextFromCG(_ cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let fullText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: fullText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            if #available(macOS 14.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
            } else {
                request.revision = VNRecognizeTextRequestRevision2
            }
            
            request.automaticallyDetectsLanguage = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Barcode/QR Code Detection
    
    private func detectBarcodes(_ cgImage: CGImage) async throws -> [BarcodeResult] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = observations.compactMap { observation -> BarcodeResult? in
                    guard let payload = observation.payloadStringValue else { return nil }
                    return BarcodeResult(payload: payload, type: observation.symbology)
                }
                
                continuation.resume(returning: results)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
