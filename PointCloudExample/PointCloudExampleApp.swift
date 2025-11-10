import SwiftUI
import ARKit

struct UIViewWrapper<V: UIView>: UIViewRepresentable {
    let view: UIView

    func makeUIView(context: Context) -> some UIView { view }
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

@main
struct PointCloudExampleApp: App {
    @StateObject var arManager = ARManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(arManager)
                .ignoresSafeArea()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var arManager: ARManager

    var body: some View {
        ZStack(alignment: .bottom) {
            UIViewWrapper(view: arManager.sceneView)

            VStack {
                Spacer()
                HStack {
                    Button(action: { arManager.isCapturing ? arManager.stopCapturing() : arManager.startCapturing() }) {
                        Text(arManager.isCapturing ? "Stop" : "Capture")
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        Task {
                            let ply = await arManager.exportPLY()
                            // For now we print the PLY content - you'll likely want to write to a file in a real app
                            print(ply.prefix(1000))
                        }
                    }) {
                        Text("Export PLY")
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { Task { await arManager.clearCaptured() } }) {
                        Text("Clear")
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

            }
        }
    }
}
