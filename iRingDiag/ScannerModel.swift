//
//  ScannerModel.swift
//  iRingDiag
//
//  Defines every CT scanner supported by iRingDiag.
//
//  Keeping this enumeration separate allows the
//  user interface and engineering calculations
//  to reference the same scanner definitions.
//
//  Author: Stan Benoit
//

import Foundation

/// Supported Toshiba CT scanner models.
enum ScannerModel: String, CaseIterable, Identifiable {

    /// Aquilion 16 detector.
    case aquilion16 = "Aquilion 16"

    /// Aquilion 32 detector.
    case aquilion32 = "Aquilion 32"

    /// Aquilion 64 detector.
    case aquilion64 = "Aquilion 64"

    /// Required by SwiftUI ForEach.
    var id: String {
        rawValue
    }
}
