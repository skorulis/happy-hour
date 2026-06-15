//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation
import Knit

final class DealScraperAssembly: AutoInitModuleAssembly {
    static var dependencies: [any Knit.ModuleAssembly.Type] { [] }
    typealias TargetResolver = Resolver
    
    private let purpose: IOCPurpose

    init() {
        self.purpose = .testing
    }

    init(purpose: IOCPurpose) {
        self.purpose = purpose
    }
    
    @MainActor func assemble(container: Container<TargetResolver>) {
        registerStores(container: container)
        registerServices(container: container)
        
        container.register(ImageImportViewModel.self) { ImageImportViewModel.make(resolver: $0) }
    }
    
    @MainActor
    private func registerServices(container: Container<TargetResolver>) {
        container.register(DealImageExtractor.self) { _ in DealImageExtractor() }
        container.register(DealTextAnalyzer.self) { _ in DealTextAnalyzer() }
        container.register(OpenAIClient.self) { _ in OpenAIClient() }
        container.register(OpenRouterClient.self) { _ in OpenRouterClient() }
        container.register(OnDeviceDealProcessor.self) { OnDeviceDealProcessor.make(resolver: $0) }

        container.register(OpenAIVisionDealProcessor.self) { resolver in
            OpenAIVisionDealProcessor(client: resolver.openAIClient())
        }

        container.register(OpenRouterVisionDealProcessor.self) { resolver in
            OpenRouterVisionDealProcessor(client: resolver.openRouterClient())
        }
    }
    
    @MainActor
    private func registerStores(container: Container<TargetResolver>) {
        switch purpose {
        case .testing:
            container.register(SQLStore.self) { _ in
                SQLStore.inMemory()
            }
            .inObjectScope(.container)
        case .normal:
            // @knit ignore
            container.register(SQLStore.self) { _ in
                SQLStore.default()
            }
            .inObjectScope(.container)
        }
    }
}

extension DealScraperAssembly {
    @MainActor static func testing() -> ScopedModuleAssembler<Resolver> {
        ScopedModuleAssembler<Resolver>([DealScraperAssembly()])
    }
}
