//
//  Aq16Converters.swift
//  iRingDiag
//
//  Aquilion 16 Detector Converter Lookup Tables
//
//  Purpose
//  -------
//  The Aquilion 16 detector is divided into multiple CONV16
//  converter boards.
//
//  Each converter services a fixed range of detector channels.
//
//  Given a detector channel, these lookup tables determine
//  which converter board contains that detector.
//
//  This information is useful when troubleshooting:
//
//      • Ring artifacts
//      • Failed detector channels
//      • Converter board failures
//      • Detector calibration problems
//
//  No engineering calculations are performed here.
//
//  This file contains only deterministic lookup tables.
//
//  NASA Power of 10 Notes
//  ----------------------
//  • No dynamic memory allocation.
//  • No recursion.
//  • No hidden side effects.
//  • Constant execution time.
//  • Every possible input produces a valid return value.
//
//  Author: Stan Benoit
//

import Foundation

//======================================================================
// MARK: - Aquilion 16 Converter Lookup
//======================================================================

/// Lookup tables relating detector channels to CONV16 boards.
///
/// The detector contains 896 channels distributed across
/// 32 converter boards.
///
/// These functions perform simple range lookups rather than
/// mathematical calculations.
///
/// A return value of zero indicates that the supplied detector
/// channel lies outside the supported Aquilion 16 detector range.
enum Aq16Converters {

    //==================================================================
    // MARK: - Low Detector Converter Lookup
    //==================================================================

    /// Returns the converter board servicing a low-side detector channel.
    ///
    /// The low detector occupies channels 1 through 464.
    ///
    /// - Parameter channel:
    ///     Detector channel number.
    ///
    /// - Returns:
    ///     CONV16 board number.
    ///
    ///     Returns zero when the channel lies outside the supported
    ///     Aquilion 16 detector range.
    static func lowConverter(for channel: Int) -> Int {

        switch channel {

        case 1...32:      return 1
        case 33...80:     return 2
        case 81...128:    return 3
        case 129...152:   return 4
        case 153...176:   return 5
        case 177...200:   return 6
        case 201...224:   return 7
        case 225...248:   return 8
        case 249...272:   return 9
        case 273...296:   return 10
        case 297...320:   return 11
        case 321...341:   return 12
        case 342...368:   return 13
        case 369...392:   return 14
        case 393...416:   return 15
        case 417...440:   return 16
        case 441...464:   return 17

        default:
            return 0
        }
    }


    //==================================================================
    // MARK: - High Detector Converter Lookup
    //==================================================================

    /// Returns the converter board servicing a high-side detector channel.
    ///
    /// The high detector occupies channels 441 through 896.
    ///
    /// Notice that converter 17 services detector channels on both
    /// the low detector and the high detector.
    ///
    /// This mirrors the physical Aquilion detector architecture.
    ///
    /// - Parameter channel:
    ///     Detector channel number.
    ///
    /// - Returns:
    ///     CONV16 board number.
    ///
    ///     Returns zero when the channel lies outside the supported
    ///     Aquilion 16 detector range.
    static func highConverter(for channel: Int) -> Int {

        switch channel {

        case 441...464:   return 17
        case 465...488:   return 18
        case 489...512:   return 19
        case 513...536:   return 20
        case 537...560:   return 21
        case 561...584:   return 22
        case 585...608:   return 23
        case 609...632:   return 24
        case 633...656:   return 25
        case 657...680:   return 26
        case 681...704:   return 27
        case 705...728:   return 28
        case 729...752:   return 29
        case 753...800:   return 30
        case 801...848:   return 31
        case 849...896:   return 32

        default:
            return 0
        }
    }
}
