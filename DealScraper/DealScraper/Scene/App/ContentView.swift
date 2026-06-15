//  Created by Alexander Skorulis on 14/6/2026.

import SwiftUI
import Knit

struct ContentView: View {
    
    @Environment(\.resolver) private var resolver
    
    var body: some View {
        ImageImportView(viewModel: resolver!.imageImportViewModel())
    }
}

#Preview {
    ContentView()
}
