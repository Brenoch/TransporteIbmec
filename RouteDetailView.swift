import SwiftUI
import MapKit
import UserNotifications

/// Detalhe de um itinerário (paradas + horários), no estilo "Route Detail" do Stitch.
struct RouteDetailView: View {
    let itinerario: Itinerario
    @Environment(\.dismiss) private var dismiss

    @State private var alertaAtivo = false
    @State private var mostrarShare = false
    @State private var itensShare: [Any] = []
    @State private var bus: LiveLocation?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -22.9519, longitude: -43.1836),
        latitudinalMeters: 1500, longitudinalMeters: 1500
    )

    private struct BusPin: Identifiable { let id = "bus"; let coordinate: CLLocationCoordinate2D }

    private var pins: [BusPin] {
        guard let b = bus, b.temPosicao else { return [] }
        return [BusPin(coordinate: CLLocationCoordinate2D(latitude: b.lat, longitude: b.lng))]
    }

    private var paradas: [(nome: String, horario: String?)] {
        itinerario.rotas.enumerated().map { idx, nome in
            (nome, idx < itinerario.horarios.count ? itinerario.horarios[idx] : nil)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#F8FAFC").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    mapaAoVivo
                    cardProximo
                    pontosDeParada
                    proximosHorarios
                    acoes
                }
                .padding(16)
                .padding(.top, 64)
                .padding(.bottom, 24)
            }

            header
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $mostrarShare) {
            ShareSheet(items: itensShare)
        }
        .task(id: itinerario.id) {
            while !Task.isCancelled {
                await atualizarLocalizacao()
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }

    // MARK: Mapa ao vivo

    private var mapaAoVivo: some View {
        ZStack(alignment: .topLeading) {
            Map(coordinateRegion: $region, annotationItems: pins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    Image(systemName: "bus.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.ibmecBlue)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 3)
                }
            }
            .frame(height: 220)

            statusAoVivo
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
    }

    private var statusAoVivo: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(bus?.temPosicao == true ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(bus?.temPosicao == true
                 ? "Ao vivo\(bus?.motoristaNome.map { " • \($0)" } ?? "")"
                 : "Ônibus não está em rota")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.ibmecBlue)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func atualizarLocalizacao() async {
        guard let loc = try? await BackendService.shared.liveLocation(itinerarioId: itinerario.id) else { return }
        bus = loc
        if loc.temPosicao {
            withAnimation {
                region.center = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.lng)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.white)
                    .padding(8)
            }
            Text(itinerario.nome)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color.ibmecBlue.ignoresSafeArea(edges: .top))
    }

    // MARK: Próximo embarque

    private var cardProximo: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("PRÓXIMO EMBARQUE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.ibmecBlue.opacity(0.7))
                        if itinerario.emRota {
                            Text("EM ROTA")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.ibmecBlue)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.ibmecBlue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text(proximoHorario)
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.ibmecBlue)
                }
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.ibmecBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
            .background(Color.ibmecAccent)

            if let endereco = itinerario.localizacaoAtual?.endereco ?? itinerario.endereco {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#F1F5F9"))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LOCALIZAÇÃO ATUAL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Text(endereco)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.ibmecBlue)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    // MARK: Pontos de parada

    private var pontosDeParada: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pontos de Parada")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.ibmecBlue)

            VStack(spacing: 10) {
                ForEach(Array(paradas.enumerated()), id: \.offset) { idx, parada in
                    let ehDestino = idx == paradas.count - 1
                    HStack(spacing: 14) {
                        Image(systemName: ehDestino ? "flag.fill" : "mappin.circle.fill")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(ehDestino ? Color(hex: "#1E293B") : Color.ibmecBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(parada.nome)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.ibmecBlue)
                                Spacer()
                                Text(idx == 0 ? "PARTIDA" : (ehDestino ? "DESTINO" : "PARADA"))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(idx == 0 ? .green : .gray)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background((idx == 0 ? Color.green : Color.gray).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            if let h = parada.horario {
                                Label(h, systemImage: "clock")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#EEF0F3"), lineWidth: 1))
                }
            }
        }
    }

    // MARK: Próximos horários

    private var proximosHorarios: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Próximos Horários", systemImage: "calendar")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.ibmecBlue)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(itinerario.horarios, id: \.self) { h in
                    let atual = h == proximoHorario
                    Text(h)
                        .font(.system(size: 12, weight: atual ? .black : .bold))
                        .foregroundColor(atual ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(atual ? Color.ibmecBlue : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#EEF0F3"), lineWidth: atual ? 0 : 1))
                }
            }
        }
    }

    // MARK: Ações

    private var acoes: some View {
        VStack(spacing: 12) {
            Button(action: alternarAlerta) {
                Label(alertaAtivo ? "Alerta Ativado ✓" : "Ativar Alerta de Chegada",
                      systemImage: alertaAtivo ? "checkmark.circle.fill" : "bell.badge")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(alertaAtivo ? Color.successGreen : Color.ibmecBlue).foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Button(action: compartilharRota) {
                Label("Compartilhar Rota", systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .foregroundColor(.ibmecBlue)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E2E8F0"), lineWidth: 2))
            }
        }
    }

    private func compartilharRota() {
        let origem = itinerario.rotas.first ?? "—"
        let destino = itinerario.rotas.last ?? "—"
        let texto = """
        \(itinerario.nome)
        De \(origem) até \(destino)
        Horários: \(itinerario.horarios.joined(separator: ", "))
        """
        itensShare = [texto]
        mostrarShare = true
    }

    private func alternarAlerta() {
        alertaAtivo.toggle()
        let center = UNUserNotificationCenter.current()
        let id = "alerta-\(itinerario.id)"
        if alertaAtivo {
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                let content = UNMutableNotificationContent()
                content.title = "Ônibus a caminho"
                content.body = "Seu ônibus está chegando — \(itinerario.nome)"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [id])
        }
    }

    // MARK: Helpers

    private var proximoHorario: String {
        guard !itinerario.horarios.isEmpty else { return "--:--" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let agora = fmt.string(from: Date())
        return itinerario.horarios.first { $0 >= agora } ?? itinerario.horarios[0]
    }
}
