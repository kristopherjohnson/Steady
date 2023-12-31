import SwiftUI

/// Button style similar to borderedProminent, but which allows specifying the background color.
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
    @State private var isRunning = false
    @State private var bpm = 120
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
    
    var body: some View {
        NavigationStack {
            List {
                Section("Metronome") {
                    HStack {
                        Spacer()
                        
                        Button(action: toggleIsRunning) {
                            HStack {
                                if isRunning {
                                    Image(systemName: "pause.fill")
                                    Text("Stop")
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Start")
                                }
                            }
                        }
                        .buttonStyle(BigButtonStyle(color: isRunning ? .red : .green))
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Tempo") {
                    VStack {
                        HStack {
                            Image(systemName: "metronome")
                            Picker("Beats per minute", selection: $bpm) {
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
                    }                }
            }
            .navigationTitle("Steady")
        }
    }
    
    /// Switch between running and not-running state
    func toggleIsRunning() {
        isRunning = !isRunning
    }
    
    /// Set tempo based on interval between button taps
    func tapTempo() {
        // TODO
    }
}

#Preview {
    ContentView()
}
