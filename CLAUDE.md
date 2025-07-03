# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Steady is a cross-platform metronome app built with SwiftUI, targeting both iOS and macOS. The app provides precise timing for musicians with configurable tempo, beats per measure, accent patterns, and visual/audio feedback. **Key Feature**: The app supports uninterrupted background audio, allowing musicians to continue hearing the metronome even when the app is backgrounded or the device is locked.

## Development Commands

### Building and Testing
- **Build the project**: Use Xcode (`⌘+B`) or `xcodebuild -project Steady.xcodeproj -scheme Steady build`
- **Run tests**: Use Xcode Test Navigator (`⌘+U`) or `xcodebuild test -project Steady.xcodeproj -scheme Steady`
- **Run on simulator**: Use Xcode (`⌘+R`) or `xcodebuild -project Steady.xcodeproj -scheme Steady -destination 'platform=iOS Simulator,name=iPhone 15'`

### Key Files for Development
- Unit tests are in `SteadyTests/SteadyTests.swift` but currently contain only placeholder tests
- UI tests are in `SteadyUITests/` but are not yet implemented
- Audio assets: `click_high.wav` and `click_low.wav` provide the metronome sounds

## Architecture

### Core Components
- **SteadyApp.swift**: Main app entry point, handles default registration
- **ContentView.swift**: Primary UI containing the metronome interface, tempo controls, and options
- **MetronomeViewModel.swift**: Core metronome logic using unified `AVAudioEngine` system for sample-accurate timing in both foreground and background
- **Defaults.swift**: UserDefaults key management with default values
- **BeatsPlayed.swift**: Enum defining which beats in a measure to play clicks on
- **BigButtonStyle.swift**: Custom button style for the main start/stop control

### Key Architecture Patterns
- **MVVM Pattern**: ContentView observes MetronomeViewModel using `@StateObject`
- **Unified Audio System**: Uses `AVAudioEngine` with `AVAudioPlayerNode` for sample-accurate timing in all app states
- **Background Audio Support**: Configured with `audio` background mode capability for uninterrupted operation
- **Cross-Platform**: Conditional compilation (`#if os(iOS)`) for platform-specific audio session management
- **State Persistence**: All user preferences automatically saved to UserDefaults
- **Separated Concerns**: Independent audio timing and UI updates for optimal performance

### Audio & Timing Implementation
The metronome uses a unified `AVAudioEngine` system for all timing scenarios:

#### Audio System Architecture:
- **AVAudioEngine**: Core audio processing engine that runs continuously
- **AVAudioPlayerNode**: Handles scheduled buffer playback for metronome clicks
- **Sample-Accurate Scheduling**: Uses `scheduleBuffer(at:)` with calculated `AVAudioTime` for precise timing
- **Audio Buffers**: Pre-loaded `AVAudioPCMBuffer` instances for high/low click sounds
- **Background Session**: Continuous silent audio buffers maintain active audio session when backgrounded

#### Timing Strategy:
- **Audio Timing**: `AVAudioEngine` provides sample-accurate scheduling (`60.0 / beatsPerMinute` converted to sample frames)
- **UI Timing**: Separate `DispatchSourceTimer` handles UI updates independently from audio
- **Background Compatibility**: Audio continues precisely when app is backgrounded or device is locked
- **No Mode Switching**: Same audio system operates in foreground and background for consistency

### Platform Differences
- **iOS**: Uses wheel picker style, number pad keyboard, and enhanced audio session configuration with background modes
  - Audio session category: `.playback` with `.mixWithOthers`, `.allowAirPlay`, `.allowBluetooth` options
  - Background audio capability: Enabled via `INFOPLIST_KEY_UIBackgroundModes = audio`
  - Supports AirPlay, Bluetooth, and background operation
- **macOS**: Uses default picker style, regular keyboard input, no background audio session setup needed
  - Background audio works automatically on macOS without special configuration

### State Management
All settings are persisted using UserDefaults with the Defaults struct providing centralized key management. The ViewModel automatically saves changes to tempo, beats per measure, accent settings, and beat patterns.

## Background Audio Implementation

### Configuration Requirements
- **Project Settings**: `INFOPLIST_KEY_UIBackgroundModes = audio` must be set in both Debug and Release configurations
- **Audio Session**: Enhanced configuration for background playbook compatibility
- **Continuous Audio**: Silent buffer scheduling maintains active audio session when backgrounded

### Key Implementation Details
- **Unified Architecture**: Single `AVAudioEngine` system handles all timing scenarios (no foreground/background switching)
- **Sample-Accurate Timing**: Audio scheduling uses precise sample time calculations for consistent beat intervals
- **Resource Management**: Proper engine lifecycle management with cleanup in `deinit`
- **Buffer Pre-loading**: Audio files loaded once into `AVAudioPCMBuffer` instances for immediate playbook
- **Silent Audio Track**: Continuous inaudible buffers keep audio session active for background operation

### Development Notes
- Background audio functionality works automatically once the app is properly configured
- No UI changes required - background operation is transparent to the user interface
- Audio timing remains precise regardless of app state (foreground, background, device locked)
- Compatible with other audio apps through `.mixWithOthers` audio session option
- Supports wireless audio devices (AirPlay, Bluetooth) in both foreground and background modes

### Testing Background Audio
1. Start the metronome in the app
2. Background the app (home button/gesture) or lock the device
3. Metronome should continue playing without interruption
4. Return to foreground - metronome continues seamlessly
5. Test with other audio apps running simultaneously to verify mixing behavior