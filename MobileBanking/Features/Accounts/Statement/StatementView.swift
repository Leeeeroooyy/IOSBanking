import PDFKit
import SwiftUI

/// "Výpis z účtu": pick a month, create the PDF, preview it and share or save it.
struct StatementView: View {
    let account: Account
    let banking: any BankingService

    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @State private var month: Date
    @State private var fileURL: URL?
    @State private var failed = false

    private let months: [Date]

    init(account: Account, banking: any BankingService) {
        self.account = account
        self.banking = banking
        let months = AccountStatement.availableMonths(since: account.createdAt)
        self.months = months
        _month = State(initialValue: months.first ?? .now)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.l) {
                Picker("statement.month", selection: $month) {
                    ForEach(months, id: \.self) { month in
                        Text(month, format: .dateTime.month(.wide).year()).tag(month)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.primary)
                .accessibilityIdentifier("statement.month")

                if let fileURL {
                    PDFPreview(url: fileURL)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous).stroke(Theme.Colors.border))
                        .accessibilityLabel(Text("statement.preview"))

                    ShareLink(item: fileURL) {
                        Label("statement.share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.primary)
                    .accessibilityIdentifier("statement.share")
                } else if failed {
                    ErrorStateView { create() }
                } else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }

                Text("statement.demoNote")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.xl)
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("statement.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("statement.close") { dismiss() }
                }
            }
            .task(id: month) { create() }
        }
    }

    private func create() {
        do {
            let history = try banking.transactions(accountIDs: [account.id], limit: nil)
            let statement = AccountStatement.make(account: account, history: history, month: month)
            let data = StatementPDFRenderer(locale: locale).render(statement)

            // "Vypis-2026-11-123456789.pdf" in the temporary folder; the system deletes it later.
            let monthText = month.formatted(.iso8601.year().month())
            let digits = account.number.filter(\.isNumber)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Vypis-\(monthText)-\(digits.suffix(6)).pdf")
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            fileURL = url
            failed = false
        } catch {
            fileURL = nil
            failed = true
        }
    }
}

/// PDFKit's `PDFView` in SwiftUI.
struct PDFPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = .secondarySystemBackground
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        // A new document every time: the file at the same URL may have been rewritten.
        view.document = PDFDocument(url: url)
    }
}
