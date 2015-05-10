//
//  BHDemuxerBlock.m
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import "BHDemuxerBlock.h"
#import <objc/objc-runtime.h>
#import <libkern/OSAtomic.h>

enum {
    BH_BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BH_BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BH_BLOCK_IS_GLOBAL =         (1 << 28),
    BH_BLOCK_HAS_STRET =         (1 << 29), // IFF BH_BLOCK_HAS_SIGNATURE
    BH_BLOCK_HAS_SIGNATURE =     (1 << 30),
};

struct BH_BLOCK_descriptor_1 {
    unsigned long int reserved;         // NULL
    unsigned long int size;         // sizeof(struct BH_BLOCK_literal_1)
    void *rest[1];
};

struct BH_BLOCK_literal_1 {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct BH_BLOCK_descriptor_1 *descriptor;
    // imported variables
};

const char *BHBlockSignature(id blockObj)
{
    struct BH_BLOCK_literal_1 *block = (__bridge void *)blockObj;
    struct BH_BLOCK_descriptor_1 *descriptor = block->descriptor;
    
    assert(block->flags & BH_BLOCK_HAS_SIGNATURE);
    
    int index = 0;
    if(block->flags & BH_BLOCK_HAS_COPY_DISPOSE)
        index += 2;
    
    return descriptor->rest[index];
}

@interface BHDemuxerBlock () {
    int _flags;
    int _reserved;
    IMP _invoke;
    struct BH_BLOCK_descriptor_1 *_descriptor;
    
    @public
    BHBlocksRetriever _blockRetriever;
    int32_t _executed;
}

@end

#define BHINVOKE_NSInvocation __BHDemuxer_IS_CALLING_BLOCKS
#define BHINVOKE_block_t _BHDemuxer_IS_CALLING_BLOCKS_

NS_INLINE void BHEnforceOnce(BHDemuxerBlock *demuxBlock) {
    if (!OSAtomicCompareAndSwap32(0, 1, &(demuxBlock->_executed))) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Block can only be called once" userInfo:nil] raise];
    }
}

void BHINVOKE_NSInvocation(BHDemuxerBlock *demuxBlock, ...) {
    BHEnforceOnce(demuxBlock);
    NSArray *blocksToInvoke = demuxBlock->_blockRetriever();
    if (blocksToInvoke.count == 0) return;
    
    NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:BHBlockSignature(demuxBlock)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:blockSignature];
    
    va_list argp;
    va_start(argp, demuxBlock);
    for (int i = 1; i < blockSignature.numberOfArguments; i++) {
        void *argument = va_arg(argp, void *);
        [invocation setArgument:&argument atIndex:i];
    }
    va_end(argp);
    
    for (id aBlock in blocksToInvoke) {
        [invocation invokeWithTarget:aBlock];
    }
}

void BHINVOKE_block_t(BHDemuxerBlock *demuxBlock) {
    BHEnforceOnce(demuxBlock);
    NSArray *blocksToInvoke = demuxBlock->_blockRetriever();
    if (blocksToInvoke.count == 0) return;

    for (dispatch_block_t block in blocksToInvoke) {
        block();
    }
}

@implementation BHDemuxerBlock

- (instancetype)initWithSampleBlock:(id)aBlock blockRetriever:(BHBlocksRetriever)retriever
{
    if (self = [super init]) {
        struct BH_BLOCK_literal_1 *block = (__bridge struct BH_BLOCK_literal_1 *)(aBlock);
        // NB: The bottom 16 bits represent the block's retain count
        _flags = block->flags & ~0xFFFF;
        _descriptor = malloc(sizeof(struct BH_BLOCK_descriptor_1));
        _descriptor->size = class_getInstanceSize([self class]);
        
        int index = 0;
        if (_flags & BH_BLOCK_HAS_COPY_DISPOSE)
            index += 2;
        
        const char *blockSig = BHBlockSignature(aBlock);
        _descriptor->rest[index] = (void *)blockSig;
        
        _blockRetriever = [retriever copy];
        _executed = 0;
        
        NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:blockSig];

        if (blockSignature.numberOfArguments > 1) {
            /**
             I... don't know why, but otherwise the object is not retained...
             But... it does get released O.o */
            CFRetain((__bridge CFTypeRef)(self));
            _invoke = (IMP)&BHINVOKE_NSInvocation;
        } else {
            /**
             dispatch_queue_* don't retain but do release.
             OTOH, we can't know if this block will be called inside another which does a normal retain/release
             cycle.
             
             Therefore we wrap self to ensure a predictable case.
             */
            _invoke = (IMP)&BHINVOKE_block_t;
            id wasSelf = self;
            self = (id)^{((dispatch_block_t)wasSelf)();};
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (void)dealloc
{
    free(_descriptor);
}


@end
