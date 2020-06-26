struct LazySplitKeepingCollection<Base: Collection> {
    enum Index: Comparable {
        case index(Base.Index)
        case ended

        var index: Base.Index? {
            switch self {
            case let .index(index):
                return index
            case .ended:
                return nil
            }
        }

        static func < (lhs: Index, rhs: Index) -> Bool {
            switch (lhs, rhs) {
            case let (.index(left), .index(right)):
                return left < right
            case (.index, .ended):
                return true
            default:
                return false
            }
        }
    }

    let base: Base
    let isSeparator: (Base.Element) -> Bool
}

extension LazySplitKeepingCollection: Collection {
    var startIndex: Index { .index(base.startIndex) }
    var endIndex: Index { .ended }

    subscript(position: Index) -> Base.SubSequence {
        guard let index = position.index,
            index != base.endIndex
            else { return base[base.endIndex ..< base.endIndex] }

        let separator = base[index...].firstIndex(where: isSeparator)
        return base[index ..< (separator ?? base.endIndex)]
    }

    func index(after i: Index) -> Index {
        guard let index = i.index,
            index != base.endIndex,
            let separator = base[index...].firstIndex(where: isSeparator)
        else { return endIndex }

        return .index(base.index(after: separator))
    }
}

extension LazySplitKeepingCollection: BidirectionalCollection where Base: BidirectionalCollection {
    func index(before i: Index) -> Index {
        guard let index = i.index else { return endIndex }
        let reversed = base[..<base.index(before: index)].reversed()
        let separator = reversed.firstIndex(where: isSeparator)
        return .index(separator?.base ?? base.startIndex)
    }
}

extension LazySplitKeepingCollection: LazyCollectionProtocol {}

extension LazyCollectionProtocol {
    func splitKeepingEmptySubsequences(
        isSeparator: @escaping (Elements.Element) -> Bool
    ) -> LazySplitKeepingCollection<Elements> {
        LazySplitKeepingCollection(
            base: elements,
            isSeparator: isSeparator
        )
    }
}

extension LazyCollectionProtocol where Elements.Element: Equatable {
    func splitKeepingEmptySubsequences(
        separator: Elements.Element
    ) -> LazySplitKeepingCollection<Elements> {
        LazySplitKeepingCollection(
            base: elements,
            isSeparator:  { $0 == separator }
        )
    }
}

