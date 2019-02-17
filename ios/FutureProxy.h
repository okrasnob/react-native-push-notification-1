//
//  FutureProxy.h
//  RCTPushNotification
//
//  Created by dmueller39 on 11/15/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

// because the native modules are not available at start up, we use a FutureProxy
// which will proxy as the class we provide it with, and then forward those

@interface FutureProxy<ObjectType>: NSProxy

-(instancetype _Nonnull )initWithClass:(Class _Nonnull)clazz;

-(void)addTarget:(id _Nonnull )target;
-(void)removeTarget:(id _Nonnull )target;

-(void)flushInvocations;

@end
