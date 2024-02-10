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
    
    private let metronomeDispatchQueue = DispatchQueue(label: "net.kristopherjohnson.Steady.metronome", attributes: .concurrent)
    
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
            
            DispatchQueue.main.async {
                if !self.isRunning {
                    return
                }
                
                var nextBeatIndex = self.beatIndex + 1
                if nextBeatIndex > self.beatsPerMeasure {
                    nextBeatIndex = 1
                }
                self.beatIndex = nextBeatIndex

                self.playClickSound()
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
            try session.setCategory(.playback)
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
    
    private func playClickSound() {
        if soundEnabled {
            if accentFirstBeatEnabled && (beatIndex == 1) {
                accentAudioPlayer?.play()
            } else if shouldPlayClick() {
                clickAudioPlayer?.play()
            }
        }
    }
    
    private func shouldPlayClick() -> Bool {
        switch beatsPlayed {
        case .all:
            return true
        case .odd:
            return beatIndex % 2 == 1
        case .even:
            return beatIndex % 2 == 0
        }
    }
}
