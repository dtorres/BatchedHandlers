//
//  BHBlockManager.m
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import "BHBlockManager.h"
#import "BHDemuxerBlock.h"

@interface BHBlockManager ()

@property (nonatomic, readonly) id target;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, readonly) BHHandlerInvoker invoker;
@property (nonatomic, readonly) dispatch_queue_t serialQueue;
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, getter=isExecuting) NSMutableDictionary *argumentsHandlers;

@end

@implementation BHBlockManager

- (instancetype)initWithTarget:(id)target selector:(SEL)sel queue:(dispatch_queue_t)queue handlerInvoker:(BHHandlerInvoker)invoker
{
    NSParameterAssert(target);
    NSParameterAssert(sel);
    NSParameterAssert(queue);
    if (self = [super init]) {
        _target = target;
        _selector = sel;
        _invoker = invoker;
        _queue = queue;
        _serialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _argumentsHandlers = [NSMutableDictionary new];
    }
    return self;
}

- (instancetype)initWithTarget:(id)target selector:(SEL)sel handlerInvoker:(BHHandlerInvoker)invoker
{
    return [self initWithTarget:target selector:sel queue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT) handlerInvoker:invoker];
}

- (NSMutableArray *)_handlersForArguments:(NSArray *)arguments
{
    NSMutableArray *state = [self.argumentsHandlers objectForKey:arguments];
    if (!state) {
        state = [NSMutableArray new];
        [self.argumentsHandlers setObject:state forKey:arguments];
    }
    return state;
}

- (void)performWithHandler:(id)block
{
    [self performWithArguments:[NSArray array] handler:block];
}

- (void)performWithArguments:(NSArray *)argArray handler:(id)block
{
    dispatch_async(self.serialQueue, ^{
        NSMutableArray *handlers = [self _handlersForArguments:argArray];
        [handlers addObject:block];
        if (handlers.count == 1) {
            dispatch_async(self.queue, ^{
                [self _performSelectorWithArguments:argArray];
            });
        }
    });
}

- (void)_performSelectorWithArguments:(NSArray *)arguments
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self.target methodSignatureForSelector:self.selector]];
    invocation.target = self.target;
    invocation.selector = self.selector;
    
    //Set all the arguments
    NSUInteger index = 2;
    for (id argument in arguments) {
        void *anArg = (void *)&argument;
        if ([argument isKindOfClass:[NSValue class]]) {
            anArg = [argument pointerValue];
        } else if ([argument isKindOfClass:[NSNull class]]) {
            anArg = nil;
        }
        [invocation setArgument:anArg atIndex:index];
        index++;
    }
    
//Set the handler the selector has to invoke
//    id blockDemuxer = [[BHDemuxerBlock alloc] initWithSampleBlock:[[self.argumentsHandlers objectForKey:arguments] firstObject] blockRetriever:^NSArray *{
//        __block NSArray *handlers;
//        dispatch_sync(self.serialQueue, ^{
//            handlers = [self.argumentsHandlers objectForKey:arguments];
//            [self.argumentsHandlers removeObjectForKey:arguments];
//        });
//        return handlers;
//    } queue:self.queue];
    
    void(^handlerInvoker)(NSArray *) = ^(NSArray *resultArguments) {
        __block NSArray *handlers;
        dispatch_sync(self.serialQueue, ^{
            handlers = [self.argumentsHandlers objectForKey:arguments];
            [self.argumentsHandlers removeObjectForKey:arguments];
        });
        for (id block in handlers) {
            dispatch_async(self.queue, ^{
                self.invoker(resultArguments, block);
            });
        }
    };
    [invocation setArgument:&handlerInvoker atIndex:index];
    
    [invocation invoke];
}

@end
