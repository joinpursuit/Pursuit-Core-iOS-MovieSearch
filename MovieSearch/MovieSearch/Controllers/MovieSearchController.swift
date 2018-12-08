//
//  ViewController.swift
//  MovieSearch
//
//  Created by Alex Paul on 12/7/18.
//  Copyright © 2018 Alex Paul. All rights reserved.
//

import UIKit

class MovieSearchController: UIViewController {
  
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var tableView: UITableView!
  
  private var movies = [Movie]() {
    didSet { // property observer
      // dispatch back to the main thread
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.dataSource = self
    searchBar.delegate = self
    searchMovies(keyword: "holiday") // default movie search
  }
  
  // present a dialog to the user
  private func showAlert(title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    // create an ok action to dismiss the alertController
    let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
    
    // add okAction to alertController
    alertController.addAction(okAction)
    
    // present the alertController
    present(alertController, animated: true, completion: nil)
  }
  
  private func searchMovies(keyword: String) {
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }
    MovieSearchAPI.search(keyword: encodedKeyword) { (error, movies) in
      if let error = error {
        // we're on the background thread so need to dispatch back to the main thread
        DispatchQueue.main.async {
          self.showAlert(title: "Error", message: "\(error.localizedDescription)")
        }
      } else if let movies = movies {
        self.movies = movies
      }
    }
  }
}

extension MovieSearchController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return movies.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath)
    let movie = movies[indexPath.row]
    cell.textLabel?.text = movie.trackName
    if let description = movie.longDescription {
      cell.detailTextLabel?.text = description
    }
    // image processing
    // image data from url
    // needs to be on a background thread
    fetchImageForCell(cell: cell, movie: movie)
    return cell
  }
  
  private func fetchImageForCell(cell: UITableViewCell, movie: Movie) {
    DispatchQueue.global().async {
      do {
        let imageData = try Data(contentsOf: movie.artworkUrl100)
        // need to dispatch back to the main thread
        // create an image from the imageData
        DispatchQueue.main.async {
          cell.imageView?.image = UIImage(data: imageData)
        }
      } catch {
        print("contents of url error: \(error)")
      }
    }
  }
}

extension MovieSearchController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    guard let searchText = searchBar.text else { return }
    searchMovies(keyword: searchText)
  }
}

