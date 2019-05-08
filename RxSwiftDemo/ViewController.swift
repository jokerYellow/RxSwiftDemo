//
//  ViewController.swift
//  RxSwiftDemo
//
//  Created by HuangYaqing on 2019/5/8.
//  Copyright © 2019 HuangYaqing. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ViewController: UIViewController {

    @IBOutlet weak var passWordField: UITextField!
    
    @IBOutlet weak var userNameField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bindView()
        // Do any additional setup after loading the view, typically from a nib.
    }

    private func bindView(){
        let passWordInput = self.passWordField.rx.text
        let userNameInput = self.userNameField.rx.text
        let passWordValid = passWordInput.map { (passWord) -> Bool in
            if let passWord = passWord{
                return passWord.count > 6 && passWord.count < 20
            }
            return false
        }.debug("passWordValid")
        let userNameValid = userNameInput.map { (userName) -> Bool in
            if let userName = userName {
                return userName.count == 11
            }
            return false
        }.debug("userNameValid")
        let loginValid = Observable<Bool>.combineLatest(userNameValid, passWordValid) { (userName, passWord) -> Bool in
            return userName && passWord
        }
        loginValid.debug("loginValid").bind(to: self.loginButton.rx.isEnabled).disposed(by: bag)
    }

}

