//
//  BHManager.h
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BHManagerAddHandler(manager, handler, key) \
 (typeof(handler))[manager addHandler:handler forKey:key]

@interface BHManager : NSObject

- (void)setSampleHandler:(id)handler forKey:(id <NSCopying>)key;
- (id)addHandler:(id)handler forKey:(id <NSCopying>)key;

@end
