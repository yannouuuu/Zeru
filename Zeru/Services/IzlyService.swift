//
//  IzlyService.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import Foundation

actor IzlyService {
    private let SERVICE_VERSION = "7.0"
    private let CLIENT_TYPE     = "PART"
    private let SOAP_URL        = "https://soap.izly.fr/Service.asmx"
    private let SOAP_USER_AGENT = "ksoap2-android/2.6.0+"
    private let REST_BASE       = "https://rest.izly.fr/Service/PublicService.svc/rest/"

    // MARK: - Étape 1 : Login
    func login(identifier: String, password: String) async throws -> LoginResult {
        let soapBody = """
        <?xml version="1.0" encoding="utf-8"?>
        <v:Envelope xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
                    xmlns:d="http://www.w3.org/2001/XMLSchema"
                    xmlns:c="http://schemas.xmlsoap.org/soap/encoding/"
                    xmlns:v="http://schemas.xmlsoap.org/soap/envelope/">
          <v:Body>
            <Logon xmlns="Service" id="o0" c:root="1">
              <version i:type="d:string">\(SERVICE_VERSION)</version>
              <channel i:type="d:string">AIZ</channel>
              <format i:type="d:string">T</format>
              <model i:type="d:string">A</model>
              <language i:type="d:string">fr</language>
              <user i:type="d:string">\(identifier)</user>
              <password i:type="d:string">\(password)</password>
              <smoneyClientType i:type="d:string">\(CLIENT_TYPE)</smoneyClientType>
              <rooted i:type="d:string">0</rooted>
            </Logon>
          </v:Body>
        </v:Envelope>
        """

        var request = URLRequest(url: URL(string: SOAP_URL)!)
        request.httpMethod = "POST"
        request.setValue("text/xml;charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Service/Logon",           forHTTPHeaderField: "SOAPAction")
        request.setValue(SERVICE_VERSION,           forHTTPHeaderField: "clientVersion")
        request.setValue(CLIENT_TYPE,               forHTTPHeaderField: "smoneyClientType")
        request.setValue(SOAP_USER_AGENT,           forHTTPHeaderField: "User-Agent")
        request.httpBody = soapBody.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IzlyError.networkError("HTTP error lors du login")
        }

        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw IzlyError.parseError
        }

        guard let rawResult = extractBetween(xmlString, start: "<LogonResult>", end: "</LogonResult>") else {
            if let msg = extractBetween(xmlString, start: "<Msg>", end: "</Msg>") {
                throw IzlyError.networkError(msg)
            }
            throw IzlyError.parseError
        }

        let result = rawResult
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")

        let parsed = await IzlyXMLParser.parse(data: Data(result.utf8))

        guard let salt = parsed["SALT"],
              let uid  = parsed["UID"] else {
            throw IzlyError.parseError
        }

        return LoginResult(salt: salt, uid: uid)
    }

    // MARK: - Étape 2 : Tokenize
    func tokenize(activationURL: String) async throws -> TokenizeResult {
        let parts = activationURL.split(separator: "/")
        guard parts.count >= 2 else {
            throw IzlyError.networkError("URL d'activation invalide")
        }
        let code       = String(parts[parts.count - 1])
        let identifier = String(parts[parts.count - 2])

        let soapBody = """
        <?xml version="1.0" encoding="utf-8"?>
        <v:Envelope xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
                    xmlns:d="http://www.w3.org/2001/XMLSchema"
                    xmlns:c="http://schemas.xmlsoap.org/soap/encoding/"
                    xmlns:v="http://schemas.xmlsoap.org/soap/envelope/">
          <v:Body>
            <Logon xmlns="Service" id="o0" c:root="1">
              <version i:type="d:string">\(SERVICE_VERSION)</version>
              <channel i:type="d:string">AIZ</channel>
              <format i:type="d:string">T</format>
              <model i:type="d:string">A</model>
              <language i:type="d:string">fr</language>
              <user i:type="d:string">\(identifier)</user>
              <password i:null="true" />
              <smoneyClientType i:type="d:string">\(CLIENT_TYPE)</smoneyClientType>
              <rooted i:type="d:string">0</rooted>
              <actCode i:type="d:string">\(code)</actCode>
            </Logon>
          </v:Body>
        </v:Envelope>
        """

        var request = URLRequest(url: URL(string: SOAP_URL)!)
        request.httpMethod = "POST"
        request.setValue("text/xml;charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Service/Logon",           forHTTPHeaderField: "SOAPAction")
        request.setValue(SERVICE_VERSION,           forHTTPHeaderField: "clientVersion")
        request.setValue(CLIENT_TYPE,               forHTTPHeaderField: "smoneyClientType")
        request.setValue(SOAP_USER_AGENT,           forHTTPHeaderField: "User-Agent")
        request.httpBody = soapBody.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw IzlyError.parseError
        }

        guard let rawResult = extractBetween(xmlString, start: "<LogonResult>", end: "</LogonResult>") else {
            if let msg = extractBetween(xmlString, start: "<Msg>", end: "</Msg>") {
                throw IzlyError.networkError(msg)
            }
            throw IzlyError.parseError
        }

        let result = rawResult
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")

        let parsed = await IzlyXMLParser.parse(data: Data(result.utf8))

        guard let accessToken  = parsed["ACCESS_TOKEN"],
              let refreshToken = parsed["REFRESH_TOKEN"],
              let sessionID    = parsed["SID"],
              let userID       = parsed["USER_ID"],
              let firstName    = parsed["FNAME"],
              let lastName     = parsed["LNAME"],
              let email        = parsed["EMAIL"] else {
            throw IzlyError.parseError
        }

        let balanceStr = parsed["UP"] ?? parsed["BALANCE"] ?? "0"
        let balance    = Double(balanceStr) ?? 0.0
        let seed       = parsed["SEED"] ?? ""
        let alias      = parsed["ALIAS"] ?? parsed["UID"] ?? ""

        let identification = IzlyIdentification(
            accessToken:  accessToken,
            refreshToken: refreshToken,
            sessionID:    sessionID,
            userID:       userID,
            identifier:   alias,
            seed:         seed,
            counter:      0
        )

        let profile = IzlyProfile(
            firstName:  firstName,
            lastName:   lastName,
            email:      email,
            identifier: alias
        )

        return TokenizeResult(
            identification: identification,
            profile:        profile,
            balance:        balance
        )
    }

    // MARK: - Extraire URL izly://
    func extractActivationURL(from httpsURL: String) async throws -> String {
        guard let url = URL(string: httpsURL) else {
            throw IzlyError.networkError("URL invalide")
        }

        let config  = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: RedirectHandler(), delegateQueue: nil)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              let location = httpResponse.value(forHTTPHeaderField: "Location") else {
            throw IzlyError.networkError("Lien d'activation expiré")
        }

        return location
    }

    // MARK: - Solde réel
    func fetchBalance(identification: IzlyIdentification) async throws -> Double {
        let url = URL(string: "\(REST_BASE)IsSessionValid")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",                     forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(identification.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("AIZ",                                  forHTTPHeaderField: "channel")
        request.setValue(SERVICE_VERSION,                        forHTTPHeaderField: "clientVersion")
        request.setValue("T",                                    forHTTPHeaderField: "format")
        request.setValue("fr",                                   forHTTPHeaderField: "language")
        request.setValue("A",                                    forHTTPHeaderField: "model")
        request.setValue(identification.sessionID,               forHTTPHeaderField: "sessionId")
        request.setValue(CLIENT_TYPE,                            forHTTPHeaderField: "smoneyClientType")
        request.setValue(identification.identifier,              forHTTPHeaderField: "userId")
        request.setValue("1.0",                                  forHTTPHeaderField: "version")
        request.setValue(SOAP_USER_AGENT,                        forHTTPHeaderField: "User-Agent")

        let body = ["sessionId": identification.sessionID]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["IsSessionValidResult"] as? [String: Any],
              let up = result["UP"] as? [String: Any] else {
            throw IzlyError.parseError
        }

        let balStr = up["BAL"] as? String ?? "\(up["BAL"] ?? 0)"
        return Double(balStr) ?? 0.0
    }

    // MARK: - Transactions réelles
    func fetchOperations(identification: IzlyIdentification, group: Int, limit: Int = 30) async throws -> [IzlyTransaction] {
        let urlStr = "\(REST_BASE)GetHomePageOperations?transactionGroup=\(group)&top=\(limit)"
        let url    = URL(string: urlStr)!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(identification.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("AIZ",                                  forHTTPHeaderField: "channel")
        request.setValue(SERVICE_VERSION,                        forHTTPHeaderField: "clientVersion")
        request.setValue("T",                                    forHTTPHeaderField: "format")
        request.setValue("fr",                                   forHTTPHeaderField: "language")
        request.setValue("A",                                    forHTTPHeaderField: "model")
        request.setValue(identification.sessionID,               forHTTPHeaderField: "sessionId")
        request.setValue(CLIENT_TYPE,                            forHTTPHeaderField: "smoneyClientType")
        request.setValue(identification.identifier,              forHTTPHeaderField: "userId")
        request.setValue("2.0",                                  forHTTPHeaderField: "version")
        request.setValue(SOAP_USER_AGENT,                        forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["GetHomePageOperationsResult"] as? [String: Any],
              let ops = result["Result"] as? [[String: Any]] else {
            throw IzlyError.parseError
        }

        return ops.compactMap { op -> IzlyTransaction? in
            guard let id       = op["Id"] as? Int,
                  let amount   = op["Amount"] as? Double,
                  let isCredit = op["IsCredit"] as? Bool else { return nil }

            let rawDate      = op["Date"] as? String ?? ""
            let timestamp    = extractTimestamp(rawDate)
            let date         = formatDate(rawDate)
            let rawLabel = op["Message"] as? String ?? ""
            var label    = rawLabel.isEmpty ? labelForGroup(group) : rawLabel
            let signedAmount = isCredit ? amount : -amount
            
            // Dans le filtre Paiements (group 0), "Virement" → "Paiement"
            if group == 0 && label == "Virement" {
                label = "Paiement"
            }

            return IzlyTransaction(
                id:     "\(id)",
                date:   date,
                label:  label,
                amount: signedAmount,
                group: group,
                timestamp: timestamp
            )
        }
    }

    // MARK: - Refresh session
    func refresh(identification: inout IzlyIdentification, password: String) async throws {
        guard let otpCode = OTPService.generate(seed: identification.seed, counter: identification.counter) else {
            throw IzlyError.parseError
        }
        let passOTP = password + otpCode
        identification.counter += 1

        let url = URL(string: "\(REST_BASE)LogonLight")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded",    forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(identification.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("AIZ",                                  forHTTPHeaderField: "channel")
        request.setValue(SERVICE_VERSION,                        forHTTPHeaderField: "clientVersion")
        request.setValue("T",                                    forHTTPHeaderField: "format")
        request.setValue("fr",                                   forHTTPHeaderField: "language")
        request.setValue("A",                                    forHTTPHeaderField: "model")
        request.setValue(passOTP,                                forHTTPHeaderField: "passOTP")
        request.setValue(password,                               forHTTPHeaderField: "password")
        request.setValue(CLIENT_TYPE,                            forHTTPHeaderField: "smoneyClientType")
        request.setValue(identification.identifier,              forHTTPHeaderField: "userId")
        request.setValue("2.0",                                  forHTTPHeaderField: "version")
        request.setValue(SOAP_USER_AGENT,                        forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw IzlyError.parseError
        }

        if let code = json["Code"] as? Int {
            if code == 140 || code == 570 || code == 571 {
                throw IzlyError.invalidCredentials
            }
            throw IzlyError.networkError(json["ErrorMessage"] as? String ?? "Erreur inconnue")
        }

        guard let result = (json["LogonLightResult"] as? [String: Any])?["Result"] as? [String: Any] else {
            throw IzlyError.parseError
        }

        identification.sessionID = result["SessionId"] as? String ?? identification.sessionID

        if let tokens = result["Tokens"] as? [String: Any] {
            identification = IzlyIdentification(
                accessToken:  tokens["AccessToken"] as? String ?? identification.accessToken,
                refreshToken: tokens["RefreshToken"] as? String ?? identification.refreshToken,
                sessionID:    identification.sessionID,
                userID:       identification.userID,
                identifier:   identification.identifier,
                seed:         identification.seed,
                counter:      identification.counter
            )
        }
    }

    // MARK: - Helpers
    private func extractBetween(_ string: String, start: String, end: String) -> String? {
        guard let startRange = string.range(of: start),
              let endRange   = string.range(of: end) else { return nil }
        let from = startRange.upperBound
        let to   = endRange.lowerBound
        guard from < to else { return nil }
        return String(string[from..<to])
    }

    private func formatDate(_ raw: String) -> String {
        // Format Izly : "/Date(timestamp+offset)/"
        if raw.hasPrefix("/Date(") {
            let inner = raw
                .replacingOccurrences(of: "/Date(", with: "")
                .replacingOccurrences(of: ")/", with: "")
            var timestampStr = inner
            if let plusRange = inner.range(of: "+") {
                timestampStr = String(inner[inner.startIndex..<plusRange.lowerBound])
            } else if let minusRange = inner.range(of: "-") {
                timestampStr = String(inner[inner.startIndex..<minusRange.lowerBound])
            }
            if let ms = Double(timestampStr) {
                let date      = Date(timeIntervalSince1970: ms / 1000)
                let formatter = DateFormatter()
                formatter.locale     = Locale(identifier: "fr_FR")
                formatter.dateFormat = "dd/MM/yyyy HH:mm"
                formatter.timeZone   = TimeZone.current
                return formatter.string(from: date)
            }
        }
        let parts = raw.split(separator: " ")
        guard let datePart = parts.first else { return raw }
        return datePart.replacingOccurrences(of: "-", with: "/")
    }

    private func labelForGroup(_ group: Int) -> String {
        switch group {
        case 0: return "Virement"
        case 1: return "Rechargement"
        case 2: return "Paiement"
        default: return "Transaction"
        }
    }
    
    private func extractTimestamp(_ raw: String) -> Double {
        guard raw.hasPrefix("/Date(") else { return 0 }
        let inner = raw
            .replacingOccurrences(of: "/Date(", with: "")
            .replacingOccurrences(of: ")/", with: "")
        var timestampStr = inner
        if let plusRange = inner.range(of: "+") {
            timestampStr = String(inner[inner.startIndex..<plusRange.lowerBound])
        } else if let minusRange = inner.range(of: "-") {
            timestampStr = String(inner[inner.startIndex..<minusRange.lowerBound])
        }
        return Double(timestampStr) ?? 0
    }
}

// ── Gestionnaire de redirections ───────────────────────
class RedirectHandler: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
