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

    /// Mismas categorías en español (las que usa la app desde 1.26) con vocabulario
    /// en español. Se conservan las claves en inglés para no romper notas antiguas.
    private static let spanishKeywords: [String: [String]] = [
        "hábitos": ["rutina", "hábito", "habito", "diario", "diaria", "cada", "día", "manana", "mañana", "dormir", "caminar", "correr", "meditar", "leer", "agua", "constante", "constancia", "disciplina"],
        "personas": ["amigo", "amiga", "amigos", "familia", "mamá", "mama", "papá", "papa", "hermana", "hermano", "pareja", "novio", "novia", "esposa", "esposo", "llamar", "llamé", "llame", "platicar", "platicamos", "hablar", "hablamos", "juntos", "juntas", "gente", "persona", "alguien", "abuela", "abuelo", "primo", "prima", "bebé", "bebe"],
        "lugares": ["parque", "playa", "casa", "café", "cafe", "restaurante", "ciudad", "pueblo", "montaña", "montana", "bosque", "viaje", "afuera", "naturaleza", "jardín", "jardin", "calle", "colonia", "cuarto", "cocina", "balcón", "balcon"],
        "actividades": ["trabajo", "proyecto", "pasatiempo", "juego", "jugar", "cocinar", "horno", "dibujar", "dibujo", "pintar", "limpiar", "ordenar", "planear", "estudiar", "aprender", "practicar", "escribir", "crear"],
        "música": ["canción", "cancion", "canciones", "música", "musica", "playlist", "álbum", "album", "banda", "concierto", "escuchar", "melodía", "melodia", "cantar", "guitarra", "piano", "spotify", "letra"],
        "autocuidado": ["descanso", "descansar", "relajarme", "respirar", "calma", "baño", "bano", "siesta", "cuidarme", "amable", "suave", "mindfulness", "consentir", "té", "te", "silencio", "lento", "lenta", "diario"],
        "salud": ["salud", "doctor", "doctora", "medicina", "medicamento", "enfermo", "enferma", "dolor", "cabeza", "hospital", "terapia", "terapeuta", "gym", "gimnasio", "ejercicio", "cuerpo", "energía", "energia", "cansado", "cansada", "recuperación", "recuperacion"],
        "trabajo": ["jefe", "jefa", "compañero", "companero", "compañera", "oficina", "junta", "reunión", "reunion", "cliente", "correo", "carrera", "ascenso", "entrevista", "sueldo", "equipo", "entrega"],
        "dinero": ["presupuesto", "gasto", "gastar", "ahorro", "ahorrar", "cuenta", "renta", "deuda", "pagar", "pago", "banco"],
        "comida": ["comer", "comida", "platillo", "desayuno", "almuerzo", "cena", "receta", "snack", "fruta", "verdura", "pizza", "pastel", "hambre", "rico", "antojito"],
        "naturaleza": ["sol", "solcito", "lluvia", "llover", "cielo", "nube", "nubes", "árbol", "arbol", "árboles", "flor", "flores", "mar", "océano", "oceano", "viento", "estrellas", "luna", "nieve", "hojas"],
        "aprendizaje": ["libro", "libros", "leer", "curso", "clase", "lección", "leccion", "aprender", "estudio", "escuela", "universidad", "idioma", "habilidad"],
        "emociones": ["siento", "sentí", "sentir", "feliz", "triste", "enojado", "enojada", "ansioso", "ansiosa", "preocupado", "preocupada", "estresado", "estresada", "agradecido", "agradecida", "amor", "esperanza", "miedo", "emocionado", "emocionada", "solo", "sola", "orgulloso", "orgullosa", "abrumado", "abrumada"]
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

            if let list = keywords[key] ?? spanishKeywords[key] {
                score += list.filter { words.contains($0) }.count * 2
            }

            if score > 0, best == nil || score > best!.score {
                best = (category, score)
            }
        }

        return best?.category
    }
}
