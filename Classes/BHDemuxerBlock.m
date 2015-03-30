//
//  BHDemuxerBlock.m
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import "BHDemuxerBlock.h"
#import <objc/objc-runtime.h>

enum {
    TD_BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    TD_BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    TD_BLOCK_IS_GLOBAL =         (1 << 28),
    TD_BLOCK_HAS_STRET =         (1 << 29), // IFF TD_BLOCK_HAS_SIGNATURE
    TD_BLOCK_HAS_SIGNATURE =     (1 << 30),
};

struct TD_Block_descriptor_1 {
    unsigned long int reserved;         // NULL
    unsigned long int size;         // sizeof(struct TD_Block_literal_1)
    void *rest[1];
};

struct TD_Block_literal_1 {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct TD_Block_descriptor_1 *descriptor;
    // imported variables
};

static const char *BlockSig(id blockObj)
{
    struct TD_Block_literal_1 *block = (__bridge void *)blockObj;
    struct TD_Block_descriptor_1 *descriptor = block->descriptor;
    
    assert(block->flags & TD_BLOCK_HAS_SIGNATURE);
    
    int index = 0;
    if(block->flags & TD_BLOCK_HAS_COPY_DISPOSE)
        index += 2;
    
    return descriptor->rest[index];
}

static void *BlockImpl(id blockObj)
{
    struct TD_Block_literal_1 *block = (__bridge void *)blockObj;
    return block->invoke;
}

@interface NSInvocation (PrivateHack)
- (void)invokeUsingIMP: (IMP)imp;
@end

@interface BHDemuxerBlock () {
    int _flags;
    int _reserved;
    IMP _invoke;
    struct TD_Block_descriptor_1 *_descriptor;
    
    BHBlocksRetriever _blockRetriever;
    dispatch_queue_t _queue;
}

@end

@implementation BHDemuxerBlock

- (instancetype)initWithSampleBlock:(id)aBlock blockRetriever:(BHBlocksRetriever)retriever queue:(dispatch_queue_t)queue
{
    if (self = [super init]) {
        struct TD_Block_literal_1 *block = (__bridge struct TD_Block_literal_1 *)(aBlock);
        // NB: The bottom 16 bits represent the block's retain count
        _flags = block->flags & ~0xFFFF;
        _descriptor = malloc(sizeof(struct TD_Block_descriptor_1));
        _descriptor->size = class_getInstanceSize([self class]);
        
        int index = 0;
        if (_flags & TD_BLOCK_HAS_COPY_DISPOSE)
            index += 2;
        
        _descriptor->rest[index] = (void *)BlockSig(aBlock);
        
        if (_flags & TD_BLOCK_HAS_STRET)
            _invoke = (IMP) _objc_msgForward_stret;
        else
            _invoke = _objc_msgForward;
        
        _blockRetriever = [retriever copy];
        _queue = queue;
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)sel
{
    const char *types = BlockSig(self);
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes: types];
    while([sig numberOfArguments] < 2)
    {
        types = [[NSString stringWithFormat: @"%s%s", types, @encode(void *)] UTF8String];
        sig = [NSMethodSignature signatureWithObjCTypes: types];
    }
    return sig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSArray *blocksToInvoke = _blockRetriever();
    CFRetain((__bridge CFTypeRef)(self));
    dispatch_async(_queue, ^{
        for (id block in blocksToInvoke) {
            [anInvocation setTarget:block];
            [anInvocation invokeUsingIMP:BlockImpl(block)];
        }
        CFRelease((__bridge CFTypeRef)(self));
    });
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
