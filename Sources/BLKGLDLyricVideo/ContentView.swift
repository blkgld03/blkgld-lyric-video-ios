import SwiftUI
import UniformTypeIdentifiers

private let bg = Color(red: 0.012, green: 0.051, blue: 0.027) // #030D07
private let gold = Color(red: 0.831, green: 0.686, blue: 0.216) // #D4AF37

struct ContentView: View {
    @StateObject private var vm = TranscribeViewModel()
    @ObservedObject private var log = DebugLog.shared
    @State private var showPicker = false
    @State private var pickedURL: URL?

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 16) {
                header

                if !vm.isModelReady {
                    ProgressView("Loading whisper model…")
                        .tint(.white)
                        .foregroundColor(.white)
                        .padding(.top, 24)
                } else {
                    controls
                }

                Divider().background(Color.gray.opacity(0.4))

                debugLogView
            }
            .padding(.top, 8)
        }
        .fileImporter(
            isPresented: $showPicker,
            // `.audio` alone can be too strict in the Files picker for some real-world
            // files (greys them out even when the format is standard) — list common
            // audio UTTypes explicitly, plus `.audio` as a catch-all.
            allowedContentTypes: [.audio, .mp3, .wav, .aiff, .mpeg4Audio]
        ) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    pickedURL = url
                    DebugLog.shared.add("Picked: \(url.lastPathComponent)")
                } else {
                    DebugLog.shared.add("ERROR: could not access picked file (security scope)")
                }
            case .failure(let error):
                DebugLog.shared.add("Picker error: \(error)")
            }
        }
        .task {
            await vm.loadModel()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Circle().fill(gold).frame(width: 10, height: 10)
                Text("BLKGLD").font(.system(size: 13, weight: .black)).tracking(3).foregroundColor(.white)
            }
            Text("Phase 1 · on-device transcription")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(gold)
        }
        .padding(.top, 40)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                showPicker = true
            } label: {
                Text(pickedURL?.lastPathComponent ?? "Pick a song")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(gold)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)

            Button {
                guard let pickedURL else { return }
                Task { await vm.transcribe(url: pickedURL) }
            } label: {
                HStack(spacing: 8) {
                    if vm.isTranscribing {
                        ProgressView().tint(.black)
                    }
                    Text(vm.isTranscribing ? "Transcribing… \(vm.elapsedSeconds)s" : "Transcribe")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(pickedURL == nil ? Color.gray : gold)
                .cornerRadius(12)
            }
            .disabled(pickedURL == nil || vm.isTranscribing)
            .padding(.horizontal, 24)

            if vm.wordCount > 0 {
                Text("✓ \(vm.wordCount) words in \(vm.elapsedSeconds)s")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(gold)
            }
            if let err = vm.lastError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var debugLogView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DEBUG LOG")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(log.lines.enumerated()), id: \.offset) { idx, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                                .id(idx)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                }
                .onChange(of: log.lines.count) { newCount in
                    if newCount > 0 {
                        proxy.scrollTo(newCount - 1, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.bottom, 12)
    }
}

#Preview {
    ContentView()
}
