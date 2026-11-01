import XCTest

/// The signed-in screens, reached without the sign-up form, so its problems do not hide theirs.
final class MainScreensUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDashboardShowsTheSignedInUser() {
        let app = launchApp(signedIn: true)

        let userName = app.staticTexts["dashboard.userName"]
        XCTAssertTrue(userName.waitForExistence(timeout: 10))
        XCTAssertEqual(userName.label, "Jana Novakova")
        attachScreenshot(named: "dashboard-light")
    }

    func testDashboardInDarkTheme() {
        let app = launchApp(appearance: "dark", signedIn: true)

        XCTAssertTrue(app.staticTexts["dashboard.userName"].waitForExistence(timeout: 10))
        attachScreenshot(named: "dashboard-dark")
    }

    func testCzechTabsShowTheirEmptyStates() {
        let app = launchApp(signedIn: true)

        assertTab("Platby", showsTitle: "Platby zatím nejsou k dispozici", in: app)
        assertTab("Trhy", showsTitle: "Trhy zatím nejsou k dispozici", in: app)
        assertTab("Zprávy", showsTitle: "Zprávy zatím nejsou k dispozici", in: app)
    }

    /// The simulator language must not win over the language chosen in the app.
    func testEnglishTabs() {
        let app = launchApp(language: "en", signedIn: true)

        assertTab("Payments", showsTitle: "Payments are not available yet", in: app)
        assertTab("Markets", showsTitle: "Markets are not available yet", in: app)
        assertTab("News", showsTitle: "News is not available yet", in: app)
    }

    func testProfileShowsTheUserAndOpensSettings() {
        let app = launchApp(signedIn: true)

        waitAndTap(app.tabBars.buttons["Profil"])
        XCTAssertTrue(app.staticTexts["jana@example.cz"].waitForExistence(timeout: 5))
        attachScreenshot(named: "profile")

        waitAndTap(app.buttons["profile.settings"])
        XCTAssertTrue(app.switches["settings.faceID"].waitForExistence(timeout: 5))
        attachScreenshot(named: "settings")
    }

    func testSignOutReturnsToSignIn() {
        let app = launchApp(signedIn: true)

        waitAndTap(app.tabBars.buttons["Profil"])
        waitAndTap(app.buttons["profile.signOut"])

        XCTAssertTrue(app.staticTexts["login.title"].waitForExistence(timeout: 5))
    }

    private func assertTab(
        _ tab: String,
        showsTitle title: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitAndTap(app.tabBars.buttons[tab])
        // The empty state may merge its title and description into one element.
        let element = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", title))
            .firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Tab \(tab)", file: file, line: line)
        attachScreenshot(named: "tab-\(tab)")
    }
}
