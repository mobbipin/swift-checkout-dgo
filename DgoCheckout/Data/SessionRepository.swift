import Foundation

final class SessionRepository {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getRegion() -> PriceRegion {
        let stored = defaults.string(forKey: Self.keyRegion) ?? PriceRegion.nepal.code
        return PriceRegion(rawValue: stored) ?? .nepal
    }

    func setRegion(_ region: PriceRegion) {
        defaults.set(region.code, forKey: Self.keyRegion)
    }

    func getSession() -> SubscriptionSession? {
        guard let data = defaults.data(forKey: Self.keySession) else { return nil }
        return try? JSONDecoder().decode(SubscriptionSession.self, from: data)
    }

    func cancelAtPeriodEnd() {
        guard var current = getSession(), current.billingMode == .recurring else { return }
        current.status = .canceling
        current.pendingPlan = nil
        setSession(current)
    }

    func resumeSubscription() {
        guard var current = getSession(), current.billingMode == .recurring else { return }
        current.status = .active
        setSession(current)
    }

    func setSession(_ session: SubscriptionSession?) {
        if let session, let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: Self.keySession)
        } else {
            defaults.removeObject(forKey: Self.keySession)
        }
    }

    func sessionFromSku(_ sku: SubscriptionSku) -> SubscriptionSession {
        let billingMode: BillingMode = sku.region.stripe ? .recurring : .prepaid
        let paidThroughMonths = billingMode == .prepaid ? sku.duration.months : (sku.duration == .m12 ? 12 : 1)
        let paidThrough = Self.addUtcMonths(paidThroughMonths)
        return SubscriptionSession(
            skuId: sku.id,
            tier: sku.tier,
            duration: sku.duration,
            region: sku.region,
            liveSports: sku.liveSports,
            entitlement: sku.entitlement,
            billingMode: billingMode,
            status: .active,
            paidThrough: paidThrough,
            nextBillingDate: billingMode == .recurring ? paidThrough : nil
        )
    }

    func persistPurchase(_ sku: SubscriptionSku, current: SubscriptionSession?, kind: PlanChangeKind) {
        if let current, current.billingMode == .recurring, kind == .providerDowngrade {
            var updated = current
            updated.status = .active
            updated.pendingPlan = PendingPlan(
                skuId: sku.id,
                tier: sku.tier,
                duration: sku.duration,
                effectiveDate: current.nextBillingDate ?? current.paidThrough
            )
            setSession(updated)
            return
        }
        var next = sessionFromSku(sku)
        if let current {
            switch (current.billingMode, kind) {
            case (.prepaid, .fixedTierUpgrade):
                next.paidThrough = current.paidThrough
                next.nextBillingDate = nil
            case (.prepaid, .renewal), (.prepaid, .immediateExtension):
                next.paidThrough = Self.addMonths(to: current.paidThrough, sku.duration.months)
            case (.recurring, .providerUpgrade):
                next.paidThrough = current.paidThrough
                next.nextBillingDate = current.nextBillingDate
                next.status = .active
                next.pendingPlan = nil
            default:
                break
            }
        }
        setSession(next)
    }

    func generateOrderRef() -> String {
        let hex = String((0..<8).map { _ in "0123456789ABCDEF".randomElement()! })
        return "DGO-\(hex.prefix(4))-\(hex.suffix(4))"
    }

    static let keyRegion = "dgo_dev_region"
    static let keySession = "dgo_unlock_subscription"

    private static var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    static func addUtcMonths(_ months: Int, from date: Date = Date()) -> String {
        formatIso(utcCalendar.date(byAdding: .month, value: months, to: date) ?? date)
    }

    static func addMonths(to value: String, _ months: Int) -> String {
        guard let date = parseIso(value) else { return addUtcMonths(months) }
        return addUtcMonths(months, from: date)
    }
}
