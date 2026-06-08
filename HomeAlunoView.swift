import SwiftUI

struct HomeAlunoView: View {
    let nomeAluno: String

    @EnvironmentObject private var authManager: AuthManager

    @State private var itinerarios: [Itinerario] = []
    @State private var carregando = true
    @State private var erro: String?
    @State private var mostrarMenu = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(hex: "#F3F4F6").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        bannerAlerta
                        rotasDeHoje
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 80)
                    .padding(.bottom, 24)
                }

                header
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .task { await carregar() }
        .sheet(isPresented: $mostrarMenu) {
            MenuLateralView(nomeAluno: nomeAluno, authManager: authManager)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.ibmecAccent)
                HStack(spacing: 4) {
                    Text("TRANSPORTE").italic().font(.system(size: 17, weight: .bold))
                    Text("]").font(.system(size: 20, weight: .light)).foregroundColor(.ibmecAccent)
                    Text("ibmec").font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
            }
            Spacer()
            Button(action: { mostrarMenu = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24))
                    .foregroundColor(.ibmecAccent)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(Color.ibmecBlue.ignoresSafeArea(edges: .top))
    }

    // MARK: Banner (estático — não há fonte no backend)

    private var bannerAlerta: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: [Color.ibmecBlue, Color(hex: "#003B8A")], startPoint: .leading, endPoint: .trailing)

            HStack(spacing: 4) {
                Image(systemName: "bell.fill").font(.system(size: 11))
                Text("ALERTA").font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color.white.opacity(0.2)).clipShape(Capsule())
            .padding(16)

            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                Text("Atenção Passageiros")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("Acompanhe os horários e a posição das rotas em tempo real.")
                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.8)).lineLimit(2)
            }
            .padding(16)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    // MARK: Rotas

    private var rotasDeHoje: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rotas de Hoje")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.ibmecBlue)

            if carregando {
                ProgressView().tint(.ibmecBlue).frame(maxWidth: .infinity).padding(.vertical, 30)
            } else if let erro = erro {
                estadoVazio(icone: "wifi.exclamationmark", texto: erro, comRetry: true)
            } else if itinerarios.isEmpty {
                estadoVazio(icone: "bus", texto: "Nenhuma rota disponível agora.", comRetry: false)
            } else {
                VStack(spacing: 12) {
                    ForEach(itinerarios) { it in
                        NavigationLink(destination: RouteDetailView(itinerario: it)) {
                            rotaCard(it)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func estadoVazio(icone: String, texto: String, comRetry: Bool) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icone).font(.largeTitle).foregroundColor(.gray)
            Text(texto).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
            if comRetry {
                Button("Tentar de novo") { Task { await carregar() } }.foregroundColor(.ibmecBlue)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 24)
    }

    private func rotaCard(_ it: Itinerario) -> some View {
        let origem = it.rotas.first ?? "—"
        let destino = it.rotas.last ?? "—"
        return HStack(spacing: 16) {
            ZStack {
                Circle().fill(it.emRota ? Color.green.opacity(0.15) : Color(hex: "#F3F4F6"))
                Image(systemName: "bus.fill").foregroundColor(it.emRota ? .green : .gray)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("\(origem) → \(destino)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.ibmecText)
                        .lineLimit(1)
                    Circle().fill(it.emRota ? Color.green : Color.gray).frame(width: 8, height: 8)
                }
                Text(it.nome)
                    .font(.system(size: 12)).foregroundColor(.gray).lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(proximoHorario(it.horarios))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(it.emRota ? .ibmecBlue : .gray)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(it.emRota ? Color.ibmecAccent : Color(hex: "#E5E7EB"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                if it.emRota {
                    Text("EM ROTA").font(.system(size: 9, weight: .medium)).foregroundColor(.ibmecAccent)
                }
            }

            Image(systemName: "chevron.right").foregroundColor(Color.gray.opacity(0.6))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#F0F0F0"), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: Dados

    private func carregar() async {
        carregando = true
        erro = nil
        do {
            itinerarios = try await BackendService.shared.itinerarios()
        } catch {
            erro = error.localizedDescription
        }
        carregando = false
    }

    private func proximoHorario(_ horarios: [String]) -> String {
        guard !horarios.isEmpty else { return "--:--" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let agora = fmt.string(from: Date())
        return horarios.first { $0 >= agora } ?? horarios[0]
    }
}

// MARK: - Menu lateral (drawer)

private struct MenuLateralView: View {
    let nomeAluno: String
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                cabecalho

                VStack(alignment: .leading, spacing: 4) {
                    item(icone: "person.text.rectangle", titulo: "Carteirinha", subtitulo: "Acesso rápido ao transporte")
                    item(icone: "clock", titulo: "Horários", subtitulo: "Tabela completa de partidas")
                    item(icone: "mappin.and.ellipse", titulo: "Pontos de Embarque", subtitulo: "Veja os locais no mapa")
                }
                .padding(.vertical, 16).padding(.horizontal, 12)

                secao("SERVIÇOS ACADÊMICOS")
                VStack(alignment: .leading, spacing: 4) {
                    item(icone: "graduationcap", titulo: "SAVA", subtitulo: "Disciplinas e materiais")
                    item(icone: "desktopcomputer", titulo: "SIA", subtitulo: "Portal de serviços integrados")
                }
                .padding(.horizontal, 12)

                secao("AJUDA E SUPORTE")
                VStack(alignment: .leading, spacing: 4) {
                    item(icone: "questionmark.circle", titulo: "Central de Ajuda", subtitulo: "Perguntas frequentes")
                }
                .padding(.horizontal, 12)

                Divider().padding(.vertical, 12)

                Button(action: { Task { await authManager.logout() } }) {
                    HStack {
                        Spacer()
                        Label("Sair da conta", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 56)).foregroundColor(.white)
                .overlay(Circle().stroke(Color.ibmecAccent, lineWidth: 2))

            Text(nomeAluno.isEmpty ? "Aluno Ibmec" : nomeAluno)
                .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24).padding(.top, 16)
        .background(Color.ibmecBlue)
    }

    private func secao(_ titulo: String) -> some View {
        Text(titulo)
            .font(.system(size: 11, weight: .bold)).foregroundColor(.gray).tracking(1)
            .padding(.horizontal, 24).padding(.top, 8)
    }

    private func item(icone: String, titulo: String, subtitulo: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icone).font(.system(size: 20)).foregroundColor(.ibmecBlue).frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(titulo).font(.system(size: 14, weight: .semibold)).foregroundColor(.ibmecBlue)
                Text(subtitulo).font(.system(size: 11)).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
    }
}
