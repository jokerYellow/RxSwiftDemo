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

struct User : Codable {
    let name : String
}

struct Response:Codable {
    let errorCode:Int
    let user:User
    static let LoginSuccess = 1
}

enum LoginError:Swift.Error {
    case networkError
    case loginInfoValid
}


func login(userName:String,passWord:String) -> Single<Response> {
    return  Single<Response>.create(subscribe: { (single) -> Disposable in
        var request = URLRequest.init(url: URL.init(string: "http://127.0.0.1:8080/login")!)
        request.httpMethod = "POST"
        let info = ["username":userName,
                    "password":passWord]
        
        let data = try? JSONEncoder().encode(info)
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data,
                let response = try? JSONDecoder().decode(Response.self, from: data){
                if response.errorCode != Response.LoginSuccess{
                    single(SingleEvent.error(LoginError.loginInfoValid))
                }else{
                    single(SingleEvent.success(response))
                }
            }else{
                single(SingleEvent.error(LoginError.networkError))
            }
        })
        task.resume()
        return Disposables.create {
            task.cancel()
        }
    })
}


class ViewController: UIViewController {

    enum error:Swift.Error {
        case invalidUserName
    }
    
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
        
        let userNameInput = self.userNameField.rx.text
        let passWordInput = self.passWordField.rx.text
        
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
        
        let loginInfo = Observable<(String,String)>.combineLatest(userNameInput, passWordInput) { (userNameText, passWordText) -> (String, String) in
            return (userNameText ?? "",passWordText ?? "")
        }
        
        let loginEvent = self.loginButton.rx.tap
        
        loginEvent.withLatestFrom(loginInfo).flatMap { (info) -> Observable<Event<Response>> in
                let (userName,passWord) = info
                return login(userName: userName,
                             passWord: passWord)
                    .do(onError: { (error) in
                        //handle error
                        print(error)
                    }).asObservable().materialize()
            }.debug("login")
            .map { (event) -> User? in
                //map next User? type
                return event.element?.user
            }.filter({ (u) -> Bool in
                //filter nil model
                return u != nil
            })
            .subscribe().disposed(by: bag)
    }

}

