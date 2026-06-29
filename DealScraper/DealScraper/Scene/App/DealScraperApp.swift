//  Created by Alexander Skorulis on 14/6/2026.

import ASKCore
import ASKCoordinator
import SwiftUI
import Knit

@main
struct DealScraperApp: App {
    
    private let assembler: ScopedModuleAssembler<Resolver> = {
        let assembler = ScopedModuleAssembler<Resolver>(
            [
                DealScraperAssembly()
            ]
        )
        return assembler
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.resolver, assembler.resolver)
                .environment(\.ask_debugging, true)
        }
    }
}
