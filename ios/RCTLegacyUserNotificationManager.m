/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTLegacyUserNotificationManager.h"
#import "RCTConvert+Notifications.h"
#import "FutureProxy.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

static NSString *const kErrorUnableToRequestPermissions = @"E_UNABLE_TO_REQUEST_PERMISSIONS";

@implementation RCTLegacyUserNotificationManager
{
  RCTPromiseResolveBlock _requestPermissionsResolveBlock;
}

+(FutureProxy*)proxy{
  static FutureProxy* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[FutureProxy alloc] initWithClass:[RCTLegacyUserNotificationManager class]];
  });
  return instance;
}

// use the proxied instance will keep track of invocations for us until the native module has started observing
+(instancetype)proxiedInstance{
  return (RCTLegacyUserNotificationManager*)[RCTLegacyUserNotificationManager proxy];
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
  NSAssert([RCTLegacyUserNotificationManager shouldUseLegacyNotifications], @"should only startObserving when +shouldUseLegacyNotifications is true");
  // If there are multiple concurrent instances of RCTRemoteNotificationManager, then
  // whichever calls startObserving first will be called with the invocations from launch.
  [[RCTLegacyUserNotificationManager proxy] addTarget:self];
  [[RCTLegacyUserNotificationManager proxy] flushInvocations];
}

- (void)stopObserving
{
  [[RCTLegacyUserNotificationManager proxy] removeTarget:self];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"notificationReceived"];
}

- (void)didReceiveLegacyRemoteUserNotification:(NSDictionary *)notification
{
  [self sendEventWithName:@"notificationReceived" body:RCTFormatLegacyRemoteNotification(notification, NO)];
}

- (void)didReceiveLegacyLocalNotification:(UILocalNotification *)notification
{
  [self sendEventWithName:@"notificationReceived" body:RCTFormatLocalNotification(notification, NO)];
}

- (void)didRegisterUserNotificationSettings:(__unused UIUserNotificationSettings *)notificationSettings
{
  if (_requestPermissionsResolveBlock == nil) {
    return;
  }

  NSDictionary *notificationTypes = @{
    @"alert": @((notificationSettings.types & UIUserNotificationTypeAlert) > 0),
    @"sound": @((notificationSettings.types & UIUserNotificationTypeSound) > 0),
    @"badge": @((notificationSettings.types & UIUserNotificationTypeBadge) > 0),
  };

  _requestPermissionsResolveBlock(notificationTypes);
  // Clean up listener added in requestPermissions
  [self removeListeners:1];
  _requestPermissionsResolveBlock = nil;
}

RCT_EXPORT_METHOD(requestPermissions:(NSDictionary *)permissions
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  if (RCTRunningInAppExtension()) {
    reject(kErrorUnableToRequestPermissions, nil, RCTErrorWithMessage(@"Requesting push notifications is currently unavailable in an app extension"));
    return;
  }

  if (_requestPermissionsResolveBlock != nil) {
    RCTLogError(@"Cannot call requestPermissions twice before the first has returned.");
    return;
  }

  // Add a listener to make sure that startObserving has been called
  [self addListener:@"notificationReceived"];
  _requestPermissionsResolveBlock = resolve;

  UIUserNotificationType types = UIUserNotificationTypeNone;
  if (permissions) {
    if ([RCTConvert BOOL:permissions[@"alert"]]) {
      types |= UIUserNotificationTypeAlert;
    }
    if ([RCTConvert BOOL:permissions[@"badge"]]) {
      types |= UIUserNotificationTypeBadge;
    }
    if ([RCTConvert BOOL:permissions[@"sound"]]) {
      types |= UIUserNotificationTypeSound;
    }
  } else {
    types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
  }

  UIUserNotificationSettings *notificationSettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
  [RCTSharedApplication() registerUserNotificationSettings:notificationSettings];
}

RCT_EXPORT_METHOD(checkPermissions:(RCTResponseSenderBlock)callback)
{
  if (RCTRunningInAppExtension()) {
    callback(@[@{@"alert": @NO, @"badge": @NO, @"sound": @NO}]);
    return;
  }

  NSUInteger types = [RCTSharedApplication() currentUserNotificationSettings].types;
  callback(@[@{
    @"alert": @((types & UIUserNotificationTypeAlert) > 0),
    @"badge": @((types & UIUserNotificationTypeBadge) > 0),
    @"sound": @((types & UIUserNotificationTypeSound) > 0),
  }]);
}

RCT_EXPORT_METHOD(presentLocalNotification:(UILocalNotification *)notification)
{
  [RCTSharedApplication() presentLocalNotificationNow:notification];
}

RCT_EXPORT_METHOD(scheduleLocalNotification:(UILocalNotification *)notification)
{
  [RCTSharedApplication() scheduleLocalNotification:notification];
}

RCT_EXPORT_METHOD(cancelAllLocalNotifications)
{
  [RCTSharedApplication() cancelAllLocalNotifications];
}

RCT_EXPORT_METHOD(cancelLocalNotifications:(NSDictionary<NSString *, id> *)userInfo)
{
  for (UILocalNotification *notification in RCTSharedApplication().scheduledLocalNotifications) {
    __block BOOL matchesAll = YES;
    NSDictionary<NSString *, id> *notificationInfo = notification.userInfo;
    // Note: we do this with a loop instead of just `isEqualToDictionary:`
    // because we only require that all specified userInfo values match the
    // notificationInfo values - notificationInfo may contain additional values
    // which we don't care about.
    [userInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
      if (![notificationInfo[key] isEqual:obj]) {
        matchesAll = NO;
        *stop = YES;
      }
    }];
    if (matchesAll) {
      [RCTSharedApplication() cancelLocalNotification:notification];
    }
  }
}

RCT_EXPORT_METHOD(getInitialNotification:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  UILocalNotification *initialLocalNotification =
    self.bridge.launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];

  if (initialLocalNotification) {
    resolve(RCTFormatLocalNotification(initialLocalNotification, YES));
    return;
  }

  NSDictionary *initialRemoteNotification =
  self.bridge.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
  
  if (initialRemoteNotification) {
    
    resolve(RCTFormatLegacyRemoteNotification(initialRemoteNotification, YES));
    return;
  }
  
  resolve((id)kCFNull);
}

RCT_EXPORT_METHOD(getScheduledLocalNotifications:(RCTResponseSenderBlock)callback)
{
  NSArray<UILocalNotification *> *scheduledLocalNotifications = RCTSharedApplication().scheduledLocalNotifications;
  NSMutableArray<NSDictionary *> *formattedScheduledLocalNotifications = [NSMutableArray new];
  for (UILocalNotification *notification in scheduledLocalNotifications) {
    [formattedScheduledLocalNotifications addObject:RCTFormatLocalNotification(notification, NO)];
  }
  callback(@[formattedScheduledLocalNotifications]);
}

+(BOOL)shouldUseLegacyNotifications{
  if (@available(iOS 10.0, *)) {
    return NO;
  } else {
    return YES;
  }
}


@end
