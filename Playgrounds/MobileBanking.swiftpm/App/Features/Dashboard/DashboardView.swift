import SwiftUI

/// Tab "Přehled": total balance, quick actions, accounts and the latest transactions.
struct DashboardView: View {
    @State private var model: DashboardViewModel
    @State private var showsAllTransactions = false

    private let banking: any BankingService
    private let selectTab: (MainTab) -> Void

    init(user: User, banking: any BankingService, selectTab: @escaping (MainTab) -> Void) {
        _model = State(initialValue: DashboardViewModel(user: user, banking: banking))
        self.banking = banking
        self.selectTab = selectTab
    }

    var body: some View {
        BrandScaffold {
            header
        } content: {
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { model.load() }
        .refreshable { model.load() }
        .navigationDestination(for: Account.self) { account in
            AccountDetailView(account: account, banking: banking)
        }
        .navigationDestination(for: BankTransaction.self) { transaction in
            TransactionDetailView(transaction: transaction)
        }
        .navigationDestination(isPresented: $showsAllTransactions) {
            TransactionListView(accountIDs: model.accountIDs, banking: banking)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            HStack(spacing: Theme.Spacing.m) {
                AvatarView(initials: model.user.initials)

                VStack(alignment: .leading) {
                    Text("dashboard.welcome")
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.onBrandSecondary)
                    Text(verbatim: model.user.fullName)
                        .font(Theme.Typography.sectionTitle)
                        .foregroundStyle(Theme.Colors.onBrand)
                        .lineLimit(2)
                        .accessibilityIdentifier("dashboard.userName")
                }

                Spacer()
                BrandLogo(size: 36)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("dashboard.totalBalance")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.onBrandSecondary)
                AmountText(amount: model.totalBalance, font: Theme.Typography.balance, color: Theme.Colors.onBrand)
            }
            // VoiceOver reads "Celkový zůstatek, 165 250,00 Kč" as one element.
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("dashboard.totalBalance")

            quickActions
        }
    }

    private var quickActions: some View {
        Grid(horizontalSpacing: Theme.Spacing.m, verticalSpacing: Theme.Spacing.m) {
            GridRow {
                QuickActionTile(titleKey: "dashboard.action.send", systemImage: "arrow.up.right", isPrimary: true) {
                    selectTab(.payments)
                }
                .accessibilityIdentifier("dashboard.action.send")
                QuickActionTile(titleKey: "dashboard.action.transactions", systemImage: "list.bullet") {
                    showsAllTransactions = true
                }
                .accessibilityIdentifier("dashboard.action.transactions")
            }
            GridRow {
                QuickActionTile(titleKey: "dashboard.action.stocks", systemImage: "chart.line.uptrend.xyaxis") {
                    selectTab(.markets)
                }
                .accessibilityIdentifier("dashboard.action.stocks")
                QuickActionTile(titleKey: "dashboard.action.news", systemImage: "newspaper") {
                    selectTab(.news)
                }
                .accessibilityIdentifier("dashboard.action.news")
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        case .failed:
            ErrorStateView { model.load() }
        case .loaded:
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                if let card = model.accounts.first(where: { $0.kind == .current }) {
                    BankCardView(account: card)
                }
                accounts
                recentTransactions
            }
        }
    }

    private var accounts: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionTitle(titleKey: "dashboard.accounts")
            ForEach(model.accounts) { account in
                NavigationLink(value: account) {
                    AccountRow(account: account)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(titleKey: "dashboard.recent")
                Spacer()
                Button("dashboard.recent.all") { showsAllTransactions = true }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityIdentifier("dashboard.recent.all")
            }

            if model.recentTransactions.isEmpty {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.primary)
                        .frame(width: 48, height: 48)
                        .background(Theme.Colors.primary.opacity(0.1), in: Circle())
                        .accessibilityHidden(true)
                    Text("dashboard.empty")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.s)
            } else {
                ForEach(model.recentTransactions) { transaction in
                    NavigationLink(value: transaction) {
                        TransactionRow(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                    if transaction.id != model.recentTransactions.last?.id {
                        Divider().overlay(Theme.Colors.border)
                    }
                }
            }
        }
    }
}

/// Title of a section on the sheet ("Moje účty", "Poslední pohyby").
struct SectionTitle: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        Text(titleKey)
            .font(Theme.Typography.sectionTitle)
            .foregroundStyle(Theme.Colors.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    let dependencies = AppDependencies.inMemory()
    return NavigationStack {
        DashboardView(
            user: User(fullName: "Jana Nováková", email: "jana@example.cz"),
            banking: dependencies.banking,
            selectTab: { _ in }
        )
    }
    .environment(dependencies)
}
