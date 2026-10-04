import Foundation

struct TitleCard: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let tag: String
    var year = ""
    var rating = ""
    var duration = ""
    var subtitle = ""
    var desc = ""
    var poster: String? = nil
    var hero: String? = nil
}

struct ContentRail {
    let title: String
    let items: [TitleCard]
}

struct LandingTab {
    let id: String
    let label: String
    let color: UInt32
    let secondary: UInt32
    let hero: [TitleCard]
    let rails: [ContentRail]
    var partnerEyebrow: String? = nil
    var partnerTagline: String? = nil
}

private let posters: [String: String] = [
    "Asur": "poster_asur",
    "Asur 2": "poster_asur2",
    "Bajao": "poster_bajao",
    "Empire": "poster_empire",
    "Ghar Waapsi": "poster_ghar",
    "Honeymoon Photographer": "poster_honeymoon",
    "Illegal 2": "poster_illegal",
    "Inspector Avinash": "poster_inspector",
    "Khalbali Records": "poster_khalbali",
    "London Files": "poster_london",
    "Special Ops": "poster_special_ops",
    "Taaza Khabar": "poster_taaza",
]

private let heroes: [String: String] = [
    "Asur": "hero_asur",
    "Asur 2": "hero_asur2",
    "Special Ops": "hero_special_ops",
    "Taaza Khabar": "hero_taaza",
    "Inspector Avinash": "hero_inspector",
]

private let heroOsr = "hero_osr"
private let heroHome = "hero_home"
private let heroHotstar = "hero_hotstar"

private func show(
    _ title: String,
    _ tag: String,
    _ year: String = "",
    _ rating: String = "",
    _ duration: String = "",
    _ subtitle: String = "",
    _ desc: String = "",
    fallbackHero: String? = nil
) -> TitleCard {
    TitleCard(
        title: title, tag: tag, year: year, rating: rating, duration: duration,
        subtitle: subtitle, desc: desc,
        poster: posters[title],
        hero: heroes[title] ?? fallbackHero ?? posters[title]
    )
}

private let home = LandingTab(
    id: "home",
    label: "Home",
    color: 0xFF8A3FFC,
    secondary: 0xFFFF00BD,
    hero: [
        show("Prem Geet", "OSR Digital", "2016", "8.4", "2h 17m", "The film that defined Nepali YouTube", "Pooja Sharma and Pradeep Khadka — the crown jewel of the OSR Digital library.", fallbackHero: heroOsr),
        show("Special Ops", "JioHotstar", "2020", "8.6", "Eps", "Kay Kay Menon · Hotstar Specials", "The flagship thriller from JioHotstar — included with Mobile and Plus."),
        show("Buhari", "OSR Serial", "2026", "8.6", "Eps", "कथा चेलीको · 290+ episodes", "Nepal's most-watched sentimental serial.", fallbackHero: heroHome),
    ],
    rails: [
        ContentRail(title: "From OSR Digital", items: [
            show("Prem Geet", "Romance", "2016", "8.4", "2h 17m", "Pooja Sharma, Pradeep Khadka", fallbackHero: heroOsr),
            show("Prasad 2", "Drama", "2026", "8.1", "2h 10m", "Bipin Karki, Keki Adhikari", fallbackHero: heroOsr),
            show("Jhingedaau", "Comedy", "2026", "7.8", "2h 05m", fallbackHero: heroOsr),
            show("Behuli from Meghauli", "Drama", "2025", "8.0", "2h 12m", fallbackHero: heroOsr),
            show("Prem Geet 3", "Romance", "2022", "7.6", "2h 22m", fallbackHero: heroOsr),
            show("Buhari", "OSR Serial", "2026", "8.6", "290+ Eps", fallbackHero: heroHome),
        ]),
        ContentRail(title: "JioHotstar on DGO", items: [
            show("Special Ops", "Hotstar Specials", "2020", "8.6", "Eps", "Kay Kay Menon"),
            show("Asur", "Crime", "2020", "8.4", "Eps", "Arshad Warsi, Barun Sobti"),
            show("Asur 2", "Crime", "2023", "8.5", "8 Eps"),
            show("Taaza Khabar", "Fantasy", "2023", "8.1", "Eps", "Bhuvan Bam"),
            show("Inspector Avinash", "Crime", "2023", "7.8", "Eps", "Randeep Hooda"),
            show("Ghar Waapsi", "Drama", "2022", "8.4", "12 Eps"),
        ]),
        ContentRail(title: "Serials people finish", items: [
            show("Buhari", "OSR Serial", "2026", "8.6", "290+ Eps", fallbackHero: heroHome),
            show("Asur", "Hotstar Specials", "2020", "8.4", "Eps"),
            show("Kill Me Heal Me", "K-Drama", "2015", "8.3", "20 Eps"),
            show("Hospital Ship", "Medical", "2017", "7.5", "40 Eps"),
        ]),
        ContentRail(title: "Movies tonight", items: [
            show("Prem Geet", "OSR", "2016", "8.4", "2h 17m", fallbackHero: heroOsr),
            show("Honeymoon Photographer", "JioHotstar", "2024", "7.1", "6 Eps"),
            show("Prasad", "OSR", "2018", "8.2", "2h 15m", fallbackHero: heroOsr),
            show("Empire", "JioHotstar", "2021", "7.3", "8 Eps"),
            show("Imitation Game", "Drama", "2014", "8.0", "1h 54m"),
        ]),
    ]
)

private let hotstar = LandingTab(
    id: "hotstar",
    label: "JioHotstar",
    color: 0xFF0B5FFF,
    secondary: 0xFFFF4D9A,
    hero: [
        show("Special Ops", "Hotstar Specials", "2020", "8.6", "Eps", "Kay Kay Menon", "A wounded agency and a vanishing asset — the flagship JioHotstar thriller."),
        show("Asur", "Hotstar Specials", "2020", "8.4", "Eps", "Arshad Warsi · Barun Sobti", "Forensic science versus a killer who thinks in myths."),
        show("Taaza Khabar", "Hotstar Specials", "2023", "8.1", "Eps", "Bhuvan Bam", "See tomorrow, pay for it today."),
        show("Inspector Avinash", "Hotstar Specials", "2023", "7.8", "Eps", "Randeep Hooda", "A no-rules UP cop, inspired by true events."),
    ],
    rails: [
        ContentRail(title: "Hotstar Specials", items: [
            show("Special Ops", "Thriller", "2020", "8.6", "Eps", "Kay Kay Menon"),
            show("Asur", "Crime", "2020", "8.4", "Eps", "Arshad Warsi, Barun Sobti"),
            show("Asur 2", "Crime", "2023", "8.5", "8 Eps"),
            show("Taaza Khabar", "Fantasy", "2023", "8.1", "Eps", "Bhuvan Bam"),
            show("Inspector Avinash", "Crime", "2023", "7.8", "Eps", "Randeep Hooda"),
            show("Illegal 2", "Courtroom", "2021", "7.6", "Eps", "Neha Sharma"),
        ]),
        ContentRail(title: "Binge now", items: [
            show("Asur 2", "Crime", "2023", "8.5", "8 Eps"),
            show("Ghar Waapsi", "Drama", "2022", "8.4", "12 Eps", "Vineet Kumar"),
            show("London Files", "Thriller", "2022", "6.9", "6 Eps", "Arjun Rampal"),
            show("Honeymoon Photographer", "Thriller", "2024", "7.1", "6 Eps", "Asha Negi"),
        ]),
        ContentRail(title: "From the vault", items: [
            show("Bajao", "Comedy", "2023", "7.5", "8 Eps", "Raftaar"),
            show("Khalbali Records", "Music", "2024", "7.4", "8 Eps", "Ram Kapoor"),
            show("Empire", "Historical", "2021", "7.3", "8 Eps", "Kunal Kapoor"),
            show("Taaza Khabar", "Fantasy", "2023", "8.1", "Eps"),
        ]),
    ],
    partnerEyebrow: "Partner hub",
    partnerTagline: "Hotstar Specials — Special Ops, Asur, Taaza Khabar and the rest of the Spark catalogue on DGO."
)

private let osr = LandingTab(
    id: "osr",
    label: "OSR",
    color: 0xFFE10600,
    secondary: 0xFFF5C518,
    hero: [
        show("Prem Geet", "OSR Digital", "2016", "8.4", "2h 17m", "Pooja Sharma · Pradeep Khadka", "The most-viewed Nepali film on YouTube.", fallbackHero: heroOsr),
        show("Prasad 2", "New on OSR Movies", "2026", "8.1", "2h 10m", "Bipin Karki · Keki Adhikari", "The 2026 follow-up, now in the DGO OSR hub.", fallbackHero: heroOsr),
        show("Buhari", "OSR Serial", "2026", "8.6", "290+ Eps", "कथा चेलीको", "Hundreds of episodes, millions of weekly views.", fallbackHero: heroOsr),
    ],
    rails: [
        ContentRail(title: "OSR superhits", items: [
            show("Prem Geet", "Romance", "2016", "8.4", "2h 17m", fallbackHero: heroOsr),
            show("Prem Geet 2", "Romance", "2018", "8.0", "2h 20m", fallbackHero: heroOsr),
            show("Prem Geet 3", "Romance", "2022", "7.6", "2h 22m", fallbackHero: heroOsr),
            show("Prasad", "Drama", "2018", "8.2", "2h 15m", fallbackHero: heroOsr),
            show("Prasad 2", "Drama", "2026", "8.1", "2h 10m", fallbackHero: heroOsr),
            show("Jhingedaau", "Comedy", "2026", "7.8", "2h 05m", fallbackHero: heroOsr),
            show("Behuli from Meghauli", "Drama", "2025", "8.0", "2h 12m", fallbackHero: heroOsr),
        ]),
        ContentRail(title: "New on OSR Movies", items: [
            show("Gobar Ganesh", "Coming soon", "2026", "", "Trailer", "Barsha Siwakoti", fallbackHero: heroOsr),
            show("Pahad", "Drama", "2026", "7.9", "2h 08m", fallbackHero: heroOsr),
            show("Bar & Badhu", "Drama", "2024", "7.5", "Feature", fallbackHero: heroOsr),
            show("The Break Up", "Romance", "2019", "7.1", "2h 05m", fallbackHero: heroOsr),
        ]),
        ContentRail(title: "OSR serials", items: [
            show("Buhari", "Serial", "2026", "8.6", "290+ Eps", "कथा चेलीको", fallbackHero: heroHome),
            show("Juthe", "Serial", "2026", "8.1", "S2", fallbackHero: heroHome),
            show("Katha Cheliko", "Serial", "2025", "7.8", "Eps", fallbackHero: heroHome),
        ]),
    ],
    partnerEyebrow: "Partner hub",
    partnerTagline: "Nepali films, music, serials and reality from OSR Digital."
)

private let sports = LandingTab(
    id: "sports",
    label: "Sports",
    color: 0xFF8A3FFC,
    secondary: 0xFFFF4D00,
    hero: [
        show("Asia Cup Tonight", "Cricket", "2026", "", "Live", "Live & highlights", "Live sports is included on 3-month and 12-month plans.", fallbackHero: heroHotstar),
        show("Premier League Weekend", "Football", "2026", "", "90 min", fallbackHero: heroHotstar),
    ],
    rails: [
        ContentRail(title: "Live & highlights", items: [
            show("Asia Cup Tonight", "Cricket", "2026", "", "Live", fallbackHero: heroHotstar),
            show("Premier League Weekend", "Football", "2026", "", "90 min", fallbackHero: heroHotstar),
            show("Kabaddi Nationals", "Kabaddi", "2025", "", "2h 10m", fallbackHero: heroHotstar),
            show("NSL Matchday", "Football", "2025", "", "Live", fallbackHero: heroHotstar),
            show("Court Side", "Basketball", "2026", "", "Highlights", fallbackHero: heroHotstar),
        ]),
    ]
)

private let entertainment = LandingTab(
    id: "entertainment",
    label: "Entertainment",
    color: 0xFF8A3FFC,
    secondary: 0xFFFF00BD,
    hero: [
        show("Imitation Game", "Drama", "2014", "8.0", "1h 54m", "Hindi dubbed & more", fallbackHero: heroHome),
        show("Kill Me Heal Me", "Romance", "2015", "8.3", "20 Eps", fallbackHero: heroHome),
    ],
    rails: [
        ContentRail(title: "Hindi Dubbed", items: [
            show("After Math", "Action", "2016", "5.3", "1h 30m"),
            show("24 Hours To Live", "Thriller", "2017", "5.8", "1h 33m"),
            show("Imitation Game", "Drama", "2014", "8.0", "1h 54m"),
            show("Killing Them Softly", "Crime", "2012", "6.2", "1h 37m"),
            show("47 Meters Down", "Horror", "2017", "5.6", "1h 29m"),
        ]),
        ContentRail(title: "Nepali Movies", items: [
            show("Kalo Barsa", "Drama", "2018", "7.1", "2h 10m", fallbackHero: heroOsr),
            show("Mann Manai Manparaye", "Romance", "2019", "6.5", "2h 5m", fallbackHero: heroOsr),
            show("Teen Ghumti", "Classic", "2015", "7.5", "2h 15m", fallbackHero: heroOsr),
            show("Hasideu Ek Fera", "Comedy", "2020", "7.0", "1h 55m", fallbackHero: heroOsr),
        ]),
        ContentRail(title: "Korean Drama", items: [
            show("Bad Papa", "Drama", "2018", "7.8", "16 Eps"),
            show("Hospital Ship", "Medical", "2017", "7.5", "40 Eps"),
            show("Kill Me Heal Me", "Romance", "2015", "8.3", "20 Eps"),
            show("Sweet Revenge", "Teen", "2017", "7.2", "22 Eps"),
            show("Two Cops", "Fantasy", "2017", "7.3", "32 Eps"),
        ]),
    ]
)

private let specials = LandingTab(
    id: "specials",
    label: "Specials",
    color: 0xFF8A3FFC,
    secondary: 0xFFFF00BD,
    hero: [
        show("Documentary: The Himalayas", "Documentary", "2023", "9.2", "1h 45m", "Premium rental", "Unlock a single premium title. Separate from a DGO subscription.", fallbackHero: heroHome),
    ],
    rails: [
        ContentRail(title: "Exclusive Specials", items: [
            show("Comedy Night Live", "Comedy", "2024", "8.5", "1h 30m"),
            show("Music Awards 2024", "Music", "2024", "9.0", "3h 00m"),
            show("Documentary: The Himalayas", "Documentary", "2023", "9.2", "1h 45m", fallbackHero: heroHome),
        ]),
    ]
)

private let junior = LandingTab(
    id: "junior",
    label: "Junior",
    color: 0xFF22D3EE,
    secondary: 0xFF8A3FFC,
    hero: [
        show("Boonie Bears Homeward Journey", "Family", "2013", "7.0", "1h 08m", "Kids choice", fallbackHero: heroHome),
    ],
    rails: [
        ContentRail(title: "Kids Choice", items: [
            show("Sir Billi", "Animation", "2012", "4.5", "1h 20m"),
            show("Atomicron", "Action", "2014", "6.0", "1h 10m"),
            show("Dinofroz The Origin", "Adventure", "2015", "6.5", "1h 15m"),
            show("Boonie Bears Homeward Journey", "Family", "2013", "7.0", "1h 08m"),
            show("Felix All Around The World", "Adventure", "2005", "5.8", "1h 22m"),
        ]),
    ]
)

enum LandingCatalog {
    static let tabs: [LandingTab] = [home, hotstar, osr, sports, entertainment, specials, junior]

    static func tab(_ id: String) -> LandingTab { tabs.first { $0.id == id } ?? home }

    static func search(_ query: String) -> [TitleCard] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return [] }
        var seen = Set<String>()
        let all = tabs.flatMap { tab in tab.rails.flatMap(\.items) + tab.hero }
        return Array(
            all.filter { seen.insert($0.title).inserted }
                .filter {
                    $0.title.lowercased().contains(q) ||
                        $0.tag.lowercased().contains(q) ||
                        $0.subtitle.lowercased().contains(q)
                }
                .prefix(20)
        )
    }
}
