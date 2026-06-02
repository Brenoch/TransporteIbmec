import SwiftUI

struct EsqueciSenhaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var codigo = ""
    @State private var novaSenha = ""

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(Color.primaryContainer)

                Text("Esqueci minha senha")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryContainer)

                Text("Informe seu e-mail institucional para receber o codigo de recuperacao")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("E-mail")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("nome@aluno.ibmec.edu.br", text: $email)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.secondaryFixed, lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Codigo")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("000000", text: $codigo)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.secondaryFixed, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Nova senha")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SecureField("Digite a nova senha", text: $novaSenha)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.secondaryFixed, lineWidth: 1)
                        )
                }

                Button(action: {}) {
                    Text("Redefinir senha")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryContainer)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Recuperacao")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.primaryContainer)
                }
            }
        }
    }
}
