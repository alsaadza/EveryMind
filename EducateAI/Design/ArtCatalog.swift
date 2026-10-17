import Foundation

/// A public-domain artwork bundled in the asset catalog (see docs/CREDITS.md).
struct ArtPiece: Hashable {
    let asset: String
    let title: String
    let artist: String
    let date: String
    let source: String
}

enum ArtCatalog {
    static let defaultAsset = "art-default"

    static let all: [ArtPiece] = [
        ArtPiece(asset: "art-hero-student", title: "A Sunday on La Grande Jatte — 1884", artist: "Georges Seurat", date: "1884–86", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-hero-teacher", title: "Moonlight, Strandgade 30", artist: "Vilhelm Hammershøi", date: "1900–1906", source: "The Metropolitan Museum of Art, CC0"),
        ArtPiece(asset: "art-water", title: "Under the Wave off Kanagawa (The Great Wave)", artist: "Katsushika Hokusai", date: "1830/33", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-probability", title: "Sugoroku Players", artist: "Torii Kiyohiro", date: "c. 1750", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-math", title: "Lozenge Composition with Yellow, Black, Blue, Red, and Gray", artist: "Piet Mondrian", date: "1921", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-fractions", title: "Bedcover (pieced quilt)", artist: "Unknown maker, United States or England", date: "1820/50", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-literature", title: "Woman Reading", artist: "Édouard Manet", date: "1880–82", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-essay", title: "The Letter", artist: "Mary Cassatt", date: "1890–91", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-science", title: "Gloriosa Superba (Climbing Lily)", artist: "Pierre-Joseph Redouté", date: "ca. 1810", source: "The Metropolitan Museum of Art, CC0"),
        ArtPiece(asset: "art-astronomy", title: "Rabbits in Moonlight", artist: "Utagawa Hiroshige", date: "c. 1849/52", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-history", title: "The Landing Place", artist: "Hubert Robert", date: "1788", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-nature", title: "Cliff Walk at Pourville", artist: "Claude Monet", date: "1882", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-biology", title: "Crown Imperial (Fritillaria imperialis), from \"Les Liliacées\"", artist: "Pierre-Joseph Redouté", date: "1802–16", source: "The Metropolitan Museum of Art, CC0"),
        ArtPiece(asset: "art-civics", title: "Paris Street; Rainy Day", artist: "Gustave Caillebotte", date: "1877", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-music-art", title: "Woman at the Piano", artist: "Pierre-Auguste Renoir", date: "1875–76", source: "Art Institute of Chicago, CC0"),
        ArtPiece(asset: "art-default", title: "Branch of the Seine near Giverny (Mist)", artist: "Claude Monet", date: "1897", source: "Art Institute of Chicago, CC0"),
    ]

    private static let byAsset: [String: ArtPiece] = Dictionary(uniqueKeysWithValues: all.map { ($0.asset, $0) })

    /// Returns the piece for an asset name, falling back to `art-default`.
    static func piece(_ asset: String) -> ArtPiece {
        byAsset[asset] ?? byAsset[defaultAsset]!
    }

    /// Ordered rules; the first rule with a matching keyword wins.
    /// Keywords of 5+ characters also match as word prefixes ("geometr" → "geometric");
    /// shorter ones match whole words or simple plurals ("star" → "stars", not "start").
    private static let rules: [(asset: String, keywords: [String])] = [
        ("art-probability", ["probabilit", "chance", "dice", "die", "card", "statistic", "random", "odds"]),
        ("art-water", ["water", "rain", "rainfall", "ocean", "weather", "climate", "river", "sea"]),
        ("art-fractions", ["fraction", "ratio", "percent", "decimal", "proportion"]),
        ("art-math", ["math", "maths", "mathematic", "algebra", "geometr", "number", "equation", "calculus", "arithmetic"]),
        ("art-essay", ["essay", "argument", "writing", "write", "writer", "persua", "thesis"]),
        ("art-literature", ["reading", "read", "novel", "poem", "poetry", "literat", "story", "stories", "shakespeare"]),
        ("art-biology", ["cell", "cellular", "biolog", "plant", "animal", "ecosystem", "photosynth", "genetic"]),
        ("art-science", ["physics", "chemi", "science", "scientific", "energy"]),
        ("art-astronomy", ["space", "planet", "star", "moon", "astronom", "solar"]),
        ("art-history", ["histor", "war", "ancient", "revolution", "empire"]),
        ("art-civics", ["govern", "civic", "democra", "vote", "voting", "econom"]),
        ("art-music-art", ["music", "art", "arts", "artist", "artwork", "painting", "paint"]),
        ("art-nature", ["nature", "natural", "geograph", "earth"]),
    ]

    private static func matches(_ token: Substring, _ keyword: String) -> Bool {
        if token == keyword || token == keyword + "s" || token == keyword + "es" { return true }
        return keyword.count >= 5 && token.hasPrefix(keyword)
    }

    /// Picks a cover for an arbitrary course/assignment topic by keyword.
    /// Deterministic and case-insensitive; falls back to `art-default`.
    static func cover(for topic: String) -> ArtPiece {
        let tokens = topic.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        guard !tokens.isEmpty else { return piece(defaultAsset) }
        for rule in rules {
            for keyword in rule.keywords where tokens.contains(where: { matches($0, keyword) }) {
                return piece(rule.asset)
            }
        }
        return piece(defaultAsset)
    }
}
