/**
 * @providesModule Notifications
 * @flow
 */

"use strict";

import { Platform } from "react-native";
import { state as AppState, component as RNNotifications } from "./component";
import {
  type Notification,
  type NotificationHandler,
  type Permissions
} from "./component/types";

export class Notifications {
  handler: NotificationHandler = (RNNotifications: any);
  onRegister: (({ token: string, os: string }) => void) | boolean = false;
  onError: boolean = false;
  onNotification: (Notification => void) | false = false;
  onContentAvailableNotification: (Notification => void) | false = false;
  isLoaded: boolean = false;

  isPermissionsRequestPending: boolean = false;
  senderID: ?string = null;

  permissions: {
    alert?: boolean,
    badge?: boolean,
    sound?: boolean
  } = {
    alert: true,
    badge: true,
    sound: true
  };

  /**
   * Configure local and remote notifications
   * @param {Object}		options
   * @param {function}	options.onRegister - Fired when the user registers for remote notifications.
   * @param {function}	options.onNotification - Fired when a remote notification is received.
   * @param {function} 	options.onError - None
   * @param {Object}		options.permissions - Permissions list
   * @param {Boolean}		options.requestPermissions - Check permissions when register
   */
  configure = (options: Object) => {
    if (typeof options.onRegister !== "undefined") {
      this.onRegister = options.onRegister;
    }

    if (typeof options.onError !== "undefined") {
      this.onError = options.onError;
    }

    if (typeof options.onNotification !== "undefined") {
      this.onNotification = options.onNotification;
    }

    if (typeof options.permissions !== "undefined") {
      this.permissions = options.permissions;
    }

    if (typeof options.senderID !== "undefined") {
      this.senderID = options.senderID;
    }

    if (typeof options.onContentAvailableNotification !== "undefined") {
      this.onContentAvailableNotification =
        options.onContentAvailableNotification;
    }

    if (this.isLoaded === false) {
      this.handler.addEventListener("register", this._onRegister);
      this.handler.addEventListener("notification", this._onNotification);
      this.handler.addEventListener(
        "contentAvailableNotification",
        this._onContentAvailableNotification
      );

      this.isLoaded = true;
    }

    if (options.requestPermissions !== false) {
      this._requestPermissions();
    }
  };

  /* Unregister */
  unregister = function() {
    this.handler.removeEventListener("register", this._onRegister);
    this.handler.removeEventListener("notification", this._onNotification);
    this.handler.removeEventListener(
      "contentAvailableNotification",
      this._onContentAvailableNotification
    );
    this.isLoaded = false;
  };

  /**
   * Local Notifications
   * @param {Object}		details
   * @param {String}		details.title  -  The title displayed in the notification alert.
   * @param {String}		details.message - The message displayed in the notification alert.
   * @param {String}		details.ticker -  ANDROID ONLY: The ticker displayed in the status bar.
   * @param {Object}		details.userInfo -  iOS ONLY: The userInfo used in the notification alert.
   */
  localNotification = (details: Object) => {
    if (Platform.OS === "ios") {
      // https://developer.apple.com/reference/uikit/uilocalnotification

      let soundName = details.soundName ? details.soundName : "default"; // play sound (and vibrate) as default behaviour

      if (details.hasOwnProperty("playSound") && !details.playSound) {
        soundName = ""; // empty string results in no sound (and no vibration)
      }

      // for valid fields see: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html
      // alertTitle only valid for apple watch: https://developer.apple.com/library/ios/documentation/iPhone/Reference/UILocalNotification_Class/#//apple_ref/occ/instp/UILocalNotification/alertTitle

      this.handler.presentLocalNotification({
        alertTitle: details.title,
        alertBody: details.message,
        alertAction: details.alertAction,
        category: details.category,
        soundName: soundName,
        applicationIconBadgeNumber: details.number,
        userInfo: details.userInfo
      });
    } else {
      this.handler.presentLocalNotification(details);
    }
  };

  /**
   * Local Notifications Schedule
   * @param {Object}		details (same as localNotification)
   * @param {Date}		details.date - The date and time when the system should deliver the notification
   */
  localNotificationSchedule = (details: Object) => {
    if (Platform.OS === "ios") {
      let soundName = details.soundName ? details.soundName : "default"; // play sound (and vibrate) as default behaviour

      if (details.hasOwnProperty("playSound") && !details.playSound) {
        soundName = ""; // empty string results in no sound (and no vibration)
      }

      const iosDetails = {
        fireDate: details.date.toISOString(),
        alertTitle: details.title,
        alertBody: details.message,
        category: details.category,
        soundName: soundName,
        userInfo: details.userInfo,
        repeatInterval: details.repeatType,
        applicationIconBadgeNumber: undefined
      };

      if (details.number) {
        iosDetails.applicationIconBadgeNumber = parseInt(details.number, 10);
      }

      // ignore Android only repeatType
      if (!details.repeatType || details.repeatType === "time") {
        delete iosDetails.repeatInterval;
      }
      this.handler.scheduleLocalNotification(iosDetails);
    } else {
      details.fireDate = details.date.getTime();
      delete details.date;
      // ignore iOS only repeatType
      if (["year", "month"].includes(details.repeatType)) {
        delete details.repeatType;
      }
      this.handler.scheduleLocalNotification(details);
    }
  };

  /* Internal Functions */
  _onRegister = (token: string) => {
    const onRegister = this.onRegister;
    if (typeof onRegister === "function") {
      onRegister({
        token: token,
        os: Platform.OS
      });
    }
  };

  _onContentAvailableNotification = (notificationData: Object) => {
    if (this.onContentAvailableNotification !== false) {
      this.onContentAvailableNotification(notificationData);
    }
  };

  _onNotification = (data: Object) => {
    if (this.onNotification !== false) {
      this.onNotification(data);
    }
  };

  /* onResultPermissionResult */
  _onPermissionResult = function() {
    this.isPermissionsRequestPending = false;
  };

  // Prevent requestPermissions called twice if ios result is pending
  _requestPermissions = function() {
    if (Platform.OS === "ios") {
      if (
        typeof this.handler.requestPermissions === "function" &&
        this.isPermissionsRequestPending === false
      ) {
        this.isPermissionsRequestPending = true;
        const promise = this.handler
          .requestPermissions(this.permissions)
          .then(this._onPermissionResult.bind(this))
          .catch(this._onPermissionResult.bind(this));
      }
    } else if (
      this.senderID != null &&
      typeof this.handler.registerService === "function"
    ) {
      return this.handler.registerService(this.senderID);
    }
  };

  // Stock requestPermissions function
  requestPermissions = function() {
    if (typeof this.handler.requestPermissions === "function") {
      return this.handler.requestPermissions(this.permissions);
    } else if (
      this.senderID != null &&
      typeof this.handler.registerService === "function"
    ) {
      return this.handler.registerService(this.senderID);
    }
  };

  /* Fallback functions */
  subscribeToTopic = function(topic: Object) {
    return this.handler.subscribeToTopic(topic);
  };

  presentLocalNotification = function(notification: Object) {
    return this.handler.presentLocalNotification(notification);
  };

  scheduleLocalNotification = function(notification: Object) {
    return this.handler.scheduleLocalNotification(notification);
  };

  cancelLocalNotifications = function(notification: Object) {
    return this.handler.cancelLocalNotifications(notification);
  };

  clearLocalNotification = function(notification: Object) {
    return this.handler.clearLocalNotifications(notification);
  };

  cancelAllLocalNotifications = function() {
    return this.handler.cancelAllLocalNotifications();
  };

  setApplicationIconBadgeNumber = function(badgeNumber: number) {
    return this.handler.setApplicationIconBadgeNumber(badgeNumber);
  };

  getApplicationIconBadgeNumber = function(): Promise<number> {
    return this.handler.getApplicationIconBadgeNumber();
  };

  // pops the initial notification and calls the handler when it is complete
  // notifications are received via the onNotification callback
  popInitialNotification = (handler: () => void) => {
    const onInitialNotification = this._onNotification;
    this.handler.getInitialNotification().then(function(result: ?Object) {
      if (result != null) {
        onInitialNotification(result);
      }
      if (typeof handler === "function") {
        handler();
      }
    });
  };

  abandonPermissions = function() {
    return this.handler.abandonPermissions();
  };

  checkPermissions = function(callback: Permissions => void) {
    return this.handler.checkPermissions(callback);
  };

  registerNotificationActions = function(actions: string[]) {
    return this.handler.registerNotificationActions(actions);
  };

  nativeNotificationSchedule = function(request: Object) {
    // Only available for iOS
    return this.handler.addNotificationRequest(request);
  };
}

export default new Notifications();
