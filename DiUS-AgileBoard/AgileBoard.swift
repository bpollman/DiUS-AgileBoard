//
//  AgileBoard.swift
//  DiUS-AgileBoard
//
//  Created by Ben Pollman on 6/26/18.
//  Copyright © 2018 Bernard Pollman. All rights reserved.
//

import CoreFoundation

enum BoardError: Error {
    case NoStartColumn
    case MultipleStartColumns
    case NoDoneColumn
    case MultipleDoneColumns
    case CardAlreadyAdded
    case CardNotFound
    case ColumnNotFound
    case NoLastMove
    case WIPLimitExceeded
}

class Card {
    var title: String
    var description: String
    var estimate: Int
    var column: Column?

    init(title t: String, description d: String, estimate e: Int) {
        title = t
        description = d
        estimate = e
    }
}

class Column {
    enum ColumnType {
        case starting
        case normal
        case done
    }

    var name: String
    let type: ColumnType
    var pointsLimit: Int? = nil

    init(name n: String, type t: ColumnType, pointsLimit pl: Int? = nil) {
        name = n
        type = t
        pointsLimit = pl
    }
}

class Iteration {
    let board: Board
    private(set) var cards: [Card] = []
    private(set) var lastMove: (Card, Column)?

    init(board b: Board) {
        board = b
    }

    func add(card: Card) throws {

        // Ensure we don't create duplicate entries
        guard !cards.contains(where: { $0 === card }) else {
            throw BoardError.CardAlreadyAdded
        }

        // Add card and place in start column by default
        cards.append(card)
        card.column = board.startColumn

        //NOTE: we dont do WIP max limits when adding a card. can be easily dont if desired
    }

    func remove(card: Card) throws {

        // Ensure card is in iteration
        guard let i = cards.index(where: { $0 === card }) else {
            throw BoardError.CardNotFound
        }

        // remove card
        cards.remove(at: i)
    }

    private func privateMove(card: Card, to column: Column) throws {
        // Ensure this card is in our iteration
        guard cards.contains(where: { $0 === card }) else {
            throw BoardError.CardNotFound
        }

        // Ensure this column is in our board
        guard board.columns.contains(where: { $0 === column }) else {
            throw BoardError.ColumnNotFound
        }

        // Update card to new column
        card.column = column
    }

    func move(card: Card, to column: Column) throws {

        if let limit = column.pointsLimit {
            let curPoints = try points(in: column)

            guard curPoints + card.estimate <= limit else {
                throw BoardError.WIPLimitExceeded
            }
        }
        try privateMove(card: card, to: column )

        // Store move transaction for undo
        lastMove = (card, column)
    }


    func undoLastMove() throws {

        // Ensure there is something to undo
        guard let lastMove = lastMove else {
            throw BoardError.NoLastMove
        }

        try privateMove(card: lastMove.0, to: lastMove.1 )
    }

    func cards(in column: Column) throws-> [Card] {

        // Ensure this column is in our board
        guard board.columns.contains(where: { $0 === column }) else {
            throw BoardError.ColumnNotFound
        }

        return cards.filter{ $0.column === column }
    }

    private func points(in column: Column) throws -> Int {

        // Ensure this column is in our board
        guard board.columns.contains(where: { $0 === column }) else {
            throw BoardError.ColumnNotFound
        }

        return cards.filter{ $0.column === column }.reduce(0, { $0 + $1.estimate })
    }

    func velocity() -> Int {

        // Find all cards from 'done' column then sum estimates together to get velocity
        return cards.filter{ $0.column?.type == .done }.reduce(0, { $0 + $1.estimate })
    }
}


// Agile Board
class Board {
    let columns: [Column]
    private(set) var startColumn: Column
    private(set) var doneColumn: Column

    // Lazy init iteration to avoid issues with use of self
    lazy var iteration: Iteration = Iteration(board: self)

    init(columns c: [Column]) throws {

        // Validate there is one start column
        let startColumns = c.filter{ $0.type == .starting }
        guard startColumns.count != 0 else { throw BoardError.NoStartColumn }
        guard startColumns.count < 2 else { throw BoardError.MultipleStartColumns }

        startColumn = startColumns[0]

        // Validate there is one done column
        let doneColumns = c.filter{ $0.type == .done }
        guard doneColumns.count != 0 else { throw BoardError.NoDoneColumn }
        guard doneColumns.count < 2 else { throw BoardError.MultipleDoneColumns }

        doneColumn = doneColumns[0]

        columns = c
    }
}
