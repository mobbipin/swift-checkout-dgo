import SwiftUI

struct ChoosePlanScreen: View {
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        let selected = vm.sku
        let change = vm.planChange
        let selectedCurrent = vm.manageMode && selected != nil && vm.session?.skuId == selected?.id

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(vm.region.billedIn)
                    .font(.dgo(11, .semibold)).white(0.5)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .capsuleCard(fill: Color.white.opacity(0.04), stroke: .white.opacity(0.1))
                    .accessibilityIdentifier("billedIn")

                Text(headline)
                    .font(.dgo(34, .black)).tracking(-0.7).foregroundStyle(.white)
                    .padding(.top, 14)
                    .accessibilityIdentifier("planHeadline")

                Group {
                    if vm.manageMode, let session = vm.session {
                        Text("Current: \(session.tier.meta.name) · \(session.duration.label)")
                    } else {
                        Text("Mobile for phones. Plus adds TV.")
                    }
                }
                .font(.dgo(14)).white(0.5).padding(.top, 8)

                DurationTabs(region: vm.region, tier: vm.tier, selected: vm.duration) { vm.duration = $0 }
                    .padding(.top, 22)

                PlanPager(vm: vm).padding(.top, 18)

                if vm.manageMode, vm.session?.status == .canceling {
                    Text("Renewal is off. A new plan turns it back on.")
                        .font(.dgo(12)).foregroundStyle(Color.amber)
                        .padding(.top, 12)
                }
                if vm.manageMode, let session = vm.session {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle").font(.system(size: 15)).foregroundStyle(Color.brandPurple)
                        Text(lifecycleNote(session, change)).font(.dgo(12)).white(0.5).lineSpacing(4)
                            .accessibilityIdentifier("lifecycleNote")
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .card(16, fill: Color.white.opacity(0.04), stroke: .white.opacity(0.1))
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selected.map { $0.tier.meta.name } ?? "Choose a plan")
                        .font(.dgo(12, .bold)).foregroundStyle(.white).lineLimit(1)
                        .accessibilityIdentifier("summaryName")
                    Text(summaryLine(selected, change))
                        .font(.dgo(11)).white(0.4)
                        .accessibilityIdentifier("summaryPrice")
                }
                Spacer()
                BrandButton(
                    label: planActionLabel(change, currentPlan: selectedCurrent),
                    enabled: vm.canAdvanceFromPlan,
                    identifier: "planContinue",
                    action: vm.nextFromPlan
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.9).ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Divider1(opacity: 0.1) }
        }
    }

    private var headline: String {
        if vm.manageMode && vm.session != nil { return "Change your plan" }
        if vm.manageMode { return "Add time or upgrade" }
        return "Choose your plan"
    }

    private func summaryLine(_ sku: SubscriptionSku?, _ change: PlanChange?) -> String {
        guard let sku else { return "Select a package" }
        let showDue: Set<PlanChangeKind> = [.providerUpgrade, .providerDowngrade, .deferred, .current]
        if let kind = change?.kind, showDue.contains(kind) {
            return "\(sku.duration.label) · \(dueTodayCaption(change, vm.amount, sku.currency))"
        }
        return "\(sku.duration.label) · \(formatMoney(vm.amount, sku.currency))"
    }
}

private struct PlanPager: View {
    @Bindable var vm: CheckoutViewModel
    @State private var page: PlanTier?

    var body: some View {
        let tiers = Catalog.tiers
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(tiers, id: \.self) { tier in
                        TierCard(id: tier, vm: vm, active: (page ?? vm.tier) == tier)
                            .containerRelativeFrame(.horizontal)
                            .id(tier)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 8, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $page)
            .scrollIndicators(.hidden)
            .padding(.horizontal, -8)
            .accessibilityIdentifier("tierPager")

            HStack(spacing: 2) {
                ForEach(tiers, id: \.self) { tier in
                    let on = (page ?? vm.tier) == tier
                    Button { withAnimation { page = tier } } label: {
                        Circle()
                            .fill(on ? Color(argb: tier.meta.accent) : Color.white.opacity(0.25))
                            .frame(width: on ? 8 : 6, height: on ? 8 : 6)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tier.meta.shortName)
                    .accessibilityIdentifier("pagerDot_\(tier.rawValue)")
                }
            }
            .padding(.top, 10)

            Text("Swipe for \((page ?? vm.tier) == tiers.first ? "Mobile" : "Plus")")
                .font(.dgo(11)).white(0.35)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .onAppear { page = vm.tier }
        .onChange(of: page) { _, next in
            if let next, vm.tier != next { vm.tier = next }
        }
        .onChange(of: vm.tier) { _, next in
            if page != next { withAnimation { page = next } }
        }
    }
}

private struct DurationTabs: View {
    let region: PriceRegion
    let tier: PlanTier
    let selected: PlanDuration
    let onSelect: (PlanDuration) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Catalog.durations, id: \.self) { duration in
                let active = selected == duration
                let sample = Catalog.findSku(region, tier, duration)
                let save = savingsVsMonthly(region, tier, duration)
                let sports = sample?.liveSports ?? (duration != .m01)
                Button { onSelect(duration) } label: {
                    VStack(spacing: 0) {
                        Text(duration.label).font(.dgo(15, .black))
                            .foregroundStyle(active ? Color.white : Color.white.opacity(0.72))
                        Text(rateLine(sample, save, duration))
                            .font(.dgo(10, .medium)).lineLimit(1).minimumScaleFactor(0.8)
                            .foregroundStyle(Color.white.opacity(active ? 0.82 : 0.38))
                        Text(sports ? "Live sports" : "No live sports")
                            .font(.dgo(11, .bold))
                            .foregroundStyle(active ? Color.white : Color.white.opacity(sports ? 0.55 : 0.32))
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .background {
                        if active { RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.gradient) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("duration_\(duration.rawValue)")
            }
        }
        .padding(5)
        .card(22, fill: Color(argb: 0xFF121212), stroke: .white.opacity(0.1))
    }

    private func rateLine(_ sample: SubscriptionSku?, _ save: Savings?, _ duration: PlanDuration) -> String {
        var line = sample.map(formatMonthlyRate) ?? "—"
        if duration == .m12, let save { line += " · −\(save.percent)%" }
        return line
    }
}

private struct TierCard: View {
    let id: PlanTier
    let vm: CheckoutViewModel
    let active: Bool

    var body: some View {
        let meta = id.meta
        let row = Catalog.findSku(vm.region, id, vm.duration)
        let currentPlan = vm.manageMode && row != nil && vm.session?.skuId == row?.id
        let rowChange = resolvePlanChange(vm.session, row, manageMode: vm.manageMode)
        let save: Savings? = (row != nil && rowChange?.kind != .fixedTierUpgrade && rowChange?.kind != .deferred)
            ? savingsVsMonthly(vm.region, id, vm.duration) : nil
        let compareAt = save != nil ? compareAtPrice(vm.region, id, vm.duration) : 0
        let displayAmount: Double = {
            guard let row else { return 0 }
            if rowChange?.kind == .fixedTierUpgrade { return rowChange!.amount }
            return row.price
        }()
        let accent = Color(argb: meta.accent)
        let state = planStateLabel(rowChange?.kind)

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(meta.shortName).font(.dgo(22, .black)).foregroundStyle(.white)
                Spacer()
                if currentPlan || state != nil {
                    Text(currentPlan ? "Current" : (state ?? ""))
                        .font(.dgo(11, .black))
                        .foregroundStyle(currentPlan ? Color.emerald : accent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(currentPlan ? Color.emerald.opacity(0.14) : accent.opacity(0.16), in: Capsule())
                        .accessibilityIdentifier("tierState_\(id.rawValue)")
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 0) {
                if save != nil, compareAt > 0, let row {
                    Text(formatMoney(compareAt, row.currency))
                        .font(.dgo(18, .bold)).white(0.3).strikethrough()
                        .padding(.trailing, 8)
                }
                Text(row.map { formatMoney(displayAmount, $0.currency) } ?? "—")
                    .font(.dgo(36, .black)).tracking(-0.8).foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .accessibilityIdentifier("tierPrice_\(id.rawValue)")
                if let save {
                    Text("−\(save.percent)%")
                        .font(.dgo(10, .black)).foregroundStyle(Color.emerald)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.emerald.opacity(0.12), in: Capsule())
                        .padding(.leading, 8)
                }
            }
            .padding(.top, 14)

            Text(subline(row, rowChange))
                .font(.dgo(13)).white(0.45)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(meta.facts, id: \.self) { FactRow(text: $0, accent: accent) }
                FactRow(
                    text: row?.liveSports == true ? "Live sports included" : "No live sports",
                    accent: accent,
                    dim: row?.liveSports != true
                )
            }
            .padding(.top, 16)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [accent.opacity(active ? 0.16 : 0.05), Color(argb: 0xFF09090B)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(active ? Color(argb: meta.border) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tierCard_\(id.rawValue)")
    }

    private func subline(_ row: SubscriptionSku?, _ change: PlanChange?) -> String {
        switch change?.kind {
        case .fixedTierUpgrade: return "Pay the difference · same end date"
        case .providerUpgrade: return "Starts now · pay only the difference"
        case .providerDowngrade: return "Starts next bill · $0 today"
        case .deferred: return "After your current term"
        case .renewal: return "+\(vm.duration.label) after this term"
        case .immediateExtension: return "Added after this term"
        default:
            var parts: [String] = []
            if let row, row.duration != .m01 {
                parts.append(formatMonthlyRate(row))
            }
            parts.append(billingCadenceLabel(vm.duration, vm.region))
            return parts.joined(separator: " · ")
        }
    }
}

private struct FactRow: View {
    let text: String
    let accent: Color
    var dim = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                .foregroundStyle(dim ? accent.opacity(0.35) : accent)
            Text(text).font(.dgo(13)).white(dim ? 0.4 : 0.7)
        }
        .padding(.vertical, 3)
    }
}
