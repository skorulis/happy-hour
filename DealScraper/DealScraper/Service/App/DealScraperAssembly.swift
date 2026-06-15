//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit

final class DealScraperAssembly: AutoInitModuleAssembly {
    static var dependencies: [any Knit.ModuleAssembly.Type] { [] }
    typealias TargetResolver = Resolver
    
    init() {}
    
    @MainActor func assemble(container: Container<TargetResolver>) {
        container.register(DealImageExtractor.self) { _ in
            DealImageExtractor()
        }
        
        container.register(DealTextAnalyzer.self) { _ in
            DealTextAnalyzer()
        }

        container.register(OpenAIClient.self) { _ in
            OpenAIClient()
        }

        container.register(OpenRouterClient.self) { _ in
            OpenRouterClient()
        }

        container.register(OnDeviceDealProcessor.self) { OnDeviceDealProcessor.make(resolver: $0) }

        container.register(OpenAIVisionDealProcessor.self) { resolver in
            OpenAIVisionDealProcessor(client: resolver.openAIClient())
        }

        container.register(OpenRouterVisionDealProcessor.self) { resolver in
            OpenRouterVisionDealProcessor(client: resolver.openRouterClient())
        }
        
        container.register(ImageImportViewModel.self) { ImageImportViewModel.make(resolver: $0) }
    }
}

extension DealScraperAssembly {
    @MainActor static func testing() -> ScopedModuleAssembler<Resolver> {
        ScopedModuleAssembler<Resolver>([DealScraperAssembly()])
    }
}
