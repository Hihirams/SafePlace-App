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

    func testCreatedNoteShowsUpOnHome() throws {
        let app = launchApp()
        waitForHome(app)
        let text = "Nota E2E \(Int(Date().timeIntervalSince1970))"
        createNote(app, text: text)
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 10),
                      "La nota recién creada no aparece en Home")
    }

    func testDeletingAsksForConfirmationFirst() throws {
        let app = launchApp()
        waitForHome(app)
        let text = "Borrar E2E \(Int(Date().timeIntervalSince1970))"
        createNote(app, text: text)
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 10))

        let menu = app.buttons["Note options"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 8), "No hay menú de opciones en la tarjeta")
        menu.tap()

        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()

        // Primero confirma: la nota sigue visible y aparece Cancelar.
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "No apareció la confirmación de borrado")
        cancel.tap()
        XCTAssertTrue(app.staticTexts[text].exists, "La nota se borró sin confirmar")
    }
}
