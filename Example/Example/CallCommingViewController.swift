//
//  CallCommingViewController.swift
//  Example
//
//  Created by Weller Zhao on 2018/7/31.
//  Copyright © 2018 weller. All rights reserved.
//

import UIKit
import EasySip

class CallCommingViewController: UIViewController {
    
    var call: OpaquePointer?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        let btnAccept = UIButton(frame: CGRect(x: 40, y: 40, width: 100, height: 40))
        btnAccept.setTitle("接听", for: .normal)
        btnAccept.setTitleColor(.black, for: .normal)
        btnAccept.addTarget(self, action: #selector(onAcceptClick(sender:)), for: .touchUpInside)
        view.addSubview(btnAccept)
        
        let btnRefuse = UIButton(frame: CGRect(x: 220, y: 40, width: 100, height: 40))
        btnRefuse.setTitle("拒绝", for: .normal)
        btnRefuse.setTitleColor(.black, for: .normal)
        btnRefuse.addTarget(self, action: #selector(onRefuseClick(sender:)), for: .touchUpInside)
        view.addSubview(btnRefuse)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onCallEnd(notification:)), name: NSNotification.Name(rawValue: ES_ON_CALL_END), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onOpenCamera(notification:)), name: NSNotification.Name(rawValue: ES_ON_REMOTE_OPEN_CEMERA), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc private func onAcceptClick(sender: UIButton?) {
        if let call = call {
            ESSipManager.instance().accept(call)
        }
    }
    
    @objc private func onRefuseClick(sender: UIButton?) {
        ESSipManager.instance().hangUpCall()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onCallEnd(notification: NSNotification) {
        call = nil
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onOpenCamera(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let call = (userInfo["call"] as? NSValue)?.pointerValue else {
                return
        }
        
        let alertController = UIAlertController(title: "", message: "对方正在请求开启视频通话", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "接受", style: .default, handler: {[weak self] (alertAction) in
            ESSipManager.instance().allowToOpenCamera(byRemote: OpaquePointer(call))
            let videoCallController = VideoCallViewController()
            self?.present(videoCallController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "拒绝", style: .cancel, handler: { (alertAction) in
            ESSipManager.instance().refuseToOpenCamera(byRemote: OpaquePointer(call))
        }))
        present(alertController, animated: true, completion: nil)
    }

}
