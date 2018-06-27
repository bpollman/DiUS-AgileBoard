//
//  main.swift
//  DiUS-AgileBoard
//
//  Created by Ben Pollman on 6/26/18.
//  Copyright © 2018 Bernard Pollman. All rights reserved.
//

/*
 DiUS are keen on this "Agile" thing. We want to develop a tracking system for Agile cards.

 Your application should cater for the following:

 - Be able to create cards. Cards have a title, description and estimate in points
 - Cards belong to an iteration
 - Assume a board has only one iteration at the moment
 - An iteration can have multiple columns. (It should have at least two, one starting and one done)
 - There is a column designated as the starting column. And one designated as the done column.
 - Columns have a name
 - You can undo your last card column transition. So if you moved it to the done column, you can undo that move by calling a method
 - You can calculate the velocity of a given iteration. This is defined as the sum of the points of all cards that are in the done column for an iteration.
 - You can get all the cards in a particular column
 - You can enforce a work in progress limit (expressed in points) for a column. If you try and add a card to a column that goes above the WIP limit, an exception should be thrown
 - Your interface should look something like the following:

 board = new Board(columns);
 iteration.add(card);
 iteration.velocity();
 iteration.moveCard(card, toColumn);
 iteration.undoLastMove();

 Notes on implementation:

 use Java, Javascript, Groovy, Scala, Ruby or Swift
 try not to spend more than 2 hours maximum. (We don't want you to lose a weekend over this!)
 don't build guis etc, we're more interested in your approach to solving the given task, not how shiny it looks.
 don't use any frameworks (rails, spring etc), or any external jars/gems (unless it's for testing..)
 When you've finished, zip up the solution and send it to bmorrison@dius.com.au. Happy coding :)

 */

import Foundation

//
// Test use case from the Challenge
//
func defaultTest() throws {

    do {
        let columns = [ Column(name: "starting", type: .starting),
                        Column(name: "done", type: .done) ]

        let board = try Board(columns: columns)
        let iteration = board.iteration

        var v = iteration.velocity()
        assert(v == 0, "velocity == 0, velocity = \(v)")

        let card = Card(title: "card title", description: "this is a card", estimate: 5)
        try iteration.add(card: card)

        v = iteration.velocity()
        assert(v == 0, "velocity == 0, velocity = \(v)")

        try iteration.move(card: card, to: columns[1])

        v = iteration.velocity()
        assert(v == 5, "velocity == 5, velocity = \(v)")

        assert( card.column === columns[1],
                "card.column == columns[1], card.column = \(String(describing: card.column))")

        try iteration.undoLastMove()
    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }
}

//
// Test error checking for column validation during board creation
//
func columnTests() throws {

    do {
        let c = [ Column(name: "c", type: .normal), Column(name: "c2", type: .done) ]
         _ = try Board(columns: c)
        assertionFailure("board init should fail with invalid columns")
    }
    catch BoardError.NoStartColumn {
    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }

    do {
        let c = [ Column(name: "c", type: .starting), Column(name: "c2", type: .starting) ]
        _ = try Board(columns: c)
        assertionFailure("board init should fail with invalid columns")
    }
    catch BoardError.MultipleStartColumns {
    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }

    do {
        let c = [ Column(name: "c", type: .normal), Column(name: "c2", type: .starting) ]
        _ = try Board(columns: c)
        assertionFailure("board init should fail with invalid columns")
    }
    catch BoardError.NoDoneColumn {
    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }

    do {
        let c = [ Column(name: "c", type: .starting), Column(name: "c2", type: .done), Column(name: "c3", type: .done) ]
        _ = try Board(columns: c)
        assertionFailure("board init should fail with invalid columns")
    }
    catch BoardError.MultipleDoneColumns {
    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }

}

//
// Test error handling for adding and moving cards
//
func cardTests() throws {

    do {
        let columns = [ Column(name: "starting", type: .starting),
                        Column(name: "done", type: .done) ]

        let board = try Board(columns: columns)
        let iteration = board.iteration

        var v = iteration.velocity()
        assert(v == 0, "velocity == 0, velocity = \(v)")

        let card = Card(title: "card title", description: "this is a card", estimate: 5)

        do {
            _ = try iteration.move(card: card, to: columns[1])
            assertionFailure("cant move a card not in iteration")
        }
        catch BoardError.CardNotFound {
        }
        catch {
            assertionFailure("unexpected error: \(error)")
        }

        try iteration.add(card: card)

        do {
            _ = try iteration.add(card: card)
            assertionFailure("card already exists")
        }
        catch BoardError.CardAlreadyAdded {
        }
        catch {
            assertionFailure("unexpected error: \(error)")
        }

        do {
            _ = try iteration.move(card: card, to: Column(name: "missing", type: .normal))
            assertionFailure("cant move to a column not in iteration")
        }
        catch BoardError.ColumnNotFound {
        }
        catch {
            assertionFailure("unexpected error: \(error)")
        }


        try iteration.move(card: card, to: columns[1])

        let card2 = Card(title: "card title", description: "this is a card", estimate: 42)
        try iteration.add(card: card2)
        try iteration.move(card: card2, to: columns[1])

        v = iteration.velocity()
        assert(v == 47, "velocity == 47, velocity = \(v)")

        var cards = try iteration.cards(in: columns[0])
        assert(cards.count == 0, "cards.count == 0, cards.count = \(cards.count)")

        cards = try iteration.cards(in: columns[1])
        assert(cards.count == 2, "cards.count == 2, cards.count = \(cards.count)")


    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }
}

//
// Test error handling for undo'ing card moves
//
func undoMoveTests() throws {

    do {
        let columns = [ Column(name: "starting", type: .starting),
                        Column(name: "done", type: .done) ]

        let board = try Board(columns: columns)
        let iteration = board.iteration

        let card = Card(title: "card title", description: "this is a card", estimate: 5)
        try iteration.add(card: card)

        do {
            try iteration.undoLastMove()
            assertionFailure("no move to undo")
        }
        catch BoardError.NoLastMove {
        }
        catch {
            assertionFailure("unexpected error: \(error)")
        }

        try iteration.move(card: card, to: columns[1])

        try  iteration.undoLastMove()
    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }
}

//
// Test error handling for WIP points limits
//
func wipLimitTests() throws {

    do {
        let columns = [ Column(name: "starting", type: .starting, pointsLimit: 10),
                        Column(name: "done", type: .done) ]

        let board = try Board(columns: columns)
        let iteration = board.iteration

        let card = Card(title: "card title", description: "this is a card", estimate: 5)
        try iteration.add(card: card)

        let card2 = Card(title: "card title", description: "this is a card", estimate: 5)
        try iteration.add(card: card2)

        let card3 = Card(title: "card title", description: "this is a card", estimate: 5)
        try iteration.add(card: card3)

    }
    catch {
        assertionFailure("unexpected error: \(error)")
    }
}

//
// Program entry point
//
print("DiUS Agile Board Tests")
do {
    try defaultTest()
    try columnTests()
    try cardTests()
    try undoMoveTests()
    try wipLimitTests()
    print("All Tests Passed")
} catch {
    print("Error: \(error)")
}
