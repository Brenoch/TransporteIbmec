import SwiftUI

// MARK: - Shape

/// Retângulo com cantos arredondados apenas no topo (bottom-sheet do design Stitch).
struct TopRoundedRectangle: Shape {
    var radius: CGFloat = 36

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Logo

/// Marca "ibmec" com ícone de ônibus, igual ao header do login no Stitch.
struct AuthBrandLogo: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bus.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.ibmecAccent)

            Text("ibmec")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .tracking(0.5)
        }
    }
}

// MARK: - Campo com floating label

/// Campo de texto com rótulo flutuante (sobe quando preenchido), no estilo do design.
struct AuthField: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    @State private var revealed = false

    private var floating: Bool { !text.isEmpty }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 8) {
                Group {
                    if isSecure && !revealed {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.ibmecText)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.top, floating ? 14 : 0)

                if isSecure {
                    Button(action: { revealed.toggle() }) {
                        Image(systemName: revealed ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, floating ? 14 : 0)
                }
            }

            Text(label)
                .font(.system(size: floating ? 11 : 15))
                .foregroundColor(floating ? .ibmecBlue : Color.gray)
                .offset(y: floating ? -15 : 0)
                .animation(.easeInOut(duration: 0.15), value: floating)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.ibmecField)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.ibmecBorder, lineWidth: 1)
        )
    }
}

// MARK: - Botão primário

struct AuthPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(enabled ? Color.ibmecBlue : Color.ibmecBlue.opacity(0.4))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.ibmecBlue.opacity(0.3), radius: 10, y: 4)
        }
        .disabled(!enabled || isLoading)
    }
}

// MARK: - Abas Entrar / Cadastrar

enum AuthTab {
    case entrar, cadastrar
}

struct AuthTabs: View {
    let selected: AuthTab
    var onEntrar: () -> Void = {}
    var onCadastrar: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            tab(title: "Entrar", active: selected == .entrar, action: onEntrar)
            tab(title: "Cadastrar", active: selected == .cadastrar, action: onCadastrar)
        }
        .overlay(
            Rectangle()
                .fill(Color.ibmecBorder.opacity(0.6))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func tab(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 16, weight: active ? .bold : .medium))
                    .foregroundColor(active ? .ibmecBlue : Color.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 14)

                Rectangle()
                    .fill(active ? Color.ibmecAccent : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scaffold (fundo azul + header + bottom sheet branco)

struct AuthScaffold<Header: View, Content: View>: View {
    var headerTopPadding: CGFloat = 40
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.ibmecBlue.ignoresSafeArea()

            VStack(spacing: 0) {
                header()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, headerTopPadding)
                    .padding(.bottom, 28)

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.ibmecAccent)
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    content()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.white)
                .clipShape(TopRoundedRectangle(radius: 36))
                .shadow(color: .black.opacity(0.25), radius: 20, y: -6)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationBarHidden(true)
    }
}
