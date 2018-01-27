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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var loggedInId = ""
  var backgroundMode = false
  
  override init() {
    FirebaseApp.configure()
  }
  
  private func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]? = [:]) -> Bool {
    UIApplication.shared.statusBarStyle = .lightContent
    return true
  }

  public func setOnlineStateTo(_ state: Bool) {
    let usersReference = Database.database().reference(withPath: "members")
    usersReference.observe(.value, with: {
      snapshot in
      for aUser in snapshot.children {
        let thisUser = User(snapshot: aUser as! DataSnapshot)
        if thisUser.uid == self.loggedInId {
          let values: [String: Any] = ["email": thisUser.email as Any, "firstName": thisUser.firstName as Any, "lastName": thisUser.lastName as Any,  "online": state]
          let userRef = usersReference.child(self.loggedInId)
          userRef.setValue(values)
          break
        }
      }
    })
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//    if loggedInId != "" {
//      setOnlineStateTo(false)
//    }
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    if loggedInId != "" {
//      setOnlineStateTo(true)
//    }
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
//    if loggedInId != "" {
//      setOnlineStateTo(false)
//    }
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
//    backgroundMode = true
//    if loggedInId != "" {
//      setOnlineStateTo(false)
//    }
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
//    if loggedInId != "" {
//      setOnlineStateTo(true)
//    }
  }
}

