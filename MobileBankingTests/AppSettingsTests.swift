import SwiftUI
import XCTest
@testable import MobileBanking

final class AppSettingsTests: XCTestCase {

    // MARK: Language

    func testDefaultLanguageIsCzech() {
        XCTAssertEqual(AppLanguage.default, .czech)
    }

    func testUnknownLanguageFallsBackToCzech() {
        XCTAssertEqual(AppLanguage.resolve("de"), .czech)
        XCTAssertEqual(AppLanguage.resolve(""), .czech)
    }

    func testLanguageLocales() {
        XCTAssertEqual(AppLanguage.czech.locale.identifier, "cs_CZ")
        XCTAssertEqual(AppLanguage.english.locale.identifier, "en_GB")
    }

    func testLanguagesAreNamedInTheirOwnLanguage() {
        XCTAssertEqual(AppLanguage.czech.nativeName, "Čeština")
        XCTAssertEqual(AppLanguage.english.nativeName, "English")
    }

    // MARK: Bundle localization (checks Info.plist and the String Catalog build)

    func testDevelopmentLanguageIsCzech() {
        XCTAssertEqual(Bundle.main.developmentLocalization, "cs")
    }

    func testCzechAndEnglishAreBundled() {
        let localizations = Bundle.main.localizations
        XCTAssertTrue(localizations.contains("cs"), "Bundled: \(localizations)")
        XCTAssertTrue(localizations.contains("en"), "Bundled: \(localizations)")
    }

    // MARK: Appearance

    func testDefaultAppearanceFollowsSystem() {
        XCTAssertEqual(AppAppearance.default, .system)
        XCTAssertNil(AppAppearance.system.colorScheme)
    }

    func testAppearanceColorSchemes() {
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
        XCTAssertEqual(AppAppearance.resolve("unknown"), .system)
    }
}
