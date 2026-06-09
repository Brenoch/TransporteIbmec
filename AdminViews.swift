import SwiftUI

// MARK: - Util de formatação de horário

private let horaFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.dateFormat = "HH:mm"
    return f
}()

private func dataDeHorario(_ texto: String) -> Date {
    horaFormatter.date(from: texto) ?? Date()
}

// MARK: - Campo de formulário (estilo admin)

private struct AdminField: View {
    let titulo: String
    var placeholder: String = ""
    @Binding var texto: String
    var keyboard: UIKeyboardType = .default
    var secure: Bool = false

    @State private var revelado = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.ibmecText)

            HStack(spacing: 8) {
                Group {
                    if secure && !revelado {
                        SecureField(placeholder, text: $texto)
                    } else {
                        TextField(placeholder, text: $texto)
                    }
                }
                .font(.system(size: 15))
                .keyboardType(keyboard)
                .autocapitalization(secure ? .none : .sentences)
                .disableAutocorrection(secure)

                if secure {
                    Button(action: { revelado.toggle() }) {
                        Image(systemName: revelado ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    }
                    .accessibilityLabel(revelado ? "Ocultar senha" : "Mostrar senha")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.ibmecField)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.ibmecBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Header de admin reutilizável

private struct AdminHeader<Trailing: View>: View {
    let titulo: String
    var onVoltar: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            if let onVoltar = onVoltar {
                Button(action: onVoltar) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .padding(6)
                }
                .accessibilityLabel("Voltar")
            }

            Text(titulo)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color.ibmecBlue.ignoresSafeArea(edges: .top))
    }
}

// MARK: - Lista de Rotas (Home do admin)

struct AdminRotasView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var rotas: [Itinerario] = []
    @State private var carregando = true
    @State private var erro: String?
    @State private var busca = ""

    @State private var sheet: AdminSheet?
    @State private var paraExcluir: Itinerario?

    private enum AdminSheet: Identifiable {
        case criar
        case editar(Itinerario)
        case motorista

        var id: String {
            switch self {
            case .criar: return "criar"
            case .editar(let it): return "editar-\(it.id)"
            case .motorista: return "motorista"
            }
        }
    }

    private var rotasFiltradas: [Itinerario] {
        let q = busca.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return rotas }
        return rotas.filter { it in
            it.nome.lowercased().contains(q) || it.rotas.contains { $0.lowercased().contains(q) }
        }
    }

    private var ativas: Int { rotas.filter { !$0.suspensa }.count }
    private var suspensas: Int { rotas.filter { $0.suspensa }.count }

    var body: some View {
        ZStack(alignment: .top) {
            Color.ibmecBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                conteudo
            }

            botaoAdicionar
        }
        .task { await carregar() }
        .sheet(item: $sheet, onDismiss: { Task { await carregar() } }) { item in
            switch item {
            case .criar:
                AdminRotaFormView(original: nil)
            case .editar(let it):
                AdminRotaFormView(original: it)
            case .motorista:
                AdminMotoristaFormView()
            }
        }
        .confirmationDialog(
            "Remover \(paraExcluir?.nome ?? "rota")?",
            isPresented: Binding(get: { paraExcluir != nil }, set: { if !$0 { paraExcluir = nil } }),
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                if let it = paraExcluir { Task { await excluir(it) } }
            }
            Button("Cancelar", role: .cancel) { paraExcluir = nil }
        } message: {
            Text("Essa ação não pode ser desfeita.")
        }
    }

    // MARK: Header

    private var header: some View {
        AdminHeader(titulo: "Administração de Rotas") {
            HStack(spacing: 8) {
                Menu {
                    Button { sheet = .motorista } label: {
                        Label("Cadastrar motorista", systemImage: "person.badge.plus")
                    }
                    Button(role: .destructive) {
                        Task { await authManager.logout() }
                    } label: {
                        Label("Sair", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.white)
                        .padding(6)
                }
                .accessibilityLabel("Menu")
            }
        }
    }

    // MARK: Conteúdo

    @ViewBuilder
    private var conteudo: some View {
        if carregando {
            Spacer(); ProgressView().tint(.ibmecBlue); Spacer()
        } else if let erro = erro {
            estadoErro(erro)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    stats
                    busca_
                    if rotasFiltradas.isEmpty {
                        estadoVazio
                    } else {
                        ForEach(rotasFiltradas) { rota in
                            cardRota(rota)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 90)
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statCard(titulo: "ROTAS ATIVAS", valor: ativas, cor: .successGreen)
            statCard(titulo: "SUSPENSAS", valor: suspensas, cor: .error)
        }
    }

    private func statCard(titulo: String, valor: Int, cor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text("\(valor)")
                .font(.system(size: 26, weight: .black))
                .foregroundColor(cor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ibmecCardBorder, lineWidth: 1))
    }

    private var busca_: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Buscar rota...", text: $busca)
                .font(.system(size: 15))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if !busca.isEmpty {
                Button(action: { busca = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.ibmecCardBorder, lineWidth: 1))
    }

    private func cardRota(_ rota: Itinerario) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                statusPill(rota)
                Spacer()
                Text("\(rota.horarios.count) horários")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)
            }

            Text(rota.nome)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.ibmecBlue)

            VStack(alignment: .leading, spacing: 10) {
                pontoLinha(rotulo: "ORIGEM", valor: rota.rotas.first ?? "—", icone: "smallcircle.filled.circle", cor: .ibmecBlue)
                pontoLinha(rotulo: "DESTINO", valor: rota.rotas.last ?? "—", icone: "mappin.circle.fill", cor: .ibmecAccent)
            }

            HStack(spacing: 10) {
                Button(action: { sheet = .editar(rota) }) {
                    Label("Editar Rota", systemImage: "square.and.pencil")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.ibmecBlue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Menu {
                    Button { sheet = .editar(rota) } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button { Task { await alternarSuspensao(rota) } } label: {
                        Label(rota.suspensa ? "Reativar" : "Suspender",
                              systemImage: rota.suspensa ? "play.circle" : "pause.circle")
                    }
                    Button(role: .destructive) { paraExcluir = rota } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.ibmecBlue)
                        .frame(width: 44, height: 44)
                        .background(Color.ibmecSlateTint)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityLabel("Mais opções")
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.ibmecCardBorder, lineWidth: 1))
    }

    private func pontoLinha(rotulo: String, valor: String, icone: String, cor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icone)
                .foregroundColor(cor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(rotulo)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                Text(valor)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.ibmecText)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private func statusPill(_ rota: Itinerario) -> some View {
        let (texto, cor): (String, Color) = {
            if rota.suspensa { return ("SUSPENSA", .error) }
            if rota.emRota { return ("EM ROTA", .ibmecAccent) }
            return ("ATIVA", .successGreen)
        }()
        return Text(texto)
            .font(.system(size: 10, weight: .black))
            .foregroundColor(cor)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(cor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var estadoVazio: some View {
        VStack(spacing: 10) {
            Image(systemName: "bus").font(.system(size: 40)).foregroundColor(.gray.opacity(0.5))
            Text(busca.isEmpty ? "Nenhuma rota cadastrada" : "Nenhuma rota encontrada")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(.gray)
            if busca.isEmpty {
                Text("Toque em + para criar a primeira.")
                    .font(.system(size: 13)).foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func estadoErro(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundColor(.gray)
            Text(msg).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
            Button("Tentar de novo") { Task { await carregar() } }.foregroundColor(.ibmecBlue)
            Spacer()
        }
        .padding(32)
    }

    private var botaoAdicionar: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { sheet = .criar }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.ibmecBlue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .accessibilityLabel("Nova rota")
                .padding(20)
            }
        }
    }

    // MARK: Ações

    private func carregar() async {
        carregando = rotas.isEmpty
        erro = nil
        do {
            rotas = try await BackendService.shared.adminItinerarios()
        } catch {
            erro = error.localizedDescription
        }
        carregando = false
    }

    private func alternarSuspensao(_ rota: Itinerario) async {
        do {
            try await BackendService.shared.suspenderItinerario(id: rota.id, suspensa: !rota.suspensa)
            await carregar()
        } catch {
            erro = error.localizedDescription
        }
    }

    private func excluir(_ rota: Itinerario) async {
        paraExcluir = nil
        do {
            try await BackendService.shared.deletarItinerario(id: rota.id)
            await carregar()
        } catch {
            erro = error.localizedDescription
        }
    }
}

// MARK: - Formulário de Rota (criar / editar)

struct AdminRotaFormView: View {
    let original: Itinerario?
    @Environment(\.dismiss) private var dismiss

    @State private var nome = ""
    @State private var paradas: [String] = ["", ""]
    @State private var horarios: [Date] = [Date(), Date()]
    @State private var endereco = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var enderecoLocal = ""

    @State private var salvando = false
    @State private var erro: String?
    @State private var confirmarExclusao = false

    private var ehEdicao: Bool { original != nil }

    var body: some View {
        ZStack(alignment: .top) {
            Color.ibmecBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AdminHeader(titulo: ehEdicao ? "Editar Rota" : "Criar Nova Rota",
                            onVoltar: { dismiss() }) { EmptyView() }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        secaoBasica
                        secaoParadas
                        secaoHorarios
                        secaoLocalizacao
                        if let erro = erro { mensagemErro(erro) }
                        if ehEdicao { botaoRemover }
                        acoes
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear(perform: preencher)
        .confirmationDialog("Remover rota?", isPresented: $confirmarExclusao, titleVisibility: .visible) {
            Button("Excluir", role: .destructive) { Task { await remover() } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essa ação não pode ser desfeita.")
        }
    }

    // MARK: Seções

    private var secaoBasica: some View {
        cartao(titulo: "Informações Básicas", icone: "info.circle") {
            VStack(spacing: 12) {
                AdminField(titulo: "Nome da rota", placeholder: "Ex.: Linha Expressa Centro", texto: $nome)
                    .disabled(ehEdicao)
                    .opacity(ehEdicao ? 0.6 : 1)
                if ehEdicao {
                    Text("O nome identifica a rota e não pode ser alterado.")
                        .font(.system(size: 11)).foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var secaoParadas: some View {
        cartao(titulo: "Pontos de Parada", icone: "mappin.and.ellipse",
               acessorio: AnyView(botaoAdicionar(titulo: "Adicionar") { paradas.append("") })) {
            VStack(spacing: 10) {
                ForEach(paradas.indices, id: \.self) { idx in
                    HStack(spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Color.ibmecBlue)
                            .clipShape(Circle())
                        TextField(rotuloParada(idx), text: $paradas[idx])
                            .font(.system(size: 15))
                            .padding(.horizontal, 12).frame(height: 46)
                            .background(Color.ibmecField)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ibmecBorder, lineWidth: 1))
                        if paradas.count > 2 {
                            Button(action: { paradas.remove(at: idx) }) {
                                Image(systemName: "minus.circle.fill").foregroundColor(.error)
                            }
                            .accessibilityLabel("Remover parada")
                        }
                    }
                }
                Text("A 1ª é a origem e a última é o destino. Mínimo de 2.")
                    .font(.system(size: 11)).foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var secaoHorarios: some View {
        cartao(titulo: "Horários", icone: "clock",
               acessorio: AnyView(botaoAdicionar(titulo: "Adicionar") { horarios.append(Date()) })) {
            VStack(spacing: 10) {
                ForEach(horarios.indices, id: \.self) { idx in
                    HStack(spacing: 10) {
                        Image(systemName: "clock").foregroundColor(.ibmecBlue).frame(width: 26)
                        DatePicker("", selection: $horarios[idx], displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "pt_BR"))
                        Spacer()
                        if horarios.count > 2 {
                            Button(action: { horarios.remove(at: idx) }) {
                                Image(systemName: "minus.circle.fill").foregroundColor(.error)
                            }
                            .accessibilityLabel("Remover horário")
                        }
                    }
                    .padding(.horizontal, 12).frame(height: 46)
                    .background(Color.ibmecField)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ibmecBorder, lineWidth: 1))
                }
                Text("Deve ter a mesma quantidade de paradas. Mínimo de 2.")
                    .font(.system(size: 11)).foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var secaoLocalizacao: some View {
        cartao(titulo: "Localização inicial", icone: "location") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    AdminField(titulo: "Latitude", placeholder: "-22.9519", texto: $latitude, keyboard: .numbersAndPunctuation)
                    AdminField(titulo: "Longitude", placeholder: "-43.1836", texto: $longitude, keyboard: .numbersAndPunctuation)
                }
                AdminField(titulo: "Endereço de referência", placeholder: "Ex.: Av. Pres. Wilson, 118", texto: $endereco)
                AdminField(titulo: "Endereço da localização (opcional)", placeholder: "Ponto inicial do ônibus", texto: $enderecoLocal)
            }
        }
    }

    private var botaoRemover: some View {
        Button(action: { confirmarExclusao = true }) {
            Label("Remover Rota", systemImage: "trash")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(Color.error).foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var acoes: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Text("Cancelar")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundColor(.ibmecBlue)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ibmecHairline, lineWidth: 2))
            }
            Button(action: { Task { await salvar() } }) {
                HStack(spacing: 8) {
                    if salvando { ProgressView().tint(.white) }
                    Text(ehEdicao ? "Salvar Alterações" : "Salvar Rota")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(Color.ibmecAccent).foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(salvando)
        }
    }

    // MARK: Helpers de layout

    private func cartao<Content: View>(
        titulo: String,
        icone: String,
        acessorio: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(titulo, systemImage: icone)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.ibmecBlue)
                Spacer()
                if let acessorio = acessorio { acessorio }
            }
            content()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ibmecCardBorder, lineWidth: 1))
    }

    private func botaoAdicionar(titulo: String, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Label(titulo, systemImage: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.ibmecBlue)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.ibmecSlateTint)
                .clipShape(Capsule())
        }
    }

    private func rotuloParada(_ idx: Int) -> String {
        if idx == 0 { return "Origem" }
        if idx == paradas.count - 1 { return "Destino" }
        return "Parada \(idx + 1)"
    }

    private func mensagemErro(_ msg: String) -> some View {
        Text(msg)
            .font(.system(size: 13)).foregroundColor(.error)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Dados

    private func preencher() {
        guard let it = original else { return }
        nome = it.nome
        paradas = it.rotas.isEmpty ? ["", ""] : it.rotas
        horarios = it.horarios.isEmpty ? [Date(), Date()] : it.horarios.map(dataDeHorario)
        endereco = it.endereco ?? ""
        if let loc = it.localizacaoAtual {
            if let p = loc.local {
                latitude = String(p.latitude)
                longitude = String(p.longitude)
            }
            enderecoLocal = loc.endereco ?? ""
        }
    }

    private func salvar() async {
        erro = nil
        let paradasLimpas = paradas.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        guard !nome.trimmingCharacters(in: .whitespaces).isEmpty else {
            erro = "Informe o nome da rota."; return
        }
        guard paradasLimpas.count >= 2 else {
            erro = "Informe pelo menos 2 paradas (origem e destino)."; return
        }
        guard horarios.count >= 2 else {
            erro = "Informe pelo menos 2 horários."; return
        }
        guard paradasLimpas.count == horarios.count else {
            erro = "Paradas e horários devem ter a mesma quantidade (\(paradasLimpas.count) × \(horarios.count))."; return
        }
        guard let lat = Double(latitude.replacingOccurrences(of: ",", with: ".")),
              let lng = Double(longitude.replacingOccurrences(of: ",", with: ".")) else {
            erro = "Latitude e longitude devem ser números válidos."; return
        }

        let body = ItinerarioInput(
            nome: ehEdicao ? (original?.nome ?? nome) : nome.trimmingCharacters(in: .whitespaces),
            rotas: paradasLimpas,
            horarios: horarios.map { horaFormatter.string(from: $0) },
            endereco: endereco.trimmingCharacters(in: .whitespaces),
            localizacaoAtual: LocalizacaoInput(
                local: GeoPointInput(latitude: lat, longitude: lng),
                endereco: enderecoLocal.isEmpty ? nil : enderecoLocal
            )
        )

        salvando = true
        do {
            if let it = original {
                _ = try await BackendService.shared.atualizarItinerario(id: it.id, body: body)
            } else {
                _ = try await BackendService.shared.criarItinerario(body)
            }
            salvando = false
            dismiss()
        } catch {
            salvando = false
            erro = error.localizedDescription
        }
    }

    private func remover() async {
        guard let it = original else { return }
        do {
            try await BackendService.shared.deletarItinerario(id: it.id)
            dismiss()
        } catch {
            erro = error.localizedDescription
        }
    }
}

// MARK: - Cadastrar Motorista

struct AdminMotoristaFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var nome = ""
    @State private var cpf = ""
    @State private var senha = ""

    @State private var salvando = false
    @State private var erro: String?
    @State private var sucesso = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.ibmecBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AdminHeader(titulo: "Cadastrar Motorista", onVoltar: { dismiss() }) { EmptyView() }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        cartao
                        if let erro = erro {
                            Text(erro).font(.system(size: 13)).foregroundColor(.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        botaoSalvar
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert("Motorista cadastrado", isPresented: $sucesso) {
            Button("OK") { dismiss() }
        } message: {
            Text("\(nome) foi adicionado com sucesso.")
        }
    }

    private var cartao: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 26))
                    .foregroundColor(.ibmecBlue)
                    .frame(width: 64, height: 64)
                    .background(Color.ibmecSlateTint)
                    .clipShape(Circle())
                Text("Novo Motorista")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.ibmecBlue)
                Text("Insira os dados do motorista para registro no sistema.")
                    .font(.system(size: 13)).foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            VStack(spacing: 14) {
                AdminField(titulo: "Nome completo", placeholder: "Ex.: João da Silva", texto: $nome)
                AdminField(titulo: "CPF", placeholder: "Somente números (11 dígitos)", texto: $cpf, keyboard: .numberPad)
                AdminField(titulo: "Senha", placeholder: "Mínimo de 6 caracteres", texto: $senha, secure: true)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ibmecCardBorder, lineWidth: 1))
    }

    private var botaoSalvar: some View {
        Button(action: { Task { await salvar() } }) {
            HStack(spacing: 8) {
                if salvando { ProgressView().tint(.white) }
                Label("Cadastrar Motorista", systemImage: "checkmark.seal")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color.ibmecAccent).foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(salvando)
    }

    private func salvar() async {
        erro = nil
        let cpfLimpo = cpf.filter { $0.isNumber }
        guard !nome.trimmingCharacters(in: .whitespaces).isEmpty else {
            erro = "Informe o nome completo."; return
        }
        guard cpfLimpo.count == 11 else {
            erro = "O CPF deve ter 11 dígitos."; return
        }
        guard senha.count >= 6 else {
            erro = "A senha deve ter no mínimo 6 caracteres."; return
        }

        salvando = true
        do {
            _ = try await BackendService.shared.criarMotorista(
                cpf: cpfLimpo,
                nome: nome.trimmingCharacters(in: .whitespaces),
                senha: senha
            )
            salvando = false
            sucesso = true
        } catch {
            salvando = false
            erro = error.localizedDescription
        }
    }
}
