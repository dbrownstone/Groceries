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

class LoginViewController: UIViewController {
  
  // MARK: Constants
  let loginToList = "LoginToList"
  
  // MARK: Outlets
  @IBOutlet weak var textFieldLoginEmail: UITextField!
  @IBOutlet weak var textFieldLoginPassword: UITextField!
  
  var currentUserId: String?
  let appDelegate = UIApplication.shared.delegate as! AppDelegate
  var sv: UIView?
  
  override func viewDidLoad() {
    var listener: AuthStateDidChangeListenerHandle!
    var loggedIn = false
    
    self.textFieldLoginEmail.becomeFirstResponder()
    sv = UIViewController.displaySpinner(onView: self.view)
    listener = Auth.auth().addStateDidChangeListener {
      auth, user in
      if user != nil {
        self.currentUserId = user?.uid
        loggedIn = true
        self.appDelegate.loggedInId = (user?.uid)!
        
      } else {
        loggedIn = false
        self.appDelegate.loggedInId = ""
        UIViewController.removeSpinner(spinner: self.sv!)
      }
      let usersReference = Database.database().reference(withPath: "members")
      usersReference.observe(.value, with: {
        snapshot in
        for aUser in snapshot.children {
          let thisUser = User(snapshot: aUser as! DataSnapshot)
          if thisUser.uid == self.currentUserId {
            let values: [String: Any] = ["email": thisUser.email as Any, "firstName": thisUser.firstName as Any, "lastName": thisUser.lastName as Any,  "online": loggedIn]
            let userRef = usersReference.child(self.currentUserId!)
            userRef.setValue(values)
            if user?.uid != nil && loggedIn {
              self.performSegue(withIdentifier: self.loginToList, sender: self)
              UIViewController.removeSpinner(spinner: self.sv!)
            } else {
              self.textFieldLoginEmail.text = ""
              self.textFieldLoginEmail.becomeFirstResponder()
              self.textFieldLoginPassword.text = ""
            }
          }
        }
      })
    }
  }
  
  // MARK: Actions
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    Auth.auth().signIn(withEmail: textFieldLoginEmail.text!, password: textFieldLoginPassword.text!)
    sv = UIViewController.displaySpinner(onView: self.view)
  }

  var values: [String : AnyObject]?
  @IBAction func signUpDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Register",
                                  message: "Register",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) {
                                    action in
                                    let firstname = alert.textFields![0].text
                                    let lastname = alert.textFields![1].text
                                    let emailField = alert.textFields![2]
                                    let passwordField = alert.textFields![3]
                                    Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) {
                                      user, error in
                                      if error != nil {
                                        if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                          switch errorCode {
                                          case .weakPassword:
                                            print("Your password is too weak. Use at least 6 mixed_case characters!")
                                          case .emailAlreadyInUse:
                                            print("Email address already in use. Please login.")
                                            break
                                          case .missingEmail:
                                            break
                                          default:
                                            print("There is an error!")
                                            break
                                          }
                                        }
                                      }
                                      if user != nil {
//                                        user?.sendEmailVerification() {
//                                          error in
//                                          print(error?.localizedDescription)
//                                        }
                                        self.values = ["fullname" : firstname! + " " + lastname!, "email" : emailField.text!] as [String : AnyObject]
                                        self.registerUserIntoDatabaseWithUID(uid:(user?.uid)!)
                                      }
                                      Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!)
                                      self.performSegue(withIdentifier: self.loginToList, sender: nil)
                                      
                                    }
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    alert.addTextField { textEmail in
      textEmail.placeholder = "Enter your first name"
    }
    
    alert.addTextField { textEmail in
      textEmail.placeholder = "Enter your last name"
    }
    
    alert.addTextField { textEmail in
      textEmail.placeholder = "Enter your email"
    }
    
    alert.addTextField { textPassword in
      textPassword.isSecureTextEntry = true
      textPassword.placeholder = "Enter your password"
    }
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  func registerUserIntoDatabaseWithUID(uid: String) {
    let ref = Database.database().reference(fromURL: "https://groceries-730a8.firebaseio.com/")
    let usersRef = ref.child("members").child(uid)
    usersRef.updateChildValues(values!, withCompletionBlock: {(err, ref) in
      if err != nil {
        print(err ?? "")
        return
      }
      let user = User()
      user.setValuesForKeys(self.values!)
    })
  }
  
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    if identifier == self.loginToList && self.viewIfLoaded?.window != nil {
      return true
    }
    return false
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == loginToList && self.viewIfLoaded?.window != nil {
      let navController = segue.destination as! UINavigationController
      let controller = navController.topViewController as! GroceryListTableViewController
      controller.currentUserId = self.currentUserId
    }
  }
}

extension LoginViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == textFieldLoginEmail {
      textFieldLoginPassword.becomeFirstResponder()
    }
    if textField == textFieldLoginPassword {
      textField.resignFirstResponder()
      self.loginDidTouch(textField)
    }
    return true
  }
  
}

extension UIViewController {
  class func displaySpinner(onView : UIView) -> UIView {
    let spinnerView = UIView.init(frame: onView.bounds)
    spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
    ai.startAnimating()
    ai.center = spinnerView.center
    
    DispatchQueue.main.async {
      spinnerView.addSubview(ai)
      onView.addSubview(spinnerView)
    }
    
    return spinnerView
  }
  
  class func removeSpinner(spinner :UIView) {
    DispatchQueue.main.async {
      spinner.removeFromSuperview()
    }
  }
}
