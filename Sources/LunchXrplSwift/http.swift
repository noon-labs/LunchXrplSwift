//
//  http.swift
//  LunchXrplSwift
//
//  Created by 한상범 on 12/27/24.
//

import Foundation

enum APIError : Error {
    case invalidURL
    case noData
    case httpResponseIsNil
    case unknownError
}

enum HttpMethod: String {
    case put = "PUT"
    case post = "POST"
    case get = "GET"
    case delete = "DELETE"
}

typealias APIParams = [String: Any?]

let TimeoutInterval = TimeInterval(3)

func request<T: Decodable>(httpMethod : HttpMethod, url: URL, params: APIParams? = nil) async throws -> T? {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)

    guard let finalURL = components?.url else {
        throw APIError.invalidURL
    }
    
    var request = URLRequest(url: finalURL)
    request.httpMethod = httpMethod.rawValue
    request.timeoutInterval = TimeoutInterval
    
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if params != nil && ![.get, .delete].contains(httpMethod) {
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params as Any)
        } catch {
            print("Error creating JSON data: \(error)")
        }
    }
    
    let urlsession = URLSession.shared
    let (data, urlResponse) = try await urlsession.data(for: request)
    guard let httpResponse = urlResponse as? HTTPURLResponse else {
        throw APIError.httpResponseIsNil
    }
    
    switch httpResponse.statusCode {
    case 200:
        do {
            let data = try JSONDecoder().decode(T.self, from: data)
            return data
        }catch{
            print(error)
            throw error
        }
        
    case 201..<400:
        return nil
    case 400...:
        return nil
    default:
        print("[DEBUG]\n fileID : \(#file)\n line: \(#line)\n function: \(#function) \n message: data is \(data) \n---------")
        throw APIError.unknownError
    }

}
