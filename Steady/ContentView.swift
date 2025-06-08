import AVFoundation
import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var model = MetronomeViewModel()
    
    @State private var lastTapTempoDate = Date.distantPast
    
    @State private var isPresentingKeypad = false
    @State private var keypadValue = ""
    @State private var isKeypadValueValid = false
    @FocusState private var isKeypadFocused
    
    private var minBeatsPerMinute: Int { model.minBeatsPerMinute }
    private var maxBeatsPerMinute: Int { model.maxBeatsPerMinute }
    
    // MARK: - Constants
    private static let maxTempoDigits = 3
    private static let maxTapTempoInterval: TimeInterval = 2.0
    private static let minTapTempoInterval: TimeInterval = 0.2
    private static let keypadFocusDelay: TimeInterval = 0.6
    
    var body: some View {
        Form {
            // Title
            Section {
                HStack {
                    Spacer()
                    Image(systemName: "metronome")
                        .accessibilityHidden(true)
                    Text("Steady")
                        .accessibilityHidden(true)
                    Spacer()
                }
                .font(.title)
            }
            .listRowBackground(Color.clear)
            
            // Tempo picker and buttons
            Section("Tempo") {
                Picker("Tempo", selection: $model.beatsPerMinute) {
                    ForEach(minBeatsPerMinute...maxBeatsPerMinute, id: \.self) { n in
                        Text("\(n) bpm").tag(n)
                    }
                }
                .pickerStyleForPlatform()
                .disabled(model.isRunning)
                .opacity(model.isRunning ? 0.6 : 1.0)
                .accessibilityIdentifier("beatsPerMinutePicker")
                .accessibilityHint("Selects the tempo")
                
                HStack {
                    // Tap Tempo button
                    Button(action: tapTempo) {
                        HStack {
                            Image(systemName: "hand.tap")
                            Text("Tap Tempo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(.capsule)
                    .accessibilityIdentifier("tapTempoButton")
                    .accessibilityHint("Sets tempo from taps")
                    
                    // Keypad entry button
                    Button {
                        keypadValue = ""
                        isKeypadValueValid = false
                        isPresentingKeypad = true
                    } label: {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Keypad")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(.capsule)
                    .accessibilityIdentifier("enterTempoButton")
                    .accessibilityHint("Enter tempo via keypad")
                    .sheet(isPresented: $isPresentingKeypad) {
                        NavigationView {
                            Form {
                                Section("Enter tempo (\(minBeatsPerMinute)-\(maxBeatsPerMinute)") {
                                    TextField("Beats per minute", text: $keypadValue)
                                        .numberPadKeyboardTypeForPlatform()
                                        .autocorrectionDisabled()
                                        .textContentType(nil)
                                        .accessibilityIdentifier("enterTempoField")
                                        .accessibilityHint("Enter new tempo")
                                        .focused($isKeypadFocused)
                                        .onSubmit(onKeypadDone)
                                        .submitLabel(.done)
                                        .onChange(of: keypadValue) { _, newValue in
                                            var value = newValue
                                            var valueChanged = false
                                            if value.count > Self.maxTempoDigits {
                                                value = String(newValue.prefix(Self.maxTempoDigits))
                                                valueChanged = true
                                            }
                                            isKeypadValueValid = isValidBeatsPerMinute(text: value)
                                            if valueChanged {
                                                keypadValue = value
                                            }
                                        }
                                }
                            }
                            .navigationBarItems(
                                leading: Button("Cancel") {
                                    isPresentingKeypad = false
                                },
                                trailing: Button("Done") {
                                    onKeypadDone()
                                }
                                    .disabled(!isKeypadValueValid)
                            )
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Self.keypadFocusDelay) {
                                    isKeypadFocused = true
                                }
                            }
                        }
                    }
                }
            }
            
            // Start/stop and beat indicator
            Section {
                
                if model.beatsPerMeasure > 8 {
                    let mid = (model.beatsPerMeasure + 1) / 2
                    HStack {
                        Spacer()
                        ForEach(1...mid, id: \.self) { n in
                            Image(systemName: symbolName(beatIndex: n))
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray)
                                .accessibilityHidden(true)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        ForEach((mid+1)...model.beatsPerMeasure, id: \.self) { n in
                            Image(systemName: symbolName(beatIndex: n))
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray)
                                .accessibilityHidden(true)
                        }
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        ForEach(1...model.beatsPerMeasure, id: \.self) { n in
                            Image(systemName: symbolName(beatIndex: n))
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray)
                                .accessibilityHidden(true)
                        }
                        Spacer()
                    }
                }
                
                HStack {
                    // Start/Stop button
                    Button(action: toggleIsRunning) {
                        HStack {
                            if model.isRunning {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            } else {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BigButtonStyle(color: model.isRunning ? .red : .green))
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("startStopButton")
                    .accessibilityHint("Starts or stops the metronome")
                    
                }
                .padding(.top)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // Options
            Section("Options") {
                HStack {
                    Image(systemName: "lines.measurement.horizontal")
                        .accessibilityHidden(true)
                    Picker("Beats per measure", selection: $model.beatsPerMeasure) {
                        ForEach(2...16, id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                        .accessibilityIdentifier("beatsPerMeasurePicker")
                        .accessibilityHint("Selects the number of beats per measure")
                    }
                }
                
                HStack {
                    Image(systemName: "1.square")
                        .accessibilityHidden(true)
                    Toggle("Accent first beat", isOn: $model.accentFirstBeatEnabled)
                        .accessibilityIdentifier("accessFirstBeatEnabledToggle")
                        .accessibilityHint("Play a different sound for the first beat of a measure")
                }
                
                HStack {
                    Image(systemName: "music.quarternote.3")
                        .accessibilityHidden(true)
                    Picker("Play click on", selection: $model.beatsPlayed) {
                        ForEach(BeatsPlayed.allCases) { bp in
                            Text("\(bp.rawValue)").tag(bp)
                        }
                    }
                    .accessibilityIdentifier("beatsPicker")
                    .accessibilityHint("Selects on which beats a click will be played")
                }
            }
        }
    }
    
    /// Switch between running and not-running state
    private func toggleIsRunning() {
        model.isRunning.toggle()
    }
    
    /// Set tempo based on interval between button taps
    private func tapTempo() {
        let now = Date.now
        
        let tapInterval = now.timeIntervalSince(lastTapTempoDate)
        if tapInterval < Self.maxTapTempoInterval && tapInterval >= Self.minTapTempoInterval {
            let newBeatsPerMinute = 60.0 / tapInterval
            model.beatsPerMinute = Int(newBeatsPerMinute.rounded())
        }
        
        lastTapTempoDate = now
    }
    
    /// Handle tap of the Done button in the tempo entry keypad.
    ///
    /// If the text field holds a valid value, then that is set as the new tempo
    /// and then the sheet is dismissed.  Otherwise, there is no effect.
    private func onKeypadDone() {
        if let newBeatsPerMinute = Int(keypadValue) {
            if newBeatsPerMinute >= minBeatsPerMinute && newBeatsPerMinute <= maxBeatsPerMinute {
                model.beatsPerMinute = newBeatsPerMinute
                isPresentingKeypad = false
            }
        }
    }
    
    /// Determine whether the given text is a valid value for beatsPerMinute.
    private func isValidBeatsPerMinute(text: String) -> Bool {
        guard let beatsPerMinute = Int(text) else { return false }
        return beatsPerMinute >= minBeatsPerMinute && beatsPerMinute <= maxBeatsPerMinute
    }
    
    /// Return symbol name for given beatIndex.
    ///
    /// Returns a filled circle if the index matches
    /// the model's current beat index
    private func symbolName(beatIndex: Int) -> String {
        return beatIndex == model.beatIndex
        ? "\(beatIndex).circle.fill"
        : "\(beatIndex).circle"
    }
}

extension View {
    @ViewBuilder
    func numberPadKeyboardTypeForPlatform() -> some View {
#if os(iOS)
        self.keyboardType(.numberPad)
#else
        self
#endif
    }
    
    @ViewBuilder
    func pickerStyleForPlatform() -> some View {
#if os(iOS)
        self.pickerStyle(WheelPickerStyle())
#else
        self.pickerStyle(DefaultPickerStyle())
#endif
    }
}

#Preview {
    ContentView()
}
