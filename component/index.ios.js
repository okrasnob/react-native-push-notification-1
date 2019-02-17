"use strict";
// @flow

import { AppState, NativeModules } from "react-native";

const getNotificationComponent = NativeModules => {
  // We should only require the version that we want to use
  if (
    NativeModules.UserNotificationManager != null &&
    NativeModules.UserNotificationManager.isUNUserNotificationCenterAvailable
  ) {
    const IOSUserNotificationHandler = require("./IOSUserNotificationHandler");
    return new IOSUserNotificationHandler();
  }
  if (NativeModules.LegacyUserNotificationManager != null) {
    const IOSLegacyUserNotificationHandler = require("./IOSLegacyUserNotificationHandler");
    return new IOSLegacyUserNotificationHandler();
  }
  return null;
};

module.exports = {
  state: AppState,
  component: getNotificationComponent(NativeModules)
};
