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
    
#if false
    @State private var flashEnabled = false
#endif
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack {
                        HStack {
                            Image(systemName: "metronome")
                            Picker("Beats per minute", selection: $model.beatsPerMinute) {
                                ForEach(minBeatsPerMinute...maxBeatsPerMinute, id: \.self) { n in
                                    Text("\(n) bpm").tag(n)
                                }
                                .accessibilityIdentifier("beatsPerMinutePicker")
                                .accessibilityHint("Selects the tempo")
                            }
                        }
                        
                        HStack {
                            Spacer()
                            
                            // Tap Tempo button
                            Button(action: tapTempo) {
                                HStack {
                                    Image(systemName: "hand.tap")
                                    Text("Tap Tempo")
                                }
                                .padding(4.0)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("tapTempoButton")
                            .accessibilityHint("Sets tempo from taps")
                            
                            Spacer()
                            
                            // Keypad entry button
                            Button {
                                keypadValue = String(model.beatsPerMinute)
                                isKeypadValueValid = true
                                isPresentingKeypad = true
                            } label: {
                                HStack {
                                    Image(systemName: "keyboard")
                                    Text("Keypad")
                                }
                                .padding(4.0)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("enterTempoButton")
                            .accessibilityHint("Enter tempo via keypad")
                            .sheet(isPresented: $isPresentingKeypad) {
                                NavigationView {
                                    List {
                                        HStack {
                                            Image(systemName: "metronome")
                                            Text("Beats per minute")
                                            
                                            TextField("\(minBeatsPerMinute)–\(maxBeatsPerMinute)", text: $keypadValue)
                                                .keyboardType(.numberPad)
                                                .multilineTextAlignment(.trailing)
                                                .autocorrectionDisabled()
                                                .textContentType(nil)
                                                .accessibilityIdentifier("enterTempoField")
                                                .accessibilityHint("Enter new tempo")
                                                .focused($isKeypadFocused)
                                                .onSubmit(onKeypadDone)
                                                .onChange(of: keypadValue) { oldValue, newValue in
                                                    var value = newValue
                                                    var valueChanged = false
                                                    if value.count > 3 {
                                                        value = String(newValue.prefix(3))
                                                        valueChanged = true
                                                    }
                                                    isKeypadValueValid = isValidBeatsPerMinute(text: value)
                                                    if valueChanged {
                                                        print("changing keypadValue")
                                                        keypadValue = value
                                                    }
                                                }
                                        }
                                    }
                                    .navigationBarTitle("Enter Tempo", displayMode: .inline)
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
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                            isKeypadFocused = true
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.top)
                    }
                }
                .padding(.bottom)
                
                Section {
                    HStack {
                        Image(systemName: "lines.measurement.horizontal")
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
                        Toggle("Accent first beat", isOn: $model.accentFirstBeatEnabled)
                            .accessibilityIdentifier("accessFirstBeatEnabledToggle")
                            .accessibilityHint("Play a different sound for the first beat of a measure")
                    }
                    
                    HStack {
                        Image(systemName: "music.quarternote.3")
                        Picker("Play click on", selection: $model.beatsPlayed) {
                            ForEach(BeatsPlayed.allCases) { bp in
                                Text("\(bp.rawValue)").tag(bp)
                            }
                        }
                        .accessibilityIdentifier("beatsPicker")
                        .accessibilityHint("Selects on which beats a click will be played")
                    }
                }
                
#if false
                Section("Options") {
                    HStack {
                        Image(systemName: "speaker.wave.1")
                        Toggle("Sound enabled", isOn: $soundEnabled)
                            .accessibilityIdentifier("soundEnabledToggle")
                            .accessibilityHint("Enables audio click sounds")
                    }
                    
                    HStack {
                        Image(systemName: "bolt")
                        Toggle("Flash enabled", isOn: $flashEnabled)
                            .accessibilityIdentifier("flashEnabledToggle")
                            .accessibilityHint("Enables visual flash for each click")
                    }
                }
#endif
                
                Section {
                    VStack {
                        // Beat indicator
                        VStack {
                            if model.beatsPerMeasure > 8 {
                                let mid = (model.beatsPerMeasure + 1) / 2
                                HStack {
                                    Spacer()
                                    ForEach(1...mid, id: \.self) { n in
                                        Image(systemName: symbolName(beatIndex: n))
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundStyle(.gray)
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
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.bottom)
                        
                        HStack {
                            Spacer()
                            
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
                            }
                            .buttonStyle(BigButtonStyle(color: model.isRunning ? .red : .green))
                            .accessibilityIdentifier("startStopButton")
                            .accessibilityHint("Starts or stops the metronome")
                            
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Steady")
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
        if tapInterval < 2.0 && tapInterval >= 0.2 {
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

#Preview {
    ContentView()
}
