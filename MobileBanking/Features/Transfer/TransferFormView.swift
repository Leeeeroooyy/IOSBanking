import SwiftUI

/// Tab "Platby": a new payment. Confirmation and result are pushed on top of it.
struct TransferFormView: View {
    @State private var model: TransferViewModel
    @State private var showsMoreSymbols = false
    @FocusState private var focus: TransferViewModel.Field?

    init(user: User, banking: any BankingService, biometrics: any BiometricService, templates: any TemplateService) {
        _model = State(initialValue: TransferViewModel(user: user, banking: banking, biometrics: biometrics, templates: templates))
    }

    var body: some View {
        BrandScaffold {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("transfer.title")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.onBrand)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("transfer.title")
                    Text("transfer.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.onBrandSecondary)
                }
                Spacer()
                HeaderIcon(systemImage: "paperplane.fill")
            }
        } content: {
            if model.loadFailed {
                ErrorStateView { model.load() }
            } else {
                form
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { model.load() }
        .navigationDestination(isPresented: $model.isConfirmationPresented) {
            TransferConfirmView(model: model)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            sourcePicker

            if !model.templates.isEmpty {
                templateList
            }

            if !model.suggestedRecipients.isEmpty {
                recipientSuggestions
            }

            AppTextField(
                titleKey: "transfer.field.recipientAccount",
                text: $model.recipientAccount,
                kind: .accountNumber,
                error: model.errors[.recipientAccount]?.messageKey,
                identifier: "transfer.recipientAccount"
            )
            .focused($focus, equals: .recipientAccount)

            AppTextField(
                titleKey: "transfer.field.recipientName",
                text: $model.recipientName,
                kind: .name,
                error: model.errors[.recipientName]?.messageKey,
                identifier: "transfer.recipientName"
            )
            .focused($focus, equals: .recipientName)

            AppTextField(
                titleKey: "transfer.field.amount",
                text: $model.amountText,
                kind: .amount,
                error: model.errors[.amount]?.messageKey,
                identifier: "transfer.amount"
            )
            .focused($focus, equals: .amount)

            AppTextField(
                titleKey: "transfer.field.variableSymbol",
                text: $model.variableSymbol,
                kind: .digits,
                error: model.errors[.variableSymbol]?.messageKey,
                identifier: "transfer.variableSymbol"
            )
            .focused($focus, equals: .variableSymbol)

            AppTextField(
                titleKey: "transfer.field.message",
                text: $model.message,
                kind: .text,
                error: model.errors[.message]?.messageKey,
                identifier: "transfer.message"
            )
            .focused($focus, equals: .message)

            DisclosureGroup("transfer.moreSymbols", isExpanded: $showsMoreSymbols) {
                VStack(spacing: Theme.Spacing.l) {
                    AppTextField(
                        titleKey: "transfer.field.constantSymbol",
                        text: $model.constantSymbol,
                        kind: .digits,
                        error: model.errors[.constantSymbol]?.messageKey,
                        identifier: "transfer.constantSymbol"
                    )
                    AppTextField(
                        titleKey: "transfer.field.specificSymbol",
                        text: $model.specificSymbol,
                        kind: .digits,
                        error: model.errors[.specificSymbol]?.messageKey,
                        identifier: "transfer.specificSymbol"
                    )
                }
                .padding(.top, Theme.Spacing.m)
            }
            .font(.subheadline.weight(.semibold))
            .tint(Theme.Colors.primary)

            Button("transfer.continue") {
                focus = nil
                model.review()
                // Errors in the hidden symbols must be visible.
                if model.errors[.constantSymbol] != nil || model.errors[.specificSymbol] != nil {
                    showsMoreSymbols = true
                }
            }
            .buttonStyle(.primary)
            .disabled(model.sourceAccount == nil)
            .accessibilityIdentifier("transfer.continue")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("transfer.keyboard.done") { focus = nil }
            }
        }
    }

    /// The account the money leaves from.
    private var sourcePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("transfer.field.from")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.textSecondary)
            ForEach(model.accounts, id: \.id) { account in
                Button {
                    model.fromAccountID = account.id
                } label: {
                    AccountRow(account: account)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                                .stroke(Theme.Colors.primary, lineWidth: model.fromAccountID == account.id ? 2 : 0)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectionTraits(for: account))
            }
        }
    }

    /// VoiceOver says "selected" for the chosen source account.
    private func selectionTraits(for account: Account) -> AccessibilityTraits {
        model.fromAccountID == account.id ? .isSelected : []
    }

    /// Saved payments: one tap fills the whole form, long press deletes.
    private var templateList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("templates.title")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(model.templates, id: \.id) { template in
                        Button {
                            model.apply(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Label {
                                    Text(verbatim: template.name)
                                } icon: {
                                    Image(systemName: "star.fill").foregroundStyle(Theme.Colors.accent)
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Colors.textPrimary)
                                if let amount = template.amount {
                                    AmountText(amount: amount.amount, currencyCode: amount.currencyCode, font: .caption.weight(.semibold))
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.vertical, Theme.Spacing.s)
                            .frame(minHeight: 44)
                            .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous).stroke(Theme.Colors.border))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("templates.delete", systemImage: "trash", role: .destructive) {
                                model.deleteTemplate(template)
                            }
                        }
                        .accessibilityHint(Text("templates.hint"))
                    }
                }
            }
            if let error = model.templateError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.negative)
            }
        }
    }

    /// One tap fills in an own account or another client of the demo bank.
    private var recipientSuggestions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("transfer.suggestions")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(model.suggestedRecipients, id: \.id) { account in
                        Button {
                            model.fill(recipient: account)
                        } label: {
                            Group {
                                if account.ownerID == model.user.id {
                                    Text(account.kind.titleKey)
                                } else {
                                    Text(verbatim: account.holderName)
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .padding(.horizontal, Theme.Spacing.m)
                            .frame(minHeight: 40)
                            .background(Theme.Colors.surfaceRaised, in: Capsule())
                            .overlay(Capsule().stroke(Theme.Colors.border))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
