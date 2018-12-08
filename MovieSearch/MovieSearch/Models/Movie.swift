//
//  Movie.swift
//  MovieSearch
//
//  Created by Alex Paul on 12/7/18.
//  Copyright © 2018 Alex Paul. All rights reserved.
//

import Foundation

struct SearchData: Codable {
  let resultCount: Int
  let results: [Movie]
}
struct Movie: Codable {
  let collectionId: Int?
  let trackId: Int
  let artistName: String
  let trackName: String
  let artworkUrl100: URL
  let longDescription: String?
}
// using ? optionals since some movies don't have values for the relavant properties



