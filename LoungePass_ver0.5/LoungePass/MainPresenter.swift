//
//  MainPresenter.swift
//  LoungePass
//
//  Created by MacBook on 20/05/2019.
//  Copyright © 2019 LimSoYul. All rights reserved.
//

import Foundation

class MainViewPresenter :ServerConstant,Presenter{
    
    
    private let view :View
    private let socket = ServerConnect.sharedInstance
    private let dataConverter = ConvertData()
    private let bypass = SejongConnect()
    private let defaultInfo = UserDefaultSetting()
    private let encryption = Encryption(keySize: 512, privateTag: "makeKeyPair", publicTag: "makeKeyPair")
    private let studentInfo = StudentInfo.sharedInstance
    
    private var auto = false
    
    required init(view: View) {
        self.view = view
    }
    
    func loginClicked(user : UserInfo, brightness: Float)->String {
        
        var passFlag :String
        print(user.id)
        print(user.pw)
        if user.tag == "2"{
            passFlag = self.serverPass(user: user)
            print(passFlag)
        }else {
            passFlag = self.sejongPass(user: user)
            print(passFlag)
        }
        
        if passFlag == "7" {setAutoInfo(user: user, brightness: brightness)}
        
        return passFlag
    }
    
    func sejongPass(user:UserInfo) -> String {
        
        var response : String?
        
        if(bypass.connectedToNetwork){
            response = bypass.requestPass(id: user.id!, pw: user.pw!)
            if response == nil {return "0"}
            else if response!.contains("아이디") || response!.contains("ID") { return "1"}
            else if response!.contains("패스워드") {return "2"}
            else {return self.serverPass(user: user)}
            
        }else{ return "3"}
    }
    
    func serverPass(user:UserInfo) -> String {

        if socket.connecting(){
            _ = socket.sendData(string: dataConverter.getLoginData(seq: LOGIN, id: user.id!, exponent: encryption.getExponent()!, modulus: encryption.getHex()!, type: user.tag!))
            let response = self.socket.readResponse()
            let dic = dataConverter.jsonStringToDictionary(text: response!)

            // setting student info
            let seq = dic!["seqType"] as! String
            if seq == LOGIN_OK{
                let info = encryption.decpryptBase64(encrpted:dic!["data"] as! String)
                let plainTxt = dataConverter.jsonStringToDictionary(text: info!)
                studentInfo.setStudentInfo(dic: plainTxt!)
                return "7"
            }
            else if seq == LOGIN_ALREADY{ return "4" }
            else if seq == LOGIN_NO_DATA { return "6"}
        }
        
        return "5"
    }
    
    func setNewIP(newIP :String){
        socket.setIP(newIP: newIP)
    }
    
    func setAutoInfo(user : UserInfo, brightness: Float) {
        if auto {
            defaultInfo.setIsAuto(value: auto)
            defaultInfo.setUserInfo(user: user)
            defaultInfo.setBrightness(brightness: brightness)
        }else{
            defaultInfo.removeInfo()
            defaultInfo.setBrightness(brightness: brightness)
        }
    }
    func autoLoginClicked(isAuto: Bool){
        self.auto = isAuto
    }
    
    func isPlayAutoLogin(brightness: Float) ->Bool{
        // 자동로그인 true인 경우
        // userdefault정보로 로그인 시도.
        // 우회로그인 -> 서버로그인 인증시 true 아니면 false
        let user = UserInfo()
        if defaultInfo.getInfo(key: "autoLogin") as? Bool == true {
            print("autologin")
            user.id = defaultInfo.getInfo(key: "id") as? String
            user.pw = defaultInfo.getInfo(key: "pwd") as? String
            user.tag = defaultInfo.getInfo(key: "tag") as? String
            self.auto = true
            if loginClicked(user: user,brightness: brightness) == "7" {return true}
        }
        return false

    }
    
    
}