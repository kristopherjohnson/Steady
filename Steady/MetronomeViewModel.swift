import Foundation
import AVFoundation
import Combine

/// Implementation of metronome state and operation for use by ContentView.
class MetronomeViewModel: ObservableObject {
    
    let minBeatsPerMinute = 30
    let maxBeatsPerMinute = 300
    
    /// Set true to enable the metronome's periodic clicking.
    @Published var isRunning = false {
        didSet {
            if isRunning {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    /// Tempo
    @Published var beatsPerMinute: Int {
        didSet {
            assert(beatsPerMinute >= 1)
            
            UserDefaults.standard.setValue(beatsPerMinute, forKey: Defaults.beatsPerMinute)
            
            if isRunning {
                startTimer()
            }
        }
    }
    
    /// Current beat index
    @Published var beatIndex = 0 {
        didSet {
            assert(beatIndex >= 0)
        }
    }
    
    /// Number of beats per measure
    @Published var beatsPerMeasure: Int {
        didSet {
            assert(beatsPerMeasure >= 2)
            
            UserDefaults.standard.setValue(beatsPerMeasure, forKey: Defaults.beatsPerMeasure)
        }
    }
    
    /// If set true, first beat of each measure has a different sound
    @Published var accentFirstBeatEnabled: Bool {
        didSet {
            UserDefaults.standard.setValue(accentFirstBeatEnabled, forKey: Defaults.accentFirstBeatEnabled)
        }
    }
    
    /// Which beats of a measure to play sounds on
    @Published var beatsPlayed: BeatsPlayed {
        didSet {
            UserDefaults.standard.setValue(beatsPlayed.rawValue, forKey: Defaults.beatsPlayed)
        }
    }
    
    /// If true, make audio sounds.  Otherwise, silent.
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.setValue(soundEnabled, forKey: Defaults.soundEnabled)
        }
    }
    
    private let metronomeDispatchQueue = DispatchQueue(label: "net.kristopherjohnson.Steady.metronome", qos: .userInteractive, attributes: .concurrent)
    
    private var metronomeTimer: DispatchSourceTimer?
    
    private var clickAudioPlayer: AVAudioPlayer?
    private var accentAudioPlayer: AVAudioPlayer?
    
    init() {
        let userDefaults = UserDefaults.standard
        
        beatsPerMinute = max(
            min(
                userDefaults.integer(forKey: Defaults.beatsPerMinute),
                maxBeatsPerMinute
            ),
            minBeatsPerMinute)
        
        beatsPerMeasure = userDefaults.integer(forKey: Defaults.beatsPerMeasure)
        accentFirstBeatEnabled = userDefaults.bool(forKey: Defaults.accentFirstBeatEnabled)
        beatsPlayed = BeatsPlayed(rawValue: userDefaults.string(forKey: Defaults.beatsPlayed) ?? BeatsPlayed.all.rawValue) ?? .all
        soundEnabled = userDefaults.bool(forKey: Defaults.soundEnabled)
        
        loadSounds()
    }
    
    private func startTimer() {
        stopTimer()
        
        beatIndex = 0
        let interval = 60.0 / Double(beatsPerMinute)
        
        metronomeTimer = DispatchSource.makeTimerSource(
            flags: .strict,
            queue: metronomeDispatchQueue)
        
        metronomeTimer?.setEventHandler { [weak self] in
            guard let self else { return }
            
            if !self.isRunning {
                return
            }
            
            var nextBeatIndex = self.beatIndex + 1
            if nextBeatIndex > self.beatsPerMeasure {
                nextBeatIndex = 1
            }
            
            // Play sound immediately on timer thread for precise timing
            self.playClickSound(beatIndex: nextBeatIndex)
            
            // Update UI on main thread (non-blocking for audio)
            DispatchQueue.main.async {
                self.beatIndex = nextBeatIndex
            }
        }
        
        metronomeTimer?.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(10))
        metronomeTimer?.activate()
    }
    
    private func stopTimer() {
        beatIndex = 0
        metronomeTimer?.cancel()
        metronomeTimer = nil
    }
    
    private func loadSounds() {
#if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
#endif
        
        guard let clickUrl = Bundle.main.url(forResource: "click_low", withExtension: "wav") else {
            fatalError("click sound not found.")
        }
        
        guard let accentUrl = Bundle.main.url(forResource: "click_high", withExtension: "wav") else {
            fatalError("accent sound not found.")
        }
        
        do {
            clickAudioPlayer = try AVAudioPlayer(contentsOf: clickUrl)
            clickAudioPlayer?.prepareToPlay()
            
            accentAudioPlayer = try AVAudioPlayer(contentsOf: accentUrl)
            accentAudioPlayer?.prepareToPlay()
        } catch {
            fatalError("unable to load click sound: \(error)")
        }
    }
    
    private func playClickSound(beatIndex: Int? = nil) {
        let currentBeatIndex = beatIndex ?? self.beatIndex
        
        if soundEnabled {
            if accentFirstBeatEnabled && (currentBeatIndex == 1) {
                accentAudioPlayer?.play()
            } else if shouldPlayClick(beatIndex: currentBeatIndex) {
                clickAudioPlayer?.play()
            }
        }
    }
    
    private func shouldPlayClick(beatIndex: Int? = nil) -> Bool {
        let currentBeatIndex = beatIndex ?? self.beatIndex
        
        switch beatsPlayed {
        case .all:
            return true
        case .odd:
            return currentBeatIndex % 2 == 1
        case .even:
            return currentBeatIndex % 2 == 0
        }
    }
}
