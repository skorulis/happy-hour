//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation
import Knit

final class DealScraperAssembly: AutoInitModuleAssembly {
    static var dependencies: [any Knit.ModuleAssembly.Type] { [] }
    typealias TargetResolver = Resolver
    
    private let purpose: IOCPurpose

    init() {
        self.purpose = .normal
    }

    init(purpose: IOCPurpose) {
        self.purpose = purpose
    }
    
    @MainActor func assemble(container: Container<TargetResolver>) {
        ASKCoreAssembly(purpose: purpose).assemble(container: container)
        
        registerStores(container: container)
        registerServices(container: container)
        registerViewModels(container: container)
    }
    
    @MainActor
    private func registerViewModels(container: Container<TargetResolver>) {
        container.register(MainPathRenderer.self) { MainPathRenderer(resolver: $0) }
        
        container.register(ImageImportViewModel.self) { ImageImportViewModel.make(resolver: $0) }
        container.register(ExperimentViewModel.self) { ExperimentViewModel.make(resolver: $0) }
        container.register(SettingsViewModel.self) { SettingsViewModel.make(resolver: $0) }
        container.register(VenueImportViewModel.self) { VenueImportViewModel.make(resolver: $0) }
        container.register(VenueDetailsViewModel.self) { (resolver: Resolver, googleID: String) in
            VenueDetailsViewModel.make(resolver: resolver, googleMapId: googleID)
        }
    }
    
    @MainActor
    private func registerServices(container: Container<TargetResolver>) {
        container.register(DealImageExtractor.self) { _ in DealImageExtractor() }
        container.register(DealTextAnalyzer.self) { _ in DealTextAnalyzer() }
        container.register(OpenAIClient.self) { _ in OpenAIClient() }
        container.register(OpenRouterClient.self) { _ in OpenRouterClient() }
        container.register(GooglePlacesClient.self) { _ in GooglePlacesClient() }
        container.register(OnDeviceDealProcessor.self) { OnDeviceDealProcessor.make(resolver: $0) }

        container.register(OpenAIVisionDealProcessor.self) { resolver in
            OpenAIVisionDealProcessor(client: resolver.openAIClient())
        }

        container.register(OpenRouterVisionDealProcessor.self) { resolver in
            OpenRouterVisionDealProcessor(client: resolver.openRouterClient())
        }

        container.register(WebPageLoader.self) { _ in WebPageLoader() }
            .inObjectScope(.container)

        container.register(DealSourceExtractor.self) { _ in DealSourceExtractor() }

        container.register(ContentBlockGrouper.self) { _ in ContentBlockGrouper() }

        container.register(VenueLinkExtractor.self) { _ in VenueLinkExtractor() }

        container.register(CrawlImageCache.self) { _ in CrawlImageCache() }
            .inObjectScope(.container)

        container.register(CrawlImageFetcher.self) { resolver in
            CrawlImageFetcher(cache: resolver.crawlImageCache())
        }

        container.register(CrawlImageValidator.self) { resolver in
            CrawlImageValidator(
                fetcher: resolver.crawlImageFetcher(),
                imageExtractor: resolver.dealImageExtractor()
            )
        }

        container.register(VenueWebsiteCrawler.self) { resolver in
            VenueWebsiteCrawler(
                pageLoader: resolver.webPageLoader(),
                extractor: resolver.dealSourceExtractor(),
                venueLinkExtractor: resolver.venueLinkExtractor(),
                imageValidator: resolver.crawlImageValidator(),
                dealSourceRepository: resolver.dealSourceRepository(),
                venueRepository: resolver.venueRepository(),
                venueLinksRepository: resolver.venueLinksRepository()
            )
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

        container.register(VenueRepository.self) { resolver in
            VenueRepository(store: resolver.sqlStore())
        }
        .inObjectScope(.container)

        container.register(DealSourceRepository.self) { resolver in
            DealSourceRepository(store: resolver.sqlStore())
        }
        .inObjectScope(.container)

        container.register(VenueLinksRepository.self) { resolver in
            VenueLinksRepository(store: resolver.sqlStore())
        }
        .inObjectScope(.container)

        container.register(APIKeyStore.self) { resolver in
            APIKeyStore(secureStore: resolver.secureKeyValueStore())
        }
        .inObjectScope(.container)
    }
}

extension DealScraperAssembly {
    @MainActor static func testing() -> ScopedModuleAssembler<Resolver> {
        ScopedModuleAssembler<Resolver>([DealScraperAssembly(purpose: .testing)])
    }
}
