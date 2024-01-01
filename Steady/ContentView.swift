import AVFoundation
import Combine
import SwiftUI

/// Button style similar to `borderedProminent`, but which allows
///  specification of the background color.
struct BigButtonStyle: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.largeTitle)
            .frame(minWidth: 210)
            .padding()
            .background(configuration.isPressed ? color.opacity(0.7) : color)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ContentView: View {
    @StateObject private var model = MetronomeModel()
    
    @State private var lastTapTempoDate = Date.distantPast
    
    #if false
    @State private var timeSignature = "4/4"
    @State private var beats = "All"
    @State private var soundEnabled = true
    @State private var flashEnabled = false
    @State private var accentFirstBeatEnabled = false
        
    private var timeSignatures = [
        "2/4",
        "3/4",
        "4/4",
        "5/4",
        "6/4",
        "7/4",
    ]
    
    private var beatSelections = [
        "All",
        "Odd beats",
        "Even beats"
    ]
    #endif
    
    var body: some View {
        NavigationStack {
            List {
                Section("Metronome") {
                    HStack {
                        Spacer()
                        
                        Button(action: toggleIsRunning) {
                            HStack {
                                if model.isRunning {
                                    Image(systemName: "pause.fill")
                                    Text("Stop")
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Start")
                                }
                            }
                        }
                        .buttonStyle(BigButtonStyle(color: model.isRunning ? .red : .green))
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Tempo") {
                    VStack {
                        HStack {
                            Image(systemName: "metronome")
                            Picker("Beats per minute", selection: $model.beatsPerMinute) {
                                ForEach(30...300, id: \.self) { n in
                                    Text("\(n) bpm").tag(n)
                                }
                            }
                            .accessibilityIdentifier("bpmPicker")
                        }
                        
                        Button(action: tapTempo) {
                            HStack {
                                Image(systemName: "hand.tap")
                                Text("Tap Tempo")
                            }
                            .padding()
                        }
                        .font(.title)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("tapTempoButton")
                    }
                }
                
                #if false // Meter not implmented yet
                Section("Meter") {
                    HStack {
                        Image(systemName: "lines.measurement.horizontal")
                        Picker("Time signature", selection: $timeSignature) {
                            ForEach(timeSignatures, id: \.self) { ts in
                                Text("\(ts)").tag(ts)
                            }
                        }
                        .accessibilityIdentifier("timeSignaturePicker")
                    }
                    
                    HStack {
                        Image(systemName: "music.note.list")
                        Picker("Beats", selection: $beats) {
                            ForEach(beatSelections, id: \.self) { b in
                                Text("\(b)").tag(b)
                            }
                        }
                        .accessibilityIdentifier("beatsPicker")
                    }
                }
                #endif
                
                #if false
                Section("Options") {
                    HStack {
                        Image(systemName: "speaker.wave.1")
                        Toggle("Sound enabled", isOn: $soundEnabled)
                            .accessibilityIdentifier("soundEnabledToggle")
                    }
                    
                    HStack {
                        Image(systemName: "bolt")
                        Toggle("Flash enabled", isOn: $flashEnabled)
                            .accessibilityIdentifier("flashEnabledToggle")
                    }
                    
                    HStack {
                        Image(systemName: "1.circle")
                        Toggle("Accent first beat", isOn: $accentFirstBeatEnabled)
                            .accessibilityIdentifier("accessFirstBeatEnabledToggle")
                    }
                }
                #endif
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
}

#Preview {
    ContentView()
}
