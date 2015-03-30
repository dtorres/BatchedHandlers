//
//  BHBlockManager.h
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BHHandlerInvoker)(NSArray *arguments, id block); //Workaround to BHDemuxerBlock not working
typedef void(^BHResultHandler)(NSArray *arguments);

@interface BHBlockManager : NSObject

- (instancetype)initWithTarget:(id)target selector:(SEL)sel handlerInvoker:(BHHandlerInvoker)invoker;
- (instancetype)initWithTarget:(id)target selector:(SEL)sel queue:(dispatch_queue_t)queue  handlerInvoker:(BHHandlerInvoker)invoker NS_DESIGNATED_INITIALIZER;

- (void)performWithHandler:(id)block;
- (void)performWithArguments:(NSArray *)argArray handler:(id)block;

@end
