//
//  VideoCallViewController.swift
//  Example
//
//  Created by Weller Zhao on 2018/7/31.
//  Copyright © 2018 weller. All rights reserved.
//

import UIKit

class VideoCallViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        let vVideo = UIView(frame: UIScreen.main.bounds)
        view.addSubview(vVideo)
        
        let vPreVideo = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 200))
        view.addSubview(vPreVideo)
        
        let btnHangup = UIButton(frame: CGRect(x: 20, y: 20, width: 100, height: 40))
        btnHangup.setTitle("挂断", for: .normal)
//        btnHangup.setTitleColor(.black, for: .normal)
        view.addSubview(btnHangup)
        btnHangup.addTarget(self, action: #selector(onHangUp(sender:)), for: .touchUpInside)
        
        ESSipManager.instance().configVideo(vVideo, cameraView: vPreVideo)
    }
    
    @objc private func onHangUp(sender: UIButton) {
        ESSipManager.instance().hangUpCall()
    }

}
