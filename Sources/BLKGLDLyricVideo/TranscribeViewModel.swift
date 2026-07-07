import Foundation
import WhisperKit

// Mirrors the desktop pipeline's speed lessons (pipeline/lyrics.mjs): whisper's
// default beam-size 5 / best-of 5 is a ~5x compute tax unrelated to model size.
// temperatureFallbackCount: 0 keeps decoding to a single greedy pass — the same
// fix that took desktop auto-transcribe from 6-14min down to ~3min.
final class TranscribeViewModel: ObservableObject {
    @Published var isModelReady = false
    @Published var isTranscribing = false
    @Published var elapsedSeconds = 0
    @Published var wordCount = 0
    @Published var lastError: String?

    private var whisperKit: WhisperKit?
    private var timer: Timer?
    private var startedAt: Date?

    func loadModel() async {
        DebugLog.shared.add("Loading WhisperKit (small.en)…")
        do {
            let config = WhisperKitConfig(model: "small.en")
            let kit = try await WhisperKit(config)
            await MainActor.run {
                self.whisperKit = kit
                self.isModelReady = true
            }
            DebugLog.shared.add("Model ready.")
        } catch {
            await MainActor.run { self.lastError = "Model load failed: \(error.localizedDescription)" }
            DebugLog.shared.add("ERROR loading model: \(error)")
        }
    }

    func transcribe(url: URL) async {
        guard let whisperKit else {
            DebugLog.shared.add("Transcribe called before model was ready.")
            return
        }
        await MainActor.run {
            self.isTranscribing = true
            self.wordCount = 0
            self.lastError = nil
        }
        startTimer()
        DebugLog.shared.add("Transcribing \(url.lastPathComponent)…")

        let startClock = Date()
        do {
            let options = DecodingOptions(
                wordTimestamps: true,
                withoutTimestamps: false,
                temperatureFallbackCount: 0
            )
            let results = try await whisperKit.transcribe(audioPath: url.path, decodeOptions: options)
            let words = results.flatMap { $0.segments.flatMap { $0.words ?? [] } }
            let elapsed = Date().timeIntervalSince(startClock)
            await MainActor.run { self.wordCount = words.count }
            DebugLog.shared.add("Done: \(words.count) words in \(String(format: "%.1f", elapsed))s")
        } catch {
            await MainActor.run { self.lastError = "Transcription failed: \(error.localizedDescription)" }
            DebugLog.shared.add("ERROR transcribing: \(error)")
        }

        stopTimer()
        await MainActor.run { self.isTranscribing = false }
    }

    private func startTimer() {
        startedAt = Date()
        Task { @MainActor in
            self.elapsedSeconds = 0
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let startedAt = self.startedAt else { return }
            let secs = Int(Date().timeIntervalSince(startedAt))
            Task { @MainActor in
                self.elapsedSeconds = secs
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
