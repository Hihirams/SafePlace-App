import XCTest

final class SmokeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        return app
    }

    private func waitForHome(_ app: XCUIApplication) {
        // The centered serif wordmark lives on the Home header.
        XCTAssertTrue(app.staticTexts["SafePlace"].waitForExistence(timeout: 15))
    }

    /// Crea una nota a través de la UI y la guarda.
    private func createNote(_ app: XCUIApplication, text: String) {
        app.buttons["tab-create"].tap()
        let editor = app.textViews["create-text"]
        XCTAssertTrue(editor.waitForExistence(timeout: 8), "No se abrió el editor")
        editor.tap()
        editor.typeText(text)
        let save = app.buttons["create-save"]
        XCTAssertTrue(save.isEnabled, "Guardar debería habilitarse al escribir")
        save.tap()
    }

    func testAppLaunchesToHome() throws {
        waitForHome(launchApp())
    }

    func testTabBarIsReachable() throws {
        let app = launchApp()
        waitForHome(app)
        for id in ["tab-journal", "tab-mind", "tab-saved", "tab-create"] {
            XCTAssertTrue(app.buttons[id].exists, "Missing tab: \(id)")
        }
    }

    func testLanguageChangesWhileSettingsStayOpen() throws {
        let app = launchApp()
        waitForHome(app)
        app.buttons["home-avatar"].tap()

        let spanish = app.buttons["settings-language-es"]
        XCTAssertTrue(spanish.waitForExistence(timeout: 8))
        spanish.tap()
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 8))

        let english = app.buttons["settings-language-en"]
        if !english.isHittable { spanish.swipeLeft() }
        english.tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["settings-appearance-system"].exists)
        app.buttons["xmark"].tap()
        XCTAssertTrue(app.staticTexts["Home"].waitForExistence(timeout: 8))
    }

    func testCreatedNoteShowsUpOnHome() throws {
        let app = launchApp()
        waitForHome(app)
        let text = "Nota E2E \(Int(Date().timeIntervalSince1970))"
        createNote(app, text: text)
        XCTAssertTrue(app.staticTexts[text].firstMatch.waitForExistence(timeout: 10),
                      "La nota recién creada no aparece en Home")
    }

    func testStreakDetailOpensAndCloses() throws {
        let app = launchApp()
        waitForHome(app)
        let streak = app.buttons["home-streak"]
        XCTAssertTrue(streak.waitForExistence(timeout: 8), "No hay fila de racha en Home")
        streak.tap()
        let close = app.buttons["streak-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 8), "El detalle de la racha no se abrió")
        close.tap()
        XCTAssertTrue(streak.waitForExistence(timeout: 8), "El detalle no se cerró")
    }
}
