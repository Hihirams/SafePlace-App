import UIKit
import Social
import UniformTypeIdentifiers

/// Matches the `SharedNote` model used by the main app so notes round-trip
/// through the shared app-group container.
struct SharedNotePayload: Codable {
    let id: String
    let title: String
    let text: String
    let createdAt: Date
}

let shareGroupID = "group.com.hihirams.safeplace"

final class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    override func didSelectPost() {
        let body = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
        var attachments = [String]()

        let inputItems = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let group = DispatchGroup()

        for item in inputItems {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                for type in [UTType.plainText.identifier, UTType.text.identifier, UTType.url.identifier] {
                    guard provider.hasItemConformingToTypeIdentifier(type) else { continue }
                    group.enter()
                    provider.loadItem(forTypeIdentifier: type, options: nil) { result, _ in
                        defer { group.leave() }
                        switch result {
                        case let url as URL:
                            attachments.append(url.absoluteString)
                        case let string as String:
                            if !string.isEmpty {
                                attachments.append(string)
                            }
                        default:
                            break
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            var combined = body
            for attachment in attachments where !attachment.isEmpty {
                if !combined.isEmpty { combined += "\n\n" }
                combined += attachment
            }
            self.save(combined)
            self.extensionContext?.completeRequest(returningItems: [])
        }
    }

    override func didCancel() {
        extensionContext?.completeRequest(returningItems: [])
    }

    // MARK: - Persistence (shared app-group container)

    private func save(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var notes = Self.load()
        notes.insert(
            SharedNotePayload(
                id: "n-\(UUID().uuidString)",
                title: Self.title(from: trimmed),
                text: trimmed,
                createdAt: Date()
            ),
            at: 0
        )
        Self.write(notes)
    }

    private static func title(from text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if let first = lines.first {
            return String(first.prefix(60))
        }
        return "Shared note"
    }

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: shareGroupID)?
            .appendingPathComponent("SharedNotes.json")
    }

    private static func load() -> [SharedNotePayload] {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([SharedNotePayload].self, from: data)) ?? []
    }

    private static func write(_ notes: [SharedNotePayload]) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: url, options: .atomic)
        } catch { }
    }
}