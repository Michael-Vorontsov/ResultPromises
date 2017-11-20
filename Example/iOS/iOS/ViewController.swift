//
//  ViewController.swift
//  iOS
//
//  Created by Mykhailo Vorontsov on 9/8/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import ResultPromises

final class ViewController: UITableViewController {
  
  enum ViewControllerError: Error {
    case imageConvertion
    case simulatedError
  }
  
  let session = URLSession.shared
  var reloadCount = 0
  var users = [User]()
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    reloadData()
  }
  
  @IBAction func pullToRefreshAction(_ sender: Any) {
    //! Launch reload function, with artificial delay 2.0 sconds, and artificial failure on every 5th load.
    reloadData(delay: 2.0, errorSimulationCounter: 5)
//! Replace line above with line below to launch native-style reload procedure
//    oldReload()
//! Replace first line of this fucntion with line below to run request without artificial errors and delays.
//    reloadData()
  }
  
  func resetUsers() {
    tableView.beginUpdates()
    if users.count > 0 {
      tableView.deleteSections([0], with: .fade)
    }
    users = []
    tableView.endUpdates()
  }
  
  //* Reload data old manner
  func oldReload() {
    let request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/users")!)
    session.dataTask(with: request) { (data, response, error) in
      DispatchQueue.main.async {
        self.tableView.refreshControl?.endRefreshing()
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
          self.tableView.reloadData()
        } catch {
          self.showError(message: error.localizedDescription)
        }
      }
      }.resume()
  }
  
  // Reload data simples way
  func reloadData() {
    self.tableView.refreshControl?.beginRefreshing()
    resetUsers()
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
  
  //* Reload data, with delay, and failing with error
  func reloadData(delay: Double, errorSimulationCounter: Int) {
    self.tableView.refreshControl?.beginRefreshing()
    resetUsers()
    URLRequest.requestFor(path: "https://jsonplaceholder.typicode.com/users")
      .then {(request) -> Promise<[User]> in
        return self.session.fetchRESTObject(from: request)
      }
      // Add delay for better illustration
      .then{ (users) -> Promise<[User]> in
        let promise = Promise<[User]>()
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + delay) {
          promise.resolve(result: users)
        }
        return promise
      }
      // Add probability to fail
      .then{ (users) -> [User] in
        self.reloadCount += 1
        if 0 == self.reloadCount % errorSimulationCounter {
          self.title = "Error simulation"
          throw ViewControllerError.simulatedError
        }
        self.title = "Pull \(5 - self.reloadCount % errorSimulationCounter) more time to get error"
        return users
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
  
  fileprivate func showError(message: String) {
    let alert = UIAlertController(title: "Network connection required!", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
  
  //MARK: TableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return users.count > 0 ? 1 : 0
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return users.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let user = users[indexPath.row]
    cell.textLabel?.text = user.name
    cell.detailTextLabel?.text = user.email
    
    // Load user avatars
    let name = user.username
    cell.tag = name.hashValue
    URLRequest.requestFor(path: "https://robohash.org/\(name)")
      .then {(request) -> Promise<Data> in
        self.session.fetchData(from: request)
      }
      .then { (data) -> UIImage in
        guard let image = UIImage(data: data) else {
          throw ViewControllerError.imageConvertion
        }
        return image
      }
      // Add delay for better illustration
      .then{ (image) -> Promise<UIImage> in
        let promise = Promise<UIImage>()
        let rand = (Double(arc4random()) / Double(RAND_MAX)) + 0.5
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + rand) {
          promise.resolve(result: image)
        }
        return promise
      }
      .onSuccess { (image) in
        // Cell can be reused with different user already
        if cell.tag == name.hashValue {
          cell.imageView?.image = image
          cell.setNeedsLayout()
        }
    }
    
    return cell
  }
  
  
}
