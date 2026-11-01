import XCTest

extension XCTestCase {
    /// Every launch starts clean: no users, no session, default settings (see `AppDependencies.live()`).
    /// `-appLanguage en` style arguments override the settings for this run only.
    func launchApp(language: String? = nil, appearance: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "YES"]
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
}
