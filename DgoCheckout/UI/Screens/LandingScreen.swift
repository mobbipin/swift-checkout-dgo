import SwiftUI

struct LandingScreen: View {
    @Bindable var vm: CheckoutViewModel

    var body: some View {
        let tab = LandingCatalog.tab(vm.tabId)
        ZStack(alignment: .bottom) {
            (tab.id == "junior" ? Color(argb: 0xFF0A1529) : Color.black).ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(onSearch: { vm.searchOpen = true }, onHome: { vm.selectTab("home") })
                TabStrip(selected: tab.id, onSelect: vm.selectTab)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        HeroBlock(tab: tab, onOpen: { vm.detail = $0 }, onPlans: { vm.openCheckout(manage: vm.session != nil) })
                            .id(tab.id)
                        if tab.id == "home" {
                            SubscribeDrive(vm: vm)
                        } else if tab.partnerTagline != nil {
                            PartnerBanner(tab: tab)
                        }
                        ForEach(tab.rails, id: \.title) { rail in
                            RailBlock(title: rail.title, accent: Color(argb: tab.color), items: rail.items) { vm.detail = $0 }
                        }
                        FooterNote()
                    }
                    .padding(.bottom, 96)
                }
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("landingScroll")
            }

            BottomBar(
                tabId: tab.id,
                onHome: { vm.selectTab("home") },
                onSearch: { vm.searchOpen = true },
                onBrowse: { vm.selectTab(tab.id == "home" ? "hotstar" : "home") },
                onAccount: vm.openAccount
            )

            if vm.searchOpen {
                SearchSheet(vm: vm).transition(.opacity)
            }
            if let item = vm.detail {
                DetailSheet(
                    item: item,
                    subscribed: vm.session != nil,
                    onClose: { vm.detail = nil },
                    onPlans: { vm.detail = nil; vm.openCheckout(manage: vm.session != nil) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: vm.searchOpen)
        .animation(.easeOut(duration: 0.2), value: vm.detail)
    }
}

private struct TopBar: View {
    let onSearch: () -> Void
    let onHome: () -> Void

    var body: some View {
        HStack {
            Button(action: onHome) {
                Image("dgo_logo").resizable().scaledToFit().frame(height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("logoHome")
            Spacer()
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold)).white(0.8)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("topSearch")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct TabStrip: View {
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(LandingCatalog.tabs, id: \.id) { tab in
                    let on = tab.id == selected
                    Button { onSelect(tab.id) } label: {
                        Text(tab.label)
                            .font(.dgo(12, .bold))
                            .foregroundStyle(on ? Color.black : Color.white.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(on ? Color(argb: tab.color) : Color.white.opacity(0.06), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("tab_\(tab.id)")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("tabStrip")
    }
}

private struct HeroBlock: View {
    let tab: LandingTab
    let onOpen: (TitleCard) -> Void
    let onPlans: () -> Void

    @State private var index = 0

    var body: some View {
        let slides = tab.hero
        if let slide = slides[safe: index] {
            ZStack(alignment: .bottomLeading) {
                Color.clear
                    .overlay {
                        if let art = slide.hero ?? slide.poster {
                            Image(art).resizable().scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [Color(argb: tab.color), Color(argb: tab.secondary), .black],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        }
                    }
                    .clipped()
                LinearGradient(
                    colors: [.black.opacity(0.15), .clear, .black.opacity(0.92)],
                    startPoint: .top, endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 0) {
                    Text(slide.tag.uppercased())
                        .font(.dgo(11, .black)).tracking(1.4)
                        .foregroundStyle(Color(argb: tab.secondary))
                    Text(slide.title)
                        .font(.dgo(34, .black)).foregroundStyle(.white)
                        .lineSpacing(-4)
                        .accessibilityIdentifier("heroTitle")
                    if !slide.subtitle.isEmpty {
                        Text(slide.subtitle).font(.dgo(13)).white(0.7).lineLimit(2)
                    }
                    Text(metaLine(slide)).font(.dgo(12)).white(0.45).padding(.top, 6)

                    HStack(spacing: 10) {
                        BrandButton(label: "Watch", leading: "play.fill", identifier: "heroWatch") { onOpen(slide) }
                        Button(action: onPlans) {
                            Text("See plans").font(.dgo(14, .bold)).foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("heroSeePlans")
                    }
                    .padding(.top, 14)

                    if slides.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(slides.indices, id: \.self) { i in
                                Capsule()
                                    .fill(i == index ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: i == index ? 18 : 8, height: 3)
                            }
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(20)
            }
            .frame(height: 460)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { onOpen(slide) }
            .animation(.easeInOut(duration: 0.4), value: index)
            .task(id: tab.id) {
                guard slides.count > 1 else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(7))
                    if Task.isCancelled { break }
                    index = (index + 1) % slides.count
                }
            }
        }
    }

    private func metaLine(_ slide: TitleCard) -> String {
        [
            slide.year.isEmpty ? nil : slide.year,
            slide.rating.isEmpty ? nil : "★ \(slide.rating)",
            slide.duration.isEmpty ? nil : slide.duration,
        ].compactMap { $0 }.joined(separator: "  ·  ")
    }
}

private struct SubscribeDrive: View {
    let vm: CheckoutViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let session = vm.session {
                SectionLabel(text: "YOUR PLAN", spacing: 1.6)
                Text(session.tier.meta.name).font(.dgo(20, .black)).foregroundStyle(.white).padding(.top, 6)
                    .accessibilityIdentifier("drivePlanName")
                Text(session.duration.label).font(.dgo(13)).white(0.45)
                BrandButton(
                    label: session.billingMode == .recurring ? "Manage plan" : "Add time or upgrade",
                    fullWidth: true,
                    identifier: "driveManage"
                ) { vm.openCheckout(manage: true) }
                .padding(.top, 12)
            } else {
                SectionLabel(text: "ONE MEMBERSHIP", opacity: 0.4)
                Text("Two houses.").font(.dgo(30, .black)).foregroundStyle(.white).padding(.top, 8)
                Text("The whole catalogue.").font(.dgo(30, .black)).foregroundStyle(Color.brandPink)
                Text("JioHotstar Specials and movies. OSR Digital's Nepali film library. Pick Mobile or Plus — then just watch.")
                    .font(.dgo(13)).white(0.5).lineSpacing(3).padding(.top, 8)
                BrandButton(label: "See plans", fullWidth: true, identifier: "driveSeePlans") { vm.openCheckout(manage: false) }
                    .padding(.top, 14)
                PlanTeaser(title: "DGO Mobile", line: "720p · phones & tablets", price: "From रू 199 / $3.99", accent: .brandPurple) {
                    vm.openCheckout(manage: false)
                }
                .padding(.top, 10)
                PlanTeaser(title: "DGO Plus", line: "1080p · TV & 3 streams", price: "From रू 299 / $5.99", accent: .brandPink) {
                    vm.openCheckout(manage: false)
                }
                .padding(.top, 8)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(28, fill: Color.ink, stroke: .white.opacity(0.12))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct PlanTeaser: View {
    let title: String
    let line: String
    let price: String
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased()).font(.dgo(10, .black)).tracking(1).foregroundStyle(accent)
                Text(line).font(.dgo(16, .black)).foregroundStyle(.white)
                Text(price).font(.dgo(12)).white(0.4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(16, fill: accent.opacity(0.08), stroke: accent.opacity(0.28))
        }
        .buttonStyle(.plain)
    }
}

private struct PartnerBanner: View {
    let tab: LandingTab

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            SectionLabel(text: tab.partnerEyebrow?.uppercased() ?? "PARTNER", opacity: 0.55, spacing: 1.4)
            Text(tab.label).font(.dgo(22, .black)).foregroundStyle(.white)
            Text(tab.partnerTagline ?? "").font(.dgo(13)).white(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(argb: tab.color).opacity(0.35), Color(argb: tab.secondary).opacity(0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct RailBlock: View {
    let title: String
    let accent: Color
    let items: [TitleCard]
    let onOpen: (TitleCard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Capsule().fill(Brand.gradient).frame(width: 3, height: 16)
                Text(title.uppercased()).font(.dgo(13, .black)).tracking(1.2).foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(items) { item in
                        PosterCard(item: item, accent: accent) { onOpen(item) }
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 18)
    }
}

private struct PosterCard: View {
    let item: TitleCard
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                let art = item.poster ?? item.hero
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [accent.opacity(0.55), Color(argb: 0xFF111111)], startPoint: .top, endPoint: .bottom)
                    if let art {
                        Color.clear.overlay { Image(art).resizable().scaledToFill() }.clipped()
                    }
                    LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .top, endPoint: .bottom)
                    if art == nil {
                        Text(item.title).font(.dgo(14, .black)).foregroundStyle(.white)
                            .lineLimit(3).multilineTextAlignment(.leading).padding(10)
                    }
                }
                .frame(width: 132, height: 198)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(item.title).font(.dgo(12, .bold)).white(0.85).lineLimit(1).padding(.top, 6)
                Text(item.tag).font(.dgo(11)).white(0.35).lineLimit(1)
            }
            .frame(width: 132, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("poster_\(item.title)")
    }
}

private struct FooterNote: View {
    var body: some View {
        Text("© 2026 DGO GLOBAL  ·  THE WORLD IS WATCHING")
            .font(.dgo(10, .black)).tracking(1.2).white(0.28)
            .padding(.horizontal, 16).padding(.vertical, 28)
    }
}

private struct BottomBar: View {
    let tabId: String
    let onHome: () -> Void
    let onSearch: () -> Void
    let onBrowse: () -> Void
    let onAccount: () -> Void

    var body: some View {
        HStack {
            Spacer()
            NavItem(label: "Home", icon: "house.fill", active: tabId == "home", action: onHome)
            Spacer()
            NavItem(label: "Search", icon: "magnifyingglass", active: false, action: onSearch)
            Spacer()
            NavItem(label: "Browse", icon: "square.grid.2x2", active: tabId != "home", action: onBrowse)
            Spacer()
            NavItem(label: "Account", icon: "person", active: false, action: onAccount)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.92).ignoresSafeArea(edges: .bottom))
    }
}

private struct NavItem: View {
    let label: String
    let icon: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 19))
                    .foregroundStyle(active ? Color.brandPurple : Color.white.opacity(0.55))
                    .frame(height: 22)
                Text(label).font(.dgo(10, .bold)).foregroundStyle(active ? Color.white : Color.white.opacity(0.45))
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("nav_\(label)")
    }
}

private struct SearchSheet: View {
    @Bindable var vm: CheckoutViewModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("", text: $vm.searchQuery, prompt: Text("Movies, series, sports…").foregroundStyle(Color.white.opacity(0.3)))
                    .font(.dgo(16)).foregroundStyle(.white).tint(.brandPurple)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focused)
                    .accessibilityIdentifier("searchField")
                Button {
                    vm.searchOpen = false
                    vm.searchQuery = ""
                } label: {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("searchClose")
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.searchResults) { item in
                        Button {
                            vm.searchOpen = false
                            vm.searchQuery = ""
                            vm.detail = item
                        } label: {
                            Text("\(item.title)  ·  \(item.tag)")
                                .font(.dgo(15)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("result_\(item.title)")
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.opacity(0.94).ignoresSafeArea())
        .onAppear { focused = true }
    }
}

private struct DetailSheet: View {
    let item: TitleCard
    let subscribed: Bool
    let onClose: () -> Void
    let onPlans: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.72).ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityIdentifier("detailScrim")

            VStack(alignment: .leading, spacing: 0) {
                if let art = item.hero ?? item.poster {
                    Color.clear.frame(height: 160)
                        .overlay { Image(art).resizable().scaledToFill() }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.bottom, 12)
                }
                Text(item.tag.uppercased()).font(.dgo(11, .black)).tracking(1.2).foregroundStyle(Color.brandPink)
                Text(item.title).font(.dgo(26, .black)).foregroundStyle(.white)
                    .accessibilityIdentifier("detailTitle")
                if !item.subtitle.isEmpty {
                    Text(item.subtitle).font(.dgo(13)).white(0.6)
                }
                Text([item.year, item.rating, item.duration].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.dgo(12)).white(0.4).padding(.top, 6)
                if !item.desc.isEmpty {
                    Text(item.desc).font(.dgo(13)).white(0.65).lineSpacing(3).padding(.top, 8)
                }
                BrandButton(
                    label: subscribed ? "You're in · see plan" : "Subscribe to watch",
                    fullWidth: true,
                    identifier: "detailCta",
                    action: onPlans
                )
                .padding(.top, 16)
                Button("Close", action: onClose)
                    .font(.dgo(15)).white(0.4)
                    .buttonStyle(.plain)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .accessibilityIdentifier("detailClose")
            }
            .padding(20)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
                    .fill(Color.ink)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
