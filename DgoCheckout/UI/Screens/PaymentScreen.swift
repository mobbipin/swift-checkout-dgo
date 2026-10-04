import SwiftUI

struct PaymentScreen: View {
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        let title = vm.sku.map { "\($0.tier.meta.name) · \($0.duration.label)" } ?? "DGO plan"
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if vm.region.stripe {
                    StripeHostedCheckout(vm: vm, title: title)
                } else {
                    NepalCheckout(vm: vm, title: title)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("paymentScroll")
    }
}

private struct PayCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(16, fill: Color.ink, stroke: .white.opacity(0.12))
    }
}

private struct NepalCheckout: View {
    @Bindable var vm: CheckoutViewModel
    let title: String

    var body: some View {
        let currency = vm.sku?.currency ?? vm.region.currency
        let price = formatMoney(vm.dueAmount, currency)
        let list = formatMoney(vm.amount, currency)

        PayCard {
            SectionLabel(text: "DUE TODAY")
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(price).font(.dgo(30, .black)).foregroundStyle(.white)
                    .accessibilityIdentifier("dueToday")
                if vm.coupon != nil {
                    Text(list).font(.dgo(14, .bold)).white(0.3).strikethrough()
                }
            }
            Text(title).font(.dgo(14, .bold)).white(0.8)
                .accessibilityIdentifier("payTitle")
            Text("Local wallets" + (vm.sku.map { " · \(billingCadenceLabel($0.duration, $0.region))" } ?? ""))
                .font(.dgo(12)).white(0.4)

            CouponField(coupon: vm.coupon, onApply: vm.applyCoupon, onClear: vm.clearCoupon)
                .padding(.top, 16)

            SectionLabel(text: "PAYMENT METHOD").padding(.top, 20)
            VStack(spacing: 0) {
                ForEach(Array(NepalPsp.allCases.enumerated()), id: \.element) { index, method in
                    if index > 0 { Divider1() }
                    NepalMethodRow(method: method, vm: vm)
                }
            }
            .card(12, fill: Color.white.opacity(0.03), stroke: .white.opacity(0.1))
            .padding(.top, 8)

            if let error = vm.paymentError {
                ErrorBanner(text: error).padding(.top, 10)
            }

            BrandButton(
                label: vm.nepalPsp.map { "Pay \(price) via \($0.title)" } ?? "Pay \(price)",
                enabled: vm.nepalPsp != nil,
                leading: "lock.fill",
                fullWidth: true,
                identifier: "payButton"
            ) { vm.submitNepalPayment() }
            .padding(.top, 14)

            Text("Prototype · no live charge").font(.dgo(10)).white(0.3)
                .frame(maxWidth: .infinity).padding(.top, 10)
        }
    }
}

private struct NepalMethodRow: View {
    let method: NepalPsp
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        let open = vm.nepalPsp == method
        VStack(alignment: .leading, spacing: 0) {
            Button {
                vm.nepalPsp = method
                vm.paymentError = nil
            } label: {
                HStack(spacing: 10) {
                    RadioDot(selected: open, accent: .stripePurple)
                    PspMark(method: method)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(method.title).font(.dgo(14, .bold)).foregroundStyle(.white)
                        Text(method.tagline).font(.dgo(11)).white(0.4)
                    }
                    Spacer()
                    if method == .getpay {
                        Badge(text: "VISA")
                        Badge(text: "MC")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(open ? Color.stripePurple.opacity(0.12) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("psp_\(method.rawValue)")

            if open && method != .getpay {
                VStack(alignment: .leading, spacing: 8) {
                    GhostField(
                        text: $vm.mobileNumber,
                        placeholder: method == .connectips ? "Account / Customer ID" : "98XXXXXXXX",
                        keyboard: method == .connectips ? .default : .numberPad,
                        identifier: "walletInput",
                        transform: { raw in
                            method == .connectips
                                ? String(raw.filter { $0.isLetter || $0.isNumber || "/_-".contains($0) }.prefix(24))
                                : String(raw.filter(\.isNumber).prefix(14))
                        }
                    )
                    .onChange(of: vm.mobileNumber) { vm.paymentError = nil }
                    Text("Continues in \(method.title)").font(.dgo(11)).white(0.4)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 4)
            }
            if open && method == .getpay {
                CardFields(vm: vm)
            }
        }
    }
}

private struct PspMark: View {
    let method: NepalPsp

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05))
            if let image = method.image {
                Image(image).resizable().scaledToFit().padding(3)
            } else {
                Text(method.emoji).font(.system(size: 12))
            }
        }
        .frame(width: 40, height: 24)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct CardFields: View {
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                GhostField(
                    text: $vm.cardForm.number,
                    placeholder: "1234 1234 1234 1234",
                    keyboard: .numberPad,
                    mono: true,
                    trailing: "creditcard",
                    identifier: "cardNumber",
                    transform: vm.formatCard
                )
                HStack(spacing: 0) {
                    GhostField(
                        text: $vm.cardForm.expiry,
                        placeholder: "MM / YY",
                        keyboard: .numberPad,
                        mono: true,
                        identifier: "cardExpiry",
                        transform: vm.formatExpiry
                    )
                    GhostField(
                        text: $vm.cardForm.cvc,
                        placeholder: "CVC",
                        keyboard: .numberPad,
                        mono: true,
                        identifier: "cardCvc",
                        transform: { String($0.filter(\.isNumber).prefix(3)) }
                    )
                }
            }
            .card(12, fill: Color.black.opacity(0.35), stroke: .white.opacity(0.1))
            GhostField(text: $vm.cardForm.name, placeholder: "Name on card", identifier: "cardName")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onChange(of: vm.cardForm) { vm.paymentError = nil }
    }
}

private struct Badge: View {
    let text: String
    var body: some View {
        Text(text).font(.dgo(9, .black)).white(0.7)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
    }
}

private struct StripeHostedCheckout: View {
    @Bindable var vm: CheckoutViewModel
    let title: String

    var body: some View {
        let sku = vm.sku
        let currency = sku?.currency ?? vm.region.currency
        let due = dueTodayCaption(vm.planChange, vm.dueAmount, currency)
        let kind = vm.planChange?.kind
        let newSubscription = kind == nil || kind == .new
        let money = due.hasPrefix("$") || due.hasPrefix("रू")

        PayCard {
            SectionLabel(text: "ORDER SUMMARY")
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.dgo(15, .bold)).foregroundStyle(.white)
                        .accessibilityIdentifier("payTitle")
                    Text(sku.map { billingCadenceLabel($0.duration, $0.region) } ?? "")
                        .font(.dgo(12)).white(0.45)
                }
                Spacer()
                if sku != nil && newSubscription {
                    Text(formatMoney(vm.amount, currency)).font(.dgo(14, .bold)).white(0.7)
                }
            }
            .padding(.top, 10)

            if let current = vm.session, !newSubscription {
                Text(lifecycleNote(current, vm.planChange))
                    .font(.dgo(12)).white(0.5).lineSpacing(3)
                    .padding(.top, 10)
                    .accessibilityIdentifier("payLifecycleNote")
            }
            if newSubscription, let coupon = vm.coupon {
                HStack {
                    Text("Promo \(coupon.code)")
                    Spacer()
                    Text("−" + formatMoney(vm.amount - vm.dueAmount, currency)).fontWeight(.bold)
                }
                .font(.dgo(12)).foregroundStyle(Color.emerald)
                .padding(.top, 8)
            }

            Divider1().padding(.vertical, 14)

            HStack {
                Text("Due today").font(.dgo(13, .bold)).white(0.6)
                Spacer()
                Text(due).font(.dgo(money ? 26 : 18, .black)).foregroundStyle(.white)
                    .accessibilityIdentifier("dueToday")
            }

            if newSubscription {
                CouponField(coupon: vm.coupon, onApply: vm.applyCoupon, onClear: vm.clearCoupon, label: "PROMO CODE")
                    .padding(.top, 18)
            }
        }

        StripePanel(newSubscription: newSubscription).padding(.top, 12)

        if let error = vm.paymentError {
            ErrorBanner(text: error).padding(.top, 10)
        }

        BrandButton(
            label: {
                switch kind {
                case .providerDowngrade: "Schedule on Stripe"
                case .providerUpgrade: "Continue to Stripe"
                default: "Continue to Stripe · \(due)"
                }
            }(),
            leading: "lock.fill",
            fullWidth: true,
            identifier: "stripeButton"
        ) { vm.submitStripePayment() }
        .padding(.top, 16)

        Text("Prototype · no live charge").font(.dgo(10)).white(0.3)
            .frame(maxWidth: .infinity).padding(.top, 10)
    }
}

private struct StripePanel: View {
    let newSubscription: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "SECURE PAYMENT BY", opacity: 0.45, spacing: 1.6)
                    Image("stripe_wordmark").resizable().scaledToFit().frame(height: 30)
                        .accessibilityLabel("Stripe")
                }
                Spacer()
                Image(systemName: "lock").font(.system(size: 20, weight: .semibold)).foregroundStyle(Color.stripePurple)
            }
            Text(newSubscription ? "You’ll finish on Stripe’s secure page." : "Confirm the change on Stripe’s secure page.")
                .font(.dgo(12)).white(0.6)
                .padding(.top, 6)
            if newSubscription {
                HStack(spacing: 6) {
                    ForEach(["Card", "Apple Pay", "Google Pay", "Link"], id: \.self) { label in
                        Text(label).font(.dgo(11, .bold)).white(0.8).lineLimit(1)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .capsuleCard(fill: Color.black.opacity(0.25), stroke: .white.opacity(0.14))
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(
            16,
            fill: LinearGradient(colors: [Color.stripePurple.opacity(0.22), Color.stripePurple.opacity(0.06)], startPoint: .top, endPoint: .bottom),
            stroke: .stripePurple.opacity(0.55)
        )
    }
}
