# DGO Checkout (Swift)

Mobile-first SwiftUI port of the DGO `/join` checkout, using **Product & Entitlement Spec v3.0**. It mirrors the Kotlin / Jetpack Compose build in [kotlin-checkout-dgo](https://github.com/dgostream/kotlin-checkout-dgo).

In scope: the checkout (choose plan → pay → confirmation) and the Account screen. The landing pages are out of scope. There is no player and no live payment.

## What is included

- Plan picker with the same duration tabs (1 / 3 / 12 months) and Mobile / Plus cards
- Nepal wallet accordion (Khalti, eSewa, ConnectIPS, Fonepay, GetPay)
- Stripe-only checkout for international zones: a hand-off to hosted Stripe Checkout, no card entry in the app
- Plan changes (upgrade, downgrade, renewal, extension) and Stripe cancel / resume on the Account screen
- Confirmation screen, then a subscribed home
- Prototype coupons `DGO10` / `DGO20` on Nepal checkout
- Dev overlay, same idea as the web prototype:

  `DEV · GEO / STATE` → **NP | ZA | ZB | ZC** and **OFF | SUB**

## SKUs (v3.0)

| Zone | Toggle | Currency | Sample Plus 3M |
| --- | --- | --- | --- |
| Nepal | NP | NPR | रू 799 · wallets · one-time |
| India & Middle East | ZA | USD | $14.99 · Stripe |
| USA / Europe / AU / NZ | ZB | USD | $29.99 · Stripe |
| South East Asia | ZC | USD | $17.99 · Stripe |

1-month plans have no live sports. Stripe plans charge the full price each period: monthly, every 3 months (quarterly), or annually.

For the partner implementation guide, see [docs/mobiotics-implementation-guide.md](docs/mobiotics-implementation-guide.md).

## Run it

1. Install Xcode 16 or later (built and tested with Xcode 26.2). The app targets iOS 17+.
2. Install XcodeGen once: `brew install xcodegen`
3. Generate the project: `xcodegen generate`
4. Open `DgoCheckout.xcodeproj` and run the `DgoCheckout` scheme on an iPhone simulator.

The checkout is a prototype: no live Stripe or Nepal wallet charge. Test decline card: `4000 0000 0000 0002`.

## Swift project layout

| Kotlin | Swift |
| --- | --- |
| `data/Models.kt`, `Catalog.kt`, `PlanChanges.kt` | `DgoCheckout/Data/Models.swift`, `Catalog.swift`, `PlanChanges.swift` |
| `data/SessionRepository.kt` (SharedPreferences + JSON) | `DgoCheckout/Data/SessionRepository.swift` (UserDefaults + Codable, same keys) |
| `ui/CheckoutViewModel.kt` | `DgoCheckout/UI/CheckoutViewModel.swift` (`@Observable`) |
| `ui/DgoCheckoutApp.kt` (checkout header, routing) | `DgoCheckout/UI/RootView.swift` |
| `ui/screens/*.kt` | `DgoCheckout/UI/Screens/*.swift` |
| `ui/components/*.kt` | `DgoCheckout/UI/Components/*.swift` |
| `res/drawable` | `DgoCheckout/Resources/Assets.xcassets` (Stripe wordmark as SVG) |

iOS has no system back button, so the Account screen has a "Back to home" link. Checkout keeps its header Back button.

## Tests

```sh
xcodebuild -project DgoCheckout.xcodeproj -scheme DgoCheckout \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

- `DgoCheckoutTests`: 30 unit tests covering pricing, coupons, plan-change rules, saved state and payment validation.
- `DgoCheckoutUITests`: 10 end-to-end flows on the simulator: Nepal wallet and GetPay purchases, the decline card, Nepal plan changes, Stripe purchase with promo, Stripe downgrade / upgrade / cancel / resume, same-interval upgrade keeping the billing date, ZA and ZC prices, Account and sign out, and the confirmation countdown.
