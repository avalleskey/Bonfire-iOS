//
//  Section.m
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "Section.h"

#import "BFSectionHeaderCell.h"
#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "ExpandThreadCell.h"
#import "AddReplyCell.h"
#import "ButtonCell.h"

@implementation Section

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}
+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return true;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    Section *instance = [super initWithDictionary:dict error:err];
        
    return instance;
}

- (void)refreshComponents {
    self.components = [NSMutableArray<BFComponent *> new];
    
    // no posts -> skip entirely
    if (self.attributes.posts.count == 0) {
        return;
    }
    
    // add header
    if (self.attributes.title.length > 0 ||
        self.attributes.text.length  > 0) {
        BFSectionHeaderObject *headerObject = [[BFSectionHeaderObject alloc] initWithTitle:self.attributes.title text:self.attributes.text target:self.attributes.cta.target.camp];
        
        BFComponent *component = [[BFComponent alloc] initWithObject:headerObject cellClass:[BFSectionHeaderCell class] detailLevel:BFComponentDetailLevelAll];
        [self.components addObject:component];
    }
    
    for (Post *post in self.attributes.posts) {
        // Add the parent post
        BFComponent *component = [[BFComponent alloc] initWithPost:post];
        [self.components addObject:component];
        
        if (post.attributes.summaries.replies.count > 0) {
            // Add reply cells underneath the parent post
            for (Post *reply in post.attributes.summaries.replies) {
                BFComponent *replyComponent = [[BFComponent alloc] initWithPost:reply cellClass:[ReplyCell class]];
                [self.components addObject:replyComponent];
            }
        }
        
        if (post.attributes.summaries.counts.replies > 0 ||
            post.attributes.summaries.replies.count > 0) {
//            if (post.attributes.summaries.counts.replies > post.attributes.summaries.replies.count) {
//                BFComponent *showMoreRepliesComponent = [[BFComponent alloc] initWithPost:post cellClass:[ExpandThreadCell class]];
//                [self.components addObject:showMoreRepliesComponent];
//            }
            
            // "Add a reply..." up-cell ;)
            BFComponent *addReplyComponent = [[BFComponent alloc] initWithPost:post cellClass:[AddReplyCell class]];
            [self.components addObject:addReplyComponent];
        }
    }
    
    // add cta
    if (self.attributes.cta.text.length > 0) {
        BFComponent *component = [[BFComponent alloc] initWithObject:nil cellClass:[ButtonCell class] detailLevel:BFComponentDetailLevelAll];
        [self.components addObject:component];
    }
    
        //TODO: sectionDidUpdate:
    //    if ([self.delegate respondsToSelector:@selector(sectionStreamDidUpdate:)]) {
    //        [self.delegate sectionStreamDidUpdate:self];
    //    }
}

@end

@implementation SectionAttributes

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end

@implementation SectionAttributesCta

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end

@implementation SectionAttributesCtaTarget

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end
