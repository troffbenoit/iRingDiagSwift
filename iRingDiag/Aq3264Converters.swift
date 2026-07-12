///
//  Aq3264Converters.swift
//  iRingDiag
//
//  Aquilion 32 / 64 Board Lookup Tables
//
//  Purpose
//  -------
//  Converts detector channel numbers into the corresponding:
//
//      • ADC2 board
//      • QV2 board
//
//  The detector geometry is identical to the Aquilion 16.
//
//  Only the electronics board assignments differ.
//
//  This file contains lookup tables only.
//
//  No user interface code belongs here.
//
//  Author: Stan Benoit
//

import Foundation

//======================================================================
// MARK: - Aquilion 32 / 64 Board Lookup
//======================================================================

enum Aq3264Converters {
    
    //==============================================================
    // MARK: - Low Side ADC2
    //==============================================================
    
    /// Returns the ADC2 board servicing the specified
    /// low-side detector channel.
    ///
    /// Returns zero if the channel is outside the valid range.
    static func lowADC2(for channel: Int) -> Int {
        
        switch channel {
            
        case 1...32:      return 1
        case 33...80:     return 2
        case 81...128:    return 3
        case 129...176:   return 4
        case 177...224:   return 5
        case 225...272:   return 6
        case 273...320:   return 7
        case 321...368:   return 8
        case 369...416:   return 9
        case 417...464:   return 10
            
        default:
            return 0
        }
    }
    
    
    //==============================================================
    // MARK: - High Side ADC2
    //==============================================================
    
    /// Returns the ADC2 board servicing the specified
    /// high-side detector channel.
    ///
    /// Returns zero if the channel is outside the valid range.
    static func highADC2(for channel: Int) -> Int {
        
        switch channel {
            
        case 417...464:   return 10
        case 465...512:   return 11
        case 513...560:   return 12
        case 561...608:   return 13
        case 609...656:   return 14
        case 657...704:   return 15
        case 705...752:   return 16
        case 753...800:   return 17
        case 801...848:   return 18
        case 849...896:   return 19
            
        default:
            return 0
        }
    }
    
    
    //==============================================================
    // MARK: - Low Side QV2
    //==============================================================
    
    /// Returns the QV2 board servicing the specified
    /// low-side detector channel.
    ///
    /// Returns zero if the channel is outside the valid range.
    static func lowQV2(for channel: Int) -> Int {
        
        switch channel {
            
        case 1...8:       return 1
        case 9...32:      return 2
        case 33...56:     return 3
        case 57...80:     return 4
        case 81...104:    return 5
        case 105...128:   return 6
        case 129...152:   return 7
        case 153...176:   return 8
        case 177...200:   return 9
        case 201...224:   return 10
        case 225...248:   return 11
        case 249...272:   return 12
        case 273...296:   return 13
        case 297...320:   return 14
        case 321...344:   return 15
        case 345...368:   return 16
        case 369...392:   return 17
        case 393...416:   return 18
        case 417...440:   return 19
        case 441...464:   return 20
            
        default:
            return 0
        }
    }
    
    //==============================================================
    // MARK: - High Side QV2
    //==============================================================
    
    /// Returns the QV2 board servicing the specified
    /// high-side detector channel.
    ///
    /// Returns zero if the channel is outside the valid range.
    static func highQV2(for channel: Int) -> Int {
        
        switch channel {
            
        case 441...464:   return 20
        case 465...488:   return 21
        case 489...512:   return 22
        case 513...536:   return 23
        case 537...560:   return 24
        case 561...584:   return 25
        case 585...608:   return 26
        case 609...632:   return 27
        case 633...656:   return 28
        case 657...680:   return 29
        case 681...704:   return 30
        case 705...728:   return 31
        case 729...752:   return 32
        case 753...776:   return 33
        case 777...800:   return 34
        case 801...824:   return 35
        case 825...848:   return 36
        case 849...872:   return 37
        case 873...896:   return 38
            
        default:
            return 0
        }
    }
}
