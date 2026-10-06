import SwiftUI

struct RootView: View {
    @Bindable var vm: CheckoutViewModel

    private var routeKey: String { "\(vm.screen)-\(vm.step)" }

    /// Rebuilds the plan and payment screens when the dev toggle or a purchase changes what they show.
    private var checkoutKey: String {
        "\(vm.region)-\(String(describing: vm.session))-\(vm.manageMode)-\(vm.ownedPasses.sorted())-\(vm.catalogTab)"
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if vm.screen == .checkout {
                    CheckoutHeader(vm: vm)
                }
                ZStack {
                    route
                        .id(routeKey)
                        .transition(
                            .asymmetric(
                                insertion: .offset(x: 90).combined(with: .opacity),
                                removal: .offset(x: -90).combined(with: .opacity)
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            .animation(.easeOut(duration: 0.28), value: routeKey)

            DevGeoToggle(
                region: vm.region,
                subscribed: vm.session != nil,
                exclusive: vm.exclusiveEnabled,
                onRegion: vm.setDevRegion,
                onSubscribed: vm.setSubscribed,
                onExclusive: vm.setExclusive
            )
            .padding(.bottom, devToggleBottom)
        }
    }

    @ViewBuilder
    private var route: some View {
        switch (vm.screen, vm.step) {
        case (.home, _): LandingScreen(vm: vm)
        case (.account, _): AccountScreen(vm: vm)
        case (.checkout, 0): ChoosePlanScreen(vm: vm).id(checkoutKey)
        case (.checkout, 1): PaymentScreen(vm: vm).id(checkoutKey)
        default: ConfirmationScreen(vm: vm)
        }
    }

    private var devToggleBottom: CGFloat {
        switch vm.screen {
        case .home: 66
        case .checkout where vm.step < 2: 72
        default: 12
        }
    }
}

private struct CheckoutHeader: View {
    let vm: CheckoutViewModel

    private var title: String {
        switch vm.step {
        case 0: vm.buyingEvent ? "Exclusive" : vm.manageMode ? "Change plan" : "Choose a plan"
        case 1: "Payment"
        default: "Confirmed"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: vm.back) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left").font(.system(size: 13, weight: .bold))
                        Text("Back").font(.dgo(13, .bold))
                    }
                    .white(0.5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("headerBack")

                Text(title)
                    .font(.dgo(13, .black)).white(0.8)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .accessibilityIdentifier("headerTitle")

                Image("dgo_logo").resizable().scaledToFit().frame(height: 28)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if vm.step < 2 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.08))
                        Rectangle().fill(Brand.gradient)
                            .frame(width: geo.size.width * CGFloat(vm.step + 1) / 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.bottom, 4)
        .background(Color.black.opacity(0.8))
    }
}
