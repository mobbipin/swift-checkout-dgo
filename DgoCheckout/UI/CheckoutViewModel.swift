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
    var mobileNumber = ""
    var cardForm = CardForm()
    var paymentError: String?
    var coupon: AppliedCoupon?
    private(set) var orderRef: String
    private(set) var lastPaymentLabel = "Payment method"
    private(set) var completedKind: PlanChangeKind = .new

    init(repo: SessionRepository = SessionRepository()) {
        self.repo = repo
        region = repo.getRegion()
        session = repo.getSession()
        orderRef = repo.generateOrderRef()
    }

    var sku: SubscriptionSku? { Catalog.findSku(region, tier, duration) }

    var planChange: PlanChange? { resolvePlanChange(session, sku, manageMode: manageMode) }

    var amount: Double {
        guard let selected = sku else { return 0 }
        return planChange?.amount ?? selected.price
    }

    var dueAmount: Double { applyCouponAmount(amount, sku?.currency ?? region.currency, coupon) }

    var canAdvanceFromPlan: Bool { sku != nil && (planChange?.allowed ?? true) }

    func setDevRegion(_ next: PriceRegion) {
        region = next
        repo.setRegion(next)
        if let current = repo.getSession(),
           let seededSku = Catalog.findSku(next, current.tier, current.duration) {
            let seeded = repo.sessionFromSku(seededSku)
            repo.setSession(seeded)
            session = seeded
            tier = seeded.tier
            duration = seeded.duration
        }
        nepalPsp = nil
        paymentError = nil
        coupon = nil
    }

    func setSubscribed(_ on: Bool) {
        if on {
            let seeded = Catalog.findSku(region, session?.tier ?? .plus, session?.duration ?? .m03)
                ?? Catalog.findSku(region, .plus, .m03)
            if let seeded {
                let next = repo.sessionFromSku(seeded)
                repo.setSession(next)
                session = next
            }
        } else {
            repo.setSession(nil)
            session = nil
            manageMode = false
        }
    }

    func openCheckout(manage: Bool = false) {
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
        } else if mobileNumber.trimmingCharacters(in: .whitespaces).count < 5 {
            paymentError = method == .connectips
                ? "Enter a valid account or customer ID."
                : "Enter a valid mobile number."
            return false
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
