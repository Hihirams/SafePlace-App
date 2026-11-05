import SwiftUI

@main
struct SafePlaceApp: App {
    init() {
        // Antes de que se construya ninguna vista: el bundle empieza a
        // resolver las cadenas contra el idioma guardado en Ajustes.
        LanguageBundle.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
