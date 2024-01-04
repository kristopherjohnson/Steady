import SwiftUI

@main
struct SteadyApp: App {
    init() {
        Defaults.registerDefaults()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 400)
        }
    }
}
