import SwiftUI

struct ConfirmationScreen: View {
    let vm: CheckoutViewModel

    @State private var seconds = 10

    private static let autoHome = ProcessInfo.processInfo.arguments.contains("-uiTestNoAutoHome") ? Int.max : 10

    var body: some View {
        let sku = vm.sku
        let kind = vm.completedKind
        let detail = sku.map { "\($0.tier.meta.name) · \($0.duration.label)" } ?? ""

        ZStack {
            Circle().fill(Color.brandPurple.opacity(0.18)).frame(width: 80, height: 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Circle().fill(Color.brandPink.opacity(0.10)).frame(width: 70, height: 70)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            VStack(spacing: 0) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(seconds) / 10)
                        .stroke(Brand.ringGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.9), value: seconds)
                    Circle().fill(Brand.gradient).frame(width: 48, height: 48)
                    Image(systemName: "checkmark").font(.system(size: 20, weight: .heavy)).foregroundStyle(.white)
                }
                .frame(width: 72, height: 72)

                Text(title(kind)).font(.dgo(28, .black)).foregroundStyle(.white)
                    .padding(.top, 20)
                    .accessibilityIdentifier("confirmTitle")
                Text(detail).font(.dgo(14)).white(0.5)
                    .accessibilityIdentifier("confirmDetail")
                if kind == .providerDowngrade, let session = vm.session {
                    Text("Starts \(formatRenewalDate(session.nextBillingDate ?? session.paidThrough))")
                        .font(.dgo(12)).white(0.35)
                }

                VStack(spacing: 0) {
                    ConfirmRow(label: "Paid today", value: paidToday(kind, sku))
                    Divider1()
                    ConfirmRow(label: "Payment", value: vm.lastPaymentLabel)
                    if let sku {
                        Divider1()
                        ConfirmRow(label: sku.region == .nepal ? "Access" : "Schedule", value: schedule(kind, sku))
                    }
                }
                .card(12, fill: Color.white.opacity(0.03), stroke: .white.opacity(0.08))
                .padding(.top, 20)

                Text(vm.orderRef)
                    .font(.dgo(11, mono: true)).white(0.3)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .capsuleCard(fill: Color.white.opacity(0.04), stroke: .white.opacity(0.08))
                    .padding(.top, 12)
                    .accessibilityIdentifier("orderRef")

                BrandButton(label: "Go to home", leading: "play.fill", fullWidth: true, identifier: "goHome", action: vm.goHome)
                    .padding(.top, 24)

                Text("Home in \(seconds)s").font(.dgo(12)).white(0.35)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 36)
            .card(24, fill: Color.surface, stroke: .white.opacity(0.1))
        }
        .padding(20)
        .task {
            guard Self.autoHome != .max else { return }
            for _ in 0..<Self.autoHome {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                seconds -= 1
            }
            vm.goHome()
        }
    }

    private func title(_ kind: PlanChangeKind) -> String {
        switch kind {
        case .providerDowngrade: "Plan change scheduled"
        case .providerUpgrade, .fixedTierUpgrade: "Plan updated"
        case .renewal, .immediateExtension: "Time added"
        default: "You're in"
        }
    }

    private func paidToday(_ kind: PlanChangeKind, _ sku: SubscriptionSku?) -> String {
        switch kind {
        case .providerDowngrade: "No charge today"
        case .providerUpgrade: "Price difference"
        default: formatMoney(vm.dueAmount, sku?.currency ?? vm.region.currency)
        }
    }

    private func schedule(_ kind: PlanChangeKind, _ sku: SubscriptionSku) -> String {
        switch kind {
        case .fixedTierUpgrade: "Access date unchanged"
        case .providerDowngrade: "Starts on the next bill"
        case .providerUpgrade: "Billing date kept"
        case .renewal, .immediateExtension: "\(sku.duration.label) added after this term"
        default: sku.region == .nepal ? "\(sku.duration.label) of access" : billingCadenceLabel(sku.duration, sku.region)
        }
    }
}

private struct ConfirmRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.dgo(12)).white(0.4)
            Spacer()
            Text(value).font(.dgo(12, .bold)).white(0.8)
                .accessibilityIdentifier("confirm_\(label)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
