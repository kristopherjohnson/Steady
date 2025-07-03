import Foundation
import AVFoundation
import Combine
import UIKit

/// Implementation of metronome state and operation for use by ContentView.
class MetronomeViewModel: ObservableObject {
    
    let minBeatsPerMinute = 30
    let maxBeatsPerMinute = 300
    
    /// Set true to enable the metronome's periodic clicking.
    @Published var isRunning = false {
        didSet {
            if isRunning {
                startMetronome()
            } else {
                stopMetronome()
            }
        }
    }
    
    /// Tempo
    @Published var beatsPerMinute: Int {
        didSet {
            assert(beatsPerMinute >= 1)
            
            UserDefaults.standard.setValue(beatsPerMinute, forKey: Defaults.beatsPerMinute)
            
            if isRunning {
                startMetronome()
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
    
    // Unified audio system using AVAudioEngine
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var mixer: AVAudioMixerNode?
    private var highClickBuffer: AVAudioPCMBuffer?
    private var lowClickBuffer: AVAudioPCMBuffer?
    private var silentBuffer: AVAudioPCMBuffer?
    
    // UI timing (independent of audio timing)
    private var uiTimer: DispatchSourceTimer?
    private let uiQueue = DispatchQueue(label: "net.kristopherjohnson.Steady.ui", qos: .userInteractive)
    
    // Audio timing state
    private var currentBeat = 0
    private var nextBeatTime: AVAudioTime?
    
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
        
        setupAudio()
    }
    
    private func setupAudio() {
        setupAudioSession()
        setupAudioEngine()
        loadAudioBuffers()
    }
    
    private func setupAudioSession() {
#if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, 
                                   mode: .default, 
                                   options: [.mixWithOthers, .allowAirPlay, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
#endif
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixer = audioEngine?.mainMixerNode
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        engine.attach(player)
        engine.connect(player, to: mixer!, format: nil)
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func loadAudioBuffers() {
        guard let highClickURL = Bundle.main.url(forResource: "click_high", withExtension: "wav"),
              let lowClickURL = Bundle.main.url(forResource: "click_low", withExtension: "wav") else {
            print("Could not find audio files")
            return
        }
        
        do {
            let highClickFile = try AVAudioFile(forReading: highClickURL)
            let lowClickFile = try AVAudioFile(forReading: lowClickURL)
            
            let highFrameCount = UInt32(highClickFile.length)
            let lowFrameCount = UInt32(lowClickFile.length)
            
            guard let highBuffer = AVAudioPCMBuffer(pcmFormat: highClickFile.processingFormat, frameCapacity: highFrameCount),
                  let lowBuffer = AVAudioPCMBuffer(pcmFormat: lowClickFile.processingFormat, frameCapacity: lowFrameCount) else {
                print("Could not create audio buffers")
                return
            }
            
            try highClickFile.read(into: highBuffer)
            try lowClickFile.read(into: lowBuffer)
            
            highClickBuffer = highBuffer
            lowClickBuffer = lowBuffer
            
            createSilentBuffer()
            
        } catch {
            print("Error loading audio files: \(error)")
        }
    }
    
    private func createSilentBuffer() {
        guard let engine = audioEngine else { return }
        
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let frameCount = UInt32(format.sampleRate * 0.1) // 100ms of silence
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        // Initialize with silence
        if let floatData = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                for frame in 0..<Int(frameCount) {
                    floatData[channel][frame] = 0.0
                }
            }
        }
        
        silentBuffer = buffer
    }
    
    private func startMetronome() {
        stopMetronome()
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        // Reset timing state
        currentBeat = 0
        beatIndex = 0
        
        // Ensure audio engine is running
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }
        
        // Start audio timing
        scheduleNextBeat()
        scheduleSilentAudio() // Keep audio session active in background
        
        // Start UI updates
        startUITimer()
    }
    
    private func stopMetronome() {
        // Stop audio
        playerNode?.stop()
        nextBeatTime = nil
        
        // Stop UI timer
        uiTimer?.cancel()
        uiTimer = nil
        
        // Reset UI state
        beatIndex = 0
        currentBeat = 0
    }
    
    private func scheduleNextBeat() {
        guard isRunning, let player = playerNode, let engine = audioEngine else { return }
        
        let interval = 60.0 / Double(beatsPerMinute)
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        
        // Calculate next beat time
        if let lastTime = nextBeatTime {
            let framesToAdd = AVAudioFramePosition(interval * sampleRate)
            nextBeatTime = AVAudioTime(sampleTime: lastTime.sampleTime + framesToAdd, atRate: sampleRate)
        } else {
            // First beat - schedule immediately
            let currentTime = engine.outputNode.lastRenderTime ?? AVAudioTime(sampleTime: 0, atRate: sampleRate)
            let bufferDelay = AVAudioFramePosition(0.1 * sampleRate) // 100ms buffer
            nextBeatTime = AVAudioTime(sampleTime: currentTime.sampleTime + bufferDelay, atRate: sampleRate)
        }
        
        guard let playTime = nextBeatTime else { return }
        
        // Schedule the click if sound is enabled and this beat should play
        if soundEnabled && shouldPlayBeat() {
            let isAccented = accentFirstBeatEnabled && (currentBeat % beatsPerMeasure == 0)
            let buffer = isAccented ? highClickBuffer : lowClickBuffer
            
            if let buffer = buffer {
                player.scheduleBuffer(buffer, at: playTime) { [weak self] in
                    DispatchQueue.main.async {
                        self?.advanceBeat()
                        self?.scheduleNextBeat()
                    }
                }
            } else {
                // No buffer available, schedule next beat anyway
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
                    self?.advanceBeat()
                    self?.scheduleNextBeat()
                }
            }
        } else {
            // Silent beat, schedule next beat
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
                self?.advanceBeat()
                self?.scheduleNextBeat()
            }
        }
    }
    
    private func shouldPlayBeat() -> Bool {
        let beatInMeasure = currentBeat % beatsPerMeasure
        
        switch beatsPlayed {
        case .all:
            return true
        case .odd:
            return beatInMeasure % 2 == 0
        case .even:
            return beatInMeasure % 2 == 1
        }
    }
    
    private func advanceBeat() {
        currentBeat += 1
    }
    
    private func scheduleSilentAudio() {
        // Schedule continuous silent audio to keep the session active in background
        guard let player = playerNode, let silentBuffer = silentBuffer else { return }
        
        player.scheduleBuffer(silentBuffer, at: nil) { [weak self] in
            if self?.isRunning == true {
                self?.scheduleSilentAudio()
            }
        }
    }
    
    private func startUITimer() {
        let interval = 60.0 / Double(beatsPerMinute)
        
        uiTimer = DispatchSource.makeTimerSource(flags: .strict, queue: uiQueue)
        
        uiTimer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.isRunning else { return }
                
                var nextBeatIndex = self.beatIndex + 1
                if nextBeatIndex > self.beatsPerMeasure {
                    nextBeatIndex = 1
                }
                self.beatIndex = nextBeatIndex
            }
        }
        
        uiTimer?.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(10))
        uiTimer?.activate()
    }
    
    deinit {
        stopMetronome()
        audioEngine?.stop()
    }
}