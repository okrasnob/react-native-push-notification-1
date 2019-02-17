// @flow

import { type Notification, type FetchResult } from "./types";

class AndroidUserNotification implements Notification {
  _rawNotification: Object;

  constructor(dataJSON: string) {
    this._rawNotification = JSON.parse(dataJSON);
  }
  getRawNotification = (): Object => {
    return this._rawNotification;
  };
  getForeground = (): boolean => {
    return this._rawNotification.foreground;
  };
  getNotificationType = (): string => {
    return this._rawNotification.notificationType;
  };
  getUserInteraction = (): boolean => {
    return this._rawNotification.userInteraction;
  };
  finish = (): void => {};
}

module.exports = AndroidUserNotification;
