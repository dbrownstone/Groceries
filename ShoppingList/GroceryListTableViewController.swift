/*
 * Copyright (c) 2018 Brownstone LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {

  // MARK: Constants
  let listToUsers = "ListToUsers"
  
  // MARK: Properties 
  var items: [GroceryItem] = []
  var user: User!
  var allMembers:[User]!
  var currentUserId: String!
  
  var userCountBarButtonItem: UIBarButtonItem!
  let groceryItemsReference = Database.database().reference(withPath: "grocery-items")
  let usersReference = Database.database().reference(withPath: "members")
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    
    userCountBarButtonItem = UIBarButtonItem(title: "Online: 0",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
    allMembers = []
    usersReference.observe(.value, with: {
      snapshot in
      for aUser in snapshot.children {
        let thisUser = User(snapshot: aUser as! DataSnapshot)
        if thisUser.uid == self.currentUserId {
          self.user = thisUser
          break
        }
      }
    })
    
    groceryItemsReference.observe(.value, with: {snapshot in
      print(snapshot)
    })
    
    groceryItemsReference.queryOrdered(byChild: "completed").observe(.value, with: {
      (snapshot) in
      var newItems: [GroceryItem] = []
      for item in snapshot.children {
        let groceryItem = GroceryItem(snapshot:item as! DataSnapshot)
        newItems.append(groceryItem)
      }
      
      self.items = newItems
      self.tableView.reloadData()
    })
    
//    Auth.auth().addStateDidChangeListener {
//      auth, user in
//      if let user = user {
//        self.user = User(uid: user.uid, name: "", email: user.email!)
//        let currentUserReference = self.usersReference.child(self.user.uid!)
////        currentUserReference.setValue(self.user.email)
//        currentUserReference.setValuesForKeys(["fullname": name, "email": email])
//        currentUserReference.onDisconnectRemoveValue()
//      }
//    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    var onlineCount = 0
    usersReference.observe(.value, with: {
      snapshot in
      if snapshot.exists() {
        for aUser in snapshot.children {
          let user = User(snapshot: aUser as! DataSnapshot)
          if user.isOnline! {
            onlineCount += 1
          }
        }
        self.userCountBarButtonItem.title = "Online: \(onlineCount)"
      }
      self.userCountBarButtonItem.tintColor = UIColor.white
    })
  }
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryItem = items[indexPath.row]
//      groceryItem.ref?.removeValue()
      groceryItem.ref?.setValue(nil)
      items.remove(at: indexPath.row)
      tableView.reloadData()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    var groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    groceryItem.completed = toggledCompletion
    groceryItem.ref?.updateChildValues(["completed": toggledCompletion])
    tableView.reloadData()
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = UIColor.black
      cell.detailTextLabel?.textColor = UIColor.black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = UIColor.gray
      cell.detailTextLabel?.textColor = UIColor.gray
    }
  }
  
  // MARK: Add Item
  
  @IBAction func addButtonDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Grocery Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { action in
      let textField = alert.textFields![0] 
      let groceryItem = GroceryItem(name: textField.text!,
                                    addedByUser: self.user.email!,
                                    completed: false)
      self.items.append(groceryItem)
      self.tableView.reloadData()
                                    
      let groceryItemRef = self.groceryItemsReference.child(textField.text!.lowercased())
      let values: [String: Any] = [ "name": textField.text!.lowercased(), "addedByUser": self.user.firstName as Any, "completed": false]
      groceryItemRef.setValue(values)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addTextField()
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  @objc func userCountButtonDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == listToUsers {
      let controller = segue.destination as! OnlineUsersTableViewController
      controller.currentUserId = self.currentUserId
    }
  }
}
