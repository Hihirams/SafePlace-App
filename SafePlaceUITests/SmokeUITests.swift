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
        XCTAssertTrue(app.staticTexts[text].firstMatch.waitForExistence(timeout: 10),
                      "La nota recién creada no aparece en Home")
    }
}
