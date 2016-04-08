//
//  LoginViewController.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-10-18.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts
import FBSDKCoreKit
import FBSDKLoginKit
import ParseFacebookUtilsV4
import ParseTwitterUtils

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var errorMessage = "Username and password don't match or you don't have an account yet."
    var signedUp: Bool = true
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    var mainTabBarController: MainTabBarController?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet weak var alternateButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    @IBOutlet weak var notRegisteredTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var notRegisteredTopGEConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var footerLabelBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var emailFieldSeparator: UIImageView!
    
    @IBOutlet weak var passwordTopConstraint: NSLayoutConstraint!
    
    @IBAction func fbParseLogin(sender: AnyObject) {
        let permissions = ["public_profile", "email"]
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) { (user: PFUser?, error: NSError?) -> Void in
            if error != nil {
                print(error)
            } else if user != nil {
                // This is only set after a Facebook or Twitter login.
                if user!.isNew {
                    self.loadFacebookUserDetails()
                }
                
                if user != nil {
                    self.setKeenUserGlobalProperties(user!)
                }
                
                self.delay(0.75, closure: { () -> () in
                    self.performSegueWithIdentifier("login", sender: self)
                })
            }
            else {
                self.displayAlert("Failed Log In", message: "Account not found!")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard(_:)))
        view.addGestureRecognizer(tap)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
        self.usernameField.attributedPlaceholder = NSAttributedString(string: "Username",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        self.emailField.hidden = true
        self.emailFieldSeparator.hidden = true
        self.passwordTopConstraint.constant = 3
        
        self.emailField.attributedPlaceholder = NSAttributedString(string:"E-mail",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        self.passwordField.attributedPlaceholder = NSAttributedString(string:"Password",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let mainTabBarController = segue.destinationViewController as? MainTabBarController {
            self.mainTabBarController = mainTabBarController
            self.mainTabBarController?.loginViewController = self
            if let acl = PFUser.currentUser()?.ACL {
                mainTabBarController.writeAccess = acl.getReadAccessForRoleWithName("Admin")
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if PFUser.currentUser() != nil {
            self.setKeenUserGlobalProperties(PFUser.currentUser()!)
            self.performSegueWithIdentifier("login", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadFacebookUserDetails(){
        let requestParameters = ["fields": "id, email, first_name, last_name, name"]
        let userDetails = FBSDKGraphRequest(graphPath: "me", parameters: requestParameters)
        userDetails.startWithCompletionHandler { (connection, result, error: NSError!) -> Void in
            if error != nil {
                print(error)
                PFUser.logOut()
            }else{
                let userId:String? = result["id"]! as? String
                let userEmail:String? = result["email"]! as? String
                let userFName:String? = result["first_name"]! as? String
                let userLName:String? = result["last_name"]! as? String
                //let userName:String = result["name"] as! String
                
                let userProfile = "https://graph.facebook.com/\(userId)/picture?type=large"
                let profilePictureURL = NSURL(string: userProfile)
                let profilePictureData = NSData(contentsOfURL: profilePictureURL!)
                
                if profilePictureData !=  nil {
                    if let profileFileObject = PFFile(data: profilePictureData!) {
                        PFUser.currentUser()?.setObject(profileFileObject, forKey: "profile_picture")
                    }
                }
                
                PFUser.currentUser()?.setObject(userFName!, forKey: "first_name")
                PFUser.currentUser()?.setObject(userLName!, forKey: "last_name")
                if let userEmail = userEmail {
                    PFUser.currentUser()?.email = userEmail
                }
                
                do{
                    try PFUser.currentUser()!.save()
                }catch{
                    print("Error Saving PFUser")
                }
                return
            }
        }
    }
    
    @IBAction func getIn(sender: AnyObject) {
        passwordField.resignFirstResponder()
        if usernameField.text == "" || passwordField.text == "" {
            displayAlert("Empty Field", message: "Please check your username and password!")
        } else {
            activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 100, 100))
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
            view.addSubview(activityIndicator)
            if signedUp {
                activityIndicator.startAnimating()
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                PFUser.logInWithUsernameInBackground(usernameField.text!, password: passwordField.text!, block: { (user, error) -> Void in

                    self.activityIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    if user != nil{
                        self.setKeenUserGlobalProperties(user!)
                        self.performSegueWithIdentifier("login", sender: self)
                    }else{
                        self.displayAlert("Failed Log In", message: self.errorMessage)
                    }
                })
            } else {
                if usernameField.text == "" || passwordField.text == "" || emailField.text == "" {
                    displayAlert("Empty Field", message: "Please check your username, email and password!")
                }
                else if let emailText = emailField.text where !emailText.isEmail {
                    displayAlert("Field error", message: "Please enter proper email format!")
                }
                else {
                    activityIndicator.startAnimating()
                    UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                    let user = PFUser()
                    user.username = usernameField.text
                    user.password = passwordField.text
                    user.email = emailField.text
                    user.signUpInBackgroundWithBlock({ (success, error) -> Void in
                        self.activityIndicator.stopAnimating()
                        UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        if error == nil {
                            self.performSegueWithIdentifier("login", sender: self)
                        }else{
                            if let errorString = error!.userInfo["error"] as? String {
                                self.displayAlert("Failed Sign Up", message: errorString)
                            }
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func switchContext(sender: AnyObject) {
        if signedUp {
            mainButton.setTitle("SIGN UP", forState: UIControlState.Normal)
            alternateButton.setTitle("Already Registered? Switch to Log In", forState: UIControlState.Normal)
            fbButton.setTitle("SIGN UP", forState: UIControlState.Normal)
            headerLabel.text = "SIGN UP"
            
            self.usernameField.attributedPlaceholder = NSAttributedString(string:"Username",
                attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            self.emailField.hidden = false
            self.emailFieldSeparator.hidden = false
            self.passwordTopConstraint.constant = 43
            
            self.forgotPasswordButton.hidden = true
            self.notRegisteredTopConstraint.constant = 20
            self.notRegisteredTopGEConstraint.constant = 4
        }
        else {
            mainButton.setTitle("LOG IN", forState: UIControlState.Normal)
            alternateButton.setTitle("Not Registered? Switch to Sign Up", forState: UIControlState.Normal)
            fbButton.setTitle("LOG IN" , forState: UIControlState.Normal)
            headerLabel.text = "LOG IN"
            
            self.usernameField.attributedPlaceholder = NSAttributedString(string: "Username",
                attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            self.emailField.hidden = true
            self.emailFieldSeparator.hidden = true
            self.passwordTopConstraint.constant = 3
            
            self.forgotPasswordButton.hidden = false
            self.notRegisteredTopConstraint.constant = 44
            self.notRegisteredTopGEConstraint.constant = 44
        }
        
        signedUp = !signedUp
    }
    
    @IBAction func forgotPasswordTapped(sender: AnyObject) {
        let alertController = UIAlertController(title: "Forgot your password?", message: "Please enter your E-mail:", preferredStyle: .Alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .Default) { (_) in
            if let field = alertController.textFields?[0] {
                if let emailText = field.text where !emailText.isEmail {
                    self.displayAlert("Field error", message: "Please enter proper email format!")
                }
                else {
                    self.showLoading()
                    PFUser.requestPasswordResetForEmailInBackground(field.text!, block: { (result, error) -> Void in
                        dispatch_async(dispatch_get_main_queue(), {
                            self.hideLoading()
                            self.displayAlert("Reset Password", message: result ? "Successfully submitted request!" : "Failed to submit request!")
                        })
                    })
                }
            } else {
                // user did not fill field
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "E-mail"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func displayAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if (textField.returnKeyType==UIReturnKeyType.Done)
        {
            getIn(self)
        }

        if (textField.returnKeyType==UIReturnKeyType.Next && textField.tag == 101)
        {
            if signedUp {
                self.passwordField.becomeFirstResponder()
            }
            else {
                self.emailField.becomeFirstResponder()
            }
        }
        
        if (textField.returnKeyType==UIReturnKeyType.Next && textField.tag == 102)
        {
            self.passwordField.becomeFirstResponder()
        }
        
        return true
    }
    
    func dismissKeyboard(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let info = notification.userInfo, value = info[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardFrame: CGRect = (value).CGRectValue()
            self.footerLabelBottomConstraint.constant = keyboardFrame.size.height + 8
            UIView.animateWithDuration(0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.footerLabelBottomConstraint.constant = 8
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    func setKeenUserGlobalProperties(user: PFUser) {
        
        var userDictionary: [String: AnyObject] = [:]
        userDictionary["username"] = user.username
        userDictionary["email"] = user.email ?? ""
        userDictionary["first_name"] = user.objectForKey("first_name") ?? ""
        userDictionary["last_name"] = user.objectForKey("last_name") ?? ""

        let requestParameters = ["fields": "id, email, first_name, last_name, name"]
        let userDetails = FBSDKGraphRequest(graphPath: "me", parameters: requestParameters)
        userDetails.startWithCompletionHandler { (connection, result, error: NSError!) -> Void in
            if error != nil {
                print(error)
            }else{
                let userId: String = result["id"]! as! String
                userDictionary["authData"] = userId
            }
            
            KeenClient.sharedClient().globalPropertiesDictionary =
                ["user" : userDictionary]
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.Portrait
        }
        
        return UIInterfaceOrientationMask.AllButUpsideDown
    }
}

extension UIViewController {
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}

extension PFUser {
    var isFacebookUser: Bool {
        return PFFacebookUtils.isLinkedWithUser(self)
    }
}