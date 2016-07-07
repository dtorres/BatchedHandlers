//
//  BHManager.h
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHManager : NSObject

/**
 @abstract Add a handler to a batch group
 
 @param handler A block to be notified when work is done
 @param key The key used to group the handlers
 
 @return A @c promise array to access all pending handlers.
 
 @note The returned array is also indication that you must perform the work. May return nil, in which case in most cases you should just end work from your method.
 */
- (NSArray * _Nullable)addHandler:(id _Nullable)handler forKey:(_Nonnull id <NSCopying>)key NS_SWIFT_NAME(add(handler:forKey:));

@end
