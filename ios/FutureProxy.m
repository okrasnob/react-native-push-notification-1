//
//  FutureProxy.m
//  RCTPushNotification
//
//  Created by dmueller39 on 11/15/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "FutureProxy.h"

@interface WeakReference : NSObject {
  __weak id nonretainedObjectValue;
}

+ (instancetype) weakReferenceWithObject:(id) object;

- (id) nonretainedObjectValue;

@end

@implementation WeakReference

+ (WeakReference *) weakReferenceWithObject:(id) object {
  return [[WeakReference alloc] initWithObject:object];
}

-(instancetype)initWithObject:(id) object {
  if (self = [super init]) {
    nonretainedObjectValue = object;
  }
  return self;
}

- (id) nonretainedObjectValue { return nonretainedObjectValue; }

@end

@implementation FutureProxy{
  Class _clazz;
  NSMutableSet<WeakReference*>* _targets;
  NSMutableArray* _invocations;
}

-(instancetype)initWithClass:(Class _Nonnull)clazz {
  _clazz = clazz;
  _invocations = [NSMutableArray array];
  _targets = [NSMutableSet set];
  return self;
}

-(void)addTarget:(id _Nonnull )target{
  [_targets addObject:[WeakReference weakReferenceWithObject:target]];
}
-(void)removeTarget:(id _Nonnull )target {
  NSSet* matches = [_targets objectsPassingTest:^BOOL(WeakReference * _Nonnull obj, BOOL * _Nonnull stop) {
    return obj.nonretainedObjectValue == target || obj.nonretainedObjectValue == nil;
  }];
  [_targets minusSet:matches];
}

-(void)flushInvocations{
  @synchronized(_invocations) {
    for(NSInvocation* invocation in _invocations) {
      for (WeakReference* target in _targets) {
        if (target.nonretainedObjectValue != nil) {
          [invocation invokeWithTarget:target.nonretainedObjectValue];
        }
      }
    }
    [_invocations removeAllObjects];
  }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
  return [_clazz instanceMethodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation{
  if ([_targets count] > 0) {
    for (WeakReference* target in _targets) {
      [invocation invokeWithTarget:target.nonretainedObjectValue];
    }
  } else {
    [invocation retainArguments];
    @synchronized(_invocations) {
      [_invocations addObject:invocation];
    }
  }
}

-(BOOL)respondsToSelector:(SEL)aSelector{
  return [_clazz instancesRespondToSelector:aSelector];
}

@end
