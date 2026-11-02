import XCTest

final class AuthFlowUITests: XCTestCase {

    private let fullName = "Jana Novakova"
    private let email = "jana@example.cz"
    private let password = "heslo123"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The result of stage 3: sign up, walk through all tabs, sign out and sign in again.
    func testSignUpBrowseTabsSignOutAndSignIn() {
        let app = launchApp()
        signUp(in: app)

        assertDashboard(in: app)
        XCTAssertEqual(app.staticTexts["dashboard.userName"].label, fullName)
        attachScreenshot(named: "dashboard")

        let tabs = [
            ("Platby", "Nová platba"),
            ("Trhy", "Akcie"),
            ("Zprávy", "Ekonomické zprávy")
        ]
        for (tab, emptyTitle) in tabs {
            waitAndTap(app.tabBars.buttons[tab])
            // The empty state may merge its title and description into one element.
            let title = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", emptyTitle))
                .firstMatch
            XCTAssertTrue(title.waitForExistence(timeout: 5), "Tab \(tab)")
        }

        waitAndTap(app.tabBars.buttons["Profil"])
        XCTAssertTrue(app.staticTexts[email].waitForExistence(timeout: 5))
        attachScreenshot(named: "profile")

        waitAndTap(app.buttons["profile.signOut"])
        XCTAssertTrue(app.staticTexts["login.title"].waitForExistence(timeout: 5))

        signIn(in: app, password: password)
        XCTAssertTrue(app.staticTexts["dashboard.userName"].waitForExistence(timeout: 10))
    }

    func testWrongPasswordShowsError() {
        let app = launchApp()
        signUp(in: app)
        assertDashboard(in: app)

        waitAndTap(app.tabBars.buttons["Profil"])
        waitAndTap(app.buttons["profile.signOut"])
        XCTAssertTrue(app.staticTexts["login.title"].waitForExistence(timeout: 5))

        signIn(in: app, password: "spatneheslo")

        let error = app.staticTexts["login.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertEqual(error.label, "Nesprávný e-mail nebo heslo")
    }

    func testEmptySignUpShowsInlineErrors() {
        let app = launchApp()
        openSignUp(in: app)

        app.buttons["register.submit"].tap()

        XCTAssertTrue(app.staticTexts["Zadejte jméno a příjmení"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Zadejte platný e-mail"].exists)
        attachScreenshot(named: "sign-up-errors")
    }

    // MARK: Helpers

    private func openSignUp(in app: XCUIApplication) {
        let button = app.buttons["login.register"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
        XCTAssertTrue(app.staticTexts["register.title"].waitForExistence(timeout: 5))
    }

    /// Only the first field is tapped. Each field ends with a return key press: it moves the focus on,
    /// and the last one submits. A tap could land on the keyboard, which would type an extra character.
    private func signUp(in app: XCUIApplication) {
        openSignUp(in: app)
        type(fullName + "\n", into: app.textFields["register.fullName"], tapsField: true)
        type(email + "\n", into: app.textFields["register.email"])
        type(password + "\n", into: app.textFields["register.password"])

        let passwordField = app.textFields["register.password"]
        let confirmation = app.textFields["register.passwordConfirmation"]
        type(password, into: confirmation)
        // In UI tests the password fields are plain text fields (see AppTextField),
        // so their values can be checked directly.
        XCTAssertEqual(passwordField.value as? String, password)
        XCTAssertEqual(confirmation.value as? String, password)
        attachScreenshot(named: "sign-up-before-submit")
        confirmation.typeText("\n")
    }

    /// When the dashboard is missing, the failure message says what is on the screen instead.
    private func assertDashboard(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        guard !app.staticTexts["dashboard.userName"].waitForExistence(timeout: 10) else { return }

        attachScreenshot(named: "no-dashboard")
        attachText(app.debugDescription, named: "no-dashboard-tree")

        let inlineErrors = ["Heslo musí mít alespoň 8 znaků", "Hesla se neshodují"].filter { app.staticTexts[$0].exists }
        let verdict: String
        if app.staticTexts["register.title"].exists {
            verdict = "Form still shown. Inline errors: \(inlineErrors), "
                + "register.error: \(app.staticTexts["register.error"].exists), keyboards: \(app.keyboards.count)"
        } else if app.descendants(matching: .any)["dashboard.userName"].exists {
            verdict = "Dashboard shown, but the user name is not a StaticText"
        } else {
            verdict = "Neither the form nor the dashboard: see the no-dashboard screenshot"
        }
        XCTFail(verdict, file: file, line: line)
    }

    private func signIn(in app: XCUIApplication, password: String) {
        type(email + "\n", into: app.textFields["login.email"], tapsField: true)
        type(password + "\n", into: app.textFields["login.password"])
    }

    private func type(_ text: String, into field: XCUIElement, tapsField: Bool = false) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        if tapsField { field.tap() }
        field.typeText(text)
    }
}
