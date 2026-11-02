import Foundation

/// A Czech bank account number: `[prefix-]number/bank code`, for example `19-2000145399/0800`.
///
/// Both the prefix and the number carry a mod 11 check digit (weights set by the Czech
/// National Bank), so most typos are caught before a payment is sent.
struct CzechAccountNumber: Hashable {
    /// Bank code of the demo bank. It is made up and used only inside this study app.
    static let demoBankCode = "9999"

    private static let prefixWeights = [10, 5, 8, 4, 2, 1]
    private static let numberWeights = [6, 3, 7, 9, 10, 5, 8, 4, 2, 1]

    /// Without leading zeros; empty when there is no prefix.
    let prefix: String
    /// Without leading zeros, 2–10 digits.
    let number: String
    /// Exactly 4 digits.
    let bankCode: String

    /// Parses and validates user input. Spaces around the parts are ignored.
    init?(_ text: String) {
        let compact = text.filter { !$0.isWhitespace }
        let slashParts = compact.split(separator: "/", omittingEmptySubsequences: false)
        guard slashParts.count == 2 else { return nil }

        let bankCode = String(slashParts[1])
        guard bankCode.count == 4, bankCode.allSatisfy(\.isASCIIDigit) else { return nil }

        let dashParts = slashParts[0].split(separator: "-", omittingEmptySubsequences: false)
        guard (1...2).contains(dashParts.count) else { return nil }
        let rawPrefix = dashParts.count == 2 ? String(dashParts[0]) : ""
        let rawNumber = String(dashParts[dashParts.count - 1])

        guard
            rawPrefix.count <= 6, rawPrefix.allSatisfy(\.isASCIIDigit),
            !rawNumber.isEmpty, rawNumber.count <= 10, rawNumber.allSatisfy(\.isASCIIDigit),
            !(dashParts.count == 2 && rawPrefix.isEmpty)
        else { return nil }

        // A prefix of zeros ("000000-…") means no prefix.
        let trimmedPrefix = Self.trimmingLeadingZeros(rawPrefix)
        let prefix = trimmedPrefix == "0" ? "" : trimmedPrefix
        let number = Self.trimmingLeadingZeros(rawNumber)
        guard
            number.count >= 2,
            Self.hasValidChecksum(prefix, weights: Self.prefixWeights),
            Self.hasValidChecksum(number, weights: Self.numberWeights)
        else { return nil }

        self.init(prefix: prefix, number: number, bankCode: bankCode)
    }

    private init(prefix: String, number: String, bankCode: String) {
        self.prefix = prefix
        self.number = number
        self.bankCode = bankCode
    }

    /// `19-2000145399/0800`, or `2000145399/0800` without a prefix.
    var formatted: String {
        prefix.isEmpty ? "\(number)/\(bankCode)" : "\(prefix)-\(number)/\(bankCode)"
    }

    /// The last four digits, as shown in lists: `•• 5399`.
    var masked: String {
        "•• " + String(number.suffix(4))
    }

    /// A random valid 10-digit number in the demo bank.
    static func generate<G: RandomNumberGenerator>(using generator: inout G) -> CzechAccountNumber {
        while true {
            var digits = (0..<9).map { _ in Int.random(in: 0...9, using: &generator) }
            digits[0] = Int.random(in: 1...9, using: &generator)
            let sum = zip(digits, numberWeights).reduce(0) { $0 + $1.0 * $1.1 }
            // The last weight is 1, so the check digit is whatever makes the sum divisible by 11.
            let checkDigit = (11 - sum % 11) % 11
            guard checkDigit < 10 else { continue }
            let number = (digits + [checkDigit]).map(String.init).joined()
            return CzechAccountNumber(prefix: "", number: number, bankCode: demoBankCode)
        }
    }

    static func generate() -> CzechAccountNumber {
        var generator = SystemRandomNumberGenerator()
        return generate(using: &generator)
    }

    // MARK: - Private

    private static func hasValidChecksum(_ digits: String, weights: [Int]) -> Bool {
        let values = digits.compactMap(\.wholeNumberValue)
        let padded = Array(repeating: 0, count: weights.count - values.count) + values
        let sum = zip(padded, weights).reduce(0) { $0 + $1.0 * $1.1 }
        return sum % 11 == 0
    }

    private static func trimmingLeadingZeros(_ digits: String) -> String {
        let trimmed = digits.drop { $0 == "0" }
        return trimmed.isEmpty && !digits.isEmpty ? "0" : String(trimmed)
    }
}

private extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
