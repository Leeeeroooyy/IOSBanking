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

    func testDashboardShowsBalanceAccountsAndRecentTransactions() {
        let app = launchApp(signedIn: true)

        let total = app.descendants(matching: .any)["dashboard.totalBalance"]
        XCTAssertTrue(total.waitForExistence(timeout: 10))
        // Foundation separates thousands with a non-breaking space, so compare digits only.
        XCTAssertTrue(total.label.filter(\.isNumber).hasPrefix("16525000"), total.label)
        XCTAssertTrue(app.descendants(matching: .any)["account.current"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["account.savings"].exists)
        attachScreenshot(named: "dashboard-accounts")
    }

    func testAccountDetailAndTransactionDetail() {
        let app = launchApp(signedIn: true)

        let current = app.descendants(matching: .any)["account.current"]
        XCTAssertTrue(current.waitForExistence(timeout: 10))
        current.tap()

        let title = app.staticTexts["accountDetail.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "Běžný účet")
        attachScreenshot(named: "account-detail")

        // The newest transaction of the demo current account: Petr Svoboda returns a loan.
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Petr Svoboda"))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(app.staticTexts["transactionDetail.counterparty"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["transactionDetail.counterparty"].label, "Petr Svoboda")
        attachScreenshot(named: "transaction-detail")
    }

    func testTransactionsQuickActionOpensFilteredHistory() {
        let app = launchApp(signedIn: true)

        waitAndTap(app.buttons["dashboard.action.transactions"])
        let filter = app.segmentedControls["transactions.filter"]
        XCTAssertTrue(filter.waitForExistence(timeout: 5))

        // Petr Svoboda sent money today, so he is at the top of the history.
        let petr = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Petr Svoboda")).firstMatch
        XCTAssertTrue(petr.waitForExistence(timeout: 5))

        filter.buttons["Odchozí"].tap()
        XCTAssertFalse(petr.waitForExistence(timeout: 2), "An incoming payment must be hidden by the outgoing filter")

        filter.buttons["Příchozí"].tap()
        XCTAssertTrue(petr.waitForExistence(timeout: 5))
        attachScreenshot(named: "transactions-incoming")
    }

    func testSendMoneyQuickActionOpensPaymentsTab() {
        let app = launchApp(signedIn: true)

        waitAndTap(app.buttons["dashboard.action.send"])
        let title = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Platby zatím nejsou k dispozici"))
            .firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
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
