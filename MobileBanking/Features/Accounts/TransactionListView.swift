import SwiftUI

/// All transactions of the user's accounts, grouped by day, with a filter.
struct TransactionListView: View {
    @State private var model: TransactionsViewModel

    init(accountIDs: [UUID], banking: any BankingService) {
        _model = State(initialValue: TransactionsViewModel(accountIDs: accountIDs, banking: banking))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                TransactionFilterPicker(filter: $model.filter)
                TransactionHistory(model: model)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("transactions.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.load() }
        .refreshable { model.load() }
    }
}

/// Všechny / Příchozí / Odchozí.
struct TransactionFilterPicker: View {
    @Binding var filter: TransactionsViewModel.Filter

    var body: some View {
        Picker("transactions.filter", selection: $filter) {
            Text("transactions.filter.all").tag(TransactionsViewModel.Filter.all)
            Text("transactions.filter.incoming").tag(TransactionsViewModel.Filter.incoming)
            Text("transactions.filter.outgoing").tag(TransactionsViewModel.Filter.outgoing)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("transactions.filter")
    }
}

/// The list itself, or an error / empty state.
struct TransactionHistory: View {
    let model: TransactionsViewModel

    var body: some View {
        if model.loadFailed {
            ErrorStateView { model.load() }
        } else if model.filtered.isEmpty {
            ContentUnavailableView(
                "transactions.empty.title",
                systemImage: "tray",
                description: Text("transactions.empty.message")
            )
            .padding(.top, Theme.Spacing.xxl)
        } else {
            TransactionDayList(days: model.days)
        }
    }
}
