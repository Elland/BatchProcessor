import UIKit

struct GenericAsyncSequence<Element>: AsyncSequence {
    typealias AsyncIterator = GenericAsyncIterator<Element>

    private let elements: [Element]

    struct GenericAsyncIterator<Element>: AsyncIteratorProtocol {
        private var elements: [Element]

        init(_ elements: [Element]) {
            self.elements = elements
        }

        mutating func next() async throws -> Element? {
            // Can't do popFirst() without further type constraining.
            if !self.elements.isEmpty {
                return self.elements.removeFirst()
            } else {
                return nil
            }
        }
    }

    init(_ elements: [Element]) {
        self.elements = elements
    }

    func makeAsyncIterator() -> AsyncIterator {
        GenericAsyncIterator(self.elements)
    }
}

extension Array {
    func asyncCompactMap<ElementOfResult>(_ transform: (Element) async throws -> ElementOfResult?) async rethrows -> [ElementOfResult] {
        var elements: [ElementOfResult] = []

        for try await element in GenericAsyncSequence(self) {
            if let result = try await transform(element) {
                elements.append(result)
            }
        }

        return elements
    }
}

func processImages(_ images: [UIImage], size: CGSize) async -> [UIImage] {
    await images.asyncCompactMap {
        await $0.byPreparingThumbnail(ofSize: size)
    }
}

func batchProcess<Element, ElementResult> (_ col: [Element], _ continuation: (Element) async -> ElementResult?) async -> [ElementResult] {
    await col.asyncCompactMap(continuation)
}

func prepareThumbnail(size: CGSize) async -> ((_ image: UIImage) async -> UIImage?) {
    { image in
        await image.byPreparingThumbnail(ofSize: size)
    }
}

let images = [
    #imageLiteral(resourceName: "1.jpg")
    , #imageLiteral(resourceName: "2.jpg")
    , #imageLiteral(resourceName: "3.jpg")
    , #imageLiteral(resourceName: "4.jpg")
    , #imageLiteral(resourceName: "5.jpg")
]

let task = async {
    let size = CGSize(width: 120, height: 120)
    let partialPrepareThumbnail = await prepareThumbnail(size: size)

    await batchProcess(images, partialPrepareThumbnail)
}

print("Waiting…")
