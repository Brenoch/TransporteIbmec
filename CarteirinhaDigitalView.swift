import SwiftUI
import CoreImage.CIFilterBuiltins

struct CarteirinhaDigitalView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var perfil: MeResponse?
    @State private var carregando = true
    @State private var erro: String?

    var body: some View {
        ZStack {
            Color.surface.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                header
                conteudo
            }
        }
        .task { await carregar() }
    }

    private var header: some View {
        Text("Carteirinha Digital")
            .font(.headline).bold()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.ibmecBlue)
    }

    @ViewBuilder
    private var conteudo: some View {
        if carregando {
            Spacer(); ProgressView().tint(.ibmecBlue); Spacer()
        } else if let erro = erro {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundColor(.gray)
                Text(erro).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
                Button("Tentar de novo") { Task { await carregar() } }
                    .foregroundColor(.ibmecBlue)
                Spacer()
            }
            .padding(32)
        } else if let perfil = perfil {
            ScrollView { cartao(perfil) }
        }
    }

    private func cartao(_ perfil: MeResponse) -> some View {
        VStack(spacing: 22) {
            Spacer().frame(height: 20)

            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(LinearGradient(colors: [Color.ibmecBlue, Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 130, height: 130)
                        .overlay(
                            Text(iniciais(perfil.nome))
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 8)

                    Text(perfil.emailVerificado ? "ATIVO" : "PENDENTE")
                        .font(.caption2).bold()
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(perfil.emailVerificado ? Color.successGreen : Color.ibmecAccent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Text(perfil.nome)
                    .font(.title2).bold()
                    .foregroundColor(.ibmecBlue)

                Text("Matrícula: \(perfil.matricula)")
                    .font(.subheadline).foregroundColor(.gray)

                Text(perfil.tipo.capitalized)
                    .font(.subheadline).foregroundColor(.gray)
            }

            VStack(spacing: 16) {
                Group {
                    if let qr = qrImage(from: perfil.matricula) {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                    } else {
                        Image(systemName: "qrcode").resizable().foregroundColor(.ibmecBlue)
                    }
                }
                .frame(width: 180, height: 180)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 5)

                Text("ID: \(perfil.matricula)")
                    .font(.caption).foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Image(systemName: "bus.fill").foregroundColor(.ibmecBlue)
                    Rectangle().frame(width: 1, height: 12).foregroundColor(.gray.opacity(0.4))
                    Text("Ibmec Scholar ID").font(.caption).foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.secondaryFixed)
            .cornerRadius(24)

            VStack(spacing: 12) {
                Button(action: {}) {
                    Label("Compartilhar", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.ibmecBlue).foregroundColor(.white).cornerRadius(12)
                }
                Button(action: {}) {
                    Label("Baixar Offline", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color(hex: "#D7E2FF")).foregroundColor(.ibmecBlue).cornerRadius(12)
                }
            }

            Spacer().frame(height: 20)

            Button(action: { Task { await authManager.logout() } }) {
                Label("Sair da Conta", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.error)
                    .padding(.bottom, 40)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Dados

    private func carregar() async {
        carregando = true
        erro = nil
        do {
            perfil = try await BackendService.shared.me()
        } catch {
            erro = error.localizedDescription
        }
        carregando = false
    }

    private func iniciais(_ nome: String) -> String {
        let partes = nome.split(separator: " ")
        let primeiras = partes.prefix(2).compactMap { $0.first }
        return String(primeiras).uppercased()
    }

    private func qrImage(from text: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cg = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
