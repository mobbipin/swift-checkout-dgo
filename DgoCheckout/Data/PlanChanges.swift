import Foundation

func resolvePlanChange(
    _ current: SubscriptionSession?,
    _ target: SubscriptionSku?,
    manageMode: Bool
) -> PlanChange? {
    guard let target else { return nil }
    guard manageMode, let current, current.region == target.region else {
        return PlanChange(kind: .new, amount: target.price, allowed: true)
    }
    if current.skuId == target.id {
        return current.billingMode == .recurring
            ? PlanChange(kind: .current, amount: target.price, allowed: false)
            : PlanChange(kind: .renewal, amount: target.price, allowed: true)
    }
    if current.billingMode == .recurring {
        let downgrade = (current.tier == .plus && target.tier == .mobile) ||
            target.duration.months < current.duration.months
        return PlanChange(
            kind: downgrade ? .providerDowngrade : .providerUpgrade,
            amount: target.price,
            allowed: true,
            intervalChange: target.duration != current.duration
        )
    }

    let currentMonths = current.duration.months
    let targetMonths = target.duration.months
    if targetMonths < currentMonths || (current.tier == .plus && target.tier == .mobile) {
        return PlanChange(kind: .deferred, amount: target.price, allowed: false)
    }
    if current.tier == .mobile && target.tier == .plus && current.duration == target.duration {
        let currentSku = Catalog.findSku(current.region, current.tier, current.duration)
        let fee = max(target.price - (currentSku?.price ?? 0), 0)
        return PlanChange(kind: .fixedTierUpgrade, amount: fee, allowed: true)
    }
    if targetMonths > currentMonths {
        return PlanChange(kind: .immediateExtension, amount: target.price, allowed: true)
    }
    return PlanChange(kind: .deferred, amount: target.price, allowed: false)
}

func planActionLabel(_ change: PlanChange?, currentPlan: Bool) -> String {
    switch change?.kind {
    case .current: "Current plan"
    case .fixedTierUpgrade, .providerUpgrade: "Upgrade"
    case .providerDowngrade: "Schedule downgrade"
    case .deferred: "After this term"
    case .renewal, .immediateExtension: "Add time"
    default: currentPlan ? "Add time" : "Continue"
    }
}

func planStateLabel(_ kind: PlanChangeKind?) -> String? {
    switch kind {
    case .current: "Current plan"
    case .fixedTierUpgrade, .providerUpgrade: "Upgrade"
    case .providerDowngrade: "Downgrade"
    case .deferred: "After this term"
    case .renewal: "Add time"
    case .immediateExtension: "Longer term"
    default: nil
    }
}

/// What the customer is asked to pay on this screen. Stripe proration is not calculated here.
func dueTodayCaption(_ change: PlanChange?, _ amount: Double, _ currency: Currency) -> String {
    switch change?.kind {
    case .providerDowngrade: "No charge today"
    case .providerUpgrade: "Price difference"
    case .current: "Current plan"
    case .deferred: "Not available yet"
    default: formatMoney(amount, currency)
    }
}

func lifecycleNote(_ current: SubscriptionSession, _ change: PlanChange?) -> String {
    switch change?.kind {
    case .fixedTierUpgrade:
        "Plus now. Still ends \(formatRenewalDate(current.paidThrough))."
    case .immediateExtension:
        "Added after \(formatRenewalDate(current.paidThrough)). No auto-renew."
    case .deferred:
        "Available after \(formatRenewalDate(current.paidThrough))."
    case .providerDowngrade:
        "Switches on \(formatRenewalDate(current.nextBillingDate ?? current.paidThrough)). No charge today."
    case .providerUpgrade:
        change?.intervalChange == true
            ? "Starts now. A new billing period begins today, minus credit for unused time. Stripe shows the exact amount."
            : "Starts now. You pay only for the days left until \(formatRenewalDate(current.nextBillingDate)). Stripe shows the exact amount."
    default:
        current.billingMode == .prepaid
            ? "Access until \(formatRenewalDate(current.paidThrough))."
            : "Renews \(formatRenewalDate(current.nextBillingDate))."
    }
}
