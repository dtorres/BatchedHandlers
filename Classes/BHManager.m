//
//  BHManager.m
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import "BHManager.h"
#import "BHDemuxerBlock.h"

extern const char *BHBlockSignature(id blockObj); //Implemented in BHDemuxerBlock.m

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
    __block BOOL retBatchedBlock;
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
        retBatchedBlock = emptyHandlers;
    });
    return retBatchedBlock ? [self _batchedHandlerWithSampleBlock:inBlock key:key] : nil;
}

- (void)setSampleHandler:(id)handler forKey:(id<NSCopying>)key
{
    NSParameterAssert(handler);
    NSParameterAssert(key);
    self.sampleBlocks[key] = handler;
}

- (id)_batchedHandlerWithSampleBlock:(id)block key:(id <NSCopying>)key
{
    block = block ? : self.sampleBlocks[key];
    if (block == nil) {
        NSString *reason = [NSString stringWithFormat:@"You must provide a sample block for key \"%@\" if you accept NULL handlers", key];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil] raise];
    }
    id blockDemuxer = [[BHDemuxerBlock alloc] initWithSampleBlock:block blockRetriever:^NSArray *{
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
    return blockDemuxer;
}

@end
