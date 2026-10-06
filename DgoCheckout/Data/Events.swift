import Foundation

/// One-time event passes (pay-per-view). Bought without a subscription and never renewed.
/// Prices are placeholders until the event commercial sheet is approved.
struct EventPass: Equatable {
    let key: String
    let league: String
    let title: String
    let subtitle: String
    let window: String
    let accessUntil: String
    let includes: [String]
    let prices: [PriceRegion: Double]
    let accent: UInt32
    var coveredBy: String? = nil

    func skuId(_ region: PriceRegion) -> String { "PPV-\(region.toggleLabel)-\(key)" }
    func price(_ region: PriceRegion) -> Double { prices[region]! }
}

enum Events {
    static let all: [EventPass] = [
        EventPass(
            key: "EURO28-ALL",
            league: "UEFA",
            title: "EURO 2028",
            subtitle: "Full tournament pass",
            window: "Jun – Jul 2028",
            accessUntil: "2028-07-31T23:59:59Z",
            includes: ["All 51 matches live", "Replays & highlights", "Phone, TV & web"],
            prices: [.nepal: 999, .zoneA: 9.99, .zoneB: 24.99, .zoneC: 12.99],
            accent: 0xFF3B82F6
        ),
        EventPass(
            key: "EURO28-KO",
            league: "UEFA",
            title: "EURO 2028",
            subtitle: "Knockout stage pass",
            window: "Round of 16 to the final",
            accessUntil: "2028-07-31T23:59:59Z",
            includes: ["15 knockout matches live", "Replays & highlights", "Phone, TV & web"],
            prices: [.nepal: 499, .zoneA: 5.99, .zoneB: 14.99, .zoneC: 7.99],
            accent: 0xFFFF00BD,
            coveredBy: "EURO28-ALL"
        ),
    ]

    static func find(_ key: String) -> EventPass? { all.first { $0.key == key } }
}

enum PassOwnership { case owned, included }

func passOwnership(_ event: EventPass, _ owned: Set<String>) -> PassOwnership? {
    if owned.contains(event.key) { return .owned }
    if let coveredBy = event.coveredBy, owned.contains(coveredBy) { return .included }
    return nil
}
