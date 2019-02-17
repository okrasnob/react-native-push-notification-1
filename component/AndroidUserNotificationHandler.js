"use strict";
// @flow

import {
  type Notification,
  type NotificationHandler,
  type PushNotificationEventName
} from "./types";

import AndroidUserNotification from "./AndroidUserNotification";

import { NativeModules, DeviceEventEmitter } from "react-native";

const RNPushNotification = NativeModules.RNPushNotification;

const DEVICE_NOTIF_EVENT = "notification";
const NOTIF_REGISTER_EVENT = "remoteNotificationsRegistered";
const CONTENT_AVAILABLE_EVENT = "contentAvailableNotification";

class AndroidNotificationHandler implements NotificationHandler {
  notifHandlers = new Map();

  getInitialNotification = function() {
    return RNPushNotification.getInitialNotification().then(function(
      notification
    ) {
      if (notification && notification.dataJSON) {
        return new AndroidUserNotification(notification.dataJSON);
      }
      return null;
    });
  };

  registerService = function(senderID: string) {
    RNPushNotification.registerService(senderID);
  };

  cancelLocalNotifications = function(details: Object) {
    RNPushNotification.cancelLocalNotifications(details);
  };

  cancelAllLocalNotifications = function() {
    RNPushNotification.cancelAllLocalNotifications();
  };

  presentLocalNotification = function(details: Object) {
    RNPushNotification.presentLocalNotification(details);
  };

  scheduleLocalNotification = function(details: Object) {
    RNPushNotification.scheduleLocalNotification(details);
  };

  setApplicationIconBadgeNumber = function(number: number) {
    if (!RNPushNotification.setApplicationIconBadgeNumber) {
      return;
    }
    RNPushNotification.setApplicationIconBadgeNumber(number);
  };

  abandonPermissions = function() {
    /* Void */
  };

  checkPermissions = function(callback: Function) {
    /* Void */
  };

  addEventListener = function(type: string, handler: Function) {
    var listener;
    if (type === "notification") {
      listener = DeviceEventEmitter.addListener(DEVICE_NOTIF_EVENT, function(
        notifData
      ) {
        var data = new AndroidUserNotification(notifData.dataJSON);
        handler(data);
      });
    } else if (type === "register") {
      listener = DeviceEventEmitter.addListener(NOTIF_REGISTER_EVENT, function(
        registrationInfo
      ) {
        handler(registrationInfo.deviceToken);
      });
    } else if (type === "contentAvailableNotification") {
      listener = DeviceEventEmitter.addListener(
        CONTENT_AVAILABLE_EVENT,
        function(notifData) {
          var notificationData = new AndroidUserNotification(
            notifData.dataJSON
          );
          handler(notificationData);
        }
      );
    }

    this.notifHandlers.set(type, listener);
  };

  removeEventListener = function(type: PushNotificationEventName) {
    var listener = this.notifHandlers.get(type);
    if (!listener) {
      return;
    }
    listener.remove();
    this.notifHandlers.delete(type);
  };

  registerNotificationActions = function(details: string[]) {
    RNPushNotification.registerNotificationActions(details);
  };
}

module.exports = AndroidNotificationHandler;
