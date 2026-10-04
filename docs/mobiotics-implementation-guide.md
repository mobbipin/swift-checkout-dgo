# DGO Checkout & Account — Implementation Guide for Mobiotics

**Audience:** Mobiotics app and backend teams
**Source of truth for prices and rules:** DGO Product & Entitlement Specification v3.0 (USD Stripe, prorated)
**Reference build:** this repository (Swift / SwiftUI). Run it to see every state described below. The Kotlin / Jetpack Compose build is [kotlin-checkout-dgo](https://github.com/dgostream/kotlin-checkout-dgo).

---

## 1. Scope

Work on **two areas only**:

1. **The checkout flow:** choose plan → pay → confirmation.
2. **The Account screen:** current plan, plan changes, cancel and resume.

Everything else in the current DGO app (home, browse, player, search, rentals, ads, TV pairing) is **out of scope**. Leave it as it is.

You have already mapped the Stripe plans. This guide covers what is still missing:

- Subscription **states** (active, cancelling, pending change)
- **Upgrade**, **downgrade**, **renewal** and **extension** rules
- **Cancel** and **resume**
- **Stripe-only payments** outside Nepal
- **Dev toggles**, so QA can reach every state without real payments

---

## 2. Regions and payment rails

| Toggle | Region | Currency | How they pay | Billing |
| --- | --- | --- | --- | --- |
| **NP** | Nepal | NPR | Local wallets: Khalti, eSewa, ConnectIPS, Fonepay, GetPay | **Prepaid**, one-time. No auto-renew. |
| **ZA** | India & Middle East | USD | **Stripe only** | **Recurring** subscription |
| **ZB** | USA / Europe / AU / NZ | USD | **Stripe only** | **Recurring** subscription |
| **ZC** | South East Asia | USD | **Stripe only** | **Recurring** subscription |

### Stripe exclusivity outside Nepal

- Outside Nepal, the payment step shows **one option: Stripe Checkout**. No wallets, no other gateways, and no card form in the app.
- The app **never collects card data**. Card, Apple Pay, Google Pay, Link and the rest are chosen on Stripe's hosted page.
- On mobile, open Stripe Checkout in a **WebView** (or a Custom Tab). Embedded Stripe checkout is not used on mobile.
- Nepal never shows Stripe.

---

## 3. Catalogue (v3.0)

Two tiers, three durations, four regions: 24 SKUs.

| Tier | Entitlement | Quality | Screens |
| --- | --- | --- | --- |
| Mobile | `EP-MOBILE` | 720p, 1 stream | Phones and tablets only, no TV or cast |
| Plus | `EP-PLUS` | 1080p, 3 streams | TV, cast, desktop and phones |

| SKU pattern | 1 month | 3 months | 12 months |
| --- | --- | --- | --- |
| NP Mobile / Plus (NPR) | 199 / 299 | 549 / 799 | 1,799 / 2,699 |
| ZA Mobile / Plus (USD) | 3.99 / 5.99 | 9.99 / 14.99 | 35.99 / 50.99 |
| ZB Mobile / Plus (USD) | 6.99 / 8.99 | 18.99 / 29.99 | 64.99 / 99.99 |
| ZC Mobile / Plus (USD) | 4.99 / 6.99 | 10.99 / 17.99 | 44.99 / 65.99 |

SKU IDs follow `DGO-{NP|ZA|ZB|ZC}-{MOB|PLS}-{01M|03M|12M}`, for example `DGO-ZB-PLS-03M`.

Rules:

- **1-month plans have no live sports.** 3- and 12-month plans include live sports. Show this on the duration selector.
- **Stripe 3-month plans charge the monthly rate today** (3-month price ÷ 3, e.g. $29.99 → $10.00) and **bill monthly for 3 months**. Show the monthly amount as the price, not the 3-month total.
- Stripe 12-month plans bill annually. Stripe 1-month plans bill monthly.
- Nepal is always a one-time payment for the full term.

---

## 4. Subscription state model

Your backend should expose one subscription object per user. These are the minimum fields the Account screen and checkout need:

| Field | Values | Notes |
| --- | --- | --- |
| `skuId` | e.g. `DGO-ZA-PLS-12M` | Current plan |
| `region` | NP, ZA, ZB, ZC | Region the plan was bought in |
| `tier` / `duration` | MOBILE/PLUS, 01M/03M/12M | |
| `billingMode` | `PREPAID` (Nepal), `RECURRING` (Stripe) | Decides which rules apply |
| `status` | `ACTIVE`, `CANCELING` | `CANCELING` = renewal is off, access continues until the period ends |
| `paidThrough` | date | Access end date |
| `nextBillingDate` | date or null | Stripe only |
| `pendingPlan` | `{skuId, effectiveDate}` or null | A downgrade scheduled for the next bill |

For Stripe users, **Stripe webhooks are the source of truth**. Update this object from the webhook events, not from the app.

---

## 5. Plan-change rules

When a subscribed user opens checkout from **Account → Manage plan** (Stripe) or **Account → Add time or upgrade** (Nepal), compare the plan they pick against their current plan.

### Stripe (ZA / ZB / ZC), recurring

| Picked plan vs current | Result | Card chip | Button | Due today | What happens |
| --- | --- | --- | --- | --- | --- |
| Same SKU | **Current** | "Current" | "Current plan" (disabled) | — | Nothing. Blocked. |
| Mobile → Plus, or a longer duration | **Upgrade** | "Upgrade" | "Upgrade" | "Price difference" | Applies **now**. The user pays only for the days left in the current billing period. **The billing date does not change.** Any pending downgrade is cleared. |
| Plus → Mobile, or a shorter duration | **Downgrade** | "Downgrade" | "Schedule downgrade" | "No charge today" | The current plan stays until the next bill. The new plan starts on that date. Saved as `pendingPlan`. |

If the change goes **down in either tier or duration**, treat it as a downgrade, even if the other dimension goes up. Example: Mobile 12M → Plus 3M is a **downgrade** because the duration gets shorter.

### Nepal (NP), prepaid

| Picked plan vs current | Result | Button | Due today | What happens |
| --- | --- | --- | --- | --- |
| Same SKU | **Renewal** | "Add time" | Full price | Another term is added after `paidThrough`. |
| Mobile → Plus, same duration | **Tier upgrade** | "Upgrade" | **Price difference only:** 1M रू100, 3M रू250, 12M रू900 | Plus starts now. **`paidThrough` does not change.** |
| Longer duration | **Extension** | "Add time" | Full price | The new term is added after `paidThrough`. No auto-renew. |
| Shorter duration, or Plus → Mobile | **Deferred** | "After this term" (disabled) | — | Blocked until the current term ends. |

Nepal has **no cancel**. Prepaid access simply ends on `paidThrough`.

### A cancelled Stripe subscription

If `status = CANCELING` and the user buys or changes a plan, the new plan **turns renewal back on** (status becomes `ACTIVE`). Tell the user on the plan screen: *"Renewal is off. A new plan turns it back on."*

---

## 6. Stripe integration (backend)

The app only opens a URL. Your backend talks to Stripe.

### 6.1 New subscription

1. The app calls your backend with `skuId` and an optional promo code.
2. The backend creates a **Checkout Session** with `mode: subscription` and the price mapped to the SKU.
3. The backend returns `session.url`. The app opens it in a WebView.
4. Watch for the `success_url` / `cancel_url` redirect in the WebView to close it, then show confirmation **after the webhook confirms payment**.
5. Webhooks: `checkout.session.completed`, `customer.subscription.created`, `invoice.paid`, `invoice.payment_failed`.

For the **3-month plan** (monthly rate, 3 monthly charges), confirm that your existing Stripe mapping already does this, for example with a subscription schedule of 3 monthly iterations. Do not charge the 3-month total up front.

### 6.2 Promo codes

Use standard Stripe promotion codes:

- **Code entered in the app:** the backend looks up the promotion code and passes it as `discounts: [{ promotion_code }]` when creating the session. The app shows the discounted amount before hand-off.
- **No code in the app:** create the session with `allow_promotion_codes: true`, so the user can enter one on Stripe's page.
- Stripe does **not** allow both on one session, so choose based on whether the app sent a code.
- How long a discount lasts on recurring bills (once, several months, forever) is set **on the coupon in Stripe**.
- **No promo codes on upgrades or downgrades.** Only new subscriptions.

Nepal keeps its own local coupons (prototype codes `DGO10` and `DGO20`).

### 6.3 Upgrade (immediate)

- Update the existing subscription's item to the new price with `proration_behavior: always_invoice`, so the price difference for the rest of the period is charged now.
- Keep the billing anchor, so the next bill date stays the same.
- If the user must confirm the amount first, preview it with Stripe's upcoming-invoice API, or send them to the **Stripe Customer Portal** in a WebView.
- Webhook: `customer.subscription.updated`, `invoice.paid`.

### 6.4 Downgrade (next bill)

- Do **not** change the price now. Create a **subscription schedule** whose next phase starts at `current_period_end` with the lower price.
- Save it as `pendingPlan` so Account can show *"Changes to DGO Mobile · 3 months on 4 Nov 2026."*
- No charge today.

### 6.5 Cancel and resume

- **Cancel:** set `cancel_at_period_end: true`. Status becomes `CANCELING`. Access continues until `current_period_end`. **Clear any pending downgrade.**
- **Resume:** set `cancel_at_period_end: false`. Status goes back to `ACTIVE`.
- Webhooks: `customer.subscription.updated`, and `customer.subscription.deleted` when the period actually ends.

---

## 7. Account screen

| State | What to show | Actions |
| --- | --- | --- |
| Not subscribed | "No active plans on this account" | **Subscribe now** → checkout |
| Nepal, active | Plan name, "Access until {date}" | **Add time or upgrade** → checkout in manage mode |
| Stripe, active | Plan name, "Auto-renewal on", "Next bill {date}", ACTIVE badge | **Manage plan** → checkout in manage mode; **Cancel renewal** → cancel flow |
| Stripe, pending downgrade | As above, plus the banner "Changes to {plan} on {date}" | Same |
| Stripe, cancelling | "Cancellation scheduled", "Access until {date}", ENDS SOON badge | **Resume auto-renewal** (with a confirm step: "Next charge {price} on {date}") |

### Cancel flow (Stripe only, 3 steps)

1. **Before you cancel:** "Access until {date}. Resume anytime before." Buttons: Keep plan / Continue.
2. **Why are you leaving?** Pick a reason (required). Send it to analytics.
3. **Final confirmation:** the user types `CANCEL`. Button: Turn off renewal.

---

## 8. Checkout flow

### Step 1: Choose plan

- **Duration selector:** one rounded bar with three cells (1 month / 3 months / 12 months). Each cell shows the monthly rate, the saving on 12 months, and "Live sports" or "No live sports". The selected cell uses the DGO gradient (purple `#8A3FFC` → pink `#FF00BD` → orange `#FF4D00`).
- **Tier cards:** Mobile and Plus are **two swipeable cards** with page dots. Each card shows the price, struck-through compare price, saving %, and features.
- **In manage mode**, each card shows a state chip (Current / Upgrade / Downgrade / Add time / After this term) and a one-line note, using the rules in section 5.
- **Bottom bar:** plan name, the due-today text, and the action button from section 5.

### Step 2: Payment

- **Nepal:** the order card with the coupon field, then the wallet list (only one open at a time), then "Pay रू{amount} via {wallet}".
- **Stripe regions:**
  - **Order summary card:** plan, billing frequency, promo discount line, **Due today**, promo code field (new subscriptions only).
  - **Stripe panel:** "Secure payment by" with the **official Stripe wordmark**, "You'll finish on Stripe's secure page", and chips for Card / Apple Pay / Google Pay / Link.
  - **Button:** "Continue to Stripe · $X" (new), "Continue to Stripe" (upgrade), "Schedule on Stripe" (downgrade).

### Step 3: Confirmation

| Result | Title | "Paid today" row | Schedule row |
| --- | --- | --- | --- |
| New | You're in | Amount | Billing frequency, or Nepal "{n} months of access" |
| Upgrade (Stripe or Nepal tier) | Plan updated | "Price difference" / fee | "Billing date kept" / "Access date unchanged" |
| Downgrade | Plan change scheduled | "No charge today" | "Starts on the next bill" |
| Renewal / extension | Time added | Amount | "{n} months added after this term" |

The screen returns to home automatically after 10 seconds. Show an order reference (`DGO-XXXX-XXXX`).

---

## 9. Dev toggles (QA only)

Add a hidden overlay to **debug and staging builds only**, never production. It lets QA reach every state without real payments.

```
DEV · GEO / STATE
[ NP ] [ ZA ] [ ZB ] [ ZC ]  |  [ OFF ] [ SUB ]
```

| Control | Effect |
| --- | --- |
| **NP / ZA / ZB / ZC** | Overrides the user's region, which changes the prices, currency and payment rail. If the user is subscribed, their current tier and duration are re-created in the new region. |
| **OFF** | Clears the subscription (not subscribed). |
| **SUB** | Creates an active subscription in the current region (defaults to Plus · 3 months). |

Behaviour in the reference app: the overlay collapses into a small lime tab on the left edge showing the current values (e.g. `ZA / SUB`). Tap it to open. It slides back after 4 seconds without a tap.

For backend-driven states (cancelling, pending downgrade), use Stripe **test mode** and **test clocks** to move time past a billing date.

### QA matrix

| # | Toggle | Steps | Expect |
| --- | --- | --- | --- |
| 1 | ZB · OFF | Subscribe to Plus 3M | Payment shows Stripe only; due $10.00; "Continue to Stripe · $10.00" |
| 2 | ZB · OFF | Enter a valid promo code | Due drops; the strike-through shows the original price |
| 3 | ZA · SUB (Plus 3M) | Manage → Plus 12M | Upgrade chip, "Price difference", billing date unchanged after |
| 4 | ZA · SUB (Plus 12M) | Manage → Plus 3M | Downgrade chip, "No charge today", Account shows the pending change |
| 5 | ZA · SUB | Manage → same plan | "Current plan" button disabled |
| 6 | ZC · SUB | Account → Cancel → 3 steps | ENDS SOON, "Access until …", pending downgrade cleared |
| 7 | ZC · cancelling | Resume auto-renewal | ACTIVE again |
| 8 | ZC · cancelling | Manage → pick a new plan | Note "Renewal is off…", renewal back on after |
| 9 | NP · SUB (Mobile 3M) | Add time → Plus 3M | Due रू250; access date unchanged |
| 10 | NP · SUB (Mobile 3M) | Add time → Mobile 12M | Full price; 12 months added after the current end date |
| 11 | NP · SUB (Plus 12M) | Add time → Mobile 3M | "After this term", disabled |
| 12 | NP · SUB | Account | No cancel option; only "Add time or upgrade" |
| 13 | NP · OFF | Pay with GetPay, card `4000 0000 0000 0002` | "Card declined. Try another." |

---

## 10. Copy guidelines

- Keep text short. One line per idea.
- Do **not** use the word "proration" or "prorated". Say **"pay only the difference"** or **"pay only for the days left until {date}"**.
- Always give a **date** for anything that happens later: "Switches on 4 Nov 2026", "Access until 4 Nov 2026".
- Downgrades always say **"No charge today"**.

---

## 11. Where to look in the reference build

| Topic | File |
| --- | --- |
| SKUs, prices, billing labels | `DgoCheckout/Data/Catalog.swift` |
| Plan-change rules, button and chip labels | `DgoCheckout/Data/PlanChanges.swift` |
| State changes after purchase, cancel, resume | `DgoCheckout/Data/SessionRepository.swift` |
| Plan picker (duration bar, swipe cards) | `DgoCheckout/UI/Screens/ChoosePlanScreen.swift` |
| Payment (Nepal wallets, Stripe hand-off) | `DgoCheckout/UI/Screens/PaymentScreen.swift` |
| Confirmation | `DgoCheckout/UI/Screens/ConfirmationScreen.swift` |
| Account, cancel and resume | `DgoCheckout/UI/Screens/AccountScreen.swift` |
| Dev toggle overlay | `DgoCheckout/UI/Components/DevGeoToggle.swift` |

The reference app stores state on the device and does not charge anyone. In production, the backend and Stripe webhooks own the subscription state, and the app only displays it.
