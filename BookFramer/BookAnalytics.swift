//
//  BookAnalytics.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-01-26.
//

import Foundation
import NaturalLanguage

struct BookAnalytics {
	enum Difficulty {
		case ok
		case hard
		case veryHard
	}
	
	/**
	 Calculate the Token Type Ratio for some text.
	 From: https://rishavr.github.io/Hand-Coding-Our-Very-Own-Type-Token-Ratio-Generator/
	 
	 - Parameter text: The string to analyze
	 - Returns: The Token Type Ratio (TTR)
	 */
	static func calculateTokenTypeRatio(text: String) -> Double {
		// Tokenize the text
		let tokenizer = NLTokenizer(unit: .word)
		let lcText = text.lowercased()
		tokenizer.string = lcText

		var uniqueTokens = Set<String>()
		var countTokens = 0.0
		tokenizer.enumerateTokens(in: lcText.startIndex..<lcText.endIndex) { tokenRange, _ in
			uniqueTokens.insert(String(lcText[tokenRange]))
			countTokens += 1
			//print(lcText[tokenRange])
			return true
		}
		
		let calculatedTTR = (Double(uniqueTokens.count) / countTokens) * 100.0
		return calculatedTTR
	}
	
	/**
	Calculate the Flesch Reading Ease Score for some text.
	From: https://www.geeksforgeeks.org/readability-index-pythonnlp/
	Implements Flesch Formula:
	Reading Ease score = 206.835 - (1.015 × ASL) - (84.6 × ASW)
	Here,
	 ASL = average sentence length (number of words
		 divided by number of sentences)
	 ASW = average word length in syllables (number of syllables
		 divided by number of words)

	 - Parameter text: the string to analyze
	 - Returns: the FRES score for text
	 */
	static func calculateFleschReadingEaseScore(text: String) -> Double {
		let sentences = tokens(in: text, unit: .sentence)
		if sentences.count == 0 { return 0.0 }
		var wordCount = 0
		var syllableCount = 0
		for sentence in sentences {
			let words = tokens(in: sentence, unit: .word)
			wordCount += words.count
			let syllableCounts = countSyllables(in: words)
			syllableCount += syllableCounts.reduce(0, +)
		}
		if wordCount == 0 { return 0.0 }
		
		let avgSentenceLength = Double(wordCount) / Double(sentences.count)
		let avgSyllablesPerWord = Double(syllableCount) / Double(wordCount)

		let calculatedFRES = 206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllablesPerWord)
		return calculatedFRES
	}
	
	/**
	 Classify the relative reading difficulty for a Flesch Reading Ease Score
	 - Parameter score: the FRES score to classify
	 - Returns: the relative reading difficulty
	 */
	static func classifyFRES(score: Double) -> Difficulty {
		var result = Difficulty.ok
		
		if score < 27.0 {
			result = .veryHard
		}
		else if score < 63.0 {
			result = .hard
		}
		return result
	}
	
	/**
	 Tokenizes the text.
	 
	 - Parameter text: The string to analyze
	 - Returns: array of strings. Each index contain one token.
	 */
	static func tokens(in text: String, unit: NLTokenUnit) -> [String] {
		let tokenizer = NLTokenizer(unit: unit)
		tokenizer.string = text
		
		var result = [String]()
		tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
			result.append(String(text[tokenRange]))
			//print(text[tokenRange])
			return true
		}
		
		return result
	}
	
	/**
	 Convenience function to count the syllables in multiple words.
	 - Parameter words: array of strings
	 - Returns: array of syllables, corresponding to the input words.
	 */
	static func countSyllables(in words: [String]) -> [Int] {
		var result = [Int](repeating: 0, count: words.count)
		for (i, word) in words.enumerated() {
			result[i] = countSyllables(in: word)
		}
		return result
	}
	
	private static let vowels = "aeiouy"
	
	/**
	 Uses the "written method" rules to count syllables. One syllable per cluster of vowels,
	 subtracting for words that end in "e" but not "le"
	 
	 - Parameter word: the word to count syllables of
	 - Returns: calculated number of syllables.
	 */
	static func countSyllables(in word: String) -> Int {
		let lower = word.lowercased()
		var sCount = 0
		let temp = lower.map({vowels.contains($0) ? $0 : "-"})
		let vowelClusters = temp.split(separator: "-", maxSplits: Int.max, omittingEmptySubsequences: true)
		sCount += vowelClusters.count
		if lower.hasSuffix("e") && lower.hasSuffix("le") == false {
			sCount -= 1
		}
		if sCount == 0 {
			sCount += 1
		}
		return sCount
	}
	
	/**
	 Uses NLTagger to identify all parts of speech in the given text.
	 
	 - Parameter text: the string to analyze
	 - Returns: a dictionary keyed on the string representation of a part of speech with string range values of corresponding words.
	 */
	static func tagPartsOfSpeech(in text: String) -> Dictionary<String, [Range<String.Index>]> {
		let tagger = NLTagger(tagSchemes: [.lexicalClass])
		tagger.string = text
		let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
		
		var result = Dictionary<String, [Range<String.Index>]>()
		tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
			if let tag = tag {
				//print("\(text[tokenRange]): \(tag.rawValue)")
				if result.keys.contains(tag.rawValue) == false {
					result[tag.rawValue] = [tokenRange]
				}
				else {
					result[tag.rawValue]!.append(tokenRange)
				}
			}
			return true
		}
		return result
	}
	
	/**
	 Convenience function to find adverbs in the given text.
	 - Parameter text: the string to analyze
	 - Returns: array of string range values of corresponding adverbs
	 */
	static func tagAdverbs(in text: String) -> [Range<String.Index>] {
		let allPOS = tagPartsOfSpeech(in: text)
		if allPOS.keys.contains(NLTag.adverb.rawValue) {
			return allPOS[NLTag.adverb.rawValue]!
		}
		return [Range<String.Index>]()
	}
	
	/**
	 Identifies the passive voice verb structure in the sentence, if it exists.
	 - Parameter sentence: the sentence to analyze for passive voice
	 - Returns: string range of the passive voice verb structure.
	 */
	static func tagPassiveVoice(in sentence: String) -> Range<String.Index>? {
		let tagger = NLTagger(tagSchemes: [NLTagScheme.lemma, .lexicalClass])
		tagger.string = sentence
		let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

		let lex = tagger.tags(in: sentence.startIndex..<sentence.endIndex, unit: .word,
							  scheme: .lexicalClass, options: options)
		let lem = tagger.tags(in: sentence.startIndex..<sentence.endIndex, unit: .word,
							  scheme: .lemma, options: options)
		
		// Find a "be" verb followed by 0..N adverbs and a verb
		for (i, lexEntry) in lex.enumerated() {
			if let lexTag = lexEntry.0,
			   lexTag == .verb {
				if let lemTag = lem[i].0,
				   lemTag.rawValue == "be" {
					// Word at i is a "be" verb
					// Check i+1,2,3... if there is a verb next, it's passive
					var offset = 1
					while true {
						if i + offset >= lex.count { break }
						if let nextLexTag = lex[i+offset].0 {
							if nextLexTag == .adverb {
								// ignore
								offset += 1
							}
							else if nextLexTag == .verb {
								let result = lexEntry.1.lowerBound..<lex[i+offset].1.upperBound
								return result
							}
							else {
								break // lex tag wasn't an adverb or verb
							}
						}
					}
				}
			}
		}
		return nil
	}
}
