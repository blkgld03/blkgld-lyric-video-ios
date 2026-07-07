import SwiftUI

// Phase 0: prove the CI -> unsigned IPA -> sideload pipeline works.
// Deliberately minimal — no app logic yet. If this screen shows up on the
// phone after sideloading, the pipeline is proven and Phase 1 can start.
struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 0.012, green: 0.051, blue: 0.027) // BLKGLD dark bg (#030D07)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Circle()
                    .fill(Color(red: 0.831, green: 0.686, blue: 0.216)) // #D4AF37 gold
                    .frame(width: 12, height: 12)
                Text("BLKGLD")
                    .font(.system(size: 14, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white)
                Text("Phase 0: pipeline proven ✓")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.831, green: 0.686, blue: 0.216))
                Text("CI build → unsigned IPA → sideload")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ContentView()
}
