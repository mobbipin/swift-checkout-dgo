import SwiftUI

private let cancelReasons = [
    "Too expensive",
    "Not enough to watch",
    "Technical issues",
    "Only needed it temporarily",
    "Other",
]

private let accountRed = Color(argb: 0xFFDA2128)

struct AccountScreen: View {
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        let session = vm.session
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Chip(icon: "person.2.fill", count: "1")
                        Spacer()
                        Chip(icon: "bell.fill", count: "2", dot: true)
                    }
                    Text("U").font(.dgo(28, .black)).foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.brandPurple, in: Circle())
                        .overlay(Circle().strokeBorder(Color.brandPurple.opacity(0.35), lineWidth: 2))
                }
                .padding(.top, 8)
                .padding(.bottom, 18)

                Text("Premium User").font(.dgo(18, .black)).foregroundStyle(.white)
                Text(session != nil ? "ACTIVE" : "GUEST")
                    .font(.dgo(9, .black)).tracking(0.8).foregroundStyle(accountRed)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .card(4, fill: Color(argb: 0x26DA2128), stroke: Color(argb: 0x66DA2128))
                    .padding(.top, 6)
                    .accessibilityIdentifier("accountBadge")
                Text(verbatim: "user@dgo.global").font(.dgo(12)).white(0.4).padding(.top, 8)

                Group {
                    if let session {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                SectionLabel(text: "ACTIVE PLAN", spacing: 1.4)
                                Text("\(session.tier.meta.name) · \(session.duration.label)")
                                    .font(.dgo(16, .black)).foregroundStyle(.white)
                                    .accessibilityIdentifier("activePlan")
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        BrandButton(label: "Subscribe now", fullWidth: true, identifier: "subscribeNow") {
                            vm.openCheckout(manage: false)
                        }
                    }
                }
                .padding(.top, 18)

                GroupBox {
                    Button { vm.plansOpen.toggle() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "tv").font(.system(size: 16)).foregroundStyle(Color.brandPurple.opacity(0.7))
                            Text("My Plans").font(.dgo(16)).white(0.85)
                            Spacer()
                            Image(systemName: "chevron.down").font(.system(size: 14, weight: .semibold)).white(0.25)
                                .rotationEffect(.degrees(vm.plansOpen ? 180 : 0))
                        }
                        .padding(14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("myPlansToggle")

                    if vm.plansOpen {
                        let passes = Events.all.filter { vm.ownedPasses.contains($0.key) }
                        Divider1()
                        if session == nil && passes.isEmpty {
                            Text("No active plans on this account").font(.dgo(12)).white(0.4)
                                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if session != nil { PlanDetails(vm: vm) }
                        ForEach(passes, id: \.key) { PassRow(pass: $0) }
                        if vm.exclusiveEnabled {
                            Button { vm.openCheckout(exclusive: true) } label: {
                                Text("Browse exclusive events")
                                    .font(.dgo(12, .black)).foregroundStyle(Color.brandPurple)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("browseExclusive")
                        }
                    }
                    MenuRow(icon: "airplayvideo", label: "TV pairing code") { vm.accountNotice = "TV pairing is in the full app." }
                    MenuRow(icon: "gearshape", label: "App settings") { vm.accountNotice = "Settings are in the full app." }
                    MenuRow(icon: "globe", label: "Language") { vm.accountNotice = "Language follows the device for this prototype." }
                }
                .padding(.top, 12)

                GroupBox {
                    MenuRow(icon: "ticket", label: "Support tickets") { vm.accountNotice = "No open tickets." }
                    MenuRow(icon: "questionmark.circle", label: "Help") { vm.accountNotice = "Help centre is in the full app." }
                    MenuRow(icon: "info.circle", label: "About") { vm.accountNotice = "DGO checkout prototype · entitlement spec v3.0." }
                }
                .padding(.top, 12)

                if let notice = vm.accountNotice {
                    Text(notice).font(.dgo(12)).white(0.55)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4).padding(.top, 10)
                        .accessibilityIdentifier("accountNotice")
                }

                Button(action: vm.signOut) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 14))
                        Text("SIGN OUT").font(.dgo(12, .bold)).tracking(1)
                    }
                    .white(0.55)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
                .accessibilityIdentifier("signOut")

                Button(action: vm.goHome) {
                    Text("Back to home").font(.dgo(12, .bold)).white(0.4).padding(10)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .accessibilityIdentifier("accountHome")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("accountScroll")
    }
}

private struct PassRow: View {
    let pass: EventPass

    var body: some View {
        let accent = Color(argb: pass.accent)
        HStack(spacing: 10) {
            Image(systemName: "trophy.fill").font(.system(size: 16)).foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(pass.title) · \(pass.subtitle)").font(.dgo(14, .black)).foregroundStyle(.white)
                    .accessibilityIdentifier("pass_\(pass.key)")
                Text("One-time pass · Access until \(formatRenewalDate(pass.accessUntil))").font(.dgo(11)).white(0.45)
            }
            Spacer()
            Text("PASS").font(.dgo(9, .black)).foregroundStyle(accent)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(accent.opacity(0.14), in: Capsule())
        }
        .padding(12)
        .card(12, fill: Color.white.opacity(0.03), stroke: .white.opacity(0.08))
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }
}

private struct PlanDetails: View {
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        if let session = vm.session {
            let sku = Catalog.findSku(session.region, session.tier, session.duration)
            let ending = session.billingMode == .recurring && session.status == .canceling
            VStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(session.tier.meta.name) · \(session.duration.label)")
                                .font(.dgo(14, .black)).foregroundStyle(.white)
                            if session.billingMode == .recurring {
                                Text(ending ? "Cancellation scheduled" : "Auto-renewal on").font(.dgo(11)).white(0.4)
                                    .accessibilityIdentifier("renewalState")
                            }
                        }
                        Spacer()
                        Text(ending ? "ENDS SOON" : "ACTIVE")
                            .font(.dgo(9, .black))
                            .foregroundStyle(ending ? Color.amber : Color.emerald)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background((ending ? Color.amber : Color.emerald).opacity(0.12), in: Capsule())
                            .accessibilityIdentifier("planStatus")
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "calendar").font(.system(size: 12)).foregroundStyle(Color.brandPurple)
                        Text(dateLine(session)).font(.dgo(11)).white(0.5)
                            .accessibilityIdentifier("planDate")
                    }
                    .padding(.top, 10)
                    if session.billingMode == .recurring, let pending = session.pendingPlan {
                        Text("Changes to \(pending.tier.meta.name) · \(pending.duration.label) on \(formatRenewalDate(pending.effectiveDate))")
                            .font(.dgo(11)).white(0.55)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.brandPurple.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .padding(.top, 8)
                            .accessibilityIdentifier("pendingPlan")
                    }
                }
                .padding(12)
                .card(12, fill: Color.white.opacity(0.03), stroke: .white.opacity(0.08))

                actions(session, sku)
            }
            .padding(12)
        }
    }

    private func dateLine(_ session: SubscriptionSession) -> String {
        if session.billingMode == .prepaid { return "Access until \(formatRenewalDate(session.paidThrough))" }
        if session.status == .canceling { return "Access until \(formatRenewalDate(session.nextBillingDate ?? session.paidThrough))" }
        return "Next bill \(formatRenewalDate(session.nextBillingDate))"
    }

    @ViewBuilder
    private func actions(_ session: SubscriptionSession, _ sku: SubscriptionSku?) -> some View {
        if session.billingMode == .prepaid {
            BrandButton(label: "Add time or upgrade", leading: "arrow.clockwise", fullWidth: true, identifier: "accountAddTime") {
                vm.openCheckout(manage: true)
            }
        } else if session.status == .canceling && vm.confirmResume {
            VStack(alignment: .leading, spacing: 0) {
                Text("Resume auto-renewal?").font(.dgo(15, .black)).foregroundStyle(.white)
                Text("Next charge \(sku.map { formatMoney($0.price, $0.currency) + " " } ?? "")on \(formatRenewalDate(session.nextBillingDate ?? session.paidThrough)).")
                    .font(.dgo(12)).white(0.5)
                HStack(spacing: 8) {
                    OutlineButton(label: "Not now") { vm.confirmResume = false }
                    Button(action: vm.resumeRenewal) {
                        Text("Resume renewal").font(.dgo(12, .black)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color(argb: 0xFF10B981), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("resumeConfirm")
                }
                .padding(.top, 10)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(12, fill: Color.emerald.opacity(0.06), stroke: .emerald.opacity(0.2))
        } else if session.status == .canceling {
            Button { vm.confirmResume = true } label: {
                Text("Resume auto-renewal").font(.dgo(12, .black)).foregroundStyle(Color.mint)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .card(12, fill: Color.emerald.opacity(0.08), stroke: .emerald.opacity(0.25))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("resumeRenewal")
        } else if vm.cancelStep > 0 {
            CancelFlow(vm: vm)
        } else {
            HStack(spacing: 8) {
                OutlineButton(label: "Manage plan", icon: "creditcard") { vm.openCheckout(manage: true) }
                OutlineButton(label: "Cancel renewal") { vm.cancelStep = 1 }
            }
        }
    }
}

private struct CancelFlow: View {
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        let canContinue = vm.cancelStep != 2 || !vm.cancelReason.isEmpty
        let canConfirm = vm.cancelPhrase.trimmingCharacters(in: .whitespaces) == "CANCEL"
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("CANCEL RENEWAL").font(.dgo(10, .black)).tracking(1).foregroundStyle(Color.rose)
                Spacer()
                Text("Step \(vm.cancelStep) of 3").font(.dgo(10)).white(0.3)
                    .accessibilityIdentifier("cancelStep")
            }
            .padding(.bottom, 8)

            switch vm.cancelStep {
            case 1:
                Text("Before you cancel").font(.dgo(15, .black)).foregroundStyle(.white)
                Text("Access until \(formatRenewalDate(vm.session?.nextBillingDate)). Resume anytime before.")
                    .font(.dgo(12)).white(0.55)
            case 2:
                Text("Why are you leaving?").font(.dgo(15, .black)).foregroundStyle(.white).padding(.bottom, 8)
                ForEach(cancelReasons, id: \.self) { reason in
                    let on = vm.cancelReason == reason
                    Button { vm.cancelReason = reason } label: {
                        Text(reason).font(.dgo(12, .semibold))
                            .foregroundStyle(on ? Color.white : Color.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .card(8, fill: on ? Color.brandPurple.opacity(0.15) : Color.black.opacity(0.15),
                                  stroke: on ? .brandPurple.opacity(0.5) : .white.opacity(0.08))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 6)
                    .accessibilityIdentifier("reason_\(reason)")
                }
            default:
                Text("Final confirmation").font(.dgo(15, .black)).foregroundStyle(.white)
                Text("Type CANCEL to confirm.").font(.dgo(12)).white(0.5)
                GhostField(
                    text: $vm.cancelPhrase,
                    placeholder: "Type CANCEL",
                    identifier: "cancelPhrase",
                    transform: { String($0.uppercased().filter(\.isLetter).prefix(8)) }
                )
                .padding(.top, 8)
            }

            HStack(spacing: 8) {
                OutlineButton(label: vm.cancelStep == 1 ? "Keep plan" : "Back") {
                    if vm.cancelStep == 1 {
                        vm.cancelStep = 0
                        vm.cancelReason = ""
                        vm.cancelPhrase = ""
                    } else {
                        vm.cancelStep -= 1
                    }
                }
                let enabled = vm.cancelStep < 3 ? canContinue : canConfirm
                Button {
                    if vm.cancelStep < 3 { vm.cancelStep += 1 } else { vm.cancelRenewal() }
                } label: {
                    Text(vm.cancelStep < 3 ? "Continue" : "Turn off renewal")
                        .font(.dgo(12, .black))
                        .foregroundStyle(Color.white.opacity(enabled ? 1 : 0.35))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(
                            vm.cancelStep < 3
                                ? Color.white.opacity(canContinue ? 0.12 : 0.04)
                                : Color(argb: 0xFFEF4444).opacity(canConfirm ? 0.85 : 0.25),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .accessibilityIdentifier("cancelNext")
            }
            .padding(.top, 10)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(12, fill: Color.danger.opacity(0.06), stroke: .danger.opacity(0.2))
    }
}

private struct GroupBox<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .frame(maxWidth: .infinity)
            .card(16, fill: Color.white.opacity(0.04), stroke: .white.opacity(0.1))
    }
}

private struct MenuRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Divider1()
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Color.brandPurple.opacity(0.7)).frame(width: 20)
                Text(label).font(.dgo(16)).white(0.85)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).white(0.2)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("menu_\(label)")
    }
}

private struct Chip: View {
    let icon: String
    let count: String
    var dot = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Color.brandPurple.opacity(0.8))
                .overlay(alignment: .topTrailing) {
                    if dot { Circle().fill(accountRed).frame(width: 5, height: 5).offset(x: 2, y: -1) }
                }
            Text(count).font(.dgo(10, .bold)).white(0.55)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .capsuleCard(fill: Color.white.opacity(0.05), stroke: .white.opacity(0.1))
    }
}

private struct OutlineButton: View {
    let label: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 12)) }
                Text(label).font(.dgo(12, .bold))
            }
            .white(0.65)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("outline_\(label)")
    }
}
