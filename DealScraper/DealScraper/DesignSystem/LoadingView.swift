//Created by Alex Skorulis on 20/6/2026.

import Foundation
import SwiftUI

struct LoadingView: View {
    
    let text: String?
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            if let text {
                Text(text)
            }
        }
    }
}
