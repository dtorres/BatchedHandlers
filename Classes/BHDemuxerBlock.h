//
//  BHDemuxerBlock.h
//  BatchedHandlers
//
//  Created by Diego Torres on 3/30/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSArray *(^BHBlocksRetriever)(void);

@interface BHDemuxerBlock : NSObject <NSCopying>

- (instancetype)initWithSampleBlock:(id)block blockRetriever:(BHBlocksRetriever)retriever queue:(dispatch_queue_t)queue;

@end
