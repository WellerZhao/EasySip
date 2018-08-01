//
//  ESSipManager.m
//  EasySip
//
//  Created by Weller Zhao on 2018/7/27.
//  Copyright © 2018 weller. All rights reserved.
//

#import "ESSipManager.h"
#import "LinphoneManager.h"

#define LC ([LinphoneManager getLc])

NSString *const ES_ON_REMOTE_OPEN_CEMERA = @"ES_ON_REMOTE_OPEN_CEMERA";
NSString *const ES_ON_CALL_COMMING = @"ES_ON_CALL_COMMING";
NSString *const ES_ON_CALL_END = @"ES_ON_CALL_END";
NSString *const ES_ON_CALL_STREAM_UPDATE = @"ES_ON_CALL_STREAM_UPDATE";

@implementation ESSipManager

static ESSipManager* _instance = nil;

+(instancetype) instance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init] ;
    }) ;
    
    return _instance ;
}

+(id)allocWithZone:(struct _NSZone *)zone
{
    return [ESSipManager instance];
}

-(id)copyWithZone:(struct _NSZone *)zone
{
    return [ESSipManager instance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[LinphoneManager instance] startLinphoneCore];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCallUpdate:) name:kLinphoneCallUpdate object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) login: (NSString*) username password: (NSString*) password displayName: (NSString*) displayName domain: (NSString*) domain port: (NSString *) port withTransport: (NSString*) transport {
    LinphoneProxyConfig *config = linphone_core_create_proxy_config(LC);
    LinphoneAddress *addr = linphone_address_new(NULL);
    LinphoneAddress *tmpAddr = linphone_address_new([NSString stringWithFormat:@"sip:%@",domain].UTF8String);
    linphone_address_set_username(addr, username.UTF8String);
    linphone_address_set_port(addr, linphone_address_get_port(tmpAddr));
    linphone_address_set_domain(addr, linphone_address_get_domain(tmpAddr));
    if (displayName && ![displayName isEqualToString:@""]) {
        linphone_address_set_display_name(addr, displayName.UTF8String);
    }
    linphone_proxy_config_set_identity_address(config, addr);
    if (transport) {
        linphone_proxy_config_set_route(
                                        config,
                                        [NSString stringWithFormat:@"%s;transport=%s", domain.UTF8String, transport.lowercaseString.UTF8String]
                                        .UTF8String);
        linphone_proxy_config_set_server_addr(
                                              config,
                                              [NSString stringWithFormat:@"%s;transport=%s", domain.UTF8String, transport.lowercaseString.UTF8String]
                                              .UTF8String);
    }
    
    linphone_proxy_config_enable_publish(config, FALSE);
    linphone_proxy_config_enable_register(config, TRUE);
    
    LinphoneAuthInfo *info =
    linphone_auth_info_new(linphone_address_get_username(addr), // username
                           NULL,                                // user id
                           password.UTF8String,                        // passwd
                           NULL,                                // ha1
                           linphone_address_get_domain(addr),   // realm - assumed to be domain
                           linphone_address_get_domain(addr)    // domain
                           );
    linphone_core_add_auth_info(LC, info);
    linphone_address_unref(addr);
    linphone_address_unref(tmpAddr);
    
    if (config) {
        [[LinphoneManager instance] configurePushTokenForProxyConfig:config];
        if (linphone_core_add_proxy_config(LC, config) != -1) {
            linphone_core_set_default_proxy_config(LC, config);
            // reload address book to prepend proxy config domain to contacts' phone number
            // todo: STOP doing that!
            [[LinphoneManager.instance fastAddressBook] fetchContactsInBackGroundThread];
            //            [PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
        } else {
            //            [self displayAssistantConfigurationError];
        }
    } else {
        //        [self displayAssistantConfigurationError];
    }
    
    NSLog(@"登陆信息配置成功!\nusername:%@,\npassword:%@,\ndisplayName:%@\ndomain:%@,\nport:%@\ntransport:%@", username, password, displayName, domain, port, transport);
}

- (void) logout {
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"pushnotification_preference"];
    
    LinphoneCore *lc = [LinphoneManager getLc];
    LCSipTransports transportValue = {5060,5060,-1,-1};
    
    if (linphone_core_set_sip_transports(lc, &transportValue)) {
        NSLog(@"cannot set transport");
    }
    
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"sharing_server_preference"];
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"ice_preference"];
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"stun_preference"];
    linphone_core_set_stun_server(lc, NULL);
    linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
}

- (void) call: (NSString*) username displayName: (NSString*) displayName {
    LinphoneCall *call = [[LinphoneManager instance] callByUsername:username];
    if (call == nil) {
        NSLog(@"拨打失败");
    } else {
        NSLog(@"正在拨叫...\naddress:%@,\ndisplayName:%@", username, displayName);
    }
}

- (void) acceptCall: (LinphoneCall*) call {
    [[LinphoneManager instance] acceptCall:call evenWithVideo:true];
    NSLog(@"接听电话");
}

- (void) hangUpCall {
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* currentcall = linphone_core_get_current_call(lc);
    if (linphone_core_is_in_conference(lc) || // In conference
        (linphone_core_get_conference_size(lc) > 0) // Only one conf
        ) {
        linphone_core_terminate_conference(lc);
    } else if(currentcall != NULL) { // In a call
        linphone_core_terminate_call(lc, currentcall);
    } else {
        const MSList* calls = linphone_core_get_calls(lc);
        if (ms_list_size(calls) == 1) { // Only one call
            linphone_core_terminate_call(lc,(LinphoneCall*)(calls->data));
        }
    }
    NSLog(@"挂断");
}

- (void) configVideo: (UIView*) videoView cameraView: (UIView*) cameraView {
    linphone_core_set_native_video_window_id([LinphoneManager getLc], (__bridge void *)(videoView));
    linphone_core_set_native_preview_window_id([LinphoneManager getLc], (__bridge void *)(cameraView));
}

- (void) requestOpenCamera {
    
    if (!linphone_core_video_display_enabled(LC))
    return;
    
    LinphoneCall *call = linphone_core_get_current_call(LC);
    if (call) {
        LinphoneCallAppData *callAppData = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
        callAppData->videoRequested = TRUE; /* will be used later to notify user if video was not activated because of the linphone core*/
        LinphoneCallParams *call_params = linphone_core_create_call_params(LC,call);
        linphone_call_params_enable_video(call_params, TRUE);
        linphone_core_update_call(LC, call, call_params);
        linphone_call_params_destroy(call_params);
    } else {
        NSLog(@"Cannot toggle video button, because no current call");
    }
}

- (void) closeCamera {
    if (!linphone_core_video_display_enabled(LC))
    return;
    [LinphoneManager.instance setSpeakerEnabled:FALSE];
    
    LinphoneCall *call = linphone_core_get_current_call(LC);
    if (call) {
        LinphoneCallParams *call_params = linphone_core_create_call_params(LC,call);
        linphone_call_params_enable_video(call_params, FALSE);
        linphone_core_update_call(LC, call, call_params);
        linphone_call_params_destroy(call_params);
    } else {
        NSLog(@"Cannot toggle video button, because no current call");
    }
}

- (BOOL) isVideoEnabled: (ESCall*) call {
    return linphone_call_params_video_enabled(linphone_call_get_current_params(call));
}


- (void) onCallUpdate: (NSNotification*) notification {
    NSDictionary* userInfo = [notification userInfo];
    NSValue* c = [userInfo valueForKey:@"call"];
    //    int state = (int)[userInfo valueForKey:@"state"];
    LinphoneCallState state = [[userInfo objectForKey:@"state"] intValue];
    NSString* message = [userInfo valueForKey:@"message"];
    NSLog(@"========== state: %d, message: %@", state, message);
    LinphoneCall* call = c.pointerValue;
    
    NSDictionary *dict = @{@"call" : [NSValue valueWithPointer:call],
                           @"state" : [NSNumber numberWithInt:state],
                           @"message" : message};
    
    switch (state) {
            case LinphoneCallIncomingReceived:
            [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_CALL_COMMING object: self userInfo:dict];
            case LinphoneCallOutgoingInit:
            case LinphoneCallConnected:
            case LinphoneCallStreamsRunning: {
                // check video
                if (![self isVideoEnabled:call]) {
                    const LinphoneCallParams *param = linphone_call_get_current_params(call);
                    const LinphoneCallAppData *callAppData =
                    (__bridge const LinphoneCallAppData *)(linphone_call_get_user_data(call));
                    if (state == LinphoneCallStreamsRunning && callAppData->videoRequested &&
                        linphone_call_params_low_bandwidth_enabled(param)) {
                        // too bad video was not enabled because low bandwidth
                        
                        NSLog(@"带宽太低，无法开启视频通话");
                        
                        callAppData->videoRequested = FALSE; /*reset field*/
                    }
                }
                [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_CALL_STREAM_UPDATE object:self userInfo:dict];
                break;
            }
            case LinphoneCallUpdatedByRemote: {
                const LinphoneCallParams *current = linphone_call_get_current_params(call);
                const LinphoneCallParams *remote = linphone_call_get_remote_params(call);
                
                /* remote wants to add video */
                if ((linphone_core_video_display_enabled([LinphoneManager getLc]) && !linphone_call_params_video_enabled(current) &&
                     linphone_call_params_video_enabled(remote)) &&
                    (!linphone_core_get_video_policy([LinphoneManager getLc])->automatically_accept ||
                     (([UIApplication sharedApplication].applicationState != UIApplicationStateActive) &&
                      floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max))) {
                         linphone_core_defer_call_update([LinphoneManager getLc], call);
                         
                         
                         [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_REMOTE_OPEN_CEMERA object: self userInfo:dict];
                         
                         //                     [self allowToOpenCameraByRemote:call];
                         
                     } else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
                         
                     }
                break;
            }
            case LinphoneCallUpdating:
            break;
            case LinphoneCallPausing:
            case LinphoneCallPaused:
            break;
            case LinphoneCallPausedByRemote:
            break;
            case LinphoneCallEnd://LinphoneCallEnd
            [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_CALL_END object: self userInfo:NULL];
            case LinphoneCallError:
        default:
            break;
    }
}

-(void) allowToOpenCameraByRemote: (ESCall*)call {
    LinphoneCallParams *params = linphone_core_create_call_params([LinphoneManager getLc], call);
    linphone_call_params_enable_video(params, TRUE);
    linphone_call_accept_update(call, params);
    linphone_call_params_destroy(params);
}

-(void) refuseToOpenCameraByRemote: (ESCall*)call {
    LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
    linphone_call_params_enable_video(params, FALSE);
    linphone_call_accept_update(call, params);
    linphone_call_params_destroy(params);
}

-(NSString*) getCallName: (ESCall*)call {
    if (call == NULL)
    return NULL;
    LinphoneAddress *addr = linphone_call_get_remote_address(call);
    return [FastAddressBook displayNameForAddress:addr];
}

@end
