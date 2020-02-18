//
//  NSArray+Components.m
//  Pulse
//
//  Created by Austin Valleskey on 1/23/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "NSArray+Components.h"

#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "AddReplyCell.h"
#import "ExpandThreadCell.h"

@implementation NSArray (Components)

- (NSArray<BFPostStreamComponent *> *)toPostStreamComponents {
    return  [self toPostStreamComponentsWithDetailLevel:BFComponentDetailLevelAll];
}
- (NSArray<BFPostStreamComponent *> *)toPostStreamComponentsWithDetailLevel:(BFComponentDetailLevel)detailLevel {
    NSMutableArray<BFPostStreamComponent *> *components = [NSMutableArray<BFPostStreamComponent *> new];
        
    for (Post *post in self) {
        BOOL showSummaryReplies = (post.attributes.summaries.replies.count > 0);
        BOOL showMoreReplies = (post.attributes.summaries.counts.replies > post.attributes.summaries.replies.count);
        BOOL showAddReply = (showSummaryReplies || showMoreReplies || post.attributes.summaries.counts.replies > 0);
        
        // Add the parent post
        BFPostStreamComponent *component = [[BFPostStreamComponent alloc] initWithPost:post cellClass:[StreamPostCell class] detailLevel:detailLevel];
        [components addObject:component];

        if (detailLevel < BFComponentDetailLevelMinimum) {
            if (showSummaryReplies) {
                // Add reply cells underneath the parent post
                for (Post *reply in post.attributes.summaries.replies) {
                    BFPostStreamComponent *replyComponent = [[BFPostStreamComponent alloc] initWithPost:reply cellClass:[ReplyCell class]];
                    [components addObject:replyComponent];
                }
            }
            
            if (showMoreReplies) {
                BFPostStreamComponent *showMoreRepliesComponent = [[BFPostStreamComponent alloc] initWithPost:post cellClass:[ExpandThreadCell class]];
                [components addObject:showMoreRepliesComponent];
            }
            
            if (showAddReply) {
                BFPostStreamComponent *addReplyComponent = [[BFPostStreamComponent alloc] initWithPost:post cellClass:[AddReplyCell class]];
                [components addObject:addReplyComponent];
            }
        }
        
        [components lastObject].showLineSeparator = true;
    }
    
    return components;
}

@end
