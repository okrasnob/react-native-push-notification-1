//
//  RCTConvert+Notifications.h
//  RCTPushNotification
//
//  Created by dmueller39 on 11/15/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <React/RCTConvert.h>
#import <UserNotifications/UserNotifications.h>

@interface RCTConvert (NSCalendarUnit)

+ (NSCalendarUnit)NSCalendarUnit:(id)json;

@end

@interface RCTConvert (UNNotificationRequest)

+ (UNNotificationRequest *)UNNotificationRequest:(id)json;

+ (UNNotificationTrigger *)UNNotificationTrigger:(id)json;

@end

@interface RCTConvert (UNNotificationCategory)

+ (UNNotificationCategory *)UNNotificationCategory:(id)json;

@end

@interface RCTConvert (UILocalNotification)

+ (UILocalNotification *)UILocalNotification:(id)json;

@end

extern NSDictionary *RCTFormatUNNotificationSettings(UNNotificationSettings* settings);

extern NSDictionary *RCTFormatUNNotificationRequest(UNNotificationRequest *request);

extern NSDictionary *RCTFormatUNNotification(UNNotification *notification);

extern NSDictionary *RCTFormatUNNotificationResponse(UNNotificationResponse *response);

extern NSDictionary *RCTFormatUNNotificationCategory(UNNotificationCategory *category);

extern NSDictionary *RCTFormatLocalNotification(UILocalNotification *notification, BOOL isInitial);

extern NSDictionary *RCTFormatUNNotificationCategoryOptions(UNNotificationCategoryOptions options);

extern NSDictionary *RCTFormatLegacyRemoteNotification(NSDictionary* notification, BOOL isInitial);

extern NSDictionary *RCTFormatContentAvailableNotification(NSDictionary* notification);

extern NSDictionary *RCTFormatWillPresentUNNotification(UNNotification *notification);
