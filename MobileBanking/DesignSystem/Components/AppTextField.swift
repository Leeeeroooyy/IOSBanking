import SwiftUI

/// A labelled form field with an inline error under it.
struct AppTextField: View {
    enum Kind {
        case name
        case email
        case password
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
            if Self.usesPlainPasswordFields {
                TextField("", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                // Not `.newPassword`: a demo app must not offer to generate or save a real password.
                SecureField("", text: $text)
                    .textContentType(.password)
            }
        }
    }

    /// UI tests only (debug build, `-uiTesting`): the simulator's password handling drops
    /// characters typed by XCUITest into secure fields on CI, so tests type into plain fields.
    /// Real users always get a `SecureField`; password hashing is covered by unit tests.
    private static let usesPlainPasswordFields: Bool = {
        #if DEBUG
        // Same value as `AppDependencies.uiTestingArgument` (that one is main-actor isolated).
        return ProcessInfo.processInfo.arguments.contains("-uiTesting")
        #else
        return false
        #endif
    }()
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
