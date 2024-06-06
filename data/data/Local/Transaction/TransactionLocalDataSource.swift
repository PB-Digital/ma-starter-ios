//
//  TransactionLocalDataSource.swift
//  data
//
//  Created by Karim Karimov on 23.02.22.
//

import Foundation
import RealmSwift
import Realm
import RealmFFI
import Combine

class TransactionLocalDataSource: TransactionLocalDataSourceProtocol {
    
    private let realmClient: RealmClientProtocol

    private var transactionSubjectMap: Dictionary<String, CurrentValueSubject<[TransactionLocalDTO], Never>> = [:]

    init(realmClient: RealmClientProtocol) {
        self.realmClient = realmClient
    }
    
    private func getTransactionHistory(cardId: String) -> [TransactionLocalDTO] {
        self.realmClient.read { transaction in
            transaction.cardId == cardId
        }
        .freeze()
        .sorted(by: { $0.datetime > $1.datetime })
    }
    
    func observeTransactions(cardId: String) -> AnyPublisher<[TransactionLocalDTO], Never> {
        if let observable = self.transactionSubjectMap[cardId]?.eraseToAnyPublisher() {
            return observable
        }
        let subject: CurrentValueSubject<[TransactionLocalDTO], Never> = .init([])
        Task { @MainActor [cardId] in
            subject.send(self.getTransactionHistory(cardId: cardId))
        }
        self.transactionSubjectMap[cardId] = subject
        return subject.eraseToAnyPublisher()
    }
    
    func save(cardId: String, transactions: [TransactionLocalDTO]) throws {
        try self.realmClient.replace(objects: transactions) { transaction in
            transaction.cardId == cardId
        }

        Set(transactions.map { $0.cardId }).forEach { id in
            self.syncTransactionHistory(cardId: id)
        }
    }
    
    private func syncTransactionHistory(cardId: String) {
        guard let subject = self.transactionSubjectMap[cardId] else { return }
        subject.send(self.getTransactionHistory(cardId: cardId))
    }
}
