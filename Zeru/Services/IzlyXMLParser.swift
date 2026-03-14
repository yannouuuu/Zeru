//
//  IzlyXMLParser.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import Foundation

class IzlyXMLParser: NSObject, XMLParserDelegate {

    private var results: [String: String] = [:]
    private var currentKey: String?
    private var currentValue: String = ""

    private override init() {
        super.init()
    }

    static func parse(data: Data) async -> [String: String] {
        let instance = IzlyXMLParser()
        let parser = XMLParser(data: data)
        parser.delegate = instance
        parser.parse()
        return instance.results
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentKey = elementName
        currentValue = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        if let key = currentKey {
            results[key] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        currentKey = nil
    }
}
