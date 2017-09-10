![Header](https://media.giphy.com/media/3ov9jMeeN8Ig5Jn9GU/giphy.gif)
#  ResultPromises

Helps to organise asynchronous calls in form of functional monads.

It allows to replace not very pleasant asynchronous completion block like

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
or even request and convert into generic codeable object in one go
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

## Installation

### Carthage

add to carthage file:
```
github "Michael-Vorontsov/ResultPromises"
```

### CocoaPods
```
pod ‘ResultPromises’, :git => 'https://github.com/Michael-Vorontsov/ResultPromises.git'
```


## Usage

### Problem

Swift error handling proposed by Apple suggests throwing an erros when necessary. However lot of API unable to trow an error, moreover asynchronous blocks can't  catch errors yet. Chain of asynchronous blocks, where each can throw a different errors became a nightmare.

For example if you had to fetch some data from remote URL, parse to Model and display on screen, present error otherwise.

### Result

*Result* is generic enum that can be wrapped around any type, to unify it with possible errors instead of throwing it.  Can be used to indicate succession of execution  some block or it failure with any error  as singular return.

*Result* can be converted back to throwable closure of function  by  calling ```.resolve```  method. It will return expected type or throw an error.

*Result* can be chained and transformed to another *Result* type using ```.map``` or ```.flatMap``` .

### Promise

Promise is generic wrapper object for scheduling delayed trigger on some sync or async event. Promises can be created before some async block and resolved to result or error inside this block. Promise is Reference Type, so one promise can be used across multiple functions.

Promises can be created simply by instantiating it:
```
let promiseString = Promise<String>()
```

When promises had created it's resolution state undefined. Promises can be resolved to success state providing result of it, or to faling state with some error.

```
promiseStringA.resolve(result: testString)
promiseStringB.resolve(error: TestError.test)

```

Promise can be resolved only once. Additional attempts to resolve Promise will not change it's state, nor trigger any resolution handlers. Warning message had to be logged to console though.

Promises can be subscribed for multiple resolution handlers: onSuccess, onError and onComplete. Resolution handlers had to be assigned to Promise before it is resolved. They will be triggered whenever promise resolved. One Promise can have multiple resolution handlers of any kinds.

*** Resolution handlers will be executed on queue where they was assigned ***
It can introduce slight delay of execution.

onSuccess and onError handlers will be triggered when Promises resolved to success or error state. onComplete will be triggered in any case.

It can be useful for example during handling network request for example. UI had to be refreshed with new data when data is available (onSuccess). Error message had to be shown otherwise (onError). Activity indicator had to be hidden in any case (onComplete).

```
promiseStrings.
  .onComplete { (_) in
    self.tableView.refreshControl?.endRefreshing()
  }
  .onSuccess { ([loadedStrings]) in
    self.strings = loadedStrings
    self.tableView.reloadData()
    }
  .onError { (error) in
    self.showError(message: error.localizedDescription)
  }

```

Related async chain of command can be easily attached together using *then* method. Then will created new promise using provided closure (implicitly or explicitly depends on closure result type).

If error happened, all subsequent promises will be resolved to error state at once. It allows to provide single error handler for entire chain of interdependent async operations.

It takes as an argument one of three possible closure:
* ```.then {(previousePromiseOutput) -> Promise<Type> in ... }```
Allows to create new asynchronous promise that can be resolved asynchronously to *Type* or to some *Error*.
* ```.then {(previousePromiseOutput) -> Result<Type> in ... }```
Allows to return Result type wrapped around *Type* or *Error*
*  ``` .then { (previousePromiseOutput) -> [Type] in  ... } ```
Allows to return *Type* object directly or throw an *Error*
*

```
urlRequestPromise
  .then {(request) -> Promise<Data> in
    // New promise going to be created here.
    // Code bellow will be triggered when request had been created
    let promise = Promise<(Data?, HTTPURLResponse)>()
    self.dataTask(with: request) { (data, response, error) in
    // Can be thrown out of here, so in case of error
    // resolve created promise to error state
    guard error == nil else {
      promise.resolve(error: NetworkError.network(error: error))
      return
    }
    guard let data = data, data.count > 0 else {
      promise.resolve(error: NetworkError.missedData)
      return
    }
    //Data no empty here for sure
    promise.resolve(success: data)
  }
  .then { (data) -> [User] in
    // It will be triggered when data arrived
    // And only if data available.
    // If original urlRequestPromise resolved to error, or error happened during network
    // this Promise will be resolved to error at once without executing this block.
    let decoder = JSONDecoder()
    return try decoder.decode([User].self, from: data)
    // JSONDecoder can throw. Promise will catch it and resolve itself into error.
  }
```
Unlike resolution handlers, then closures can be executed on the thread where promise resolution happened. It means that subsequent then closures can be executed earlier then resolution handlers.

Please mind that resolution handlers can be mixed with then together like
```
urlRequestPromise
  .onError{ _ in
    print("Error while creating URL request. No network request happend at all!")
  }
  .then {(request) -> Promise<Data> in
    /* Load data */
  }
  .onSuccess{ data in
    print("\(data.count) bytes had been received")
  }
  .onComplete{ _ in
    /* Stop activity indicator */
  }
  .then { (data) -> ModelData in
    /* Parse data */
  }
  .onSuccess( modelData in
    /* refresh UI */
  }
```

#### Extensions

Simple URLSession and URLRequest extensions provided. Rich comments provided on code. Please take a look.

#### Please take a look on Source code, unti tests and examples for more details.

#### Example project
available at Example/iOS folder.

## Author
Michael Vorontsov, michel06@ukr.net

## License
ResultPromises is avaialble under MIT license.
Please see LICENSE file for additional details.

