//
//  RCTConvert+Notifications.m
//  RCTPushNotification
//
//  Created by dmueller39 on 11/15/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RCTConvert+Notifications.h"

typedef id (*RCTFormatter)(id);

NSArray* RCTFormatArrayValue(RCTFormatter formatter, NSArray* values) {
  NSMutableArray* formattedValues = [NSMutableArray array];
  for (id value in values) {
    [formattedValues addObject:formatter(value)];
  }
  return [formattedValues copy];
}

@implementation RCTConvert (NSCalendarUnit)

RCT_ENUM_CONVERTER(NSCalendarUnit,
                   (@{
                      @"year": @(NSCalendarUnitYear),
                      @"month": @(NSCalendarUnitMonth),
                      @"week": @(NSCalendarUnitWeekOfYear),
                      @"day": @(NSCalendarUnitDay),
                      @"hour": @(NSCalendarUnitHour),
                      @"minute": @(NSCalendarUnitMinute)
                      }),
                   0,
                   integerValue)

@end

@implementation RCTConvert (UNNotificationRequest)

+ (UNNotificationRequest *)UNNotificationRequest:(id)json {
  NSString* identifier = [RCTConvert NSString:json[@"identifier"]];
  UNNotificationContent* content = [RCTConvert UNNotificationContent:json[@"content"]];
  UNNotificationTrigger* trigger = [RCTConvert UNNotificationTrigger:json[@"trigger"]];

  return [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
}

+ (UNNotificationTrigger *)UNNotificationTrigger:(id)json {
  if ([@"timeInterval" isEqual:json[@"type"]]) {
    BOOL repeats = [RCTConvert BOOL:json[@"repeats"]];
    NSTimeInterval timeInterval = [RCTConvert NSTimeInterval:json[@"timeInterval"]];
    return [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:repeats];
  }
  if (json) {
    RCTLogConvertError(json, @"a valid UNNotificationTrigger");
  }
  return nil;
}

+ (UNNotificationContent *)UNNotificationContent:(id)json {
  UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
  
if (json[@"badge"] != nil) {
    content.badge = [RCTConvert NSNumber:json[@"badge"]];
  }
  if (json[@"body"] != nil) {
    content.body = [RCTConvert NSString:json[@"body"]];
  }
  if (json[@"categoryIdentifier"] != nil) {
    content.categoryIdentifier = [RCTConvert NSString:json[@"categoryIdentifier"]];
  }
  if (json[@"subtitle"] != nil) {
    content.subtitle = [RCTConvert NSString:json[@"subtitle"]];
  }
  if (json[@"threadIdentifier"] != nil) {
    content.threadIdentifier = [RCTConvert NSString:json[@"threadIdentifier"]];
  }
  if (json[@"title"] != nil) {
    content.title = [RCTConvert NSString:json[@"title"]];
  }
  if (json[@"userInfo"] != nil) {
    content.userInfo = [RCTConvert NSDictionary:json[@"userInfo"]];
  }
  if ([json[@"attachments"] isKindOfClass:[NSArray class]]) {
    content.attachments = RCTConvertArrayValue(@selector(UNNotificationAttachment:), json[@"attachments"]);
  }
  if (json[@"sound"] != nil) {
    content.sound = [RCTConvert UNNotificationSound:json[@"sound"]];
  }

  return [content copy];

}

+(UNNotificationAttachment*)UNNotificationAttachment:(id)json{
  NSURL* URL = [RCTConvert NSURL:json[@"url"]];
  NSString* identifier = [RCTConvert NSString:json[@"identifier"]];
  NSError* error = nil;
  NSDictionary* options = [RCTConvert UNNotificationAttachmentOptions:json[@"options"]];
  UNNotificationAttachment* attachment = [UNNotificationAttachment attachmentWithIdentifier:identifier URL:URL options:options error:&error];
  if(attachment == nil) {
    RCTLogConvertError(json, @" UNNotificationAttachment");
  }
  return attachment;
}

+(NSDictionary*)UNNotificationAttachmentOptions:(id)json{
  if(json == nil) {
    return nil;
  }
  NSMutableDictionary* options = [NSMutableDictionary dictionary];
  if(json[@"hint"]) {
    options[UNNotificationAttachmentOptionsTypeHintKey] = [RCTConvert NSString:json[@"hint"]];
  }
  if(json[@"thumbnailHidden"]) {
    options[UNNotificationAttachmentOptionsThumbnailHiddenKey] = [RCTConvert NSNumber:json[@"thumbnailHidden"]];
  }
  if(json[@"clippingRect"]) {
    NSDictionary* clippingRect = CFBridgingRelease(CGRectCreateDictionaryRepresentation([RCTConvert CGRect:json[@"clippingRect"]]));
    options[UNNotificationAttachmentOptionsThumbnailClippingRectKey] = clippingRect;
  }
  if(json[@"thumbnailTime"]) {
    options[UNNotificationAttachmentOptionsThumbnailTimeKey] = [RCTConvert NSString:json[@"thumbnailTime"]];
  }
  return options;
}

+(UNNotificationSound*)UNNotificationSound:(id)json{
  if(json[@"name"]) {
    return [UNNotificationSound soundNamed:json[@"name"]];
  }
  return [UNNotificationSound defaultSound];
}

@end

@implementation RCTConvert (UNNotificationCategory)

+(UNNotificationAction*)UNNotificationAction:(id)json {
  UNNotificationActionOptions options = UNNotificationActionOptionNone;
  
  NSDictionary* optionDict = [RCTConvert NSDictionary:json[@"options"]];
  
  if(optionDict != nil) {
    if([RCTConvert BOOL:optionDict[@"authenticationRequired"]]){
      options |= UNNotificationActionOptionAuthenticationRequired;
    }
    if([RCTConvert BOOL:optionDict[@"destructive"]]){
      options |= UNNotificationActionOptionDestructive;
    }
    if([RCTConvert BOOL:optionDict[@"foreground"]]){
      options |= UNNotificationActionOptionForeground;
    }
  }

  NSString* identifier = [RCTConvert NSString:json[@"identifier"]];
  NSString* title = [RCTConvert NSString:json[@"title"]];

  return [UNNotificationAction actionWithIdentifier:identifier title:title options:options];
}

+(UNNotificationCategory*)UNNotificationCategory:(id)json{
  NSString* hiddenPreviewsBodyPlaceholder = [RCTConvert NSString:json[@"hiddenPreviewsBodyPlaceholder"]];
  NSString* identifier = [RCTConvert NSString:json[@"identifier"]];
  NSArray* intentIdentifiers = [RCTConvert NSArray:json[@"intentIdentifiers"]];

  UNNotificationCategoryOptions options = UNNotificationCategoryOptionNone;
  
  NSDictionary* optionDict = [RCTConvert NSDictionary:json[@"options"]];
  
  if(optionDict[@"options"] != nil) {
    if([RCTConvert BOOL:optionDict[@"customDismissAction"]]){
      options |= UNNotificationCategoryOptionCustomDismissAction;
    }
    if([RCTConvert BOOL:optionDict[@"allowInCarPlay"]]){
      options |= UNNotificationCategoryOptionAllowInCarPlay;
    }
    if (@available(iOS 11.0, *)) {
      if([RCTConvert BOOL:optionDict[@"hiddenPreviewsShowTitle"]]){
        options |= UNNotificationCategoryOptionHiddenPreviewsShowTitle;
      }
      if([RCTConvert BOOL:optionDict[@"hiddenPreviewsShowSubtitle"]]){
        options |= UNNotificationCategoryOptionHiddenPreviewsShowSubtitle;
      }
    }
  }
  
  NSArray* actions = RCTConvertArrayValue(@selector(UNNotificationAction:), json[@"actions"]);
  
  if (@available(iOS 11.0, *)) {
    if (hiddenPreviewsBodyPlaceholder) {
      return [UNNotificationCategory categoryWithIdentifier:identifier actions:actions intentIdentifiers:intentIdentifiers hiddenPreviewsBodyPlaceholder:hiddenPreviewsBodyPlaceholder options:options];
    }
  }
  return [UNNotificationCategory categoryWithIdentifier:identifier actions:actions intentIdentifiers:intentIdentifiers options:options];
}

@end

@implementation RCTConvert (UILocalNotification)

+ (UILocalNotification *)UILocalNotification:(id)json
{
  NSDictionary<NSString *, id> *details = [self NSDictionary:json];
  BOOL isSilent = [RCTConvert BOOL:details[@"isSilent"]];
  UILocalNotification *notification = [UILocalNotification new];
  notification.alertTitle = [RCTConvert NSString:details[@"alertTitle"]];
  notification.fireDate = [RCTConvert NSDate:details[@"fireDate"]] ?: [NSDate date];
  notification.alertBody = [RCTConvert NSString:details[@"alertBody"]];
  notification.alertAction = [RCTConvert NSString:details[@"alertAction"]];
  notification.userInfo = [RCTConvert NSDictionary:details[@"userInfo"]];
  notification.category = [RCTConvert NSString:details[@"category"]];
  notification.repeatInterval = [RCTConvert NSCalendarUnit:details[@"repeatInterval"]];
  if (details[@"applicationIconBadgeNumber"]) {
    notification.applicationIconBadgeNumber = [RCTConvert NSInteger:details[@"applicationIconBadgeNumber"]];
  }
  if (!isSilent) {
    notification.soundName = [RCTConvert NSString:details[@"soundName"]] ?: UILocalNotificationDefaultSoundName;
  }
  return notification;
}

RCT_ENUM_CONVERTER(UIBackgroundFetchResult, (@{
                                               @"UIBackgroundFetchResultNewData": @(UIBackgroundFetchResultNewData),
                                               @"UIBackgroundFetchResultNoData": @(UIBackgroundFetchResultNoData),
                                               @"UIBackgroundFetchResultFailed": @(UIBackgroundFetchResultFailed),
                                               }), UIBackgroundFetchResultNoData, integerValue)

@end

NSString *RCTFormatNSDate(NSDate *date)
{
  static NSDateFormatter *formatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
  });
  return [formatter stringFromDate:date];
}

NSString *RCTFormatUNAuthorizationStatus(UNAuthorizationStatus status) {
  switch(status) {
    case UNAuthorizationStatusDenied:
      return @"denied";
    case UNAuthorizationStatusAuthorized:
      return @"authorized";
#if defined(__IPHONE_12_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0
    case UNAuthorizationStatusProvisional:
      return @"provisional";
#endif
    case UNAuthorizationStatusNotDetermined:
      return @"none";
  }
}

NSString *RCTFormatUNNotificationSetting(UNNotificationSetting setting) {
  switch(setting) {
    case UNNotificationSettingDisabled:
      return @"disabled";
    case UNNotificationSettingEnabled:
      return @"enabled";
    case UNNotificationSettingNotSupported:
      return @"notSupported";
  }
}

NSString *RCTFormatUNShowPreviewsSetting(UNShowPreviewsSetting setting) NS_AVAILABLE_IOS(11.0) {
  if (@available(iOS 11.0, *)) {
    switch(setting) {
      case UNShowPreviewsSettingAlways:
        return @"always";
      case UNShowPreviewsSettingWhenAuthenticated:
        return @"whenAuthenticated";
      case UNShowPreviewsSettingNever:
        return @"never";
    }
  } else {
    return @"unavailable";
  }
}

NSString *RCTFormatUNAlertStyle(UNAlertStyle style) {
  switch(style) {
    case UNAlertStyleNone:
      return @"none";
    case UNAlertStyleBanner:
      return @"banner";
    case UNAlertStyleAlert:
      return @"alert";
  }
}

NSDictionary *RCTFormatUNNotificationSettings(UNNotificationSettings* settings) {
  NSMutableDictionary* formattedSettings = [NSMutableDictionary dictionary];
  
  formattedSettings[@"authorizationStatus"] = RCTFormatUNAuthorizationStatus(settings.authorizationStatus);

  formattedSettings[@"badgeSetting"] = RCTFormatUNNotificationSetting(settings.badgeSetting);
  formattedSettings[@"alertSetting"] = RCTFormatUNNotificationSetting(settings.alertSetting);
  formattedSettings[@"soundSetting"] = RCTFormatUNNotificationSetting(settings.soundSetting);
  formattedSettings[@"notificationCenterSetting"] = RCTFormatUNNotificationSetting(settings.notificationCenterSetting);
  formattedSettings[@"lockScreenSetting"] = RCTFormatUNNotificationSetting(settings.lockScreenSetting);
  formattedSettings[@"carPlaySetting"] = RCTFormatUNNotificationSetting(settings.carPlaySetting);

  formattedSettings[@"alertStyle"] = RCTFormatUNAlertStyle(settings.alertStyle);
  
  if (@available(iOS 11.0, *)) {
    formattedSettings[@"showPreviewsSetting"] = RCTFormatUNShowPreviewsSetting([settings showPreviewsSetting]);
  }
  
  return formattedSettings;
}

NSDictionary *RCTFormatUNNotificationAttachment(UNNotificationAttachment *attachment) {
  return @{
           @"identifier": RCTNullIfNil(attachment.identifier),
           @"URL": RCTNullIfNil(attachment.URL.absoluteString),
           @"type": RCTNullIfNil(attachment.type),
           };
}

NSDictionary *RCTFormatUNNotificationContent(UNNotificationContent *content) {
  NSMutableDictionary* formattedContent = [NSMutableDictionary dictionary];
  
  formattedContent[@"badge"] = RCTNullIfNil(content.badge);
  formattedContent[@"body"] = RCTNullIfNil(content.body);
  formattedContent[@"categoryIdentifier"] = RCTNullIfNil(content.categoryIdentifier);
  formattedContent[@"subtitle"] = RCTNullIfNil(content.subtitle);
  formattedContent[@"threadIdentifier"] = RCTNullIfNil(content.threadIdentifier);
  formattedContent[@"title"] = RCTNullIfNil(content.title);
  formattedContent[@"userInfo"] = RCTNullIfNil(content.userInfo);

  if ([content.attachments isKindOfClass:[NSArray class]]) {
    formattedContent[@"attachments"] = RCTFormatArrayValue(RCTFormatUNNotificationAttachment, content.attachments);
  }
  
  return formattedContent;
}

NSDictionary *RCTFormatUNNotificationTrigger(UNNotificationTrigger *trigger) {
  if ([trigger isKindOfClass:[UNTimeIntervalNotificationTrigger class]]) {
    NSTimeInterval timeInterval = ((UNTimeIntervalNotificationTrigger*)trigger).timeInterval;
    return @{
              @"type": @"timeInterval",
              @"timeInterval": @(timeInterval),
              @"repeats": @(trigger.repeats)
              };
  } else if ([trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    return @{
             @"type": @"push"
             };
  } else if ([trigger isKindOfClass:[UNCalendarNotificationTrigger class]]) {
    return @{
             @"type": @"calendar"
             };
  } else if ([trigger isKindOfClass:[UNLocationNotificationTrigger class]]) {
    return @{
             @"type": @"location"
             };
  }
  return nil;
}

NSDictionary *RCTFormatUNNotificationRequest(UNNotificationRequest *request) {
  NSMutableDictionary* formattedRequest = [NSMutableDictionary dictionary];
  
  formattedRequest[@"identifier"] = request.identifier;
  formattedRequest[@"content"] = RCTFormatUNNotificationContent(request.content);
  formattedRequest[@"trigger"] = RCTFormatUNNotificationTrigger(request.trigger);
  
  return formattedRequest;
}

NSDictionary *RCTFormatUNNotification(UNNotification *notification) {
  NSMutableDictionary* formattedNotification = [NSMutableDictionary dictionary];
  
  formattedNotification[@"request"] = RCTFormatUNNotificationRequest(notification.request);
  formattedNotification[@"date"] = RCTFormatNSDate(notification.date);
  
  return formattedNotification;
}

NSDictionary *RCTFormatWillPresentUNNotification(UNNotification *notification) {
  // wrap so that it matches the   
  return @{
    @"notification": RCTFormatUNNotification(notification), 
    @"actionIdentifier": @"willPresent", 
    @"foreground": @([RCTSharedApplication() applicationState] == UIApplicationStateActive), 
    @"notificationType": @"iOS-userNotification" 
  };

}

NSDictionary *RCTFormatUNNotificationResponse(UNNotificationResponse *response) {
  NSMutableDictionary* formattedResponse = [NSMutableDictionary dictionary];
  
  formattedResponse[@"notification"] = RCTFormatUNNotification(response.notification);
  formattedResponse[@"actionIdentifier"] = response.actionIdentifier;
  if ([response isKindOfClass:[UNTextInputNotificationResponse class]]) {
    formattedResponse[@"userText"] = ((UNTextInputNotificationResponse*)response).userText;
  }
  // all notification responses (also 'initial' notifications) should be considered
  // foreground = NO
  // notification response means user interaction
  // developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter
  formattedResponse[@"foreground"] = @(NO);
  formattedResponse[@"notificationType"] = @"iOS-userNotification";
  return [formattedResponse copy];
}

NSDictionary *RCTFormatUNNotificationActionOptions(UNNotificationActionOptions options) {
  NSMutableDictionary* formattedOptions = [NSMutableDictionary dictionary];
  
  formattedOptions[@"authenticationRequired"] = (options & UNNotificationActionOptionAuthenticationRequired) ? @(YES) : @(NO);
  formattedOptions[@"destructive"] = (options & UNNotificationActionOptionDestructive) ? @(YES) : @(NO);
  formattedOptions[@"foreground"] = (options & UNNotificationActionOptionForeground) ? @(YES) : @(NO);

  return formattedOptions;
}

NSDictionary *RCTFormatUNNotificationAction(UNNotificationAction* action) {
  NSMutableDictionary* formattedAction = [NSMutableDictionary dictionary];
  
  formattedAction[@"identifier"] = RCTNullIfNil(action.identifier);
  formattedAction[@"title"] = RCTNullIfNil(action.title);
  formattedAction[@"options"] = RCTFormatUNNotificationActionOptions(action.options);
  
  return formattedAction;
}

NSDictionary *RCTFormatUNNotificationCategoryOptions(UNNotificationCategoryOptions options) {
  NSMutableDictionary* formattedOptions = [NSMutableDictionary dictionary];
  
  formattedOptions[@"customDismissAction"] = (options & UNNotificationCategoryOptionCustomDismissAction) ? @(YES) : @(NO);
  formattedOptions[@"allowInCarPlay"] = (options & UNNotificationCategoryOptionAllowInCarPlay) ? @(YES) : @(NO);
  if (@available(iOS 11.0, *)) {
    formattedOptions[@"hiddenPreviewsShowTitle"] = (options & UNNotificationCategoryOptionHiddenPreviewsShowTitle) ? @(YES) : @(NO);
    formattedOptions[@"hiddenPreviewsShowSubtitle"] = (options & UNNotificationCategoryOptionHiddenPreviewsShowSubtitle) ? @(YES) : @(NO);
  }
  return formattedOptions;
}

NSDictionary *RCTFormatUNNotificationCategory(UNNotificationCategory *category) {
  NSMutableDictionary* formattedCategory = [NSMutableDictionary dictionary];
  
  formattedCategory[@"identifier"] = RCTNullIfNil(category.identifier);
  formattedCategory[@"intentIdentifiers"] = RCTNullIfNil(category.intentIdentifiers);
  if (@available(iOS 11.0, *)) {
    formattedCategory[@"hiddenPreviewsBodyPlaceholder"] = RCTNullIfNil(category.hiddenPreviewsBodyPlaceholder);
  }
  formattedCategory[@"options"] = RCTFormatUNNotificationCategoryOptions(category.options);
  formattedCategory[@"actions"] = RCTFormatArrayValue(RCTFormatUNNotificationAction, category.actions);
  
  return formattedCategory;
}

NSDictionary *RCTFormatLocalNotification(UILocalNotification *notification, BOOL isInitial)
{
  NSMutableDictionary *formattedLocalNotification = [NSMutableDictionary dictionary];
  if (notification.fireDate) {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *fireDateString = [formatter stringFromDate:notification.fireDate];
    formattedLocalNotification[@"fireDate"] = fireDateString;
  }
  formattedLocalNotification[@"alertAction"] = RCTNullIfNil(notification.alertAction);
  formattedLocalNotification[@"alertBody"] = RCTNullIfNil(notification.alertBody);
  formattedLocalNotification[@"applicationIconBadgeNumber"] = @(notification.applicationIconBadgeNumber);
  formattedLocalNotification[@"category"] = RCTNullIfNil(notification.category);
  formattedLocalNotification[@"soundName"] = RCTNullIfNil(notification.soundName);
  formattedLocalNotification[@"userInfo"] = RCTNullIfNil(RCTJSONClean(notification.userInfo));
  formattedLocalNotification[@"remote"] = @NO;
  formattedLocalNotification[@"silent"] = @NO;
  BOOL foreground = !isInitial && [RCTSharedApplication() applicationState] == UIApplicationStateActive;
  formattedLocalNotification[@"foreground"] = @(foreground);
  formattedLocalNotification[@"notificationType"] = @"iOS-legacyLocal";
  
  return formattedLocalNotification;
}

NSDictionary *RCTFormatLegacyRemoteNotification(NSDictionary* notification, BOOL isInitial)
{
  NSMutableDictionary *formattedNotification = [notification mutableCopy];
  
  formattedNotification[@"remote"] = @YES;
  BOOL foreground = !isInitial && [RCTSharedApplication() applicationState] == UIApplicationStateActive;
  formattedNotification[@"foreground"] = @(foreground);
  formattedNotification[@"notificationType"] = @"iOS-legacyRemote";
  
  return formattedNotification;
}

NSDictionary *RCTFormatContentAvailableNotification(NSDictionary* notification)
{
  NSMutableDictionary *formattedNotification = [notification mutableCopy];

  NSString *notificationId = [[NSUUID UUID] UUIDString];
  formattedNotification[@"notificationId"] = notificationId;
  formattedNotification[@"silent"] = @YES;
  formattedNotification[@"remote"] = @YES;
  formattedNotification[@"foreground"] = @([RCTSharedApplication() applicationState] == UIApplicationStateActive);
  formattedNotification[@"notificationType"] = @"iOS-silent";

  return formattedNotification;
}
