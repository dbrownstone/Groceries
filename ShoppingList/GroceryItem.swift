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

import Foundation
import Firebase

struct GroceryItem {
  
  let key: String
  let name: String
  let ref: DatabaseReference?
  var completed: Bool
  var inCurrentList: Bool
  var toBeAddedToCurrentList: Bool
  var quantity: Int
  var units: String
  
  init(name: String, currentList: Bool, completed: Bool, key: String = "") {
    self.key = name
    self.name = name
    self.inCurrentList = currentList
    self.toBeAddedToCurrentList = false
    self.completed = completed
    self.ref = nil
    self.quantity = 0
    self.units = " "
  }
  
  init(snapshot: DataSnapshot) {
    key = snapshot.key
    let snapshotValue = snapshot.value as! [String: AnyObject]
    name = snapshotValue["name"] as! String
    self.inCurrentList = snapshotValue["currentList"] as! Bool
    completed = snapshotValue["completed"] as! Bool
    self.quantity = snapshotValue["quantity"] as! Int
    self.units = snapshotValue["units"] as! String
    ref = snapshot.ref
    self.toBeAddedToCurrentList = false
  }
  
  func toAnyObject() -> Any {
    return [
      "name": name,
      "currentList": inCurrentList,
      "completed": completed,
      "quantity": quantity,
      "units": units
    ]
  }
}
