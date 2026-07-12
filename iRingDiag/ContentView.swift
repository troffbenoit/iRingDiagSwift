//
//  ContentView.swift
//  iRingDiag
//
//  Main SwiftUI user interface for the iRingDiag
//  CT ring-artifact diagnostic application.
//
//  Supported scanner models:
//
//      • Aquilion 16
//      • Aquilion 32
//      • Aquilion 64
//
//  This file is responsible for:
//
//  1. Accepting a ring radius from the user.
//  2. Keeping the radius text field and slider synchronized.
//  3. Limiting the radius to the supported operating range.
//  4. Calling the detector geometry and board lookup routines.
//  5. Displaying detector-channel and electronics-board results.
//  6. Allowing the user to select the scanner model.
//
//  Engineering calculations are intentionally kept outside this file:
//
//      ScannerModel.swift
//          Defines the scanner models supported by the application.
//
//      Aq16Math.swift
//          Calculates detector channels from the selected radius.
//
//          Aquilion 16, Aquilion 32, and Aquilion 64 currently use
//          the same detector geometry.
//
//      Aq16Converters.swift
//          Maps Aquilion 16 detector channels to CONV16 boards.
//
//      Aq3264Converters.swift
//          Maps Aquilion 32 and Aquilion 64 detector channels to
//          ADC2 and QV2 boards.
//
//  Keeping the user interface separate from the engineering calculations
//  makes the program easier to test, maintain, verify, and expand.
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
//  Revision History
//  ----------------
//
//  2026-07-10  Stan Benoit
//      Initial SwiftUI conversion for Aquilion 16.
//
//  2026-07-12  Stan Benoit
//      Added scanner model selection.
//      Added Aquilion 32 and Aquilion 64 support.
//      Added ADC2 and QV2 board calculations and display.
//      Updated documentation for multi-scanner operation.
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
/// like for its current state. SwiftUI automatically reevaluates the view
/// when one of its observed state values changes.
///
/// This structure does not directly perform detector engineering
/// calculations. Instead, it passes the current radius to `Aq16Math`
/// and passes the resulting detector channels to the appropriate
/// electronics-board lookup type.
///
/// The selected scanner determines which board results are displayed:
///
/// - Aquilion 16 displays CONV16 boards.
/// - Aquilion 32 displays ADC2 and QV2 boards.
/// - Aquilion 64 displays ADC2 and QV2 boards.
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
    /// Units:
    ///
    ///     millimeters
    ///
    /// Radius values above this limit are clamped to this value.
    private let maximumRadius: Double = 250.0

    /// Amount by which the radius changes during one slider increment.
    ///
    /// A step size of 0.1 provides one decimal place of precision.
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
    /// and updates interface elements that depend on the radius.
    ///
    /// A `String` is used because text fields edit text rather than
    /// numeric values directly.
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

    /// Scanner model currently selected by the user.
    ///
    /// Changing this value causes SwiftUI to rebuild the results section
    /// and display the electronics appropriate for that scanner.
    ///
    /// Aquilion 16 is used as the default scanner when the app starts.
    @State private var selectedScanner: ScannerModel = .aquilion16
    
    /// Tracks whether the radius text field currently owns keyboard focus.
    ///
    /// Setting this value to `false` dismisses the software keyboard.
    @FocusState private var radiusFieldIsFocused: Bool


    //==================================================================
    // MARK: - Derived Radius Value
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
    /// The nil-coalescing operator `??` supplies `minimumRadius` when
    /// conversion fails.
    ///
    /// This avoids force-unwrapping and prevents invalid text from
    /// crashing the application.
    private var radius: Double {
        Double(radiusText) ?? minimumRadius
    }


    //==================================================================
    // MARK: - Detector Channel Calculations
    //==================================================================

    /// High-side detector channel for the current radius.
    ///
    /// Aquilion 16, Aquilion 32, and Aquilion 64 use the same
    /// radius-to-detector-channel geometry.
    ///
    /// The electronics boards differ between scanner families, but the
    /// detector channel calculation remains the same.
    private var highChannel: Int {
        Aq16Math.highChannel(forRadius: radius)
    }

    /// Low-side detector channel for the current radius.
    ///
    /// Aquilion 16, Aquilion 32, and Aquilion 64 currently use the same
    /// detector geometry calculation.
    private var lowChannel: Int {
        Aq16Math.lowChannel(forRadius: radius)
    }


    //==================================================================
    // MARK: - Aquilion 16 Converter Calculations
    //==================================================================

    /// CONV16 board associated with the high-side detector channel.
    private var highConverter: Int {
        Aq16Converters.highConverter(for: highChannel)
    }

    /// CONV16 board associated with the low-side detector channel.
    private var lowConverter: Int {
        Aq16Converters.lowConverter(for: lowChannel)
    }


    //==================================================================
    // MARK: - Aquilion 32 / 64 ADC2 Calculations
    //==================================================================

    /// ADC2 board associated with the high-side detector channel.
    private var highADC2: Int {
        Aq3264Converters.highADC2(for: highChannel)
    }

    /// ADC2 board associated with the low-side detector channel.
    private var lowADC2: Int {
        Aq3264Converters.lowADC2(for: lowChannel)
    }


    //==================================================================
    // MARK: - Aquilion 32 / 64 QV2 Calculations
    //==================================================================

    /// QV2 board associated with the high-side detector channel.
    private var highQV2: Int {
        Aq3264Converters.highQV2(for: highChannel)
    }

    /// QV2 board associated with the low-side detector channel.
    private var lowQV2: Int {
        Aq3264Converters.lowQV2(for: lowChannel)
    }


    //==================================================================
    // MARK: - Main SwiftUI View
    //==================================================================

    /// Describes the complete user interface for this screen.
    ///
    /// SwiftUI views are constructed by combining smaller views such as:
    ///
    /// - `ZStack`
    /// - `VStack`
    /// - `HStack`
    /// - `Text`
    /// - `TextField`
    /// - `Picker`
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
                // Scanner Selection
                //------------------------------------------------------

                scannerPicker


                //------------------------------------------------------
                // Scanner Model Title
                //------------------------------------------------------

                Text(selectedScanner.rawValue)
                    .font(
                        .system(
                            size: 34,
                            weight: .bold
                        )
                    )
                    .padding(.top, 10)


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
                // Electronics Board Results
                //------------------------------------------------------

                electronicsBoardSection


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
    .toolbar {

        ToolbarItemGroup(placement: .keyboard) {

            Spacer()

            Button("Done") {

                // Validate and apply the typed radius.
                applyTypedRadius()

                // Remove focus from the text field.
                // This dismisses the software keyboard.
                radiusFieldIsFocused = false
            }
        }
    }
}

    

    //==================================================================
    // MARK: - Scanner Picker
    //==================================================================

    /// Displays the scanner model selection menu.
    ///
    /// The picker is bound to `selectedScanner`.
    ///
    /// SwiftUI automatically updates `selectedScanner` when the user
    /// selects a different scanner from the menu.
    private var scannerPicker: some View {

        Picker(
            "Scanner",
            selection: $selectedScanner
        ) {

            // `ScannerModel.allCases` is available because ScannerModel
            // conforms to `CaseIterable`.
            //
            // SwiftUI creates one menu entry for each supported scanner.
            ForEach(ScannerModel.allCases) { scanner in

                Text(scanner.rawValue)
                    .tag(scanner)
            }
        }
        .pickerStyle(.menu)
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
            .focused($radiusFieldIsFocused)

            // Use a decimal keyboard when one is available.
            //
            // This is primarily useful on iPhone and iPad.
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
    // MARK: - Electronics Board Section
    //==================================================================

    /// Displays the electronics boards associated with the calculated
    /// high-side and low-side detector channels.
    ///
    /// Aquilion 16 uses CONV16 converter boards.
    ///
    /// Aquilion 32 and Aquilion 64 use two board types:
    ///
    /// - ADC2
    /// - QV2
    ///
    /// `@ViewBuilder` allows this computed property to return different
    /// SwiftUI layouts depending on the selected scanner model.
    @ViewBuilder
    private var electronicsBoardSection: some View {

        switch selectedScanner {

        //--------------------------------------------------------------
        // Aquilion 16 Electronics
        //--------------------------------------------------------------

        case .aquilion16:

            HStack {

                resultColumn(
                    heading: "High",
                    subheading: "Converter 16",
                    value: highConverter
                )

                resultColumn(
                    heading: "Low",
                    subheading: "Converter 16",
                    value: lowConverter
                )
            }


        //--------------------------------------------------------------
        // Aquilion 32 / 64 Electronics
        //--------------------------------------------------------------

        case .aquilion32,
             .aquilion64:

            VStack(spacing: 20) {

                //------------------------------------------------------
                // ADC2 Board Results
                //------------------------------------------------------

                HStack {

                    resultColumn(
                        heading: "High",
                        subheading: "ADC2",
                        value: highADC2
                    )

                    resultColumn(
                        heading: "Low",
                        subheading: "ADC2",
                        value: lowADC2
                    )
                }


                //------------------------------------------------------
                // QV2 Board Results
                //------------------------------------------------------

                HStack {

                    resultColumn(
                        heading: "High",
                        subheading: "QV2",
                        value: highQV2
                    )

                    resultColumn(
                        heading: "Low",
                        subheading: "QV2",
                        value: lowQV2
                    )
                }
            }
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
    /// channel and electronics-board value.
    ///
    /// - Parameters:
    ///   - heading: First label displayed above the result.
    ///   - subheading: Second label displayed above the result.
    ///   - value: Integer result to display.
    ///
    /// - Returns:
    ///     A SwiftUI view containing the formatted result.
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
    ///     0.0...250.0 millimeters
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
    /// This function contains no force unwraps and always produces
    /// a bounded result.
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
        //
        //     max(typedValue, minimumRadius)
        //
        // prevents the result from falling below zero.
        //
        // Then:
        //
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
    /// - Parameter value:
    ///     Radius to display in millimeters.
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
