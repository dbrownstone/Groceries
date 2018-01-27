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

class User: NSObject {
  
  var uid: String?
  var email: String?
  var firstName: String?
  var lastName: String?
  var isOnline: Bool?
  
  override init() {
    super.init()
    uid = ""
    email = ""
    firstName = ""
    lastName = ""
    isOnline = false
  }
  
  init(uid: String, firstName: String, lastName: String, email: String) {
    self.uid = uid
    self.lastName = lastName
    self.firstName = firstName
    self.email = email
//    self.profileImageUrl = profileImageUrl
  }
  
  init(snapshot: DataSnapshot) {
    uid = snapshot.key
    let snapshotValue = snapshot.value as! [String: AnyObject]
    self.firstName = snapshotValue["firstName"] as? String
    self.lastName = snapshotValue["lastName"] as? String
    self.email = snapshotValue["email"] as? String
    self.isOnline = snapshotValue["online"] as? Bool
//    self.profileImageUrl = snapshotValue["profileImageUrl"] as? String
  }
  
//  func toAnyObject() -> Any {
//    return [
//      "uid": uid,
//      "fullname": fullname,
//      "email": email
//    ]
//  }
}
