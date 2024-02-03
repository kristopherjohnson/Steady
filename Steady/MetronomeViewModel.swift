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
    
    @Published var beatIndex = 0 {
        didSet {
            assert(beatIndex >= 0)
        }
    }
    
    @Published var beatsPerMeasure: Int {
        didSet {
            assert(beatsPerMeasure >= 2)
            
            UserDefaults.standard.setValue(beatsPerMeasure, forKey: Defaults.beatsPerMeasure)
        }
    }
    
    @Published var accentFirstBeatEnabled: Bool {
        didSet {
            UserDefaults.standard.setValue(accentFirstBeatEnabled, forKey: Defaults.accentFirstBeatEnabled)
        }
    }
    
    @Published var beatsPlayed: BeatsPlayed {
        didSet {
            UserDefaults.standard.setValue(beatsPlayed.rawValue, forKey: Defaults.beatsPlayed)
        }
    }
    
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.setValue(soundEnabled, forKey: Defaults.soundEnabled)
        }
    }
    
    private var metronomeTimer: AnyCancellable?
    
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
        
        beatIndex = 1
        self.playClickSound()
        
        let interval = 60.0 / Double(beatsPerMinute)
        metronomeTimer = Timer.publish(every: interval, tolerance: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                
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
    
    private func stopTimer() {
        beatIndex = 0
        metronomeTimer?.cancel()
        metronomeTimer = nil
    }
    
    private func loadSounds() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
        
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
