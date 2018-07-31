//
//  ViewController.swift
//  Example
//
//  Created by Weller Zhao on 2018/7/31.
//  Copyright © 2018 weller. All rights reserved.
//

import UIKit
import EasySip

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let btnCall = UIButton(frame: CGRect(x: 20, y: 20, width: 200, height: 40))
        view.addSubview(btnCall)
        btnCall.setTitle("拨号", for: .normal)
        btnCall.setTitleColor(.black, for: .normal)
        btnCall.addTarget(self, action: #selector(onCallClick(sender:)), for: .touchUpInside)
        
        ESSipManager.instance().login("1003", password: "123456", displayName: "", domain: "192.168.2.119", port: "5060", withTransport: "UDP")
        
        NotificationCenter.default.addObserver(self, selector: #selector(onCallComming(notification:)), name: NSNotification.Name(rawValue: ES_ON_CALL_COMMING), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func onCallClick(sender: UIButton?) {
        ESSipManager.instance().call("1002", displayName: "")
    }

    @objc private func onCallComming(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
        let call = (userInfo["call"] as? NSValue)?.pointerValue else {
            return
        }
        let callCommingController = CallCommingViewController()
        callCommingController.call = OpaquePointer(call)
        present(callCommingController, animated: true, completion: nil)
    }
}

