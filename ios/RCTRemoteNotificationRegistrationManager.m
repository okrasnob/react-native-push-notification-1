//
//  RCTRemoteNotificationRegistrationManager.m
//  RCTPushNotification
//
//  Created by dmueller39 on 11/15/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RCTRemoteNotificationRegistrationManager.h"
#import "RCTConvert+Notifications.h"
#import "FutureProxy.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

@implementation RCTRemoteNotificationRegistrationManager
{
  RCTPromiseResolveBlock _registerResolveBlock;
  RCTPromiseRejectBlock _registerRejectBlock;
}


+(FutureProxy*)proxy{
  static FutureProxy* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[FutureProxy alloc] initWithClass:[RCTRemoteNotificationRegistrationManager class]];
  });
  return instance;
}

// use the proxied instance will keep track of invocations for us until the native module has started observing
+(instancetype)proxiedInstance{
  return (RCTRemoteNotificationRegistrationManager*)[RCTRemoteNotificationRegistrationManager proxy];
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
  // we don't need to flushInvocations here, as RN should be listening
  // before registering
  [[RCTRemoteNotificationRegistrationManager proxy] addTarget:self];
}

- (void)stopObserving
{
  [[RCTRemoteNotificationRegistrationManager proxy] removeTarget:self];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"remoteNotificationsRegistered",
           @"remoteNotificationRegistrationError"];
}


- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  NSMutableString *hexString = [NSMutableString string];
  NSUInteger deviceTokenLength = deviceToken.length;
  const unsigned char *bytes = deviceToken.bytes;
  for (NSUInteger i = 0; i < deviceTokenLength; i++) {
    [hexString appendFormat:@"%02x", bytes[i]];
  }
  NSDictionary* body = @{@"deviceToken" : [hexString copy]};
  if(_registerResolveBlock != nil) {
    _registerResolveBlock(@[body]);
  }
  [self sendEventWithName:@"remoteNotificationsRegistered" body:body];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  if(_registerRejectBlock != nil) {
    _registerRejectBlock(error.localizedDescription,nil,error);
  }
  NSDictionary *errorDetails = @{
                                 @"message": error.localizedDescription,
                                 @"code": @(error.code),
                                 @"details": error.userInfo,
                                 };
  [self sendEventWithName:@"remoteNotificationRegistrationError" body:errorDetails];
}

RCT_EXPORT_METHOD(registerForRemoteNotifications:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  _registerResolveBlock = resolve;
  _registerRejectBlock = reject;
  [RCTSharedApplication() registerForRemoteNotifications];
}


RCT_EXPORT_METHOD(unregisterForRemoteNotifications)
{
  [RCTSharedApplication() unregisterForRemoteNotifications];
}

@end
