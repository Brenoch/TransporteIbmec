import SwiftUI

struct CadastroAlunoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager

    @State private var nome = ""
    @State private var email = ""
    @State private var matricula = ""
    @State private var documento = ""
    @State private var tipoDocumento = "CPF"
    @State private var senha = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let tiposDocumento = ["CPF", "Passaporte"]

    var body: some View {
        AuthScaffold {
            VStack(spacing: 6) {
                AuthBrandLogo()
                    .padding(.bottom, 6)

                Text("Criar conta")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Preencha os dados para solicitar acesso")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        } content: {
            VStack(spacing: 0) {
                AuthTabs(
                    selected: .cadastrar,
                    onEntrar: { dismiss() },
                    onCadastrar: {}
                )
                .padding(.top, 20)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        AuthField(label: "Nome completo", text: $nome)
                        AuthField(label: "E-mail", text: $email, keyboardType: .emailAddress)
                        AuthField(label: "Matrícula", text: $matricula, keyboardType: .numberPad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tipo de documento")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Picker("Tipo de documento", selection: $tipoDocumento) {
                                ForEach(tiposDocumento, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        AuthField(label: tipoDocumento, text: $documento)
                        AuthField(label: "Senha", text: $senha, isSecure: true)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        AuthPrimaryButton(
                            title: isLoading ? "Enviando..." : "Finalizar cadastro",
                            isLoading: isLoading,
                            enabled: camposValidos,
                            action: realizarCadastro
                        )
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private var camposValidos: Bool {
        !nome.isEmpty && !email.isEmpty && !matricula.isEmpty && !documento.isEmpty && !senha.isEmpty
    }

    private func realizarCadastro() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await authManager.register(
                    matricula: matricula,
                    senha: senha,
                    nome: nome,
                    email: email,
                    documento: documento,
                    tipoDocumento: tipoDocumento
                )
                // Sucesso: volta para o login.
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
