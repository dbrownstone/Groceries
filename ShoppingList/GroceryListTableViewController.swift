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

class GroceryListTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

  // MARK: - Constants
  let listToUsers = "ListToUsers"
  
  // MARK: - Properties
  var items: [GroceryItem] = []
  var currentShoppingList: [GroceryItem]  = []
  var remainingItems: [GroceryItem] = []
  var toBeAddedByName: [String] = []
  var toBeAdded: [GroceryItem] = []
  var user: User!
  var allMembers:[User]!
  var currentUserId: String!
  
  var selectedItemDescription: UITextField!
  var selectedItemAmount: UITextField!
  var seletedItemUnits: UITextField!

  var userCountBarButtonItem: UIBarButtonItem!
  @IBOutlet var refreshBarButtonItem: UIBarButtonItem!
  let groceryItemsReference = Database.database().reference(withPath: "grocery-items")
  let usersReference = Database.database().reference(withPath: "members")
  
  // MARK: - UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    
    userCountBarButtonItem = UIBarButtonItem(title: "Online: 0",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    refreshBarButtonItem.isEnabled = false
    
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
//      print(snapshot)
    })
    
    groceryItemsReference.queryOrdered(byChild: "currentList").observe(.value, with: {
      (snapshot) in
      var newItems: [GroceryItem] = [], newSLItems: [GroceryItem] = [], remItems: [GroceryItem] = []
      for item in snapshot.children {
        let groceryItem = GroceryItem(snapshot:item as! DataSnapshot)
        if groceryItem.inCurrentList {
          newSLItems.append(groceryItem)
        } else {
          remItems.append(groceryItem)
        }
        newItems.append(groceryItem)
      }
      
      self.items = newItems
      self.currentShoppingList = newSLItems
      self.remainingItems = remItems
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
    
    usersReference.observe(.value, with: {
      snapshot in
      if snapshot.exists() {
        var onlineCount = 0
        for aUser in snapshot.children {
          let snapshotValue = (aUser as! DataSnapshot).value as! [String: AnyObject]
          if snapshotValue["online"] as! Bool {
            onlineCount += 1
          }
        }
        self.userCountBarButtonItem.title = "Online: \(onlineCount)"
      }
      self.userCountBarButtonItem.tintColor = UIColor.white
    })
  }
  // MARK: - UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentShoppingList.count
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 30.0
  }
  
  var numberCompleted = 0
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = currentShoppingList[indexPath.row]
    cell.textLabel?.text = groceryItem.name
    if indexPath.row == 0 {
      numberCompleted = 0
    }
    if !groceryItem.completed {
      cell.accessoryType = .none
      cell.textLabel?.textColor = UIColor.black
      cell.detailTextLabel?.textColor = UIColor.black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = UIColor.gray
      cell.detailTextLabel?.textColor = UIColor.gray
      numberCompleted += 1
    }
    if indexPath.row == currentShoppingList.count - 1 && numberCompleted > 0 {
      refreshBarButtonItem.isEnabled = true
    } else {
      refreshBarButtonItem.isEnabled = false
    }
  
    return cell
  }
  
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryItem = currentShoppingList[indexPath.row]
      groceryItem.ref?.updateChildValues(["completed": false, "currentList": false])
      currentShoppingList.remove(at: indexPath.row)
      tableView.reloadData()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    var groceryItem = currentShoppingList[indexPath.row]
    if groceryItem.completed {
      cell.accessoryType = .none
      cell.textLabel?.textColor = UIColor.black
      cell.detailTextLabel?.textColor = UIColor.black
      groceryItem.completed = false
      groceryItem.ref?.updateChildValues(["completed": false])
      groceryItem.inCurrentList = true
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = UIColor.gray
      cell.detailTextLabel?.textColor = UIColor.gray
      refreshBarButtonItem.isEnabled = true
      groceryItem.completed = true
      groceryItem.ref?.updateChildValues(["completed": true])
      groceryItem.inCurrentList = false
    }
    tableView.reloadData()
  }
  
  @IBAction func refreshButtonDidTouch(_ sender: AnyObject) {
    for groceryItem in currentShoppingList {
      if groceryItem.completed {
        groceryItem.ref?.updateChildValues(["currentList": false])
      }
    }
    self.tableView.reloadData()
  }
  
  // MARK: - Add Item

  var pickerView = UIPickerView()
  var typeValue = String()
  var alert: UIAlertController!
  
  func arrayContainsGroceryItem(list: NSArray, item: GroceryItem) -> Int {
    var result = -1
    var index = 0
    for anItem in list {
      if (anItem as! GroceryItem).name == item.name {
        result = index
        break
      }
      index = index + 1
    }
    return result
  }
  
  func prepareTextField(frame: CGRect, theText: String) -> UITextField {
    let theFrame = frame;
    let theTextFld: UITextField = UITextField(frame: theFrame);
    theTextFld.text = theText
    theTextFld.textColor = .lightGray
    theTextFld.textAlignment = .center
    theTextFld.layer.borderWidth = 1.0
    
    return theTextFld
  }
  
  func prepareAlertTextFields() -> UIView {
    let inputFrame = CGRect(x: 0, y: 70, width: 270, height: 35);
    let inputView: UIView = UIView(frame: inputFrame);
    
    let descriptionText = prepareTextField(frame: CGRect(x: 5, y: 5, width: 160, height: 25), theText:"Add an Item")
    descriptionText.textAlignment = .left
    self.selectedItemDescription = descriptionText
    self.selectedItemDescription.delegate = self
    inputView.addSubview(descriptionText)
    
    let amtTxt = prepareTextField(frame: CGRect(x: 173, y: 5, width: 35, height: 25), theText:"Amt")
    self.selectedItemAmount = amtTxt
    self.selectedItemAmount.delegate = self
    inputView.addSubview(amtTxt)
    
    let unitsTxt = prepareTextField(frame: CGRect(x: 216, y: 5, width: 50, height: 25), theText:"Units")
    self.seletedItemUnits = unitsTxt
    self.seletedItemUnits.delegate = self
    inputView.addSubview(unitsTxt)
    
    return inputView
  }
  
  var messageLabel: UILabel!
  @IBAction func addButtonDidTouch(_ sender: AnyObject) {
    alert = UIAlertController(title: "Groceries",
                                  message: "Prepare A List",
                                  preferredStyle: .alert)
    alert.isModalInPopover = true
    
//    alert.addTextField()
    alert.view.addSubview(prepareAlertTextFields())

    
    let label = UILabel(frame: CGRect(x: 20, y: 110, width: 260, height: 20))
    label.font = UIFont(name: "HelveticaNeue", size: 12)
    label.text = "Touch 'Return' to complete"
    label.isHidden = false
    messageLabel = label
    alert.view.addSubview(label)
    
    pickerView = UIPickerView(frame: CGRect(x: 0, y: 95, width: 260, height: (self.view.frame.height * 0.60) * 0.60))
    pickerView.dataSource = self
    pickerView.delegate = self
    
    alert.view.addSubview(pickerView)
    
    let addToListAction = UIAlertAction(title: "Add to List", style: .default) {
      action in
      var thisGroceryItem: GroceryItem!
      for groceryItem in self.toBeAdded {
        thisGroceryItem = groceryItem
        thisGroceryItem.inCurrentList =  true
        thisGroceryItem.completed =  false
        thisGroceryItem.toBeAddedToCurrentList = false
        let index = self.arrayContainsGroceryItem(list: self.items as NSArray, item: groceryItem)
        if index > -1 {
          self.items.remove(at:index)
        }
        self.items.append(thisGroceryItem)
        
        self.currentShoppingList.append(thisGroceryItem)
        let groceryItemRef = self.groceryItemsReference.child(thisGroceryItem.name)
        let values: [String: Any] = [ "name": thisGroceryItem.name.lowercased(), "currentList": true, "completed": false]
        groceryItemRef.setValue(values)
      }
      self.tableView.reloadData()
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addAction(addToListAction)
    alert.addAction(cancelAction)
    
    let viewHeight:NSLayoutConstraint = NSLayoutConstraint(item: alert.view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: self.view.frame.height * 0.60)
    
    alert.view.addConstraint(viewHeight);
    
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
  
  //MARK - PickerView
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
//    self.toBeAdded = []
//    self.toBeAddedByName = []
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return self.remainingItems.count + 1
  }
  
  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 31
  }
  
  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    let resultantView = UIView(frame: CGRect(x: 0, y: 5, width: 260, height: 31))
    let label = UILabel(frame: CGRect(x: 20, y: 5, width: 200, height: 21))
    label.textAlignment = .center
    label.font = UIFont(name: "Helvetica Neue", size: 18)
    if row == 0 {
      label.text = "Add an Item"
    } else {
      label.text = (self.remainingItems[row - 1].name).capitalized
    }
    resultantView.addSubview(label)
    if row == 0 {
      return resultantView
    }
    let checkbox = UIImageView(frame: CGRect(x:230, y: 5, width:25, height: 25))
    if self.toBeAddedByName.contains(label.text!) {
      checkbox.image = UIImage(named: "checked")
    } else {
      checkbox.image = UIImage(named: "unchecked")
    }
    resultantView.addSubview(checkbox)
    return resultantView
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let textField = self.alert.textFields![0]
    switch row {
    case 0:
      messageLabel.isHidden = false
      break
    default:
      textField.text = (self.remainingItems[row - 1].name).capitalized
      self.addTheItem(row: row - 1)
      messageLabel.isHidden = true
      break
    }
    pickerView.reloadAllComponents()
  }
  
  func addTheItem(row: Int) {
    if let index = self.toBeAddedByName.index(of:self.selectedItemDescription.text!) {
      self.toBeAdded.remove(at: index)
      self.toBeAddedByName.remove(at: index)
    } else {
      let item = GroceryItem(name: self.selectedItemDescription.text!.lowercased(), currentList: true, completed: false)
      if row == 0 {
        self.toBeAdded.append(item)
        self.remainingItems.append(item)
      } else {
        self.toBeAdded.append(self.remainingItems[row])
      }
      self.toBeAddedByName.append(self.selectedItemDescription.text!)
    }
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    messageLabel.isHidden = false
    textField.text = ""
    textField.textColor = .black
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    resignFirstResponder()
    if textField == self.selectedItemDescription {
      self.selectedItemAmount.text = ""
      self.selectedItemAmount.becomeFirstResponder()
    } else if textField == self.selectedItemAmount {
      self.seletedItemUnits.text = ""
      self.seletedItemUnits.becomeFirstResponder()
    }
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    if !(self.selectedItemAmount.text!.isEmpty) &&
      !(self.selectedItemAmount.text!.isEmpty) &&
      textField == self.seletedItemUnits {
      self.selectedItemDescription.text = "Add an Item"
      self.selectedItemAmount.text = "Amt"
      self.seletedItemUnits.text = "Units"
      self.addTheItem(row: 0)
      resignFirstResponder()
    }
    
  }
}

