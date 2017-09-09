![Header](https://media.giphy.com/media/3ov9jMeeN8Ig5Jn9GU/giphy.gif)
#  ResultPromises

Helps to orginize asynchonouse calls in form of functional monads.

It allows to replace niot very pleasant asynchonouse comletion block like

```
  let request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/users")!)
  session.dataTask(with: request) { (data, response, error) in
    DispatchQueue.main.async {
      self.tableView.refreshControl?.endRefreshing()
    }
    if let error = error {
      self.showError(message: error.localizedDescription)
      return
    }

    let httpResponse = response as! HTTPURLResponse

    guard (200...299).contains( httpResponse.statusCode) else {
      self.showError(message: "Code: \(httpResponse.statusCode)")
      return
    }

    guard let data = data else {
      self.showError(message: "Data is Empty!")
      return
    }

    let decoder = JSONDecoder()
    do {
      let users =  try decoder.decode([User].self, from: data)
      self.users = users
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    } catch {
      self.showError(message: error.localizedDescription)
    }
  }.resume()
```
to very straight forward sequence
```
  URLRequest.requestFor(path: "https://jsonplaceholder.typicode.com/users")
    .then {(request) -> Promise<Data> in
      return self.session.fetchData(from: request)
    }
    .then { (data) -> [User] in
      let decoder = JSONDecoder()
      return try decoder.decode([User].self, from: data)
    }
    .onComplete { (_) in
      self.tableView.refreshControl?.endRefreshing()
    }
    .onSuccess { (users) in
      self.users = users
      self.tableView.reloadData()
    }
    .onError { (error) in
      self.showError(message: error.localizedDescription)
    }
  
```
or even request and convert into generic codable object in one go
```
  URLRequest.requestFor(path: "https://jsonplaceholder.typicode.com/users")
    .then {(request) -> Promise<[User]> in
      return self.session.fetchRESTObject(from: request)
    }
    .onComplete { (_) in
      self.tableView.refreshControl?.endRefreshing()
    }
    .onSuccess { (users) in
      self.users = users
      self.tableView.reloadData()
    }
    .onError { (error) in
      self.showError(message: error.localizedDescription)
    }
}
```

### Please take a look on Source code, unti tests and examples for more details.

## Usage
To run example project just open project in Example/iOS folder, and run on simulaltor.

## Instalation

### Carthage

add to carthage file:
```
github "Michael-Vorontsov/ResultPromises"
```

### CocoaPods
```
pod ‘ResultPromises’, :git => 'https://github.com/Michael-Vorontsov/ResultPromises.git'
```

## Author
Michael Vorontsov, michel06@ukr.net

## License
ResultPromises is avaialble under MIT license.
Please see LICENSE file for additional details.

