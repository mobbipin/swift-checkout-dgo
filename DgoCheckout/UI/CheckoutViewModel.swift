import Foundation
import Observation

@Observable
final class CheckoutViewModel {
    private let repo: SessionRepository

    private(set) var screen: Screen = .home
    var tabId = "home"
    var detail: TitleCard?
    var searchOpen = false
    var searchQuery = ""
    var plansOpen = true
    var cancelStep = 0
    var cancelReason = ""
    var cancelPhrase = ""
    var confirmResume = false
    var accountNotice: String?
    private(set) var step = 0
    private(set) var region: PriceRegion
    var tier: PlanTier = .plus
    var duration: PlanDuration = .m03
    private(set) var session: SubscriptionSession?
    private(set) var manageMode = false

    var nepalPsp: NepalPsp?
    var cardForm = CardForm()
    var paymentError: String?
    var coupon: AppliedCoupon?
    private(set) var orderRef: String
    private(set) var lastPaymentLabel = "Payment method"
    private(set) var completedKind: PlanChangeKind = .new
    private(set) var completedEvent: EventPass?

    private(set) var exclusiveEnabled: Bool
    var catalogTab: CatalogTab = .plans
    var eventKey = Events.all[0].key
    private(set) var ownedPasses: Set<String>

    init(repo: SessionRepository = SessionRepository()) {
        self.repo = repo
        region = repo.getRegion()
        session = repo.getSession()
        orderRef = repo.generateOrderRef()
        exclusiveEnabled = repo.getExclusiveEnabled()
        ownedPasses = repo.getPasses()
    }

    var buyingEvent: Bool { exclusiveEnabled && catalogTab == .exclusive }

    var event: EventPass? { Events.find(eventKey) }

    var sku: SubscriptionSku? { Catalog.findSku(region, tier, duration) }

    var planChange: PlanChange? {
        if buyingEvent {
            return event.map { PlanChange(kind: .new, amount: $0.price(region), allowed: passOwnership($0, ownedPasses) == nil) }
        }
        return resolvePlanChange(session, sku, manageMode: manageMode)
    }

    var amount: Double {
        if buyingEvent { return event?.price(region) ?? 0 }
        guard let selected = sku else { return 0 }
        return planChange?.amount ?? selected.price
    }

    var dueAmount: Double { applyCouponAmount(amount, region.currency, coupon) }

    var canAdvanceFromPlan: Bool {
        buyingEvent ? planChange?.allowed == true : sku != nil && (planChange?.allowed ?? true)
    }

    func setExclusive(_ on: Bool) {
        exclusiveEnabled = on
        repo.setExclusiveEnabled(on)
        if !on { catalogTab = .plans }
    }

    func setDevRegion(_ next: PriceRegion) {
        guard next != region else { return }
        region = next
        repo.setRegion(next)
        remapSession(next)
        onDevToggle()
    }

    func setSubscribed(_ on: Bool) {
        if on {
            let seeded = Catalog.findSku(region, session?.tier ?? .plus, session?.duration ?? .m03)
                ?? Catalog.findSku(region, .plus, .m03)
            if let seeded {
                let next = repo.sessionFromSku(seeded)
                repo.setSession(next)
                session = next
                if screen == .checkout {
                    tier = next.tier
                    duration = next.duration
                }
            }
        } else {
            repo.setSession(nil)
            repo.clearPasses()
            session = nil
            ownedPasses = []
            manageMode = false
        }
        onDevToggle()
    }

    /// Keep tier, term, cancel, and pending plan; only the region-specific sku changes.
    private func remapSession(_ next: PriceRegion) {
        guard var seeded = repo.getSession(),
              let mapped = Catalog.findSku(next, seeded.tier, seeded.duration) else { return }
        if var pending = seeded.pendingPlan {
            pending.skuId = Catalog.findSku(next, pending.tier, pending.duration)?.id ?? pending.skuId
            seeded.pendingPlan = pending
        }
        seeded.skuId = mapped.id
        seeded.region = mapped.region
        seeded.liveSports = mapped.liveSports
        seeded.entitlement = mapped.entitlement
        seeded.billingMode = next.stripe ? .recurring : .prepaid
        if next.stripe { seeded.nextBillingDate = seeded.nextBillingDate ?? seeded.paidThrough }
        repo.setSession(seeded)
        session = seeded
    }

    private func onDevToggle() {
        nepalPsp = nil
        paymentError = nil
        coupon = nil
        cardForm = CardForm()
        guard screen == .checkout else { return }
        manageMode = session != nil
        if step == 1 && !canAdvanceFromPlan { step = 0 }
    }

    func openCheckout(manage: Bool = false, exclusive: Bool = false) {
        catalogTab = exclusive && exclusiveEnabled ? .exclusive : .plans
        manageMode = manage && session != nil
        if manageMode, let session {
            region = session.region
            tier = session.tier
            duration = session.duration
        } else {
            region = repo.getRegion()
        }
        step = 0
        nepalPsp = nil
        paymentError = nil
        coupon = nil
        orderRef = repo.generateOrderRef()
        screen = .checkout
    }

    func goHome() {
        session = repo.getSession()
        screen = .home
        step = 0
        manageMode = false
    }

    func openAccount() {
        session = repo.getSession()
        screen = .account
        searchOpen = false
        detail = nil
        cancelStep = 0
        cancelReason = ""
        cancelPhrase = ""
        confirmResume = false
        accountNotice = nil
    }

    func signOut() {
        setSubscribed(false)
        screen = .home
        accountNotice = nil
    }

    func refreshSession() {
        session = repo.getSession()
    }

    func cancelRenewal() {
        repo.cancelAtPeriodEnd()
        refreshSession()
        cancelStep = 0
        cancelReason = ""
        cancelPhrase = ""
    }

    func resumeRenewal() {
        repo.resumeSubscription()
        refreshSession()
        confirmResume = false
        cancelStep = 0
    }

    func selectTab(_ id: String) {
        tabId = id
        searchOpen = false
        detail = nil
    }

    var searchResults: [TitleCard] { LandingCatalog.search(searchQuery) }

    func back() {
        switch screen {
        case .home: return
        case .account: goHome()
        case .checkout: if step == 0 { goHome() } else { step -= 1 }
        }
    }

    func nextFromPlan() {
        guard canAdvanceFromPlan else { return }
        step = 1
    }

    /// Returns an error message, or nil when the code was applied.
    func applyCoupon(_ raw: String) -> String? {
        let code = raw.trimmingCharacters(in: .whitespaces).uppercased()
        guard let percent = Catalog.coupons[code] else { return "That code isn’t valid." }
        coupon = AppliedCoupon(code: code, percent: percent)
        return nil
    }

    func clearCoupon() {
        coupon = nil
    }

    @discardableResult
    func submitNepalPayment() -> Bool {
        paymentError = nil
        guard let method = nepalPsp else {
            paymentError = "Choose a payment method."
            return false
        }
        if method == .getpay {
            let digits = cardForm.number.filter(\.isNumber)
            if digits.count < 12 ||
                cardForm.expiry.count < 5 ||
                cardForm.cvc.count < 3 ||
                cardForm.name.trimmingCharacters(in: .whitespaces).isEmpty {
                paymentError = "Complete all card details."
                return false
            }
            if digits == Self.declineCard {
                paymentError = "Card declined. Try another."
                return false
            }
        }
        lastPaymentLabel = method.title
        completePurchase()
        return true
    }

    /// Hosted Stripe Checkout opens in a web view later; no card data is collected in the app.
    /// A backend creates the session: with `discounts = [promotion_code]` when `coupon` is set,
    /// otherwise with `allow_promotion_codes = true` (Stripe rejects both on one session).
    @discardableResult
    func submitStripePayment() -> Bool {
        paymentError = nil
        if planChange?.kind != .new { coupon = nil }
        lastPaymentLabel = "Stripe Checkout"
        completePurchase()
        return true
    }

    private func completePurchase() {
        if buyingEvent {
            guard let pass = event else { return }
            repo.addPass(pass.key)
            ownedPasses = repo.getPasses()
            completedEvent = pass
            completedKind = .new
            step = 2
            return
        }
        completedEvent = nil
        guard let selected = sku else { return }
        let kind = planChange?.kind ?? .new
        completedKind = kind
        repo.persistPurchase(selected, current: session, kind: kind)
        session = repo.getSession()
        step = 2
    }

    func formatCard(_ raw: String) -> String {
        let digits = Array(raw.filter(\.isNumber).prefix(16))
        return stride(from: 0, to: digits.count, by: 4)
            .map { String(digits[$0..<min($0 + 4, digits.count)]) }
            .joined(separator: " ")
    }

    func formatExpiry(_ raw: String) -> String {
        let digits = String(raw.filter(\.isNumber).prefix(4))
        return digits.count >= 3 ? "\(digits.prefix(2))/\(digits.dropFirst(2))" : digits
    }

    static let declineCard = "4000000000000002"
}
