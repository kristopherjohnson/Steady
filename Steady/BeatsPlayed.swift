import Foundation

/// Specifies which beats of a measure to play a click on.
enum BeatsPlayed: String, CaseIterable, Identifiable {
    case all = "All beats"
    case odd = "Odd beats"
    case even = "Even beats"
    
    var id: String { self.rawValue }
}
