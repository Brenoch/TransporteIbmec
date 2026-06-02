import SwiftUI

struct ContentView: View {
    @State private var nomeAlunoLogado = ""
    @State private var entrarNoApp = false

    var body: some View {
        NavigationView {
            ZStack {
                LoginAlunoView { nomeAluno in
                    nomeAlunoLogado = nomeAluno
                    entrarNoApp = true
                }

                NavigationLink(destination: AppPrincipalView(nomeAluno: nomeAlunoLogado), isActive: $entrarNoApp) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }
}

private struct AppPrincipalView: View {
    let nomeAluno: String

    var body: some View {
        TabView {
            MapaRotaView(nomeAluno: nomeAluno)
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }

            HomeAlunoView(nomeAluno: nomeAluno)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            CarteirinhaDigitalView()
                .tabItem {
                    Label("Carteirinha", systemImage: "person.text.rectangle")
                }
        }
        .tint(Color.primaryContainer)
    }
}

private struct LoginAlunoView: View {
    @State private var login = ""
    @State private var senha = ""
    @State private var mostrarSenha = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onLoginSuccess: (String) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.primaryContainer, Color.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                VStack(spacing: 10) {
                    Image(systemName: "bus.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#F5AC00"))

                    Text("ibmec")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Bem-vindo(a)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Acesse o app de transporte universitario")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.top, 40)

                Spacer()

                VStack(spacing: 16) {
                    Capsule()
                        .fill(Color(hex: "#F5AC00"))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)

                    Text("Entrar")
                        .font(.headline)
                        .foregroundColor(Color.primaryContainer)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Login Aluno")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("Digite seu login", text: $login)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Senha")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Group {
                                if mostrarSenha {
                                    TextField("Digite sua senha", text: $senha)
                                } else {
                                    SecureField("Digite sua senha", text: $senha)
                                }
                            }

                            Button(action: { mostrarSenha.toggle() }) {
                                Image(systemName: mostrarSenha ? "eye" : "eye.slash")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(Color.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: realizarLogin) {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text(isLoading ? "Entrando..." : "Entrar")
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.primaryContainer)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)

                    NavigationLink {
                        EsqueciSenhaView()
                    } label: {
                        Text("Esqueci minha senha")
                            .font(.subheadline)
                            .foregroundColor(Color.primaryContainer)
                    }

                    HStack(spacing: 4) {
                        Text("Nao tem conta?")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        NavigationLink {
                            CadastroAlunoView()
                        } label: {
                            Text("Criar cadastro")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.primaryContainer)
                        }
                    }

                    Spacer(minLength: 8)

                    Text("Ao entrar, voce concorda com os Termos de Uso e Politica de Privacidade.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 560)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func realizarLogin() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let response = try await AuthService.shared.loginAluno(login: login, senha: senha)
                await MainActor.run {
                    isLoading = false
                    if response.sucesso {
                        onLoginSuccess(login)
                    } else {
                        errorMessage = response.mensagem
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Nao foi possivel conectar ao servidor."
                }
            }
        }
    }
}
