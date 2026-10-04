import SwiftUI

struct BrandButton: View {
    let label: String
    var enabled = true
    var leading: String? = nil
    var fullWidth = false
    var identifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leading {
                    Image(systemName: leading).font(.system(size: 13, weight: .bold))
                }
                Text(label).font(.dgo(14, .black)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(enabled ? Color.white : Color.white.opacity(0.35))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background {
                if enabled {
                    Brand.gradient
                } else {
                    Color.white.opacity(0.08)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityIdentifier(identifier ?? label)
    }
}

struct GhostField: View {
    @Binding var text: String
    var placeholder = ""
    var keyboard: UIKeyboardType = .default
    var mono = false
    var trailing: String? = nil
    var identifier: String? = nil
    var transform: ((String) -> String)? = nil

    var body: some View {
        HStack {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.white.opacity(0.25)))
            .font(.dgo(14, mono: mono))
            .foregroundStyle(.white)
            .tint(.brandPurple)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .accessibilityIdentifier(identifier ?? placeholder)
            // Filter in onChange: a transforming Binding setter doesn't reliably redraw the field.
            .onChange(of: text) { _, raw in
                if let transform, case let clean = transform(raw), clean != raw { text = clean }
            }
            if let trailing {
                Image(systemName: trailing).font(.system(size: 14)).white(0.3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .card(10, fill: Color.black.opacity(0.4), stroke: .white.opacity(0.1))
    }
}

struct SectionLabel: View {
    let text: String
    var opacity = 0.35
    var spacing: CGFloat = 1.8

    var body: some View {
        Text(text).font(.dgo(10, .black)).tracking(spacing).white(opacity)
    }
}

struct CouponField: View {
    let coupon: AppliedCoupon?
    let onApply: (String) -> String?
    let onClear: () -> Void
    var label = "COUPON"

    @State private var value = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "ticket").font(.system(size: 11)).white(0.4)
                Text(label).font(.dgo(10, .bold)).tracking(1.4).white(0.4)
            }
            if let coupon {
                HStack {
                    Text("\(coupon.code) · \(coupon.percent)% off")
                        .font(.dgo(12)).foregroundStyle(Color.mint)
                        .accessibilityIdentifier("couponApplied")
                    Spacer()
                    Button("Remove") { onClear(); error = nil }
                        .font(.dgo(11, .bold)).white(0.45)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("couponRemove")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .card(10, fill: Color.emerald.opacity(0.08), stroke: .emerald.opacity(0.25))
            } else {
                HStack(spacing: 8) {
                    GhostField(
                        text: $value,
                        placeholder: "Enter code",
                        identifier: "couponInput",
                        transform: { String($0.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(16)) }
                    )
                    .onChange(of: value) { error = nil }
                    Button {
                        error = onApply(value)
                        if error == nil { value = "" }
                    } label: {
                        Text("Apply").font(.dgo(12, .black)).white(0.8)
                            .padding(.horizontal, 12).padding(.vertical, 11)
                            .card(10, fill: Color.white.opacity(0.06), stroke: .white.opacity(0.12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("couponApply")
                }
            }
            if let error {
                Text(error).font(.dgo(11)).foregroundStyle(Color.danger.opacity(0.8))
                    .accessibilityIdentifier("couponError")
            }
        }
    }
}

struct RadioDot: View {
    let selected: Bool
    let accent: Color
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            if selected {
                Circle().fill(accent)
                Image(systemName: "checkmark").font(.system(size: size * 0.5, weight: .heavy)).foregroundStyle(.white)
            } else {
                Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
    }
}

struct Divider1: View {
    var opacity = 0.08
    var body: some View { Rectangle().fill(Color.white.opacity(opacity)).frame(height: 1) }
}

struct ErrorBanner: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.dgo(12)).foregroundStyle(Color.rose)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .card(10, fill: Color.danger.opacity(0.08), stroke: .danger.opacity(0.2))
            .accessibilityIdentifier("paymentError")
    }
}
