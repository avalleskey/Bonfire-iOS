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

#import "SearchResultCell.h"

@implementation NSArray (Components)

- (NSArray<BFStreamComponent *> *)toStreamComponents {
    return  [self toStreamComponentsWithDetailLevel:BFComponentDetailLevelAll];
}
- (NSArray<BFStreamComponent *> *)toStreamComponentsWithDetailLevel:(BFComponentDetailLevel)detailLevel {
    NSMutableArray<BFStreamComponent *> *components = [NSMutableArray<BFStreamComponent *> new];
        
    if (self.count == 0) return @[];
    
    BOOL posts = [[self firstObject] isKindOfClass:[Post class]];
    BOOL camps = [[self firstObject] isKindOfClass:[Camp class]];
    BOOL bots = [[self firstObject] isKindOfClass:[Bot class]];
    BOOL users = [[self firstObject] isKindOfClass:[User class]];
    
    if (camps && self.count > 2) {
        BFStreamComponent *component = [[BFStreamComponent alloc] initWithSettings:nil className:@"CampCardsListCell" detailLevel:BFComponentDetailLevelSome];
        component.campArray = (NSArray<Camp *><Camp> *)self;
        component.showLineSeparator = true;
        [components addObject:component];
        
        return @[component];
    }
    
    for (id object in self) {
        if (posts) {
            Post *post = (Post *)object;
            
            BOOL showSummaryReplies = (post.attributes.summaries.replies.count > 0);
            BOOL showMoreReplies = (post.attributes.summaries.counts.replies > post.attributes.summaries.replies.count);
            BOOL showAddReply = (showSummaryReplies || showMoreReplies || post.attributes.summaries.counts.replies > 0);
            
            // Add the parent post
            BFStreamComponent *component = [[BFStreamComponent alloc] initWithPost:post cellClass:[StreamPostCell class] detailLevel:detailLevel];
            [components addObject:component];

            if (detailLevel < BFComponentDetailLevelMinimum) {
                if (showSummaryReplies) {
                    // Add reply cells underneath the parent post
                    for (Post *reply in post.attributes.summaries.replies) {
                        BFStreamComponent *replyComponent = [[BFStreamComponent alloc] initWithPost:reply cellClass:[ReplyCell class]];
                        [components addObject:replyComponent];
                    }
                }
                
                if (showMoreReplies) {
                    BFStreamComponent *showMoreRepliesComponent = [[BFStreamComponent alloc] initWithPost:post cellClass:[ExpandThreadCell class]];
                    [components addObject:showMoreRepliesComponent];
                }
                
                if (showAddReply) {
                    BFStreamComponent *addReplyComponent = [[BFStreamComponent alloc] initWithPost:post cellClass:[AddReplyCell class]];
                    [components addObject:addReplyComponent];
                }
            }
            
            [components lastObject].showLineSeparator = true;
        }
        else if (camps) {
            Camp *camp = (Camp *)object;
            
            BFStreamComponent *component = [[BFStreamComponent alloc] initWithSettings:nil className:@"SearchResultCell" detailLevel:BFComponentDetailLevelAll];
            component.camp = camp;
            component.showLineSeparator = true;
            [components addObject:component];
        }
        else if (bots) {
            Bot *bot = (Bot *)object;
            
            BFStreamComponent *component = [[BFStreamComponent alloc] initWithSettings:nil className:@"SearchResultCell" detailLevel:BFComponentDetailLevelAll];
            component.bot = bot;
            component.showLineSeparator = true;
            [components addObject:component];
        }
        else if (users) {
            User *user = (User *)object;
            
            BFStreamComponent *component = [[BFStreamComponent alloc] initWithSettings:nil className:@"SearchResultCell" detailLevel:BFComponentDetailLevelAll];
            component.user = user;
            component.showLineSeparator = true;
            [components addObject:component];
        }
    }
    
    return components;
}

@end
