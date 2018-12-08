//
//  MovieSearchAPI.swift
//  MovieSearch
//
//  Created by Alex Paul on 12/7/18.
//  Copyright © 2018 Alex Paul. All rights reserved.
//

import Foundation

enum MovieAPIError: Error {
  case badURL(String)
  case networkError(Error)
  case decodingError(Error) // associative types
}

// marking final since no one else needs to subclass
final class MovieSearchAPI {
  
  // search for a movie by keyword
  static func search(keyword: String, completion: @escaping(MovieAPIError?, [Movie]?) -> Void) {
    // this the iTunes Movie Search endpoint
    let urlString = "https://itunes.apple.com/search?media=movie&term=\(keyword)&limit=100"
    guard let url = URL(string: urlString) else {
      completion(MovieAPIError.badURL("malformatted url"), nil)
      return
    }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
      if let error = error {
        completion(MovieAPIError.networkError(error), nil)
      } else if let data = data {
        do {
          let resultData = try JSONDecoder().decode(SearchData.self, from: data)
          completion(nil, resultData.results)
        } catch {
          completion(MovieAPIError.decodingError(error), nil)
        }
      }
    }.resume() // resumes the task if it's suspended
  }
  
}

