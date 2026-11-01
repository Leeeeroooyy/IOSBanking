import SwiftUI

/// A labelled form field with an inline error under it.
struct AppTextField: View {
    enum Kind {
        case name
        case email
        case password
        case newPassword
    }

    let titleKey: LocalizedStringKey
    @Binding var text: String
    let kind: Kind
    var error: LocalizedStringKey?
    let identifier: String

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(titleKey)
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.textSecondary)
                .accessibilityHidden(true)

            field
                .accessibilityLabel(Text(titleKey))
                .accessibilityIdentifier(identifier)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(minHeight: 48)
                .background(Theme.Colors.surfaceRaised, in: shape)
                .overlay(shape.stroke(error == nil ? Theme.Colors.border : Theme.Colors.negative))

            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.negative)
            }
        }
    }

    @ViewBuilder
    private var field: some View {
        switch kind {
        case .name:
            TextField("", text: $text)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        case .email:
            TextField("", text: $text)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .password:
            SecureField("", text: $text)
                .textContentType(.password)
        case .newPassword:
            SecureField("", text: $text)
                .textContentType(.newPassword)
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.l) {
        AppTextField(titleKey: "auth.field.email", text: .constant("jana@example.cz"), kind: .email, identifier: "preview.email")
        AppTextField(
            titleKey: "auth.field.password",
            text: .constant(""),
            kind: .password,
            error: AuthFormError.passwordTooShort.messageKey,
            identifier: "preview.password"
        )
    }
    .padding()
}
