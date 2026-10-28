import XCTest

/// Navega pelo app e salva capturas de tela. Usado só no CI (substitui Tests_iOS.swift
/// na cópia de trabalho do runner, sem alterar o repositório).
final class Tests_iOS: XCTestCase {

    private let outDir = "/tmp/shots"

    override func setUpWithError() throws {
        continueAfterFailure = true
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    }

    private func shot(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// `tipo == nil` abre o app deslogado; com tipo, injeta a sessão pelos argumentos de lançamento
    /// (o UserDefaults lê `-chave valor` automaticamente).
    private func launch(tipo: String?) -> XCUIApplication {
        let app = XCUIApplication()
        if let tipo = tipo {
            app.launchArguments = [
                "-auth.idToken", "demo-token",
                "-auth.refreshToken", "demo-refresh",
                "-auth.tipoUsuario", tipo,
                "-auth.nome", "Breno Chaves",
                "-auth.uid", "demo-uid",
            ]
        }
        app.launch()
        return app
    }

    private func routeCard(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "→")).firstMatch
    }

    func test1Login() throws {
        _ = launch(tipo: nil)
        sleep(3)
        shot("00-login")
    }

    func test2HomeERota() throws {
        let app = launch(tipo: "aluno")
        let card = routeCard(app)
        XCTAssertTrue(card.waitForExistence(timeout: 20), "lista de rotas nao apareceu")
        sleep(1)
        shot("01-home")

        if card.exists {
            card.tap()
            sleep(6) // tempo para o mapa carregar
            shot("02-rota")
        }
    }

    func test3Carteirinha() throws {
        let app = launch(tipo: "aluno")
        _ = routeCard(app).waitForExistence(timeout: 20)
        let tab = app.tabBars.buttons["Carteirinha"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "aba Carteirinha nao encontrada")
        tab.tap()
        sleep(3)
        shot("03-carteirinha")
    }

    func test4Admin() throws {
        _ = launch(tipo: "adm")
        sleep(6)
        shot("04-admin")
    }
}
