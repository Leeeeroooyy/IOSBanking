import UIKit

/// Draws an `AccountStatement` as an A4 PDF with UIKit (`UIGraphicsPDFRenderer`).
/// Texts follow the language chosen in the app, not the device language.
struct StatementPDFRenderer {
    let locale: Locale

    private let page = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 in points
    private let margin: CGFloat = 40
    private let brand = UIColor(red: 0.24, green: 0.20, blue: 0.62, alpha: 1)

    func render(_ statement: AccountStatement) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: text("statement.pdf.title"),
            kCGPDFContextCreator as String: "MobileBanking (study app)",
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: page, format: format)

        return renderer.pdfData { context in
            var y = startPage(context)
            y = drawHeader(statement, at: y)
            y = drawSummary(statement, at: y)
            y = drawTableHeader(at: y)

            if statement.transactions.isEmpty {
                draw(text("statement.pdf.empty"), at: CGPoint(x: margin, y: y + 6), font: .systemFont(ofSize: 10), color: .gray)
            }
            for transaction in statement.transactions {
                if y > page.height - margin - 60 {
                    drawFooter()
                    y = startPage(context)
                    y = drawTableHeader(at: y)
                }
                y = drawRow(transaction, at: y)
            }
            drawFooter()
        }
    }

    // MARK: - Parts

    private func startPage(_ context: UIGraphicsPDFRendererContext) -> CGFloat {
        context.beginPage()
        brand.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: page.width, height: 8))
        return margin
    }

    private func drawHeader(_ statement: AccountStatement, at top: CGFloat) -> CGFloat {
        var y = top
        draw(DemoDataSeeder.bankName, at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 12), color: brand)
        y += 20
        draw(text("statement.pdf.title"), at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 22), color: .black)
        y += 32

        let period = "\(date(statement.period.start)) – \(date(statement.period.end.addingTimeInterval(-1)))"
        let rows: [(String, String)] = [
            (text("statement.pdf.holder"), statement.holderName),
            (text("statement.pdf.account"), "\(kindName(statement.accountKind)) · \(statement.accountNumber)"),
            (text("statement.pdf.iban"), statement.iban ?? "—"),
            (text("statement.pdf.currency"), statement.currencyCode),
            (text("statement.pdf.period"), period),
        ]
        for (label, value) in rows {
            draw(label, at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 10), color: .gray)
            draw(value, at: CGPoint(x: margin + 120, y: y), font: .systemFont(ofSize: 10, weight: .semibold), color: .black)
            y += 16
        }
        return y + 14
    }

    private func drawSummary(_ statement: AccountStatement, at top: CGFloat) -> CGFloat {
        let box = CGRect(x: margin, y: top, width: page.width - 2 * margin, height: 54)
        UIColor(white: 0.95, alpha: 1).setFill()
        UIBezierPath(roundedRect: box, cornerRadius: 8).fill()

        let items: [(String, Decimal)] = [
            (text("statement.pdf.opening"), statement.openingBalance),
            (text("statement.pdf.incoming"), statement.totalIncoming),
            (text("statement.pdf.outgoing"), -statement.totalOutgoing),
            (text("statement.pdf.closing"), statement.closingBalance),
        ]
        let width = box.width / CGFloat(items.count)
        for (index, item) in items.enumerated() {
            let x = box.minX + CGFloat(index) * width + 10
            draw(item.0, at: CGPoint(x: x, y: box.minY + 10), font: .systemFont(ofSize: 9), color: .gray)
            draw(money(item.1, statement.currencyCode), at: CGPoint(x: x, y: box.minY + 26), font: .boldSystemFont(ofSize: 11), color: .black)
        }
        return box.maxY + 22
    }

    private var columns: (date: CGFloat, name: CGFloat, symbol: CGFloat, amountRight: CGFloat) {
        (margin, margin + 70, margin + 330, page.width - margin)
    }

    private func drawTableHeader(at top: CGFloat) -> CGFloat {
        let font = UIFont.boldSystemFont(ofSize: 9)
        draw(text("statement.pdf.col.date"), at: CGPoint(x: columns.date, y: top), font: font, color: .gray)
        draw(text("statement.pdf.col.counterparty"), at: CGPoint(x: columns.name, y: top), font: font, color: .gray)
        draw(text("statement.pdf.col.vs"), at: CGPoint(x: columns.symbol, y: top), font: font, color: .gray)
        drawRight(text("statement.pdf.col.amount"), rightX: columns.amountRight, y: top, font: font, color: .gray)
        line(at: top + 16)
        return top + 22
    }

    private func drawRow(_ transaction: BankTransaction, at top: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 10)
        draw(date(transaction.date), at: CGPoint(x: columns.date, y: top), font: font, color: .black)
        draw(clip(transaction.counterpartyName, 42), at: CGPoint(x: columns.name, y: top), font: .systemFont(ofSize: 10, weight: .semibold), color: .black)
        let detail = [transaction.counterpartyAccount, transaction.message].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        if !detail.isEmpty {
            draw(clip(detail, 52), at: CGPoint(x: columns.name, y: top + 13), font: .systemFont(ofSize: 8), color: .gray)
        }
        draw(transaction.variableSymbol ?? "", at: CGPoint(x: columns.symbol, y: top), font: font, color: .black)
        let amount = MoneyFormatter.signedString(transaction.signedAmount, currencyCode: transaction.currencyCode, locale: locale)
        let color = transaction.direction == .incoming ? UIColor(red: 0.05, green: 0.5, blue: 0.3, alpha: 1) : UIColor.black
        drawRight(amount, rightX: columns.amountRight, y: top, font: .boldSystemFont(ofSize: 10), color: color)
        line(at: top + 28, color: UIColor(white: 0.9, alpha: 1))
        return top + 32
    }

    private func drawFooter() {
        let note = "\(text("statement.pdf.footer")) · \(text("statement.pdf.created")) \(date(.now))"
        draw(note, at: CGPoint(x: margin, y: page.height - margin + 10), font: .systemFont(ofSize: 8), color: .gray)
    }

    // MARK: - Helpers

    private func text(_ key: String.LocalizationValue) -> String {
        .localized(LocalizedStringResource(key), locale: locale)
    }

    private func kindName(_ kind: AccountKind) -> String {
        switch kind {
        case .current: return text("account.kind.current")
        case .savings: return text("account.kind.savings")
        }
    }

    private func date(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .numeric, time: .omitted).locale(locale))
    }

    private func money(_ amount: Decimal, _ currencyCode: String) -> String {
        MoneyFormatter.string(amount, currencyCode: currencyCode, locale: locale)
    }

    private func clip(_ text: String, _ length: Int) -> String {
        text.count > length ? String(text.prefix(length - 1)) + "…" : text
    }

    private func draw(_ string: String, at point: CGPoint, font: UIFont, color: UIColor) {
        (string as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private func drawRight(_ string: String, rightX: CGFloat, y: CGFloat, font: UIFont, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let width = (string as NSString).size(withAttributes: attributes).width
        (string as NSString).draw(at: CGPoint(x: rightX - width, y: y), withAttributes: attributes)
    }

    private func line(at y: CGFloat, color: UIColor = .lightGray) {
        color.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: page.width - margin, y: y))
        path.lineWidth = 0.5
        path.stroke()
    }
}
