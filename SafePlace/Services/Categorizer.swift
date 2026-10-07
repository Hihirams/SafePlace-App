import Foundation

/// Very light on-device categorizer. Suggests a category from the note text so
/// the user only has to confirm (and can always change it before saving).
enum Categorizer {

    private static let keywords: [String: [String]] = [
        "habits": ["routine", "habit", "daily", "everyday", "morning", "wake", "sleep", "walk", "run", "stretch", "meditate", "read", "water", "brush", "consistent", "streak", "discipline"],
        "people": ["friend", "friends", "family", "mom", "mum", "dad", "sister", "brother", "partner", "boyfriend", "girlfriend", "wife", "husband", "call", "called", "talked", "talking", "together", "people", "person", "someone", "grandma", "grandpa", "cousin", "baby"],
        "places": ["park", "beach", "home", "house", "cafe", "coffee", "restaurant", "city", "town", "mountain", "forest", "trip", "travel", "outside", "nature", "garden", "street", "neighborhood", "room", "kitchen", "balcony"],
        "activities": ["work", "project", "hobby", "game", "gaming", "cook", "cooking", "baking", "draw", "drawing", "paint", "painting", "clean", "tidy", "plan", "planning", "study", "learn", "practice", "build", "write", "writing", "create"],
        "music": ["song", "songs", "music", "playlist", "album", "band", "concert", "listen", "listening", "melody", "tune", "sing", "singing", "guitar", "piano", "spotify", "lyrics"],
        "self-care": ["rest", "relax", "relaxed", "breathe", "breathing", "calm", "bath", "spa", "nap", "self", "care", "kind", "gentle", "mindful", "mindfulness", "comfort", "tea", "quiet", "slow", "journal"],
        "health": ["health", "healthy", "doctor", "medicine", "sick", "pain", "headache", "hospital", "therapy", "therapist", "gym", "workout", "exercise", "body", "energy", "tired", "recovery"],
        "work": ["job", "boss", "coworker", "colleague", "deadline", "office", "meeting", "client", "email", "career", "promotion", "interview", "salary", "team"],
        "money": ["money", "budget", "spend", "spending", "save", "saving", "savings", "bill", "bills", "rent", "salary", "pay", "debt", "afford"],
        "food": ["eat", "eating", "food", "meal", "breakfast", "lunch", "dinner", "recipe", "snack", "fruit", "vegetable", "pizza", "cake", "hungry", "delicious"],
        "nature": ["sun", "sunny", "rain", "raining", "sky", "cloud", "tree", "trees", "flower", "flowers", "ocean", "sea", "wind", "stars", "moon", "snow", "leaves"],
        "learning": ["book", "books", "reading", "read", "course", "class", "lesson", "learn", "learning", "study", "school", "university", "language", "skill"],
        "emotions": ["feel", "feeling", "felt", "happy", "sad", "angry", "anxious", "worried", "stressed", "grateful", "love", "hope", "hopeful", "fear", "afraid", "excited", "lonely", "proud", "overwhelmed"]
    ]

    /// Returns the best matching category from `categories`, or nil if nothing fits.
    static func suggest(title: String, description: String, categories: [String]) -> String? {
        let normalized = " " + title.lowercased() + " " + description.lowercased() + " "
        let words = Set(normalized.split(whereSeparator: { !$0.isLetter }).map(String.init))

        var best: (category: String, score: Int)?

        for category in categories {
            let key = category.lowercased()
            var score = 0

            if normalized.contains(key) { score += 3 }
            if key.contains("-"), normalized.contains(key.replacingOccurrences(of: "-", with: " ")) { score += 3 }

            if let list = keywords[key] {
                score += list.filter { words.contains($0) }.count * 2
            }

            if score > 0, best == nil || score > best!.score {
                best = (category, score)
            }
        }

        return best?.category
    }
}
