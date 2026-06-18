//Created by Alex Skorulis on 18/6/2026.

import Foundation

actor ProgressMonitor {
    
    let block: @MainActor (String) -> Void
    
    init(block: @escaping @Sendable (String) -> Void) {
        self.block = block
    }
    
    func update(progress: String) async {
        await MainActor.run {
            block(progress)
        }
    }
}
