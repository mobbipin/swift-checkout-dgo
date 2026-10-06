import SwiftUI

struct CatalogTabs: View {
    let selected: CatalogTab
    let onSelect: (CatalogTab) -> Void

    var body: some View {
        HStack(spacing: 4) {
            cell("Plans", icon: "tv", tab: .plans)
            cell("Exclusive", icon: "ticket", tab: .exclusive)
        }
        .padding(4)
        .background(Color(argb: 0xFF121212), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func cell(_ label: String, icon: String, tab: CatalogTab) -> some View {
        let active = selected == tab
        return Button { onSelect(tab) } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(active ? Color.black : Color.white.opacity(0.55))
                Text(label).font(.dgo(13, .black))
                    .foregroundStyle(active ? Color.black : Color.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? Color.white : Color.clear, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("catalogTab_\(label)")
    }
}

struct ExclusiveCatalog: View {
    @Bindable var vm: CheckoutViewModel
    @State private var page: String?

    var body: some View {
        let events = Events.all
        let current = page ?? vm.eventKey

        Text("Exclusive events")
            .font(.dgo(34, .black)).tracking(-0.7).foregroundStyle(.white)
            .padding(.top, 18)
            .accessibilityIdentifier("exclusiveHeadline")
        Text("One-time passes. No subscription needed.")
            .font(.dgo(14)).white(0.5).padding(.top, 8)

        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(events, id: \.key) { event in
                    EventCard(event: event, vm: vm, active: current == event.key)
                        .containerRelativeFrame(.horizontal)
                        .id(event.key)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 8, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .padding(.horizontal, -8)
        .padding(.top, 20)
        .accessibilityIdentifier("eventPager")
        .onAppear { page = vm.eventKey }
        .onChange(of: page) { _, next in
            if let next, vm.eventKey != next { vm.eventKey = next }
        }
        .onChange(of: vm.eventKey) { _, next in
            if page != next { page = next }
        }

        HStack(spacing: 2) {
            ForEach(events, id: \.key) { event in
                let on = current == event.key
                Button { withAnimation { page = event.key } } label: {
                    Circle()
                        .fill(on ? Color(argb: event.accent) : Color.white.opacity(0.25))
                        .frame(width: on ? 8 : 6, height: on ? 8 : 6)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(event.subtitle)
                .accessibilityIdentifier("eventDot_\(event.key)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)

        Text("Works with or without a plan")
            .font(.dgo(11)).white(0.35)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}

private struct EventCard: View {
    let event: EventPass
    let vm: CheckoutViewModel
    let active: Bool

    var body: some View {
        let accent = Color(argb: event.accent)
        let ownership = passOwnership(event, vm.ownedPasses)

        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [accent.opacity(active ? 0.7 : 0.35), Color(argb: 0xFF1A0B2E), Color(argb: 0xFF09090B)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "trophy.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(Color.white.opacity(0.12))
                    .offset(x: 18)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                HStack(spacing: 6) {
                    Pill(text: event.league, fill: Color.white.opacity(0.16), color: .white)
                    Pill(text: "LIVE EVENT", fill: Color.black.opacity(0.35), color: .white.opacity(0.85))
                    Spacer()
                    if let ownership {
                        Pill(text: ownership == .owned ? "Owned" : "Included", fill: Color.emerald.opacity(0.2), color: .emerald)
                            .accessibilityIdentifier("eventState_\(event.key)")
                    }
                }
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .top)
                VStack(alignment: .leading, spacing: 0) {
                    Text(event.title).font(.dgo(30, .black)).tracking(-0.8).foregroundStyle(.white)
                    Text(event.subtitle).font(.dgo(13, .bold)).white(0.8)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(height: 150)
            .clipped()

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(formatMoney(event.price(vm.region), vm.region.currency))
                        .font(.dgo(34, .black)).tracking(-0.8).foregroundStyle(.white)
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .accessibilityIdentifier("eventPrice_\(event.key)")
                    Pill(text: "One-time", fill: Color.white.opacity(0.08), color: .white.opacity(0.7))
                }
                Text("\(event.window) · Access until \(formatRenewalDate(event.accessUntil))")
                    .font(.dgo(13)).white(0.45)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(event.includes, id: \.self) { line in
                        IncludeRow(text: line, accent: accent)
                    }
                    IncludeRow(text: "No renewal, no subscription", accent: accent, dim: true)
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(argb: 0xFF09090B))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(active ? accent.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("eventCard_\(event.key)")
    }
}

private struct IncludeRow: View {
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

private struct Pill: View {
    let text: String
    let fill: Color
    let color: Color

    var body: some View {
        Text(text)
            .font(.dgo(10, .black)).tracking(0.8)
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(fill, in: Capsule())
    }
}

struct EventBottomBar: View {
    let vm: CheckoutViewModel

    var body: some View {
        let event = vm.event
        let ownership = event.flatMap { passOwnership($0, vm.ownedPasses) }
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event?.title ?? "Choose an event")
                    .font(.dgo(12, .bold)).foregroundStyle(.white).lineLimit(1)
                    .accessibilityIdentifier("summaryName")
                Text(event.map { "\($0.subtitle) · \(formatMoney($0.price(vm.region), vm.region.currency))" } ?? "")
                    .font(.dgo(11)).white(0.4).lineLimit(1)
                    .accessibilityIdentifier("summaryPrice")
            }
            Spacer()
            BrandButton(
                label: {
                    switch ownership {
                    case .owned: "Owned"
                    case .included: "Included"
                    case nil: "Buy pass"
                    }
                }(),
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
