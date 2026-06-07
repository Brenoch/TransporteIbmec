import SwiftUI

struct HomeAlunoView: View {
    let nomeAluno: String

    @State private var filtroSelecionado = "Todas"
    @State private var mostrarMenu = false

    private let filtros = ["Todas", "SP - Barra Funda", "RJ - Centro"]

    var body: some View {
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
        .sheet(isPresented: $mostrarMenu) {
            MenuLateralView(nomeAluno: nomeAluno)
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
                    Text("TRANSPORTE")
                        .italic()
                        .font(.system(size: 17, weight: .bold))
                    Text("]")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.ibmecAccent)
                    Text("ibmec")
                        .font(.system(size: 17, weight: .bold))
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

    // MARK: Banner

    private var bannerAlerta: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color.ibmecBlue, Color(hex: "#003B8A")],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(spacing: 4) {
                Image(systemName: "bell.fill").font(.system(size: 11))
                Text("ALERTA").font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
            .padding(16)

            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                Text("Atenção Passageiros")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Mudança na rota do Campus Barra nesta sexta-feira devido a obras na via.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filtros, id: \.self) { filtro in
                        chip(filtro)
                    }
                }
            }

            VStack(spacing: 12) {
                rotaCard(titulo: "IBMEC → Botafogo", origem: "RJ - Centro", horario: "14:30", ativo: true)
                rotaCard(titulo: "IBMEC → Barra", origem: "RJ - Barra", horario: "18:00", ativo: false)
            }
        }
    }

    private func chip(_ texto: String) -> some View {
        let ativo = filtroSelecionado == texto
        return Button(action: { filtroSelecionado = texto }) {
            Text(texto)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ativo ? .white : Color.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ativo ? Color.ibmecBlue : Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(ativo ? Color.clear : Color(hex: "#E5E7EB"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func rotaCard(titulo: String, origem: String, horario: String, ativo: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ativo ? Color.green.opacity(0.15) : Color(hex: "#F3F4F6"))
                Image(systemName: "bus.fill")
                    .foregroundColor(ativo ? .green : Color.gray)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(titulo)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.ibmecText)
                    Circle()
                        .fill(ativo ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }
                Text("Origem: \(origem)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(horario)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ativo ? .ibmecBlue : Color.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ativo ? Color.ibmecAccent : Color(hex: "#E5E7EB"))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                if ativo {
                    Text("PRÓXIMO")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.ibmecAccent)
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#F0F0F0"), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

// MARK: - Menu lateral (drawer)

private struct MenuLateralView: View {
    let nomeAluno: String
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
                .padding(.vertical, 16)
                .padding(.horizontal, 12)

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

                Button(action: { dismiss() }) {
                    HStack {
                        Spacer()
                        Label("Sair da conta", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
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
                .font(.system(size: 56))
                .foregroundColor(.white)
                .overlay(Circle().stroke(Color.ibmecAccent, lineWidth: 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(nomeAluno.isEmpty ? "Aluno Ibmec" : nomeAluno)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("RA: 2023010542")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .padding(.top, 16)
        .background(Color.ibmecBlue)
    }

    private func secao(_ titulo: String) -> some View {
        Text(titulo)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.gray)
            .tracking(1)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    private func item(icone: String, titulo: String, subtitulo: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icone)
                .font(.system(size: 20))
                .foregroundColor(.ibmecBlue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(titulo)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.ibmecBlue)
                Text(subtitulo)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
