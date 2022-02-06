//
//  BFStateProvider.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-02-01.
//

import Foundation

protocol BFContextProvider {
	var book: Book? { get }
	var selectedPart: Any? { get }
	var selectedChapter: Chapter? { get }
	var selectedSubChapter: SubChapter? { get }
}
