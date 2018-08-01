# Use SIP quickly in iOS
一个快速集成sip的cocoapod库，免源码编译，支持模拟器调试。

- dependency:
[liblinphone (3.99.7)](https://gitlab.linphone.org/BC/public/Specs)

## Installation

### CocoaPods

	pod 'EasySip', '~> 0.0.3'
		
## Usage

### Quick Start

	import EasySip
	
	ESSipManager.instance().login("1006", password: "123456", displayName: "",
                                      domain: "192.168.2.115", port: "5060", withTransport: "UDP")
                           
	ESSipManager.instance().call("1002", displayName: "")


## License
EasySip is released under the MIT license. See LICENSE for details.