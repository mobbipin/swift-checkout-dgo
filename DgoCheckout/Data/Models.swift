import Foundation

enum PriceRegion: String, CaseIterable, Codable, Identifiable {
    case nepal
    case zoneA = "za"
    case zoneB = "zb"
    case zoneC = "zc"

    var id: String { rawValue }
    var code: String { rawValue }

    var toggleLabel: String {
        switch self {
        case .nepal: "NP"
        case .zoneA: "ZA"
        case .zoneB: "ZB"
        case .zoneC: "ZC"
        }
    }

    var catalogLabel: String {
        switch self {
        case .nepal: "Nepal"
        case .zoneA: "India & Middle East"
        case .zoneB: "USA / Europe / AU / NZ"
        case .zoneC: "South East Asia"
        }
    }

    var billedIn: String { self == .nepal ? "Billed in NPR" : "Billed in USD" }
    var currency: Currency { self == .nepal ? .npr : .usd }
    var stripe: Bool { self != .nepal }
}

enum PlanTier: String, CaseIterable, Codable { case mobile = "MOBILE", plus = "PLUS" }

enum PlanDuration: String, CaseIterable, Codable { case m01 = "M01", m03 = "M03", m12 = "M12" }

enum Currency: String, Codable { case npr = "NPR", usd = "USD" }

enum Entitlement: String, Codable { case epMobile = "EP_MOBILE", epPlus = "EP_PLUS" }

enum BillingMode: String, Codable { case prepaid = "PREPAID", recurring = "RECURRING" }

enum SessionStatus: String, Codable { case active = "ACTIVE", canceling = "CANCELING" }

enum NepalPsp: String, CaseIterable, Identifiable {
    case khalti, esewa, connectips, fonepay, getpay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .khalti: "Khalti by IME"
        case .esewa: "eSewa"
        case .connectips: "ConnectIPS"
        case .fonepay: "Fonepay"
        case .getpay: "GetPay"
        }
    }

    var tagline: String {
        switch self {
        case .khalti, .esewa: "Digital wallet"
        case .connectips: "Bank transfer"
        case .fonepay: "QR payment"
        case .getpay: "Visa / Mastercard"
        }
    }

    var image: String? {
        switch self {
        case .khalti: "psp_khalti"
        case .esewa: "psp_esewa"
        case .connectips: "psp_connectips"
        case .fonepay: "psp_fonepay"
        case .getpay: nil
        }
    }

    var emoji: String {
        switch self {
        case .khalti: "💜"
        case .esewa: "💚"
        case .connectips: "🔗"
        case .fonepay: "📱"
        case .getpay: "💳"
        }
    }
}

struct SubscriptionSku: Equatable {
    let id: String
    let region: PriceRegion
    let tier: PlanTier
    let duration: PlanDuration
    let price: Double
    let currency: Currency
    let entitlement: Entitlement
    let liveSports: Bool
}

struct PendingPlan: Codable, Equatable {
    var skuId: String
    var tier: PlanTier
    var duration: PlanDuration
    var effectiveDate: String
}

struct SubscriptionSession: Codable, Equatable {
    var skuId: String
    var tier: PlanTier
    var duration: PlanDuration
    var region: PriceRegion
    var liveSports: Bool
    var entitlement: Entitlement
    var billingMode: BillingMode
    var status: SessionStatus
    var paidThrough: String
    var nextBillingDate: String?
    var pendingPlan: PendingPlan? = nil
}

struct AppliedCoupon: Equatable {
    let code: String
    let percent: Int
}

enum PlanChangeKind {
    case new
    case current
    case renewal
    case fixedTierUpgrade
    case immediateExtension
    case providerUpgrade
    case providerDowngrade
    case deferred
}

struct PlanChange: Equatable {
    let kind: PlanChangeKind
    let amount: Double
    let allowed: Bool
    var intervalChange = false
}

struct CardForm: Equatable {
    var number = ""
    var name = ""
    var expiry = ""
    var cvc = ""
}

enum Screen { case home, account, checkout }
