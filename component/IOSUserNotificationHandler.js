/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @flow
 */

/* eslint-disable no-underscore-dangle */

import {
  type Notification,
  type NotificationHandler,
  type PushNotificationEventName,
  type FetchResult,
  type Permissions
} from "./types";

import IOSUserNotification from "./IOSUserNotification";

const NativeModules = require("react-native").NativeModules;
const NativeEventEmitter = require("react-native").NativeEventEmitter;

const RCTRemoteNotificationRegistrationManager =
  NativeModules.RemoteNotificationRegistrationManager;
const RCTContentAvailableNotificationManager =
  NativeModules.ContentAvailableNotificationManager;
const RCTUserNotificationManager = NativeModules.UserNotificationManager;
const invariant = require("fbjs/lib/invariant");

const UserNotificationEmitter = new NativeEventEmitter(
  RCTUserNotificationManager
);

const RemoteNotificationRegistrationEmitter = new NativeEventEmitter(
  RCTRemoteNotificationRegistrationManager
);

const ContentAvailableNotificationEmitter = new NativeEventEmitter(
  RCTContentAvailableNotificationManager
);

const _notifHandlers = new Map(); // eslint-disable-line no-underscore-dangle

const NOTIF_REGISTER_EVENT = "remoteNotificationsRegistered";
const NOTIF_REGISTRATION_ERROR_EVENT = "remoteNotificationRegistrationError";

const DEVICE_USER_NOTIF_EVENT = "didReceiveNotificationResponse";
const WILL_PRESENT_USER_NOTIF_EVENT = "willPresentNotification";
const DEVICE_SILENT_NOTIF_EVENT = "contentAvailableNotificationReceived";

export type ContentAvailable = 1 | null | void;

/**
 * <div class="banner-crna-ejected">
 *   <h3>Projects with Native Code Only</h3>
 *   <p>
 *     This section only applies to projects made with <code>react-native init</code>
 *     or to those made with Create React Native App which have since ejected. For
 *     more information about ejecting, please see
 *     the <a href="https://github.com/react-community/create-react-native-app/blob/master/EJECTING.md" target="_blank">guide</a> on
 *     the Create React Native App repository.
 *   </p>
 * </div>
 *
 * Handle push notifications for your app, including permission handling and
 * icon badge number.
 *
 * To get up and running, [configure your notifications with Apple](https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/AddingCapabilities/AddingCapabilities.html#//apple_ref/doc/uid/TP40012582-CH26-SW6)
 * and your server-side system.
 *
 * [Manually link](docs/linking-libraries-ios.html#manual-linking) the PushNotificationIOS library
 *
 * - Add the following to your Project: `node_modules/react-native/Libraries/PushNotificationIOS/RCTPushNotification.xcodeproj`
 * - Add the following to `Link Binary With Libraries`: `libRCTPushNotification.a`
 *
 * Finally, to enable support for `notification` and `register` events you need to augment your AppDelegate.
 *
 * At the top of your `AppDelegate.m`:
 *
 *   `#import <React/RCTRemoteNotificationRegistrationManager.h>`
 *   `#import <React/RCTContentAvailableNotificationManager.h>`
 *
 * And then in your AppDelegate implementation add the following:
 *
 *   ```
 *    // Required for the register event.
 *    - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
 *    {
 *     [RCTRemoteNotificationRegistrationManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
 *    }
 *    // Required for the notification event. You must call the completion handler after handling the remote notification.
 *    - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
 *                                                           fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
 *    {
 *      [RCTPushNotificationManager didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
 *    }
 *    // Required for the registrationError event.
 *    - (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
 *    {
 *     [RCTRemoteNotificationRegistrationManager didFailToRegisterForRemoteNotificationsWithError:error];
 *    }
 *    // Required for the notification event. You must call the completion handler after handling the remote notification.
 *    - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
 *                                                           fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
 *    {
 *      [RCTContentAvailableNotificationManager didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
 *    }
 *   ```
 */
class IOSUserNotificationHandler implements NotificationHandler {
  static FetchResult = {
    NewData: "UIBackgroundFetchResultNewData",
    NoData: "UIBackgroundFetchResultNoData",
    ResultFailed: "UIBackgroundFetchResultFailed"
  };

  /**
   * Schedules the localNotification for immediate presentation.
   *
   * details is an object containing:
   *
   * - `alertTitle`: The title displayed in the notification alert.
   * - `alertBody` : The message displayed in the notification alert.
   * - `alertAction` : The "action" displayed beneath an actionable notification. Defaults to "view";
   * - `soundName` : The sound played when the notification is fired (optional).
   * - `isSilent`  : If true, the notification will appear without sound (optional).
   * - `category`  : The category of this notification, required for actionable notifications (optional).
   * - `userInfo`  : An optional object containing additional notification data.
   * - `applicationIconBadgeNumber` (optional) : The number to display as the app's icon badge. The default value of this property is 0, which means that no badge is displayed.
   * - `identifier` : A unique string to be used as the identifier for the notification.
   */
  presentLocalNotification = (details: Object) => {
    const sound = details.isSilent
      ? undefined
      : {
          name: details.soundName
        };
    const request = {
      identifier: details.identifier || Date().toString(),
      content: {
        title: details.alertTitle,
        body: details.alertBody,
        userInfo: details.userInfo,
        sound
      },
      trigger: {
        type: "timeInterval",
        timeInterval: 0.1
      }
    };
    RCTUserNotificationManager.addNotificationRequest(request);
  };

  /**
   * Schedules the localNotification for future presentation.
   *
   * details is an object containing:
   *
   * - `fireDate` : The date and time when the system should deliver the notification.
   * - `alertTitle` : The text displayed as the title of the notification alert.
   * - `alertBody` : The message displayed in the notification alert.
   * - `alertAction` : The "action" displayed beneath an actionable notification. Defaults to "view";
   * - `soundName` : The sound played when the notification is fired (optional).
   * - `isSilent`  : If true, the notification will appear without sound (optional).
   * - `category`  : The category of this notification, required for actionable notifications (optional).
   * - `userInfo` : An optional object containing additional notification data.
   * - `applicationIconBadgeNumber` (optional) : The number to display as the app's icon badge. Setting the number to 0 removes the icon badge.
   * - `repeatInterval` : The interval to repeat as a string.  Possible values: `minute`, `hour`, `day`, `week`, `month`, `year`.
   * - `identifier` : A unique string to be used as the identifier for the notification.
   */
  scheduleLocalNotification = (details: Object) => {
    const fireData = new Date(details.fireDate);
    const sound = details.isSilent
      ? undefined
      : {
          name: details.soundName
        };
    const request = {
      identifier: details.identifier || Date().toString(),
      content: {
        title: details.alertTitle,
        categoryIdentifier: details.category,
        body: details.alertBody,
        userInfo: details.userInfo,
        sound
      },
      trigger: {
        type: "timeInterval",
        timeInterval: fireData.getTime() - new Date().getTime()
      }
    };
    RCTUserNotificationManager.addNotificationRequest(request);
  };

  /**
   * Cancels all scheduled localNotifications
   */
  cancelAllLocalNotifications = () => {
    RCTUserNotificationManager.removeAllPendingNotificationRequests();
  };

  /**
   * Remove all delivered notifications from Notification Center
   */
  removeAllDeliveredNotifications = () => {
    RCTUserNotificationManager.removeAllDeliveredNotifications();
  };

  /**
   * Provides you with a list of the app’s notifications that are still displayed in Notification Center
   *
   * @param callback Function which receive an array of delivered notifications
   *
   *  A delivered notification is an object containing:
   *
   * - `identifier`  : The identifier of this notification.
   * - `title`  : The title of this notification.
   * - `body`  : The body of this notification.
   * - `category`  : The category of this notification, if has one.
   * - `userInfo`  : An optional object containing additional notification data.
   * - `thread-id`  : The thread identifier of this notification, if has one.
   */
  getDeliveredNotifications = (
    callback: (notifications: Array<Object>) => void
  ): void => {
    RCTUserNotificationManager.getDeliveredNotifications(callback);
  };

  /**
   * Removes the specified notifications from Notification Center
   *
   * @param identifiers Array of notification identifiers
   */
  removeDeliveredNotifications = (identifiers: Array<string>) => {
    RCTUserNotificationManager.removeDeliveredNotifications(identifiers);
  };

  /**
   * Sets the badge number for the app icon on the home screen
   */
  setApplicationIconBadgeNumber = (number: number) => {
    RCTUserNotificationManager.setApplicationIconBadgeNumber(number);
  };

  /**
   * Gets the current badge number for the app icon on the home screen
   */
  getApplicationIconBadgeNumber = (callback: Function) => {
    RCTUserNotificationManager.getApplicationIconBadgeNumber(callback);
  };

  /**
   * Cancel local notifications.
   *
   * Optionally restricts the set of canceled notifications to those
   * notifications whose `userInfo` fields match the corresponding fields
   * in the `userInfo` argument.
   */
  cancelLocalNotifications = () => {};

  /**
   * Gets the local notifications that are currently scheduled.
   */
  getScheduledLocalNotifications = (callback: Function) => {
    RCTUserNotificationManager.getPendingNotificationRequests(callback);
  };

  /**
   * Attaches a listener to remote or local notification events while the app is running
   * in the foreground or the background.
   *
   * Valid events are:
   *
   * - `notification` : Fired when a remote notification is received. The
   *   handler will be invoked with an instance of `UserNotificationIOS`.
   * - `register`: Fired when the user registers for remote notifications. The
   *   handler will be invoked with a hex string representing the deviceToken.
   * - `registrationError`: Fired when the user fails to register for remote
   *   notifications. Typically occurs when APNS is having issues, or the device
   *   is a simulator. The handler will be invoked with
   *   {message: string, code: number, details: any}.
   */
  addEventListener = (type: PushNotificationEventName, handler: Function) => {
    invariant(
      type === "notification" ||
        type === "register" ||
        type === "registrationError" ||
        type === "contentAvailableNotification",
      "IOSUserNotificationHandler only supports  `notification`, `register`, `registrationError`, and `contentAvailableNotification` events, received " +
        type
    );
    let listener;
    if (type === "contentAvailableNotification") {
      listener = ContentAvailableNotificationEmitter.addListener(
        DEVICE_SILENT_NOTIF_EVENT,
        notifData => {
          handler(new IOSUserNotification(notifData));
        }
      );
    } else if (type === "notification") {
      listener = UserNotificationEmitter.addListener(
        DEVICE_USER_NOTIF_EVENT,
        notifData => {
          handler(new IOSUserNotification(notifData));
        }
      );
      // HACK for now, we treat will present events as normal notifications
      const willPresentListener = UserNotificationEmitter.addListener(
        WILL_PRESENT_USER_NOTIF_EVENT,
        notifData => {
          handler(new IOSUserNotification(notifData));
        }
      );
      _notifHandlers.set("willPresentNotification", willPresentListener);
    } else if (type === "register") {
      listener = RemoteNotificationRegistrationEmitter.addListener(
        NOTIF_REGISTER_EVENT,
        registrationInfo => {
          handler(registrationInfo.deviceToken);
        }
      );
    } else if (type === "registrationError") {
      listener = RemoteNotificationRegistrationEmitter.addListener(
        NOTIF_REGISTRATION_ERROR_EVENT,
        errorInfo => {
          handler(errorInfo);
        }
      );
    }
    _notifHandlers.set(type, listener);
  };

  /**
   * Removes the event listener. Do this in `componentWillUnmount` to prevent
   * memory leaks
   */
  removeEventListener = (type: PushNotificationEventName) => {
    invariant(
      type === "notification" ||
        type === "register" ||
        type === "registrationError" ||
        type === "contentAvailableNotification",
      "IOSUserNotificationHandler only supports `notification`, `register`, `registrationError`, and `contentAvailableNotification` events received " +
        type
    );
    const listener = _notifHandlers.get(type);
    if (!listener) {
      return;
    }
    listener.remove();
    _notifHandlers.delete(type);
    if (type === "notification") {
      const willPresentListener = _notifHandlers.get("willPresentNotification");
      if (!willPresentListener) {
        return;
      }
      willPresentListener.remove();
      _notifHandlers.delete("willPresentNotification");
    }
  };

  /**
   * Requests notification permissions from iOS, prompting the user's
   * dialog box. By default, it will request all notification permissions, but
   * a subset of these can be requested by passing a map of requested
   * permissions.
   * The following permissions are supported:
   *
   *   - `alert`
   *   - `badge`
   *   - `sound`
   *
   * If a map is provided to the method, only the permissions with truthy values
   * will be requested.

   * This method returns a promise that will resolve when the user accepts,
   * rejects, or if the permissions were previously rejected. The promise
   * resolves to the current state of the permission.
   */
  requestPermissions = (permissions?: {
    alert?: boolean,
    badge?: boolean,
    sound?: boolean
  }): Promise<{
    alert: boolean,
    badge: boolean,
    sound: boolean
  }> => {
    let requestedPermissions = {};
    if (permissions) {
      requestedPermissions = {
        alert: !!permissions.alert,
        badge: !!permissions.badge,
        sound: !!permissions.sound
      };
    } else {
      requestedPermissions = {
        alert: true,
        badge: true,
        sound: true
      };
    }
    return RCTUserNotificationManager.requestPermissions(
      requestedPermissions
    ).then(() =>
      RCTRemoteNotificationRegistrationManager.registerForRemoteNotifications()
    );
  };

  /**
   * Unregister for all remote notifications received via Apple Push Notification service.
   *
   * You should call this method in rare circumstances only, such as when a new version of
   * the app removes support for all types of remote notifications. Users can temporarily
   * prevent apps from receiving remote notifications through the Notifications section of
   * the Settings app. Apps unregistered through this method can always re-register.
   */
  abandonPermissions = () => {
    RCTRemoteNotificationRegistrationManager.unregisterForRemoteNotifications();
  };

  /**
   * See what push permissions are currently enabled. `callback` will be
   * invoked with a `permissions` object:
   *
   *  - `alert` :boolean
   *  - `badge` :boolean
   *  - `sound` :boolean
   */
  checkPermissions = (callback: Permissions => void) => {
    invariant(typeof callback === "function", "Must provide a valid callback");
    RCTUserNotificationManager.checkPermissions(callback);
  };

  /**
   * This method returns a promise that resolves to either the notification
   * object if the app was launched by a push notification, or `null` otherwise.
   */
  getInitialNotification = (): Promise<?IOSUserNotification> => {
    return RCTUserNotificationManager.getInitialNotification().then(
      notification => notification && new IOSUserNotification(notification)
    );
  };

  addNotificationRequest = (notification: Object) => {
    RCTUserNotificationManager.addNotificationRequest(notification);
  };
}

module.exports = IOSUserNotificationHandler;
