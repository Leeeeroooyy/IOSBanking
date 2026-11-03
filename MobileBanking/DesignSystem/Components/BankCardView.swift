import SwiftUI

/// A payment card drawn for the current account: chip, contactless symbol,
/// the last four digits of the account and the holder's name. Pure SwiftUI shapes, no images.
struct BankCardView: View {
    let account: Account

    private var lastDigits: String {
        let digits = account.number.split(separator: "/").first.map { $0.filter(\.isNumber) } ?? ""
        return String(digits.suffix(4))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            background

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.headline)
                    Text("app.name")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: "wave.3.right")
                        .font(.title3.weight(.semibold))
                }

                Spacer(minLength: Theme.Spacing.m)

                chip

                Spacer(minLength: Theme.Spacing.m)

                Text(verbatim: "••••  ••••  ••••  \(lastDigits)")
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(alignment: .bottom) {
                    Text(verbatim: account.holderName.uppercased())
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text("card.debit")
                        .font(.caption.weight(.heavy))
                        .tracking(1.2)
                }
                .padding(.top, Theme.Spacing.s)
            }
            .foregroundStyle(.white)
            .padding(Theme.Spacing.xl)
        }
        .aspectRatio(1.586, contentMode: .fit) // the shape of a real card (ISO/IEC 7810 ID-1)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
        .shadow(color: Theme.Colors.brand.opacity(0.35), radius: 16, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("card.accessibility \(lastDigits)"))
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Theme.Colors.brandEnd, Theme.Colors.brand, Color.black.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                GeometryReader { proxy in
                    Circle()
                        .fill(Theme.Colors.accent.opacity(0.35))
                        .frame(width: proxy.size.width * 0.8)
                        .blur(radius: 40)
                        .offset(x: proxy.size.width * 0.45, y: proxy.size.height * 0.3)
                    Circle()
                        .stroke(.white.opacity(0.08), lineWidth: 30)
                        .frame(width: proxy.size.width * 0.7)
                        .offset(x: -proxy.size.width * 0.25, y: -proxy.size.height * 0.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.15)))
    }

    private var chip: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(colors: [Color(red: 0.95, green: 0.82, blue: 0.5), Color(red: 0.75, green: 0.6, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 32)
            .overlay {
                VStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(.black.opacity(0.18)).frame(height: 1)
                    }
                }
                .padding(.horizontal, 6)
            }
    }
}
