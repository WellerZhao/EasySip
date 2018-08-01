//
//  ESSipManager.h
//  EasySip
//
//  Created by Weller Zhao on 2018/7/27.
//  Copyright © 2018 weller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
//#import "linphone/linphonecore.h"

typedef struct LinphoneCall ESCall;

extern NSString *const ES_ON_REMOTE_OPEN_CEMERA;
extern NSString *const ES_ON_CALL_COMMING;
extern NSString *const ES_ON_CALL_END;
extern NSString *const ES_ON_CALL_STREAM_UPDATE;

@interface ESSipManager : NSObject

/**
 单例
 
 @return 返回实例
 */
+ (instancetype) instance;


/**
 登录sip服务器
 
 @param username 用户名
 @param password 密码
 @param displayName 显示名
 @param domain ip/域名
 @param port 端口
 @param transport 传输协议 UDP | TCP | TLS
 */
- (void) login: (NSString*) username password: (NSString*) password displayName: (NSString*) displayName domain: (NSString*) domain port: (NSString *) port withTransport: (NSString*) transport;


/**
 退出登录，注销账户
 */
- (void) logout;


/**
 拨打电话
 
 @param username 用户名
 @param displayName 显示名
 */
- (void) call: (NSString*) username displayName: (NSString*) displayName;


/**
 接听电话
 
 @param call 电话
 */
- (void) acceptCall: (ESCall*) call;

/**
 挂断
 */
- (void) hangUpCall;


/**
 配置视频播放流
 
 @param videoView 视频播放界面
 @param cameraView 当前摄像头显示界面
 */
- (void) configVideo: (UIView*) videoView cameraView: (UIView*) cameraView;


/**
 请求对方打开摄像头
 */
- (void) requestOpenCamera;

/**
 关闭摄像头
 */
- (void) closeCamera;

/**
 判断当前通话是否开启视频
 
 @param call 通话
 @return bool
 */
- (BOOL) isVideoEnabled: (ESCall*) call;

/**
 同意打开摄像头
 
 @param call 通话
 */
-(void) allowToOpenCameraByRemote: (ESCall*)call;

/**
 拒绝打开摄像头
 
 @param call 通话
 */
-(void) refuseToOpenCameraByRemote: (ESCall*)call;


/**
 获取联系人名
 
 @param call 通话
 @return 名字
 */
-(NSString*) getCallName: (ESCall*)call;

@end
