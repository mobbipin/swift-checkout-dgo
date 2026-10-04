# DGO Checkout (Swift / SwiftUI)

SwiftUI port of [`kotlin-checkout-dgo`](https://github.com/dgostream/kotlin-checkout-dgo): the mobile DGO `/join` checkout prototype on **Product & Entitlement Spec v3.0**. Same screens, SKUs, plan-change rules and dev overlay as the Compose app. There is no player and no live payment.

## What is included

- Mobile landing: Home, JioHotstar, OSR, Sports, Entertainment, Specials, Junior, with a hero carousel, rails, search and a title detail sheet
- Plan picker: 1 / 3 / 12 month tabs and swipeable Plus / Mobile cards
- Nepal (NPR): wallet accordion (Khalti, eSewa, ConnectIPS, Fonepay, GetPay card), one-time payment, coupons `DGO10` / `DGO20`
- International zones ZA / ZB / ZC (USD): hand-off to hosted Stripe Checkout, promo code, no card entry in the app
- Plan changes: renewal, fixed-tier upgrade, extension, deferred (Nepal prepaid); Stripe upgrade, scheduled downgrade, cancel and resume (recurring)
- Confirmation screen with a 10s auto-return home, and Account
- Dev overlay (bottom-left edge tab): `DEV · GEO / STATE` → **NP | ZA | ZB | ZC** and **OFF | SUB**

## Layout

| Kotlin | Swift |
| --- | --- |
| `data/*.kt` | `DgoCheckout/Data/` (`Models`, `Catalog`, `PlanChanges`, `Landing`, `SessionRepository`) |
| `CheckoutViewModel` (Compose state) | `UI/CheckoutViewModel.swift` (`@Observable`) |
| `DgoCheckoutApp.kt` | `UI/RootView.swift` |
| `ui/screens/*` | `UI/Screens/*` |
| SharedPreferences + JSON | `UserDefaults` + `Codable` (same keys) |
| `res/drawable` | `Resources/Assets.xcassets` (Stripe wordmark as SVG) |

iOS has no system back button, so Account gets a "Back to home" link. Checkout keeps its header Back button.

## Run it

Requires Xcode 16+ (built with Xcode 26.2, iOS 17+ deployment target).

```sh
brew install xcodegen      # once
xcodegen generate
open DgoCheckout.xcodeproj # run the DgoCheckout scheme on an iPhone simulator
```

## Tests

```sh
TEST_RUNNER_SCREENSHOT_DIR=$PWD/screenshots/flows \
xcodebuild -project DgoCheckout.xcodeproj -scheme DgoCheckout \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

- `DgoCheckoutTests`: 26 unit tests for pricing, coupons, plan-change rules, persistence and view-model validation
- `DgoCheckoutUITests`: 9 end-to-end flows, which save a screenshot at each step to `screenshots/flows/`

Prototype only: no live Stripe or wallet charge. Test decline card: `4000 0000 0000 0002`.
