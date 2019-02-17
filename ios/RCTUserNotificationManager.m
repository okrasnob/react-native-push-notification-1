//
//  RCTUserNotificationManager.m
//  RCTPushNotification
//
//  Created by dmueller39 on 11/15/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RCTUserNotificationManager.h"
#import "RCTConvert+Notifications.h"
#import "FutureProxy.h"

#import <UserNotifications/UserNotifications.h>

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

static NSString *const kErrorUnableToRequestPermissions = @"E_UNABLE_TO_REQUEST_PERMISSIONS";
static NSString *const kErrorUnableToAddNotificationRequest = @"E_UNABLE_TO_ADD_NOTIFICATION_REQUEST";
static NSString *const kErrorUserNotificationsNotAvailable = @"E_USER_NOTIFICATIONS_NOT_AVAILABLE";

@interface RCTUserNotificationManager()<UNUserNotificationCenterDelegate>

@property BOOL isObserving;
@property BOOL collectInitialNotifications;
@property NSMutableArray* initialNotifications;
@property NSMutableDictionary* willPresentNotificationCompletionHandlers;

@end

@implementation RCTUserNotificationManager

+(BOOL)isUNUserNotificationCenterAvailable{
  if (@available(iOS 10.0, *)) {
    return YES;
  } else {
    return NO;
  }
}

RCT_EXTERN void RCTRegisterModule(Class);
+ (NSString *)moduleName { return @"RCTUserNotificationManager"; }

+ (void)load {
  RCTRegisterModule(self);
  // if the UNUserNotificationCenter is available on load we want to set the delegate
  if([RCTUserNotificationManager isUNUserNotificationCenterAvailable]){
    [[UNUserNotificationCenter currentNotificationCenter] setDelegate:[RCTUserNotificationManager proxiedInstance]];
  }
}

+(FutureProxy*)proxy{
  static FutureProxy* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[FutureProxy alloc] initWithClass:[RCTUserNotificationManager class]];
  });
  return instance;
}

// use the proxied instance will keep track of invocations for us until the native module has started observing
+(instancetype)proxiedInstance{
  return (RCTUserNotificationManager*)[RCTUserNotificationManager proxy];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
  self.isObserving = YES;
  // If there are multiple concurrent instances of RCTRemoteNotificationManager, then
  // whichever calls startObserving first will be called with the invocations from launch.
  [[RCTUserNotificationManager proxy] addTarget:self];
}

- (void)stopObserving
{
  self.isObserving = NO;
  [[RCTUserNotificationManager proxy] removeTarget:self];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"didReceiveNotificationResponse", @"willPresentNotification"];
}

/**
 * Update the application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(setApplicationIconBadgeNumber:(NSInteger)number)
{
  RCTSharedApplication().applicationIconBadgeNumber = number;
}

/**
 * Get the current application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(getApplicationIconBadgeNumber:(RCTResponseSenderBlock)callback)
{
  callback(@[@(RCTSharedApplication().applicationIconBadgeNumber)]);
}

RCT_EXPORT_METHOD(requestPermissions:(NSDictionary *)permissions
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  if (RCTRunningInAppExtension()) {
    reject(kErrorUnableToRequestPermissions, nil, RCTErrorWithMessage(@"Requesting user notifications is currently unavailable in an app extension"));
    return;
  }
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    reject(kErrorUserNotificationsNotAvailable, nil, RCTErrorWithMessage(@"Requesting user notifications is only available on iOS 10 and higher"));
    return;
  }

  UNAuthorizationOptions options = UNAuthorizationOptionNone;
  if (permissions) {
    if ([RCTConvert BOOL:permissions[@"alert"]]) {
      options |= UNAuthorizationOptionAlert;
    }
    if ([RCTConvert BOOL:permissions[@"badge"]]) {
      options |= UNAuthorizationOptionBadge;
    }
    if ([RCTConvert BOOL:permissions[@"sound"]]) {
      options |= UNAuthorizationOptionSound;
    }
  } else {
    options = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound;
  }

  [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
      resolve(@[RCTFormatUNNotificationSettings(settings)]);
    }];
  }];
  
}

RCT_EXPORT_METHOD(getNotificationSettings:(RCTResponseSenderBlock)callback)
{
  if (RCTRunningInAppExtension()) {
    callback(@[@{@"alert": @NO, @"badge": @NO, @"sound": @NO}]);
    return;
  }
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    callback(@[@{@"alert": @NO, @"badge": @NO, @"sound": @NO}]);
    return;
  }

  [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    callback(@[RCTFormatUNNotificationSettings(settings)]);
  }];
}

RCT_EXPORT_METHOD(addNotificationRequest:(UNNotificationRequest*)notificationRequest
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    reject(kErrorUserNotificationsNotAvailable, nil, RCTErrorWithMessage(@"Adding a notification is only available on iOS 10 and higher"));
    return;
  }
[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:notificationRequest withCompletionHandler:^(NSError * _Nullable error) {
    if(error != nil) {
      reject(kErrorUnableToAddNotificationRequest,nil,error);
    } else {
      resolve(@[]);
    }
  }];
}

RCT_EXPORT_METHOD(removeAllPendingNotificationRequests)
{
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    return;
  }
  [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
}

RCT_EXPORT_METHOD(removePendingNotificationRequests:(NSArray<NSString *> *)identifiers)
{
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    return;
  }
  [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:identifiers];
}

RCT_EXPORT_METHOD(getPendingNotificationRequests:(RCTResponseSenderBlock)callback)
{
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    return;
  }
  [[UNUserNotificationCenter currentNotificationCenter] getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
    NSMutableArray<NSDictionary *> *formattedRequests = [NSMutableArray new];
    for (UNNotificationRequest *request in requests) {
      [formattedRequests addObject:RCTFormatUNNotificationRequest(request)];
    }
    callback(@[formattedRequests]);
  }];
}

RCT_EXPORT_METHOD(removeAllDeliveredNotifications)
{
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    return;
  }
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center removeAllDeliveredNotifications];
}

RCT_EXPORT_METHOD(removeDeliveredNotifications:(NSArray<NSString *> *)identifiers)
{
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    return;
  }
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center removeDeliveredNotificationsWithIdentifiers:identifiers];
}

RCT_EXPORT_METHOD(getDeliveredNotifications:(RCTResponseSenderBlock)callback)
{
  if (![RCTUserNotificationManager isUNUserNotificationCenterAvailable]) {
    return;
  }
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *_Nonnull notifications) {
    NSMutableArray<NSDictionary *> *formattedNotifications = [NSMutableArray new];
    
    for (UNNotification *notification in notifications) {
      [formattedNotifications addObject:RCTFormatUNNotification(notification)];
    }
    callback(@[formattedNotifications]);
  }];
}

// Notification categories can be used to choose which actions will be displayed on which notifications.
RCT_EXPORT_METHOD(setNotificationCategories:(id)json) {
  NSArray* categories = RCTConvertArrayValue(@selector(UNNotificationCategory:), json);
  [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithArray:categories]];
}

RCT_EXPORT_METHOD(getNotificationCategories:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  [[UNUserNotificationCenter currentNotificationCenter] getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
    NSMutableArray<NSDictionary *> *formattedCategories = [NSMutableArray new];
    for (UNNotificationCategory *category in categories) {
      [formattedCategories addObject:RCTFormatUNNotificationCategory(category)];
    }
    resolve(@[formattedCategories]);
  }];
}

// we would like to know if any notifications came in before the bridge was initialized
// this way
RCT_EXPORT_METHOD(getInitialNotification:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  self.collectInitialNotifications = YES;
  self.initialNotifications = [NSMutableArray array];
  if (!self.isObserving) {
    [[RCTUserNotificationManager proxy] addTarget:self];
  }
  [[RCTUserNotificationManager proxy] flushInvocations];
  if (!self.isObserving) {
    [[RCTUserNotificationManager proxy] removeTarget:self];
  }
  self.collectInitialNotifications = NO;

  UNNotificationResponse* initialResponse = self.initialNotifications.lastObject;
  self.initialNotifications = nil;

  if (initialResponse) {
    resolve(RCTFormatUNNotificationResponse(initialResponse));
  } else {
    resolve((id)kCFNull);
  }
}


- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
  if(self.collectInitialNotifications) {
    [self.initialNotifications addObject:response];
  } else {
    [self sendEventWithName:@"didReceiveNotificationResponse" body:RCTFormatUNNotificationResponse(response)];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:@"PushNotificationUserResponse"
                                                      object:nil
                                                    userInfo:response.notification.request.content.userInfo];
  completionHandler();
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
  if(self.willPresentNotificationCompletionHandlers == nil) {
    self.willPresentNotificationCompletionHandlers = [NSMutableDictionary dictionary];
  }
  self.willPresentNotificationCompletionHandlers[notification.request.identifier] = completionHandler;
  [self sendEventWithName:@"willPresentNotification" body:RCTFormatWillPresentUNNotification(notification)];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"PushNotificationPresent"
                                                      object:nil
                                                    userInfo:notification.request.content.userInfo];
}

RCT_EXPORT_METHOD(presentNotification:(NSString*)identifier
                  options:(NSDictionary*)opts)
{
  UNNotificationPresentationOptions options = UNNotificationPresentationOptionNone;
  if([RCTConvert BOOL:opts[@"badge"]]) {
    options &= UNNotificationPresentationOptionBadge;
  }
  if([RCTConvert BOOL:opts[@"sound"]]) {
    options &= UNNotificationPresentationOptionSound;
  }
  if([RCTConvert BOOL:opts[@"alert"]]) {
    options &= UNNotificationPresentationOptionAlert;
  }

  void (^completionHandler)(UNNotificationPresentationOptions) = self.willPresentNotificationCompletionHandlers[identifier];
  completionHandler(options);
}


- (NSDictionary *)constantsToExport
{
  return @{ @"isUNUserNotificationCenterAvailable": @([RCTUserNotificationManager isUNUserNotificationCenterAvailable]) };
}


@end
