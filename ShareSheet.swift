import SwiftUI
import UIKit

/// Envolve UIActivityViewController para compartilhar texto/imagens (iOS 15-safe).
/// Apresente via `.sheet(isPresented:)`. Não use ShareLink (iOS 16).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
