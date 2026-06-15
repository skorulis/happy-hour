//Created by Alex Skorulis on 15/6/2026.

import ASKCoordinator
import Knit
import SwiftUI

extension CoordinatorView {
    func withRenderers(resolver: Resolver) -> Self {
        self.with(renderer: resolver.mainPathRenderer())
    }
}

