import SwiftUI

/// Round avatar with the user's initials. The name is read out next to it, so VoiceOver skips it.
struct AvatarView: View {
    let initials: String

    var body: some View {
        Text(verbatim: initials)
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(Theme.Colors.onAccent)
            .frame(width: 44, height: 44)
            .background(Theme.Colors.accent, in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    AvatarView(initials: "JN").padding()
}
