import SwiftUI
import MapKit

struct MapaRotaView: View {
    let nomeAluno: String

    var body: some View {
        ZStack(alignment: .top) {
            RotaMapViewRepresentable()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                cabecalho
                Spacer()
                painelInferior
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 22)
        }
        .navigationBarHidden(true)
    }

    private var cabecalho: some View {
        HStack(spacing: 12) {
            Image(systemName: "bus")
                .font(.headline)
                .foregroundColor(.white)
                .padding(10)
                .background(Color(hex: "#F5AC00"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Rota de hoje")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Ola, \(nomeAluno.isEmpty ? "aluno" : nomeAluno)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Image(systemName: "clock.badge.checkmark")
                .font(.title3)
                .foregroundColor(.white)
        }
        .padding(14)
        .background(Color.primaryContainer.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var painelInferior: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Campus Centro -> Linha A")
                    .font(.headline)
                    .foregroundColor(Color.primaryContainer)
                Spacer()
                Text("8 min")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.successGreen)
            }

            HStack(spacing: 8) {
                Label("Proximo ponto: Praia de Botafogo", systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Label("ETA: 07:15", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: {}) {
                Label("Ver itinerario completo", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.secondaryFixed)
                    .foregroundColor(Color.primaryContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
}

private struct RotaMapViewRepresentable: UIViewRepresentable {
    private let origem = CLLocationCoordinate2D(latitude: -22.9537, longitude: -43.1823)
    private let destino = CLLocationCoordinate2D(latitude: -22.9412, longitude: -43.1928)

    private var rota: [CLLocationCoordinate2D] {
        [
            origem,
            CLLocationCoordinate2D(latitude: -22.9492, longitude: -43.1842),
            CLLocationCoordinate2D(latitude: -22.9465, longitude: -43.1882),
            destino
        ]
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = false

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -22.9474, longitude: -43.1876),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
        mapView.setRegion(region, animated: false)

        let polyline = MKPolyline(coordinates: rota, count: rota.count)
        mapView.addOverlay(polyline)

        let start = MKPointAnnotation()
        start.title = "Partida"
        start.coordinate = origem

        let end = MKPointAnnotation()
        end.title = "Destino"
        end.coordinate = destino

        mapView.addAnnotations([start, end])
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let route = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: route)
            renderer.strokeColor = UIColor(Color.primaryContainer)
            renderer.lineWidth = 5
            renderer.lineJoin = .round
            renderer.lineCap = .round
            return renderer
        }
    }
}
