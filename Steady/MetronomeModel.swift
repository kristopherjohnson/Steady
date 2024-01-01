import Foundation
import AVFoundation
import Combine

/// Implementation of metronome state and operation for use by ContentView.
class MetronomeModel: ObservableObject {
    
    /// Set true to enable the metronome's clicks
    @Published var isRunning: Bool = false {
        didSet {
            if isRunning {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    /// Tempo
    @Published var beatsPerMinute: Int = 120 {
        didSet {
            assert(beatsPerMinute >= 1)
            
            if isRunning {
                startTimer()
            }
        }
    }

    private var metronomeTimer: AnyCancellable?
    private var audioPlayer: AVAudioPlayer?

    init() {
        loadClickSound()
    }

    private func startTimer() {
        stopTimer()

        let interval = 60.0 / Double(beatsPerMinute)
        metronomeTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] _ in
                self?.playClickSound()
            }
    }

    private func stopTimer() {
        metronomeTimer?.cancel()
        metronomeTimer = nil
    }

    private func loadClickSound() {
        guard let url = Bundle.main.url(forResource: "woodblock", withExtension: "wav") else {
            print("Click sound not found.")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error loading click sound: \(error)")
        }
    }

    private func playClickSound() {
        audioPlayer?.play()
    }
}

