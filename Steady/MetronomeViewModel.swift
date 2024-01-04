import Foundation
import AVFoundation
import Combine

/// Implementation of metronome state and operation for use by ContentView.
class MetronomeViewModel: ObservableObject {
    
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
    @Published var beatsPerMinute = 120 {
        didSet {
            assert(beatsPerMinute >= 1)
            
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
    
    @Published var beatsPerMeasure = 4 {
        didSet {
            assert(beatsPerMeasure >= 2)
        }
    }
    
    @Published var accentFirstBeatEnabled = false
    @Published var beatsPlayed = BeatsPlayed.all
    
    @Published var soundEnabled = true

    private var metronomeTimer: AnyCancellable?
    
    private var clickAudioPlayer: AVAudioPlayer?
    private var accentAudioPlayer: AVAudioPlayer?

    init() {
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