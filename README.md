Steady
======

Simple metronome app for iOS and macOS, implemented using SwiftUI.

Click sounds from <https://freesound.org/people/lennartgreen/packs/31848/>


## Known Issues

- iOS
   - While metronome is running, the beats-per-minute picker wheel can't be scrolled, due to the way that SwiftUI updates the screen when the beat indicator moves.
   - The first time the tempo entry keypad is displayed, the text field will lose focus when the first key is pressed.  After that, focus works correctly every time the keypad is shown.
- macOS
   - UI works, but doesn't look like a macOS app should
   - Timing is inconsistent


## To-Do

- Design app icon
- Add a watchOS target
- Add unit tests and UI tests
- Allow user to save and recall settings as Favorites
- Home screen widget
- Shortcuts support
- AppleScript support
- Internationalization
