//
//  RCTContentAvailableNotificationManager.h
//  RCTPushNotification
//
//  Created by dmueller39 on 1/8/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <React/RCTEventEmitter.h>

typedef void (^RCTRemoteNotificationCallback)(UIBackgroundFetchResult result);

@interface RCTContentAvailableNotificationManager : RCTEventEmitter

- (void)didReceiveSilentRemoteNotification:(NSDictionary *)notification fetchCompletionHandler:(RCTRemoteNotificationCallback)completionHandler;

// sending messages to the proxied instance will allow us to respond to messages when the native module
// becomes available
+(instancetype)proxiedInstance;

@end

