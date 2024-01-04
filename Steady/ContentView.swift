import AVFoundation
import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var model = MetronomeViewModel()
    
    @State private var lastTapTempoDate = Date.distantPast

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
                                    ForEach(30...300, id: \.self) { n in
                                        Text("\(n) bpm").tag(n)
                                    }
                                    .accessibilityIdentifier("beatsPerMinutePicker")
                                    .accessibilityHint("Selects the tempo")
                                }
                            }
                        
                        // Tap Tempo button
                        Button(action: tapTempo) {
                            HStack {
                                Image(systemName: "hand.tap")
                                Text("Tap Tempo")
                            }
                            .padding(4.0)
                        }
                        .font(.title)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("tapTempoButton")
                        .accessibilityHint("Sets tempo from taps")
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
                        Picker("Play click on beats", selection: $model.beatsPlayed) {
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
        model.isRunning = !model.isRunning
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
    
    /// Return symbol name for given beatIndex.
    ///
    /// Returns a filled circle if the index matches
    /// the model's current beat index
    func symbolName(beatIndex: Int) -> String {
        return beatIndex == model.beatIndex
            ? "\(beatIndex).circle.fill"
            : "\(beatIndex).circle"
    }
}

#Preview {
    ContentView()
}
