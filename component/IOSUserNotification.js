// @flow

import { type Notification, type FetchResult } from "./types";

const NativeModules = require("react-native").NativeModules;
const RCTContentAvailableNotificationManager =
  NativeModules.ContentAvailableNotificationManager;

class IOSUserNotification implements Notification {
  _rawNotification: Object;
  _isRemote: boolean;
  _remoteNotificationCompleteCallbackCalled: boolean = false;
  _notificationId: ?string = null;
  /**
   * You will never need to instantiate `UserNotificationIOS` yourself.
   * Listening to the `notification` event and invoking
   * `getInitialNotification` is sufficient
   */
  constructor(nativeNotif: Object) {
    this._remoteNotificationCompleteCallbackCalled = false;

    this._isRemote = nativeNotif.remote;
    if (this._isRemote) {
      this._notificationId = nativeNotif.notificationId;
    }

    this._rawNotification = nativeNotif;
  }

  /**
   * This method is available for remote notifications that have been received via:
   * `application:didReceiveRemoteNotification:fetchCompletionHandler:`
   * https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationDelegate_Protocol/#//apple_ref/occ/intfm/UIApplicationDelegate/application:didReceiveRemoteNotification:fetchCompletionHandler:
   *
   * Call this to execute when the remote notification handling is complete. When
   * calling this block, pass in the fetch result value that best describes
   * the results of your operation. You *must* call this handler and should do so
   * as soon as possible. For a list of possible values, see `IOSUserNotificationHandler.FetchResult`.
   *
   * If you do not call this method your background remote notifications could
   * be throttled, to read more about it see the above documentation link.
   */
  finish = (fetchResult: FetchResult) => {
    if (
      !this._isRemote ||
      !this._notificationId ||
      this._remoteNotificationCompleteCallbackCalled
    ) {
      return;
    }
    this._remoteNotificationCompleteCallbackCalled = true;

    RCTContentAvailableNotificationManager.onFinishRemoteNotification(
      this._notificationId,
      fetchResult
    );
  };

  getForeground = (): boolean => {
    return this._rawNotification.foreground == true;
  };

  getNotificationType = (): string => {
    return this._rawNotification.notificationType;
  };

  getUserInteraction = (): boolean => {
    return !this.getForeground() && this.getNotificationType() != "iOS-silent";
  };

  getRawNotification = (): Object => {
    return this._rawNotification;
  };
}

module.exports = IOSUserNotification;
