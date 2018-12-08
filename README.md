# Pursuit-Core-iOS-MovieSearch
MovieSearch app using URLSession, Codable, UISearchBar, UITableView, Image Processing with GCD

## URLSession 

**URLSession.shared** - singleton instance of a URLSession  

For basic requests, the URLSession class provides a [shared](https://developer.apple.com/documentation/foundation/urlsession/1409000-shared) singleton session object that gives you a reasonable default behavior for creating tasks. Use the shared session to fetch the contents of a URL to memory with just a few lines of code.

Unlike the other session types, you don’t create the shared session; you merely access it by using this property directly. As a result, you don’t provide a delegate or a configuration object.

**NB**: Caches request by default  

## Singleton

You use singletons to provide a globally accessible, shared instance of a class. You can create your own singletons as a way to provide a unified access point to a resource or service that’s shared across an app, like an audio channel to play sound effects or a network manager to make HTTP requests.

[Singleton](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/Singleton.html)  
[Managing a Shared Resource Using a Singleton
](https://developer.apple.com/documentation/swift/cocoa_design_patterns/managing_a_shared_resource_using_a_singleton) 

## Escaping Closures 

A closure is said to escape a function when the closure is passed as an argument to the function, but is called after the function returns. When you declare a function that takes a closure as one of its parameters, you can write @escaping before the parameter’s type to indicate that the closure is allowed to escape.

One way that a closure can escape is by being stored in a variable that is defined outside the function. As an example, many functions that start an asynchronous operation take a closure argument as a completion handler. The function returns after it starts the operation, but the closure isn’t called until the operation is completed—the closure needs to escape, to be called later.

[Closures](https://docs.swift.org/swift-book/LanguageGuide/Closures.html) 

## Resources 

[URLSession](https://developer.apple.com/documentation/foundation/urlsession)   
[Testing Asynchronous Operations with Expectations](https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations/testing_asynchronous_operations_with_expectations) 
[Concurrency Lesson](https://github.com/joinpursuit/Pursuit-Core-iOS/tree/master/units/unit03/lesson-05-concurrency)   

## Model 

```swift 
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
```

## Network Layer 

```swift 
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
```

## View Controller 

```swift 
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
```

