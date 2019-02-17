//
//  RCTContentAvailableNotificationManager.m
//  RCTPushNotification
//
//  Created by dmueller39 on 1/8/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "RCTContentAvailableNotificationManager.h"
#import "RCTConvert+Notifications.h"
#import "FutureProxy.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

@interface RCTContentAvailableNotificationManager ()
@property (nonatomic, strong) NSMutableDictionary *remoteNotificationCallbacks;
@end

@implementation RCTContentAvailableNotificationManager

+(FutureProxy*)proxy{
  static FutureProxy* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[FutureProxy alloc] initWithClass:[RCTContentAvailableNotificationManager class]];
  });
  return instance;
}

// use the proxied instance will keep track of invocations for us until the native module has started observing
+(instancetype)proxiedInstance{
  return (RCTContentAvailableNotificationManager*)[RCTContentAvailableNotificationManager proxy];
}


RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
  // If there are multiple concurrent instances of RCTRemoteNotificationManager, then
  // whichever calls startObserving first will be called with the invocations from launch.
  [[RCTContentAvailableNotificationManager proxy] addTarget:self];
  [[RCTContentAvailableNotificationManager proxy] flushInvocations];
}

- (void)stopObserving
{
  [[RCTContentAvailableNotificationManager proxy] removeTarget:self];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"contentAvailableNotificationReceived"];
}


- (void)didReceiveSilentRemoteNotification:(NSDictionary *)original
                    fetchCompletionHandler:(RCTRemoteNotificationCallback)completionHandler
{
  if([original[@"aps"][@"content-available"] integerValue] != 1) {
    completionHandler(UIBackgroundFetchResultNoData);
    return;
  }

  NSDictionary* formatted = RCTFormatContentAvailableNotification(original);
  NSString *notificationId = formatted[@"notificationId"];
  
  if (completionHandler) {
    if (!self.remoteNotificationCallbacks) {
      // Lazy initialization
      self.remoteNotificationCallbacks = [NSMutableDictionary dictionary];
    }
    self.remoteNotificationCallbacks[notificationId] = completionHandler;
  }
  
  [self sendEventWithName:@"contentAvailableNotificationReceived" body:formatted];
}


RCT_EXPORT_METHOD(onFinishRemoteNotification:(NSString *)notificationId fetchResult:(UIBackgroundFetchResult)result) {
  RCTRemoteNotificationCallback completionHandler = self.remoteNotificationCallbacks[notificationId];
  if (!completionHandler) {
    RCTLogError(@"There is no completion handler with notification id: %@", notificationId);
    return;
  }
  completionHandler(result);
  [self.remoteNotificationCallbacks removeObjectForKey:notificationId];
}

@end
