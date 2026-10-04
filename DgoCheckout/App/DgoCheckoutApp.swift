import SwiftUI

@main
struct DgoCheckoutApp: App {
    @State private var vm: CheckoutViewModel

    init() {
        // UI tests start from a clean slate (no stored region or subscription).
        if CommandLine.arguments.contains("-uiTestReset"), let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
        _vm = State(initialValue: CheckoutViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView(vm: vm)
                .preferredColorScheme(.dark)
        }
    }
}
