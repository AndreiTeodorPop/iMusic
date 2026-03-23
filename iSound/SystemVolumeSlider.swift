import SwiftUI
import MediaPlayer

struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        // By default, MPVolumeView only shows the slider if we don't configure the route button
        let volumeView = MPVolumeView(frame: .zero)
        return volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
