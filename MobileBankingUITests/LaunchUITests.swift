import XCTest

final class LaunchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// No language argument: the app must start in Czech, whatever the simulator language is.
    func testAppStartsInCzechByDefault() {
        let app = launchApp()

        let title = app.staticTexts["login.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Přihlášení")
        attachScreenshot(named: "login-default")
    }

    func testCzechLightTheme() {
        let app = launchApp(language: "cs", appearance: "light")

        let title = app.staticTexts["login.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Přihlášení")
        attachScreenshot(named: "login-cs-light")
    }

    func testEnglishDarkTheme() {
        let app = launchApp(language: "en", appearance: "dark")

        let title = app.staticTexts["login.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Sign in")
        attachScreenshot(named: "login-en-dark")
    }
}
