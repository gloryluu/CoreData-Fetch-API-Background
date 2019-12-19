//
//  ApiRepository.swift
//  CoreData-Fetch-API-Background
//
//  Created by Quang V. Luu on 12/19/19.
//  Copyright © 2019 Officience SARL. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case networkUnavailable
    case wrongDataFormat
    case generic(String)
}

class ApiRepository {
    
    private init() {}
    static let shared = ApiRepository()
    
    private let urlSession = URLSession.shared
    private let baseURL = URL(string: "https://swapi.co/api/")!
    
    func getFilms(completion: @escaping(Result<[[String: Any]], NetworkError>) -> Void) {
        let filmURL = baseURL.appendingPathComponent("films")
        urlSession.dataTask(with: filmURL) { (data, response, error) in
            if let error = error {
                completion(.failure(.generic(error.localizedDescription)))
                return
            }

            guard let data = data else {
                completion(.failure(.networkUnavailable))
                return
            }

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                guard let jsonDictionary = jsonObject as? [String: Any], let result = jsonDictionary["results"] as? [[String: Any]] else {
                    completion(.failure(.wrongDataFormat))
                    return
                }
                completion(.success(result))
            } catch {
                completion(.failure(.generic(error.localizedDescription)))
            }
        }.resume()
    }
}
