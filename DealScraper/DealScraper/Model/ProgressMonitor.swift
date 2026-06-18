//Created by Alex Skorulis on 18/6/2026.

import Foundation

enum ProgressState<ResultType> {
    case idle
    case inProgress(progress: String)
    case completed(ResultType)
    case failed(message: String)

}

struct ProgressMonitor<ResultType> {
    
    let block: @MainActor (ProgressState<ResultType>) -> Void
    
    init(block: @escaping (ProgressState<ResultType>) -> Void) {
        self.block = block
    }
    
    func update(progress: String) async {
        await MainActor.run {
            block(.inProgress(progress: progress))
        }
    }
    
    func completed(results: ResultType) async {
        await MainActor.run {
            block(.completed(results))
        }
    }
    
    func callAsFunction(_ progress: String) async {
        await update(progress: progress)
    }
    
    static var empty: Self {
        .init(block: { _ in })
    }
}
