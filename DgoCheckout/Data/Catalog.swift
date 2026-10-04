import Foundation

/// DGO Product & Entitlement Spec v3.0 — sellable SKUs.
/// Nepal NPR wallets + three international USD Stripe zones.
enum Catalog {
    static let skus: [SubscriptionSku] = [
        sku("DGO-NP-MOB-01M", .nepal, .mobile, .m01, 199.0, false),
        sku("DGO-NP-PLS-01M", .nepal, .plus, .m01, 299.0, false),
        sku("DGO-NP-MOB-03M", .nepal, .mobile, .m03, 549.0, true),
        sku("DGO-NP-PLS-03M", .nepal, .plus, .m03, 799.0, true),
        sku("DGO-NP-MOB-12M", .nepal, .mobile, .m12, 1799.0, true),
        sku("DGO-NP-PLS-12M", .nepal, .plus, .m12, 2699.0, true),

        sku("DGO-ZA-MOB-01M", .zoneA, .mobile, .m01, 3.99, false),
        sku("DGO-ZA-PLS-01M", .zoneA, .plus, .m01, 5.99, false),
        sku("DGO-ZA-MOB-03M", .zoneA, .mobile, .m03, 9.99, true),
        sku("DGO-ZA-PLS-03M", .zoneA, .plus, .m03, 14.99, true),
        sku("DGO-ZA-MOB-12M", .zoneA, .mobile, .m12, 35.99, true),
        sku("DGO-ZA-PLS-12M", .zoneA, .plus, .m12, 50.99, true),

        sku("DGO-ZB-MOB-01M", .zoneB, .mobile, .m01, 6.99, false),
        sku("DGO-ZB-PLS-01M", .zoneB, .plus, .m01, 8.99, false),
        sku("DGO-ZB-MOB-03M", .zoneB, .mobile, .m03, 18.99, true),
        sku("DGO-ZB-PLS-03M", .zoneB, .plus, .m03, 29.99, true),
        sku("DGO-ZB-MOB-12M", .zoneB, .mobile, .m12, 64.99, true),
        sku("DGO-ZB-PLS-12M", .zoneB, .plus, .m12, 99.99, true),

        sku("DGO-ZC-MOB-01M", .zoneC, .mobile, .m01, 4.99, false),
        sku("DGO-ZC-PLS-01M", .zoneC, .plus, .m01, 6.99, false),
        sku("DGO-ZC-MOB-03M", .zoneC, .mobile, .m03, 10.99, true),
        sku("DGO-ZC-PLS-03M", .zoneC, .plus, .m03, 17.99, true),
        sku("DGO-ZC-MOB-12M", .zoneC, .mobile, .m12, 44.99, true),
        sku("DGO-ZC-PLS-12M", .zoneC, .plus, .m12, 65.99, true),
    ]

    static let coupons: [String: Int] = ["DGO10": 10, "DGO20": 20]

    static let durations: [PlanDuration] = PlanDuration.allCases
    static let tiers: [PlanTier] = [.plus, .mobile]

    static func findSku(_ region: PriceRegion, _ tier: PlanTier, _ duration: PlanDuration) -> SubscriptionSku? {
        skus.first { $0.region == region && $0.tier == tier && $0.duration == duration }
    }

    static func findSku(id: String) -> SubscriptionSku? { skus.first { $0.id == id } }

    private static func sku(
        _ id: String,
        _ region: PriceRegion,
        _ tier: PlanTier,
        _ duration: PlanDuration,
        _ price: Double,
        _ liveSports: Bool
    ) -> SubscriptionSku {
        SubscriptionSku(
            id: id,
            region: region,
            tier: tier,
            duration: duration,
            price: price,
            currency: region.currency,
            entitlement: tier == .plus ? .epPlus : .epMobile,
            liveSports: liveSports
        )
    }
}

struct TierMeta {
    let name: String
    let shortName: String
    let slogan: String
    let quality: String
    let facts: [String]
    let accent: UInt32
    let border: UInt32
}

let tierMeta: [PlanTier: TierMeta] = [
    .mobile: TierMeta(
        name: "DGO Mobile",
        shortName: "Mobile",
        slogan: "Phones, tablets & mobile web.",
        quality: "720p HD · 1 stream",
        facts: ["Phones & tablets · no TV", "720p · 1 stream", "1 profile"],
        accent: 0xFF8A3FFC,
        border: 0x598A3FFC
    ),
    .plus: TierMeta(
        name: "DGO Plus",
        shortName: "Plus",
        slogan: "TV, casting & more screens.",
        quality: "1080p Full HD · 3 streams",
        facts: ["TV, cast, desktop & phones", "1080p · 3 streams", "4 profiles"],
        accent: 0xFFFF00BD,
        border: 0x59FF00BD
    ),
]

extension PlanTier {
    var meta: TierMeta { tierMeta[self]! }
}

extension PlanDuration {
    var label: String {
        switch self {
        case .m01: "1 month"
        case .m03: "3 months"
        case .m12: "12 months"
        }
    }

    var months: Int {
        switch self {
        case .m01: 1
        case .m03: 3
        case .m12: 12
        }
    }
}

/// Kotlin's `roundToInt` rounds half up (toward +∞); match it so prices agree across ports.
func roundToInt(_ value: Double) -> Int { Int((value + 0.5).rounded(.down)) }

private let groupedInteger: NumberFormatter = {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_US")
    f.numberStyle = .decimal
    f.maximumFractionDigits = 0
    return f
}()

func formatMoney(_ amount: Double, _ currency: Currency) -> String {
    switch currency {
    case .npr: "रू " + (groupedInteger.string(from: NSNumber(value: roundToInt(amount))) ?? "\(roundToInt(amount))")
    case .usd: "$" + String(format: "%.2f", locale: Locale(identifier: "en_US"), amount)
    }
}

func formatMonthlyRate(_ sku: SubscriptionSku) -> String {
    let per = sku.price / Double(sku.duration.months)
    switch sku.currency {
    case .npr: return "रू \(roundToInt(per))/mo"
    case .usd: return formatMoney(per, .usd) + "/mo"
    }
}

func billingCadenceLabel(_ duration: PlanDuration, _ region: PriceRegion) -> String {
    if region == .nepal { return "One-time payment" }
    switch duration {
    case .m12: return "Billed annually"
    case .m03: return "Billed every 3 months"
    case .m01: return "Billed monthly"
    }
}

struct Savings: Equatable {
    let amount: Double
    let percent: Int
    let label: String
}

func savingsVsMonthly(_ region: PriceRegion, _ tier: PlanTier, _ duration: PlanDuration) -> Savings? {
    if duration == .m01 { return nil }
    guard let monthly = Catalog.findSku(region, tier, .m01),
          let picked = Catalog.findSku(region, tier, duration) else { return nil }
    let full = monthly.price * Double(duration.months)
    let amount = full - picked.price
    if amount <= 0 { return nil }
    let percent = roundToInt(amount / full * 100)
    return Savings(amount: amount, percent: percent, label: formatMoney(amount, picked.currency))
}

func compareAtPrice(_ region: PriceRegion, _ tier: PlanTier, _ duration: PlanDuration) -> Double {
    let monthly = Catalog.findSku(region, tier, .m01)?.price ?? 0
    return monthly * Double(duration.months)
}

func applyCouponAmount(_ amount: Double, _ currency: Currency, _ coupon: AppliedCoupon?) -> Double {
    guard let coupon else { return amount }
    let raw = amount * (1 - Double(coupon.percent) / 100.0)
    return currency == .npr ? Double(roundToInt(raw)) : Double(roundToInt(raw * 100)) / 100.0
}

private let renewalFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "UTC")
    f.dateFormat = "d MMM yyyy"
    return f
}()

func parseIso(_ iso: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: iso) { return d }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: iso)
}

func formatIso(_ date: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.string(from: date)
}

func formatRenewalDate(_ iso: String?) -> String {
    guard let iso, !iso.trimmingCharacters(in: .whitespaces).isEmpty else { return "" }
    guard let date = parseIso(iso) else { return iso }
    return renewalFormatter.string(from: date)
}
