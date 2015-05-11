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
 @abstract Set a sample handler, used to create the handler returned by @c addHandler:forKey
 
 @param handler A sample handler with the same interface as those added
 @param key The key used to group the handlers
 
 @note This method is only necessary if you allow @c NULL handlers for a certain key.
 */
- (void)setSampleHandler:(id)handler forKey:(id <NSCopying>)key;

/**
 @abstract Add a handler to a batch group
 
 @param handler A block to be notified when work is done
 @param key The key used to group the handlers
 
 @return A block of the same interface to call when work is completed or nil is work in progress.
 
 @note Prefer @b BHManagerAddHandler as it provides type safety for the handler.
 */
- (id)addHandler:(id)handler forKey:(id <NSCopying>)key;

@end

/**
 @abstract Add a handler to a batch group
 
 @param manager The manager of the handlers.
 @param handler A block to be notified when work is done
 @param key The key used to group the handlers
 
 @return A block of the same interface to call when work is completed or nil is work in progress.
 
 @see -addHandler:forKey:
 */
#define BHManagerAddHandler(manager, handler, key) \
(typeof(handler))[manager addHandler:handler forKey:key]