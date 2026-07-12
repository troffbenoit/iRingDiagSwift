//
//  Aq16Math.swift
//  iRingDiag
//
//  Aquilion 16 Detector Geometry Calculations
//
//  Purpose
//  -------
//  Converts a measured CT ring-artifact radius into the
//  corresponding Aquilion 16 detector channel numbers.
//
//  The calculations implemented here reproduce the detector
//  geometry used by the original Objective-C iRingDiag application.
//
//  This file performs engineering calculations only.
//
//  No SwiftUI or other user-interface code belongs in this file.
//
//  Input
//  -----
//  Ring-artifact radius measured in millimeters.
//
//  Output
//  ------
//  Low-side detector channel.
//  High-side detector channel.
//
//  Detector Geometry
//  -----------------
//
//                     X-ray source
//                          *
//                         /|
//                        / |
//                       /  |
//                      /θ  |
//                     /    |
//                    /     |
//          Isocenter *-----* Ring artifact
//                        radius
//
//  The ring radius is converted into a fan angle:
//
//      θ = asin(radius / sourceDistance)
//
//  The fan angle is then converted into a detector-channel offset:
//
//      channelOffset = θ × radiansToDegrees × channelScale
//
//  The offset is subtracted from the detector center to obtain the
//  low-side channel and added to the detector center to obtain the
//  high-side channel.
//
//  NASA Power of 10 principles adapted for Swift
//  ---------------------------------------------
//  - No recursion.
//  - No dynamic allocation controlled by this file.
//  - No force-unwrapped optionals.
//  - All user-derived input is bounded before use.
//  - Functions are short and perform one clear task.
//  - Constants replace unexplained numeric literals.
//  - Calculation steps use descriptive engineering names.
//  - Every public calculation returns a bounded channel value.
//  - No hidden mutable state.
//  - No user-interface dependencies.
//
//  Author: Stan Benoit
//

import Foundation


//======================================================================
// MARK: - Aquilion 16 Detector Mathematics
//======================================================================

/// Engineering calculations for the Aquilion 16 detector.
///
/// This type is declared as an `enum` with no cases because the program
/// does not need to create instances of it.
///
/// In Swift, a case-less enum is a common way to group related static
/// constants and functions into a namespace.
///
/// Example:
///
///     let low = Aq16Math.lowChannel(forRadius: 25.0)
///     let high = Aq16Math.highChannel(forRadius: 25.0)
///
/// The calculations are deterministic:
///
/// - The same radius always produces the same channels.
/// - No external state is modified.
/// - No stored mutable values are used.
enum Aq16Math {

    //==================================================================
    // MARK: - Scanner Geometry Constants
    //==================================================================

    /// Source-to-isocenter distance used by the original application.
    ///
    /// Units:
    ///
    ///     millimeters
    ///
    /// This value is used to normalize the measured ring radius before
    /// passing the result to the inverse sine function.
    static let sourceDistance: Double = 600.0

    /// Approximate center channel of the Aquilion 16 detector.
    ///
    /// The value is fractional because it represents the detector's
    /// geometric center rather than one physical integer channel.
    ///
    /// The low-side channel is calculated below this center value.
    /// The high-side channel is calculated above this center value.
    static let centerChannel: Double = 448.25

    /// Converts fan angle in degrees into detector-channel displacement.
    ///
    /// This factor originates from the original Aquilion 16 engineering
    /// calculation used by the Objective-C application.
    ///
    /// The result represents the number of detector channels between
    /// the detector center and the location corresponding to the ring.
    static let channelScale: Double = 18.25

    /// Approximate radians-to-degrees conversion factor used by the
    /// original application.
    ///
    /// Mathematically, the conversion is approximately:
    ///
    ///     180.0 / π = 57.2958...
    ///
    /// The original application used 57.32, so this implementation keeps
    /// that value in order to preserve its historical results.
    static let radiansToDegrees: Double = 57.32

    /// Lowest valid detector channel number.
    ///
    /// Aquilion 16 detector channels begin at channel 1.
    static let minimumChannel: Int = 1

    /// Highest valid detector channel number.
    ///
    /// Aquilion 16 detector channels end at channel 896.
    static let maximumChannel: Int = 896


    //==================================================================
    // MARK: - Low-Side Detector Channel
    //==================================================================

    /// Calculates the low-side detector channel for a ring radius.
    ///
    /// The low-side channel lies below the geometric detector center.
    ///
    /// Calculation:
    ///
    ///     lowChannel = centerChannel - detectorOffset
    ///
    /// - Parameter radius:
    ///     Measured ring radius in millimeters.
    ///
    /// - Returns:
    ///     A detector channel bounded to the valid Aquilion 16 range
    ///     of 1 through 896.
    static func lowChannel(forRadius radius: Double) -> Int {

        // Calculate the channel displacement away from detector center.
        let offset = detectorOffset(forRadius: radius)

        // Move toward the low-numbered side of the detector.
        let calculatedChannel = centerChannel - offset

        // Swift's Int initializer truncates the fractional portion.
        //
        // Example:
        //
        //     Int(427.9) becomes 427
        //
        // This matches the behavior of the original implementation.
        let integerChannel = Int(calculatedChannel)

        // Guarantee that the returned channel remains inside the legal
        // Aquilion 16 detector range.
        return boundedChannel(integerChannel)
    }


    //==================================================================
    // MARK: - High-Side Detector Channel
    //==================================================================

    /// Calculates the high-side detector channel for a ring radius.
    ///
    /// The high-side channel lies above the geometric detector center.
    ///
    /// Calculation:
    ///
    ///     highChannel = centerChannel + detectorOffset
    ///
    /// - Parameter radius:
    ///     Measured ring radius in millimeters.
    ///
    /// - Returns:
    ///     A detector channel bounded to the valid Aquilion 16 range
    ///     of 1 through 896.
    static func highChannel(forRadius radius: Double) -> Int {

        // Calculate the same center displacement used by the low-side
        // channel calculation.
        let offset = detectorOffset(forRadius: radius)

        // Move toward the high-numbered side of the detector.
        let calculatedChannel = centerChannel + offset

        // Convert the fractional geometric channel into a physical
        // integer detector-channel number.
        let integerChannel = Int(calculatedChannel)

        // Guarantee that the returned channel remains inside the legal
        // detector range.
        return boundedChannel(integerChannel)
    }


    //==================================================================
    // MARK: - Detector Offset Calculation
    //==================================================================

    /// Converts a ring radius into detector-channel displacement.
    ///
    /// This helper contains the trigonometric portion shared by both
    /// the low-side and high-side calculations.
    ///
    /// Keeping the shared mathematics in one function prevents the same
    /// formula from being duplicated in two separate places.
    ///
    /// Calculation steps:
    ///
    /// 1. Validate the radius.
    /// 2. Divide the radius by the source distance.
    /// 3. Convert the normalized radius into a fan angle using `asin`.
    /// 4. Convert the angle from radians to degrees.
    /// 5. Convert the angle into detector-channel displacement.
    ///
    /// - Parameter radius:
    ///     Measured ring radius in millimeters.
    ///
    /// - Returns:
    ///     Number of detector channels between detector center and the
    ///     calculated ring location.
    private static func detectorOffset(forRadius radius: Double) -> Double {

        // Ensure the radius cannot produce an invalid asin input.
        let safeRadius = validatedRadius(radius)

        // Normalize the radius relative to the source-to-isocenter
        // distance.
        //
        // Because validatedRadius limits the radius to 0...600,
        // normalizedRadius is guaranteed to remain inside 0...1.
        let normalizedRadius = safeRadius / sourceDistance

        // Convert the normalized radius into the detector fan angle.
        //
        // Swift's asin function returns radians.
        let fanAngleRadians = asin(normalizedRadius)

        // Convert the fan angle into degrees using the same factor as
        // the original Objective-C application.
        let fanAngleDegrees =
            fanAngleRadians * radiansToDegrees

        // Convert the fan angle into detector-channel displacement.
        let channelOffset =
            fanAngleDegrees * channelScale

        return channelOffset
    }


    //==================================================================
    // MARK: - Radius Validation
    //==================================================================

    /// Validates the requested ring radius before trigonometric use.
    ///
    /// The inverse sine function requires its argument to be inside:
    ///
    ///     -1.0...1.0
    ///
    /// This program calculates:
    ///
    ///     radius / sourceDistance
    ///
    /// Because a physical ring radius cannot be negative, the supported
    /// radius range is:
    ///
    ///     0.0...sourceDistance
    ///
    /// Values below zero are clamped to zero.
    /// Values above the source distance are clamped to the source distance.
    ///
    /// - Parameter radius:
    ///     Unvalidated radius in millimeters.
    ///
    /// - Returns:
    ///     Radius bounded to 0.0 through 600.0 millimeters.
    private static func validatedRadius(_ radius: Double) -> Double {

        // Reject negative physical radii.
        if radius < 0.0 {
            return 0.0
        }

        // Prevent radius / sourceDistance from exceeding 1.0.
        if radius > sourceDistance {
            return sourceDistance
        }

        return radius
    }


    //==================================================================
    // MARK: - Channel Validation
    //==================================================================

    /// Restricts a calculated channel to the physical detector range.
    ///
    /// This provides a final defensive boundary after the geometry
    /// calculation and integer conversion have completed.
    ///
    /// - Parameter channel:
    ///     Calculated detector-channel number.
    ///
    /// - Returns:
    ///     Channel bounded to 1 through 896.
    private static func boundedChannel(_ channel: Int) -> Int {

        return min(
            maximumChannel,
            max(minimumChannel, channel)
        )
    }
}
