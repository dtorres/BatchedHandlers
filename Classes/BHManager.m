//
//  BHManager.m
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import "BHManager.h"

typedef NSArray *(^BHBlocksRetriever)(void);

@interface _BHPromiseArray : NSProxy {
    BHBlocksRetriever _retrieverBlock;
    NSArray *_actualArray;
}

- (instancetype)initWithArrayRetriever:(BHBlocksRetriever)retriever;

@end

@interface BHManager ()

@property (nonatomic, readonly) dispatch_queue_t serialQueue;
@property (nonatomic, readonly) NSMutableDictionary *handlersPerKey;
@property (nonatomic, readonly) NSMutableDictionary *sampleBlocks;

@end

@implementation BHManager

- (instancetype)init
{
    if (self = [super init]) {
        _serialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _handlersPerKey = [NSMutableDictionary new];
        _sampleBlocks = [NSMutableDictionary new];
    }
    return self;
}

NS_INLINE NSMutableArray *BHHandlersForKey(BHManager *self, id <NSCopying> key) {
    NSMutableArray *state = [self.handlersPerKey objectForKey:key];
    if (!state) {
        state = [NSMutableArray new];
        [self.handlersPerKey setObject:state forKey:key];
    }
    return state;
}

- (id)addHandler:(id)inBlock forKey:(id<NSCopying>)key
{
    NSParameterAssert(key);
    __block BOOL retPromiseArray;
    dispatch_sync(self.serialQueue, ^{
        id aBlock = inBlock;
        NSMutableArray *handlers = BHHandlersForKey(self, key);
        BOOL emptyHandlers = (handlers.count == 0);
        if (aBlock == nil && emptyHandlers) {
            aBlock = [NSNull null];
        }
        if (aBlock) {
            [handlers addObject:aBlock];
        }
        retPromiseArray = emptyHandlers;
    });
    
    if (retPromiseArray) {
        return [[_BHPromiseArray alloc] initWithArrayRetriever:^NSArray *{
            __block NSMutableArray *handlers;
            dispatch_sync(self.serialQueue, ^{
                handlers = [self.handlersPerKey objectForKey:key];
                [self.handlersPerKey removeObjectForKey:key];
            });
            if ([handlers.firstObject isKindOfClass:[NSNull class]]) {
                [handlers removeObjectAtIndex:0];
            }
            return handlers;
        }];
    }
    return nil;
}

@end

@implementation _BHPromiseArray

- (instancetype)initWithArrayRetriever:(BHBlocksRetriever)retriever
{
    NSParameterAssert(retriever);
    _retrieverBlock = retriever;
    
    return self;
}

- (Class)class
{
    return NSArray.class;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return _actualArray ? [_actualArray methodSignatureForSelector:sel] : [NSArray instanceMethodSignatureForSelector:sel];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    NSArray *array = _actualArray;
    if (!array) {
        array = [_retrieverBlock() copy];
        _retrieverBlock = nil;
        _actualArray = array;
    }
    return array;
}

@end
