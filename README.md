Steady
======

Simple metronome app for iOS and macOS, implemented using SwiftUI.

Click sounds from <https://freesound.org/people/lennartgreen/packs/31848/>


## Known Issues

- iOS
   - While metronome is running, the beats-per-minute popup menu can't be scrolled, due to the way that SwiftUI updates the screen when the beat indicator moves.
- macOS
   - UI works, but doesn't look like a macOS app should
   - Timing is inconsistent


## To-Do

- Design app icon
- Add a watchOS target
- Add numeric-keypad entry screen for beats-per-minute
- Allow user to save and recall settings as Favorites
- Home screen widget
- Shortcuts support
- AppleScript support
- Internationalization
