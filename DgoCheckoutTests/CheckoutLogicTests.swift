import XCTest
@testable import DgoCheckout

final class CatalogTests: XCTestCase {
    func testCatalogHas24Skus() {
        XCTAssertEqual(Catalog.skus.count, 24)
        XCTAssertEqual(Set(Catalog.skus.map(\.id)).count, 24)
    }

    func testOneMonthPlansHaveNoLiveSports() {
        for sku in Catalog.skus {
            XCTAssertEqual(sku.liveSports, sku.duration != .m01, sku.id)
        }
    }

    func testMoneyFormatting() {
        XCTAssertEqual(formatMoney(2699, .npr), "रू 2,699")
        XCTAssertEqual(formatMoney(799, .npr), "रू 799")
        XCTAssertEqual(formatMoney(14.99, .usd), "$14.99")
        XCTAssertEqual(formatMoney(10, .usd), "$10.00")
    }

    func testMonthlyRate() {
        XCTAssertEqual(formatMonthlyRate(Catalog.findSku(.nepal, .plus, .m03)!), "रू 266/mo")
        XCTAssertEqual(formatMonthlyRate(Catalog.findSku(.zoneB, .plus, .m12)!), "$8.33/mo")
    }

    func testStripeThreeMonthChargesFullQuarterlyPrice() {
        let change = resolvePlanChange(nil, Catalog.findSku(.zoneB, .plus, .m03), manageMode: false)
        XCTAssertEqual(change?.kind, .new)
        XCTAssertEqual(change?.amount, 29.99)
        XCTAssertEqual(billingCadenceLabel(.m03, .zoneB), "Billed every 3 months")
    }

    func testSavingsAndCompareAt() {
        let save = savingsVsMonthly(.nepal, .plus, .m12)!
        XCTAssertEqual(save.amount, 299 * 12 - 2699, accuracy: 0.001)
        XCTAssertEqual(save.percent, 25)
        XCTAssertNil(savingsVsMonthly(.nepal, .plus, .m01))
        XCTAssertEqual(compareAtPrice(.nepal, .plus, .m03), 897)
        XCTAssertEqual(compareAtPrice(.zoneB, .plus, .m03), 26.97, accuracy: 0.001)
    }

    func testCoupons() {
        XCTAssertEqual(applyCouponAmount(799, .npr, AppliedCoupon(code: "DGO10", percent: 10)), 719)
        XCTAssertEqual(applyCouponAmount(10, .usd, AppliedCoupon(code: "DGO20", percent: 20)), 8.0, accuracy: 0.001)
        XCTAssertEqual(applyCouponAmount(14.99, .usd, nil), 14.99)
    }

    func testCadenceLabels() {
        XCTAssertEqual(billingCadenceLabel(.m03, .nepal), "One-time payment")
        XCTAssertEqual(billingCadenceLabel(.m03, .zoneA), "Billed every 3 months")
        XCTAssertEqual(billingCadenceLabel(.m12, .zoneC), "Billed annually")
        XCTAssertEqual(billingCadenceLabel(.m01, .zoneB), "Billed monthly")
    }

    func testRenewalDateFormatting() {
        XCTAssertEqual(formatRenewalDate("2026-01-05T10:00:00Z"), "5 Jan 2026")
        XCTAssertEqual(formatRenewalDate("2026-01-05T10:00:00.123Z"), "5 Jan 2026")
        XCTAssertEqual(formatRenewalDate(nil), "")
        XCTAssertEqual(formatRenewalDate("garbage"), "garbage")
    }

    func testSearch() {
        XCTAssertEqual(LandingCatalog.search("asur").map(\.title), ["Asur", "Asur 2"])
        XCTAssertTrue(LandingCatalog.search("  ").isEmpty)
        XCTAssertTrue(LandingCatalog.search("korean").isEmpty)
        XCTAssertFalse(LandingCatalog.search("cricket").isEmpty)
    }
}

final class PlanChangeTests: XCTestCase {
    private let repo = SessionRepository(defaults: UserDefaults(suiteName: "PlanChangeTests")!)

    private func session(_ region: PriceRegion, _ tier: PlanTier, _ duration: PlanDuration) -> SubscriptionSession {
        repo.sessionFromSku(Catalog.findSku(region, tier, duration)!)
    }

    private func change(_ current: SubscriptionSession?, _ region: PriceRegion, _ tier: PlanTier, _ duration: PlanDuration, manage: Bool = true) -> PlanChange? {
        resolvePlanChange(current, Catalog.findSku(region, tier, duration), manageMode: manage)
    }

    func testNewPurchase() {
        XCTAssertEqual(change(nil, .nepal, .plus, .m03, manage: false)?.kind, .new)
        // Another region always counts as a new purchase.
        XCTAssertEqual(change(session(.nepal, .plus, .m03), .zoneB, .plus, .m03)?.kind, .new)
    }

    func testPrepaidRules() {
        let mobile3 = session(.nepal, .mobile, .m03)
        XCTAssertEqual(change(mobile3, .nepal, .mobile, .m03)?.kind, .renewal)
        let upgrade = change(mobile3, .nepal, .plus, .m03)!
        XCTAssertEqual(upgrade.kind, .fixedTierUpgrade)
        XCTAssertEqual(upgrade.amount, 250)
        XCTAssertEqual(change(mobile3, .nepal, .plus, .m12)?.kind, .immediateExtension)
        XCTAssertEqual(change(mobile3, .nepal, .mobile, .m01)?.kind, .deferred)
        XCTAssertEqual(change(mobile3, .nepal, .mobile, .m01)?.allowed, false)
        XCTAssertEqual(change(session(.nepal, .plus, .m03), .nepal, .mobile, .m03)?.kind, .deferred)
    }

    func testRecurringRules() {
        let plus3 = session(.zoneB, .plus, .m03)
        XCTAssertEqual(plus3.billingMode, .recurring)
        XCTAssertEqual(change(plus3, .zoneB, .plus, .m03)?.kind, .current)
        XCTAssertEqual(change(plus3, .zoneB, .plus, .m03)?.allowed, false)
        XCTAssertEqual(change(plus3, .zoneB, .mobile, .m03)?.kind, .providerDowngrade)
        XCTAssertEqual(change(plus3, .zoneB, .plus, .m01)?.kind, .providerDowngrade)
        XCTAssertEqual(change(plus3, .zoneB, .plus, .m12)?.kind, .providerUpgrade)
        XCTAssertEqual(change(plus3, .zoneB, .plus, .m12)?.intervalChange, true)

        let mobile3 = session(.zoneB, .mobile, .m03)
        let sameInterval = change(mobile3, .zoneB, .plus, .m03)!
        XCTAssertEqual(sameInterval.kind, .providerUpgrade)
        XCTAssertFalse(sameInterval.intervalChange)
    }

    func testUpgradeLifecycleNotes() {
        let plus3 = session(.zoneB, .plus, .m03)
        XCTAssertEqual(
            lifecycleNote(plus3, change(plus3, .zoneB, .plus, .m12)),
            "Starts now. A new billing period begins today, minus credit for unused time. Stripe shows the exact amount."
        )
        let mobile3 = session(.zoneB, .mobile, .m03)
        XCTAssertTrue(lifecycleNote(mobile3, change(mobile3, .zoneB, .plus, .m03)).hasPrefix("Starts now. You pay only for the days left until "))
    }

    func testLabels() {
        XCTAssertEqual(planActionLabel(PlanChange(kind: .providerDowngrade, amount: 0, allowed: true), currentPlan: false), "Schedule downgrade")
        XCTAssertEqual(planActionLabel(nil, currentPlan: false), "Continue")
        XCTAssertEqual(dueTodayCaption(PlanChange(kind: .providerUpgrade, amount: 1, allowed: true), 1, .usd), "Price difference")
        XCTAssertEqual(dueTodayCaption(PlanChange(kind: .new, amount: 1, allowed: true), 14.99, .usd), "$14.99")
    }
}

final class SessionRepositoryTests: XCTestCase {
    private var defaults: UserDefaults!
    private var repo: SessionRepository!

    override func setUp() {
        defaults = UserDefaults(suiteName: "SessionRepositoryTests")
        defaults.removePersistentDomain(forName: "SessionRepositoryTests")
        repo = SessionRepository(defaults: defaults)
    }

    func testRegionRoundTrip() {
        XCTAssertEqual(repo.getRegion(), .nepal)
        repo.setRegion(.zoneC)
        XCTAssertEqual(repo.getRegion(), .zoneC)
    }

    func testSessionRoundTripAndClear() {
        let s = repo.sessionFromSku(Catalog.findSku(.zoneA, .plus, .m12)!)
        repo.setSession(s)
        XCTAssertEqual(repo.getSession(), s)
        repo.setSession(nil)
        XCTAssertNil(repo.getSession())
    }

    func testDowngradeIsScheduledNotApplied() {
        let current = repo.sessionFromSku(Catalog.findSku(.zoneB, .plus, .m03)!)
        repo.setSession(current)
        repo.persistPurchase(Catalog.findSku(.zoneB, .mobile, .m03)!, current: current, kind: .providerDowngrade)
        let after = repo.getSession()!
        XCTAssertEqual(after.tier, .plus)
        XCTAssertEqual(after.pendingPlan?.tier, .mobile)
        XCTAssertEqual(after.pendingPlan?.effectiveDate, current.nextBillingDate)
    }

    func testPrepaidRenewalExtendsPaidThrough() {
        let current = repo.sessionFromSku(Catalog.findSku(.nepal, .plus, .m03)!)
        repo.persistPurchase(Catalog.findSku(.nepal, .plus, .m03)!, current: current, kind: .renewal)
        XCTAssertEqual(repo.getSession()!.paidThrough, SessionRepository.addMonths(to: current.paidThrough, 3))
    }

    func testFixedTierUpgradeKeepsEndDate() {
        let current = repo.sessionFromSku(Catalog.findSku(.nepal, .mobile, .m03)!)
        repo.persistPurchase(Catalog.findSku(.nepal, .plus, .m03)!, current: current, kind: .fixedTierUpgrade)
        let after = repo.getSession()!
        XCTAssertEqual(after.tier, .plus)
        XCTAssertEqual(after.paidThrough, current.paidThrough)
    }

    func testCancelAndResumeOnlyForRecurring() {
        repo.setSession(repo.sessionFromSku(Catalog.findSku(.nepal, .plus, .m03)!))
        repo.cancelAtPeriodEnd()
        XCTAssertEqual(repo.getSession()?.status, .active)

        repo.setSession(repo.sessionFromSku(Catalog.findSku(.zoneB, .plus, .m03)!))
        repo.cancelAtPeriodEnd()
        XCTAssertEqual(repo.getSession()?.status, .canceling)
        repo.resumeSubscription()
        XCTAssertEqual(repo.getSession()?.status, .active)
    }

    func testStripeQuarterlyPeriodIsThreeMonths() {
        let s = repo.sessionFromSku(Catalog.findSku(.zoneB, .plus, .m03)!)
        XCTAssertEqual(s.nextBillingDate, SessionRepository.addUtcMonths(3))
        XCTAssertEqual(s.paidThrough, s.nextBillingDate)
    }

    func testSameIntervalUpgradeKeepsBillingDate() {
        var current = repo.sessionFromSku(Catalog.findSku(.zoneB, .mobile, .m03)!)
        current.nextBillingDate = "2026-12-01T00:00:00Z"
        current.paidThrough = "2026-12-01T00:00:00Z"
        repo.persistPurchase(Catalog.findSku(.zoneB, .plus, .m03)!, current: current, kind: .providerUpgrade)
        let after = repo.getSession()!
        XCTAssertEqual(after.tier, .plus)
        XCTAssertEqual(after.nextBillingDate, "2026-12-01T00:00:00Z")
    }

    func testNewIntervalUpgradeStartsFreshPeriod() {
        var current = repo.sessionFromSku(Catalog.findSku(.zoneB, .plus, .m03)!)
        current.nextBillingDate = "2026-12-01T00:00:00Z"
        current.pendingPlan = PendingPlan(skuId: "DGO-ZB-MOB-03M", tier: .mobile, duration: .m03, effectiveDate: "2026-12-01T00:00:00Z")
        repo.persistPurchase(Catalog.findSku(.zoneB, .plus, .m12)!, current: current, kind: .providerUpgrade)
        let after = repo.getSession()!
        XCTAssertEqual(after.duration, .m12)
        XCTAssertEqual(after.nextBillingDate, SessionRepository.addUtcMonths(12))
        XCTAssertNil(after.pendingPlan)
    }

    func testOrderRefShape() {
        XCTAssertNotNil(repo.generateOrderRef().range(of: #"^DGO-[0-9A-F]{4}-[0-9A-F]{4}$"#, options: .regularExpression))
    }
}

final class ViewModelTests: XCTestCase {
    private func makeVM() -> CheckoutViewModel {
        let defaults = UserDefaults(suiteName: "ViewModelTests")!
        defaults.removePersistentDomain(forName: "ViewModelTests")
        return CheckoutViewModel(repo: SessionRepository(defaults: defaults))
    }

    func testNepalValidation() {
        let vm = makeVM()
        vm.openCheckout()
        vm.nextFromPlan()
        XCTAssertFalse(vm.submitNepalPayment())
        XCTAssertEqual(vm.paymentError, "Choose a payment method.")
        vm.nepalPsp = .khalti
        XCTAssertFalse(vm.submitNepalPayment())
        XCTAssertEqual(vm.paymentError, "Enter a valid mobile number.")
        vm.nepalPsp = .connectips
        XCTAssertFalse(vm.submitNepalPayment())
        XCTAssertEqual(vm.paymentError, "Enter a valid account or customer ID.")
        vm.nepalPsp = .getpay
        vm.cardForm = CardForm(number: vm.formatCard("4000000000000002"), name: "A", expiry: vm.formatExpiry("1230"), cvc: "123")
        XCTAssertFalse(vm.submitNepalPayment())
        XCTAssertEqual(vm.paymentError, "Card declined. Try another.")
        vm.cardForm.number = vm.formatCard("4242424242424242")
        XCTAssertTrue(vm.submitNepalPayment())
        XCTAssertEqual(vm.step, 2)
        XCTAssertEqual(vm.session?.skuId, "DGO-NP-PLS-03M")
    }

    func testFormatters() {
        let vm = makeVM()
        XCTAssertEqual(vm.formatCard("4242a4242424242424299"), "4242 4242 4242 4242")
        XCTAssertEqual(vm.formatExpiry("1230"), "12/30")
        XCTAssertEqual(vm.formatExpiry("12"), "12")
    }

    func testCouponApply() {
        let vm = makeVM()
        vm.openCheckout()
        XCTAssertEqual(vm.applyCoupon("nope"), "That code isn’t valid.")
        XCTAssertNil(vm.applyCoupon(" dgo10 "))
        XCTAssertEqual(vm.dueAmount, 719)
    }

    func testStripeCheckoutRecurring() {
        let vm = makeVM()
        vm.setDevRegion(.zoneB)
        vm.openCheckout()
        XCTAssertEqual(vm.amount, 29.99, accuracy: 0.001)
        vm.nextFromPlan()
        vm.submitStripePayment()
        XCTAssertEqual(vm.session?.billingMode, .recurring)
        XCTAssertEqual(vm.lastPaymentLabel, "Stripe Checkout")
    }

    func testBackNavigation() {
        let vm = makeVM()
        vm.openCheckout()
        vm.nextFromPlan()
        XCTAssertEqual(vm.step, 1)
        vm.back()
        XCTAssertEqual(vm.step, 0)
        vm.back()
        XCTAssertEqual(vm.screen, .home)
    }
}
