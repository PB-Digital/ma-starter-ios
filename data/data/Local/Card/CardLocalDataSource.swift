//
//  CardLocalDataSource.swift
//  data
//
//  Created by Karim Karimov on 23.02.22.
//

import Foundation
import RealmSwift
import Combine

class CardLocalDataSource: CardLocalDataSourceProtocol {
    
    private let realmClient: RealmClientProtocol

    private let cardsSubject: CurrentValueSubject<[CardLocalDTO], Never> = .init([])
    
    init(realmClient: RealmClientProtocol) {
        self.realmClient = realmClient
        self.syncCards()
    }
    
    private func syncCards() {
        self.cardsSubject.send(self.realmClient.read().freeze())
    }
    
    func observeCards() -> AnyPublisher<[CardLocalDTO], Never> {
        return self.cardsSubject.eraseToAnyPublisher()
    }
    
    func save(cards: [CardLocalDTO]) throws {
        try self.realmClient.replace(objects: cards)
        self.syncCards()
    }
}
