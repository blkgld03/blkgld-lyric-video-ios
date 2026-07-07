import Foundation

// There is no attached debugger in the GitHub-Actions-CI + sideload workflow this
// project builds through — every crash or silent failure without on-screen logging
// costs a blind ~15min rebuild-and-resideload cycle. This is the single log all
// screens write to, rendered live in ContentView.
//
// Deliberately NOT @MainActor: `add()` can be called from any context (background
// WhisperKit callbacks included) without forcing `await` at every call site — it
// just hops to main internally before mutating the published property.
final class DebugLog: ObservableObject {
    static let shared = DebugLog()

    @Published private(set) var lines: [String] = []

    func add(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        DispatchQueue.main.async {
            self.lines.append("[\(timestamp)] \(message)")
            if self.lines.count > 500 {
                self.lines.removeFirst(self.lines.count - 500)
            }
        }
    }
}
