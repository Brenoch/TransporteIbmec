import SwiftUI

struct EsqueciSenhaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var codigo = ""
    @State private var novaSenha = ""

    var body: some View {
        AuthScaffold {
            VStack(spacing: 6) {
                AuthBrandLogo()
                    .padding(.bottom, 6)

                Text("Recuperar senha")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Informe seu e-mail para receber o código")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        } content: {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Voltar para o login")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.ibmecBlue)
                    }
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.bottom, 24)

                VStack(spacing: 18) {
                    AuthField(label: "E-mail institucional (@ibmec.edu.br)", text: $email, keyboardType: .emailAddress)
                    AuthField(label: "Código de verificação", text: $codigo, keyboardType: .numberPad)
                    AuthField(label: "Nova senha", text: $novaSenha, isSecure: true)

                    AuthPrimaryButton(title: "Redefinir senha", action: {})
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }
}
