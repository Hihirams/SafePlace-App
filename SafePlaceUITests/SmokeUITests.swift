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

    func testAppLaunchesToHome() throws {
        let app = launchApp()
        // The centered serif wordmark lives on the Home header.
        XCTAssertTrue(app.staticTexts["SafePlace"].waitForExistence(timeout: 15))
    }

    func testTabBarIsReachable() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["SafePlace"].waitForExistence(timeout: 15))
        for id in ["tab-journal", "tab-mind", "tab-saved", "tab-create"] {
            XCTAssertTrue(app.buttons[id].exists, "Missing tab: \(id)")
        }
    }
}
