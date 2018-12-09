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

protocol MovieSearchAPIDelegate: class {
  func didFinishFetchingMovies(_ movieSearchAPI: MovieSearchAPI, _ movies: [Movie])
  func didRecieveErrorFetchingMovies(_ movieSearchAPI: MovieSearchAPI, _ movieApiError: MovieAPIError)
}

// marking final since no one else needs to subclass
final class MovieSearchAPI {
  // create a delegate property to be used to set delegate methods as apporopriate
  // conforming types will set themselves as the delegate when using the MovieSearchAPIDelegate
  weak var delegate: MovieSearchAPIDelegate?
  
  // search for a movie by keyword
  func search(keyword: String) {
    // this the iTunes Movie Search endpoint
    let urlString = "https://itunes.apple.com/search?media=movie&term=\(keyword)&limit=100"
    guard let url = URL(string: urlString) else {
      return
    }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
      if let error = error {
        self.delegate?.didRecieveErrorFetchingMovies(self, MovieAPIError.networkError(error))
      } else if let data = data {
        do {
          let resultData = try JSONDecoder().decode(SearchData.self, from: data)
          self.delegate?.didFinishFetchingMovies(self, resultData.results)
        } catch {
          self.delegate?.didRecieveErrorFetchingMovies(self, MovieAPIError.decodingError(error))
        }
      }
    }.resume() // resumes the task if it's suspended
  }
}

