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
            .inObjectScope(.container)
        container.register(SettingsViewModel.self) { SettingsViewModel.make(resolver: $0) }
        container.register(StatsViewModel.self) { StatsViewModel.make(resolver: $0) }
        container.register(VenueImportViewModel.self) { VenueImportViewModel.make(resolver: $0) }
        container.register(GoogleImportViewModel.self) { GoogleImportViewModel.make(resolver: $0) }
        container.register(VenueHerosViewModel.self) { VenueHerosViewModel.make(resolver: $0) }
        container.register(VenueDetailsViewModel.self) { (resolver: Resolver, googleID: String) in
            VenueDetailsViewModel.make(resolver: resolver, googleMapId: googleID)
        }
        container.register(SuburbListViewModel.self) { SuburbListViewModel.make(resolver: $0) }
        container.register(SuburbDetailViewModel.self) { (resolver: Resolver, suburbId: Int64) in
            SuburbDetailViewModel.make(resolver: resolver, suburbId: suburbId)
        }
        container.register(ApprovalViewModel.self) { ApprovalViewModel.make(resolver: $0) }
        container.register(JobQueueViewModel.self) { JobQueueViewModel.make(resolver: $0) }
    }
    
    @MainActor
    private func registerServices(container: Container<TargetResolver>) {
        container.register(DealImageExtractor.self) { _ in DealImageExtractor() }
        container.register(ImageFeaturePrintGenerator.self) { _ in ImageFeaturePrintGenerator() }
        container.register(DealTextFilter.self) { _ in DealTextFilter() }
        container.register(DealAdvancedTextFilter.self) { _ in DealAdvancedTextFilter() }
        container.register(OpenRouterClient.self) { _ in OpenRouterClient() }
        container.register(ExtractProcessDealsAPIClient.self) { _ in ExtractProcessDealsAPIClient() }
        container.register(GooglePlacesClient.self) { _ in GooglePlacesClient() }
        container.register(WebMarkdownGenerator.self) { _ in WebMarkdownGenerator() }
            .inObjectScope(.container)

        container.register(OpenRouterVenueDealExtractor.self) { resolver in
            OpenRouterVenueDealExtractor(
                client: resolver.extractProcessDealsAPIClient(),
                backendURLStore: resolver.backendURLStore(),
                apiKeyStore: resolver.apiKeyStore(),
                llmModelStore: resolver.llmModelStore()
            )
        }

        container.register(VenueBlurbGenerator.self) { resolver in
            VenueBlurbGenerator(
                client: resolver.openRouterClient(),
                apiKeyStore: resolver.apiKeyStore(),
                llmModelStore: resolver.llmModelStore()
            )
        }

        container.register(VenueDealSourceMaterialPreparer.self) { VenueDealSourceMaterialPreparer.make(resolver: $0) }

        container.register(VenueDealExtractionService.self) { VenueDealExtractionService.make(resolver: $0) }
        
        container.register(DealCondenser.self) { _ in KeywordDealCondenser() }
        
        container.register(WebPageLoaderFactory.self) { WebPageLoaderFactory(resolver: $0) }

        container.register(ContentBlockGrouper.self) { _ in ContentBlockGrouper() }

        container.register(PageLinkExtractor.self) { _ in PageLinkExtractor() }

        container.register(CanonicalURLExtractor.self) { _ in CanonicalURLExtractor() }

        container.register(PageLinkFilter.self) { _ in PageLinkFilter() }

        container.register(SiteMapExtractor.self) { _ in SiteMapExtractor() }

        container.register(VenueLinkExtractor.self) { _ in VenueLinkExtractor() }

        container.register(CrawlImageCache.self) { _ in CrawlImageCache() }
            .inObjectScope(.container)

        container.register(CrawlImageFetcher.self) { resolver in
            CrawlImageFetcher(cache: resolver.crawlImageCache())
        }

        container.register(CrawlImageValidator.self) { CrawlImageValidator.make(resolver: $0) }

        container.register(CrawlPDFCache.self) { _ in CrawlPDFCache() }
            .inObjectScope(.container)

        container.register(CrawlPDFFetcher.self) { resolver in
            CrawlPDFFetcher(cache: resolver.crawlPDFCache())
        }

        container.register(PDFTextExtractor.self) { _ in PDFTextExtractor() }

        container.register(PDFValidator.self) { PDFValidator.make(resolver: $0) }

        container.register(ImageDeduper.self) { _ in ImageDeduper() }

        container.register(WebpageDeduper.self) { _ in WebpageDeduper() }

        container.register(ImageClassifier.self) { _ in ImageClassifier() }

        container.register(VenueHeroImageSelector.self) { resolver in
            VenueHeroImageSelector(
                fetcher: resolver.crawlImageFetcher(),
                imageExtractor: resolver.dealImageExtractor(),
                classifier: resolver.imageClassifier()
            )
        }

        container.register(VenueHeroImageStore.self) { resolver in
            VenueHeroImageStore(
                venueRepository: resolver.venueRepository(),
                imageFetcher: resolver.crawlImageFetcher(),
                uploader: resolver.r2Client()
            )
        }

        container.register(SuburbHeroImageStore.self) { resolver in
            SuburbHeroImageStore(
                suburbRepository: resolver.suburbRepository(),
                imageFetcher: resolver.crawlImageFetcher(),
                uploader: resolver.r2Client()
            )
        }

        container.register(R2Client.self) { resolver in
            R2Client(configStore: resolver.r2ConfigStore())
        }
        .inObjectScope(.container)

        container.register(VenueWebsiteCrawler.self) { VenueWebsiteCrawler.make(resolver: $0) }

        container.register(SuburbCrawler.self) { SuburbCrawler.make(resolver: $0) }

        container.register(JobQueue.self) { JobQueue.make(resolver: $0) }
            .inObjectScope(.container)
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

        container.register(DealRepository.self) { resolver in
            DealRepository(store: resolver.sqlStore())
        }
        .inObjectScope(.container)

        container.register(VenueLinksRepository.self) { resolver in
            VenueLinksRepository(store: resolver.sqlStore())
        }
        .inObjectScope(.container)

        container.register(SuburbRepository.self) { resolver in
            SuburbRepository(store: resolver.sqlStore())
        }
        .inObjectScope(.container)

        container.register(CountryRepository.self) { resolver in
            CountryRepository(store: resolver.sqlStore())
        }
        .inObjectScope(.container)

        container.register(APIKeyStore.self) { resolver in
            APIKeyStore(secureStore: resolver.secureKeyValueStore())
        }
        .inObjectScope(.container)

        container.register(R2ConfigStore.self) { resolver in
            R2ConfigStore(
                secureStore: resolver.secureKeyValueStore(),
                keyValueStore: resolver.pKeyValueStore()
            )
        }
        .inObjectScope(.container)

        container.register(LLMModelStore.self) { resolver in
            LLMModelStore(keyValueStore: resolver.pKeyValueStore())
        }
        .inObjectScope(.container)

        container.register(BackendURLStore.self) { resolver in
            BackendURLStore(keyValueStore: resolver.pKeyValueStore())
        }
        .inObjectScope(.container)
    }
}

extension DealScraperAssembly {
    @MainActor static func testing() -> ScopedModuleAssembler<Resolver> {
        ScopedModuleAssembler<Resolver>([DealScraperAssembly(purpose: .testing)])
    }
}
