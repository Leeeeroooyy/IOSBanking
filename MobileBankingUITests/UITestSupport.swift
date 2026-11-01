import XCTest

extension XCTestCase {
    /// Every launch starts clean: no users, no session, default settings (see `AppDependencies.live()`).
    /// `-appLanguage en` style arguments override the settings for this run only.
    /// `signedIn` starts on the tab bar with a demo user, skipping the sign-up form.
    func launchApp(language: String? = nil, appearance: String? = nil, signedIn: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES"]
        if signedIn { app.launchArguments += ["-uiTestingSignedIn", "YES"] }
        if let language { app.launchArguments += ["-appLanguage", language] }
        if let appearance { app.launchArguments += ["-appAppearance", appearance] }
        app.launch()
        return app
    }

    /// Screenshots are stored in the test results (TestResults.xcresult in CI).
    func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func attachText(_ text: String, named name: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func waitAndTap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.tap()
    }
}
