//
//  PersonaTest.swift
//  SwiftBookBuilderTests
//
//  Created by Simon Biickert on 2021-08-08.
//

import XCTest
@testable import BookFramer

class PersonaTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFind() throws {
		let book = try Book(fromBFD: BookTest.SIMPLE_BOOK)
		var p = book.findPersona(named: "Bob")
		XCTAssert(p != nil, "Did not find 'Bob'")
		XCTAssert(p?.name == "Mr. Bennet")
		p = book.findPersona(named: "Annesley")
		XCTAssert(p != nil, "Did not find 'Annesley'")
		p = book.findPersona(named: "Mr. Bennet")
		XCTAssert(p != nil, "Did not find 'Mr. Bennet'")
    }

}
