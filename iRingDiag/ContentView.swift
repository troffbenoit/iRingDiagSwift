//
//  ContentView.swift
//  iRingDiag
//
//  Main SwiftUI user interface for the Toshiba Aquilion 16
//  CT ring-artifact diagnostic calculation.
//
//  This file is responsible for:
//
//  1. Accepting a radius from the user.
//  2. Keeping the text field and slider synchronized.
//  3. Limiting the radius to the supported range.
//  4. Calling the AQ16 calculation routines.
//  5. Displaying detector-channel and converter results.
//
//  Engineering calculations are intentionally kept outside this file:
//
//      Aq16Math.swift
//          Calculates detector channels from the selected radius.
//
//      Aq16Converters.swift
//          Converts detector-channel numbers into converter numbers.
//
//  Keeping the user interface separate from the engineering calculations
//  makes the program easier to test, maintain, and expand.
//
//  NASA Power of 10 principles adapted for SwiftUI:
//
//  - Use simple and predictable control flow.
//  - Bound all user input.
//  - Avoid force-unwrapping optionals.
//  - Keep functions small and focused.
//  - Avoid hidden side effects.
//  - Use constants instead of unexplained literal values.
//  - Validate data before using it.
//  - Keep calculation logic separate from presentation logic.
//  - Document assumptions and operating limits.
//  - Prefer compiler-checkable code over clever shortcuts.
//
//  Author: Stan Benoit
//

import SwiftUI


//======================================================================
// MARK: - Main Content View
//======================================================================

/// The primary screen displayed by the iRingDiag application.
///
/// `ContentView` is a SwiftUI `View`.
///
/// In SwiftUI, a view is a description of what the interface should look
/// like for its current state. SwiftUI automatically rebuilds the view
/// when one of its observed state values changes.
///
/// This structure does not directly perform the AQ16 engineering
/// calculations. Instead, it passes the current radius to `Aq16Math`
/// and passes the resulting detector channels to `Aq16Converters`.
struct ContentView: View {

    //==================================================================
    // MARK: - Radius Operating Limits
    //==================================================================

    /// Smallest radius accepted by the original iRingDiag application.
    ///
    /// Radius values below this limit are clamped to this value.
    private let minimumRadius: Double = 0.0

    /// Largest radius accepted by the original Objective-C application.
    ///
    /// The Aquilion 16 diagnostic slider supports a maximum radius
    /// of 250 millimeters.
    ///
    /// Radius values above this limit are clamped to this value.
    private let maximumRadius: Double = 250.0

    /// Amount by which the radius changes during one slider increment.
    ///
    /// A step size of 0.1 gives the user one decimal place of precision.
    private let radiusStep: Double = 0.1


    //==================================================================
    // MARK: - User Interface State
    //==================================================================

    /// Text currently displayed inside the radius text field.
    ///
    /// `@State` tells SwiftUI that this value belongs to this view and
    /// may change while the application is running.
    ///
    /// When `radiusText` changes, SwiftUI reevaluates the view's `body`
    /// and updates any interface elements that depend on this value.
    ///
    /// A `String` is used because text fields edit text, not numbers.
    @State private var radiusText: String = "0.0"

    /// Numeric radius represented by the slider.
    ///
    /// The slider requires a numeric binding, so this value is stored
    /// separately from the text-field string.
    ///
    /// The application keeps `sliderValue` and `radiusText`
    /// synchronized whenever the user moves the slider or submits
    /// a typed value.
    @State private var sliderValue: Double = 0.0


    //==================================================================
    // MARK: - Derived Input Value
    //==================================================================

    /// Numeric radius derived from the text-field contents.
    ///
    /// This is a computed property. It is calculated each time it is
    /// accessed rather than being stored separately.
    ///
    /// `Double(radiusText)` returns an optional `Double` because the text
    /// may not represent a valid number. For example, the user could
    /// temporarily enter:
    ///
    ///     ""
    ///     "."
    ///     "-"
    ///     "abc"
    ///
    /// The nil-coalescing operator `??` provides `minimumRadius` when
    /// conversion fails.
    ///
    /// This avoids force-unwrapping and prevents invalid text from
    /// crashing the application.
    private var radius: Double {
        Double(radiusText) ?? minimumRadius
    }


    //==================================================================
    // MARK: - AQ16 Detector Calculations
    //==================================================================

    /// High-side detector channel for the current radius.
    ///
    /// The actual detector geometry calculation is performed by
    /// `Aq16Math`. This view only requests and displays the result.
    private var highChannel: Int {
        Aq16Math.highChannel(forRadius: radius)
    }

    /// Low-side detector channel for the current radius.
    ///
    /// Keeping this calculation in `Aq16Math` prevents engineering
    /// formulas from becoming mixed with SwiftUI layout code.
    private var lowChannel: Int {
        Aq16Math.lowChannel(forRadius: radius)
    }


    //==================================================================
    // MARK: - AQ16 Converter Calculations
    //==================================================================

    /// Converter associated with the high-side detector channel.
    ///
    /// The high detector channel is calculated first. That channel is
    /// then passed to `Aq16Converters`, which performs the converter
    /// lookup.
    private var highConverter: Int {
        Aq16Converters.highConverter(for: highChannel)
    }

    /// Converter associated with the low-side detector channel.
    ///
    /// The low detector channel is calculated first. That channel is
    /// then passed to `Aq16Converters`, which performs the converter
    /// lookup.
    private var lowConverter: Int {
        Aq16Converters.lowConverter(for: lowChannel)
    }


    //==================================================================
    // MARK: - Main SwiftUI View
    //==================================================================

    /// Describes the complete user interface for this screen.
    ///
    /// SwiftUI views are built by combining smaller views such as:
    ///
    /// - `ZStack`
    /// - `VStack`
    /// - `HStack`
    /// - `Text`
    /// - `TextField`
    /// - `Slider`
    ///
    /// SwiftUI reevaluates this property whenever relevant state changes.
    var body: some View {

        // A ZStack places views on top of one another.
        //
        // The first view becomes the background. Later views are drawn
        // over the earlier views.
        ZStack {

            //----------------------------------------------------------
            // Background
            //----------------------------------------------------------

            // Create a gray background with reduced opacity.
            //
            // `ignoresSafeArea()` allows the background to extend behind
            // the status bar, home indicator, and other safe-area edges.
            Color.gray
                .opacity(0.32)
                .ignoresSafeArea()


            //----------------------------------------------------------
            // Main Vertical Layout
            //----------------------------------------------------------

            // A VStack arranges its child views vertically.
            //
            // The spacing argument places 24 points between each direct
            // child in the stack.
            VStack(spacing: 24) {

                //------------------------------------------------------
                // Scanner Model Title
                //------------------------------------------------------

                Text("Aquilion 16")
                    .font(
                        .system(
                            size: 34,
                            weight: .bold
                        )
                    )
                    .padding(.top, 25)


                //------------------------------------------------------
                // Radius Input Controls
                //------------------------------------------------------

                radiusInputSection


                //------------------------------------------------------
                // Detector Channel Results
                //------------------------------------------------------

                detectorChannelSection


                //------------------------------------------------------
                // Visual Separation
                //------------------------------------------------------

                Divider()


                //------------------------------------------------------
                // Converter Results
                //------------------------------------------------------

                converterSection


                //------------------------------------------------------
                // Radius Slider
                //------------------------------------------------------

                radiusSlider


                //------------------------------------------------------
                // Fill Remaining Vertical Space
                //------------------------------------------------------

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }


    //==================================================================
    // MARK: - Radius Input Section
    //==================================================================

    /// Displays the radius label and editable radius text field.
    ///
    /// Breaking major interface sections into computed properties keeps
    /// the main `body` short and easier to inspect.
    private var radiusInputSection: some View {

        VStack(spacing: 12) {

            Text("Radius")
                .font(.system(size: 22))

            TextField(
                "Radius in millimeters",
                text: $radiusText
            )
            .multilineTextAlignment(.center)
            .font(.title2)
            .textFieldStyle(.roundedBorder)
            .frame(width: 200)

            // Use a decimal keyboard when one is available.
            //
            // This is primarily useful on iPhone and iPad. On macOS,
            // the modifier may have no visible effect.
            .keyboardType(.decimalPad)

            // `onSubmit` runs when the user submits the text field,
            // normally by pressing Return or Done.
            .onSubmit {
                applyTypedRadius()
            }
        }
    }


    //==================================================================
    // MARK: - Detector Channel Section
    //==================================================================

    /// Displays the calculated high-side and low-side detector channels.
    private var detectorChannelSection: some View {

        // An HStack arranges its child views horizontally.
        HStack {

            resultColumn(
                heading: "High",
                subheading: "Channel",
                value: highChannel
            )

            resultColumn(
                heading: "Low",
                subheading: "Channel",
                value: lowChannel
            )
        }
    }


    //==================================================================
    // MARK: - Converter Section
    //==================================================================

    /// Displays the converters corresponding to the calculated channels.
    private var converterSection: some View {

        HStack {

            resultColumn(
                heading: "High",
                subheading: "Converter",
                value: highConverter
            )

            resultColumn(
                heading: "Low",
                subheading: "Converter",
                value: lowConverter
            )
        }
    }


    //==================================================================
    // MARK: - Radius Slider
    //==================================================================

    /// Slider used to select a radius between zero and 250 millimeters.
    ///
    /// The slider is bound directly to `sliderValue`.
    ///
    /// Whenever the slider changes, the radius text field is updated
    /// to show the same value with one decimal place.
    private var radiusSlider: some View {

        Slider(
            value: $sliderValue,
            in: minimumRadius...maximumRadius,
            step: radiusStep
        )
        .padding(.horizontal, 30)

        // This closure runs whenever `sliderValue` changes.
        //
        // The first parameter is the previous value. It is written as `_`
        // because the program does not need it.
        //
        // The second parameter contains the newly selected slider value.
        .onChange(of: sliderValue) { _, newValue in
            updateRadiusText(using: newValue)
        }
    }


    //==================================================================
    // MARK: - Reusable Result Column
    //==================================================================

    /// Creates one formatted result column.
    ///
    /// This helper avoids duplicating the same SwiftUI layout for every
    /// channel and converter value.
    ///
    /// - Parameters:
    ///   - heading: First label displayed above the result.
    ///   - subheading: Second label displayed above the result.
    ///   - value: Integer result to display.
    ///
    /// - Returns: A SwiftUI view containing the formatted result.
    private func resultColumn(
        heading: String,
        subheading: String,
        value: Int
    ) -> some View {

        VStack(spacing: 10) {

            Text(heading)
                .font(.title2)

            Text(subheading)
                .font(.title2)

            Text("\(value)")
                .font(.title2)

                // Monospaced digits reserve the same width for every
                // number. This prevents values from visually shifting
                // when their digits change.
                .monospacedDigit()
        }

        // Each result column receives an equal share of the available
        // horizontal space.
        .frame(maxWidth: .infinity)
    }


    //==================================================================
    // MARK: - Typed Radius Validation
    //==================================================================

    /// Validates and applies a radius typed into the text field.
    ///
    /// The function performs the following operations:
    ///
    /// 1. Attempts to convert the text into a `Double`.
    /// 2. Restores the slider value if conversion fails.
    /// 3. Limits the value to the supported range.
    /// 4. Updates the slider.
    /// 5. Reformats the text with one decimal place.
    ///
    /// Supported range:
    ///
    ///     0.0 ... 250.0 millimeters
    ///
    /// Examples:
    ///
    ///     Typed value: -20
    ///     Applied value: 0.0
    ///
    ///     Typed value: 125.75
    ///     Applied value: 125.8
    ///
    ///     Typed value: 500
    ///     Applied value: 250.0
    ///
    ///     Typed value: "abc"
    ///     Applied value: Existing slider value
    ///
    /// This function contains no force unwraps and has a bounded result.
    private func applyTypedRadius() {

        // Attempt to convert the user's text into a number.
        //
        // `guard` handles the failure case immediately. This keeps the
        // successful path straightforward and avoids deeply nested logic.
        guard let typedValue = Double(radiusText) else {

            // Invalid text is replaced with the current valid slider
            // value rather than being passed into the calculations.
            updateRadiusText(using: sliderValue)

            return
        }

        // Restrict the typed value to the legal operating range.
        //
        // First:
        //     max(typedValue, minimumRadius)
        //
        // prevents the result from falling below zero.
        //
        // Then:
        //     min(..., maximumRadius)
        //
        // prevents the result from exceeding 250 millimeters.
        let limitedValue = min(
            max(typedValue, minimumRadius),
            maximumRadius
        )

        // Synchronize the slider with the validated value.
        sliderValue = limitedValue

        // Synchronize and format the text field.
        updateRadiusText(using: limitedValue)
    }


    //==================================================================
    // MARK: - Radius Text Formatting
    //==================================================================

    /// Formats a numeric radius and places it in the text field.
    ///
    /// Keeping formatting in one helper prevents slightly different
    /// formatting code from being repeated throughout the view.
    ///
    /// - Parameter value: Radius to display in millimeters.
    private func updateRadiusText(using value: Double) {

        radiusText = String(
            format: "%.1f",
            value
        )
    }
}


//======================================================================
// MARK: - SwiftUI Preview
//======================================================================

/// Displays `ContentView` inside Xcode's preview canvas.
///
/// The preview allows the interface to be inspected without manually
/// launching the complete application in the simulator.
#Preview {
    ContentView()
}
