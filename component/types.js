// @flow

/**
 * An event emitted by PushNotificationIOS.
 */
// eslint-disable-next-line no-undef
export type PushNotificationEventName = $Enum<{
  /**
   * Fired when a remote notification is received. The handler will be invoked
   * with an instance of `PushNotificationIOS`.
   */
  notification: "notification",
  /**
   * Fired when the user registers for remote notifications. The handler will be
   * invoked with a hex string representing the deviceToken.
   */
  register: "register",
  /**
   * Fired when the user fails to register for remote notifications. Typically
   * occurs when APNS is having issues, or the device is a simulator. The
   * handler will be invoked with {message: string, code: number, details: any}.
   */
  registrationError: "registrationError",
  /**
   * Fired when a silent remote notification is received. Must call finish() on the
   * notification to inform the OS that the fetch is complete.
   */
  contentAvailableNotification: "contentAvailableNotification"
}>;

export type FetchResult =
  | "UIBackgroundFetchResultNewData"
  | "UIBackgroundFetchResultNoData"
  | "UIBackgroundFetchResultFailed";

export interface Notification {
  getRawNotification: () => Object;
  getForeground: () => boolean;
  getNotificationType: () => string;
  getUserInteraction: () => boolean;
}

export interface IOSNotification extends Notification {
  finish: FetchResult => void;
}

export type Permissions = {
  alert: boolean,
  badge: boolean,
  sound: boolean
};

export interface NotificationHandler {
  presentLocalNotification: Object => void;
  scheduleLocalNotification: Object => void;
  cancelAllLocalNotifications: () => void;
  cancelLocalNotifications: Object => void;
  addEventListener: (PushNotificationEventName, Function) => void;
  removeEventListener: PushNotificationEventName => void;

  abandonPermissions: () => void;
  checkPermissions: Function => void;
  getInitialNotification: () => Promise<?Notification>;

  // ios only
  removeDeliveredNotifications?: (Array<string>) => void;
  getDeliveredNotifications?: ((notifications: Array<Object>) => void) => void;
  getApplicationIconBadgeNumber?: Function => void;
  getScheduledLocalNotifications?: Function => void;
  removeAllDeliveredNotifications?: () => void;
  requestPermissions?: ({
    alert?: boolean,
    badge?: boolean,
    sound?: boolean
  }) => Promise<Permissions>;

  // android only
  registerService?: string => void;
}
