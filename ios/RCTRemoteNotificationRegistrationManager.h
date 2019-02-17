//
//  RCTRemoteNotificationRegistrationManager.h
//  RCTPushNotification
//
//  Created by dmueller39 on 11/15/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <React/RCTEventEmitter.h>

@interface RCTRemoteNotificationRegistrationManager : RCTEventEmitter

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

// sending messages to the proxied instance will allow us to respond to messages when the native module
// becomes available
+(instancetype)proxiedInstance;


@end
