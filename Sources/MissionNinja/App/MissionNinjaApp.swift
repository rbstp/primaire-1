import SwiftUI

@main
struct MissionNinjaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(catalog: .bundled(), curriculum: .bundled())
        }
    }
}
