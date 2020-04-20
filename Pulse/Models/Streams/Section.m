//
//  Section.m
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "Section.h"

#import "NSArray+Components.h"

#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "ExpandThreadCell.h"
#import "AddReplyCell.h"
#import "ButtonCell.h"

@implementation Section

- (instancetype)init {
    if (self = [super init]) {
        self.type = @"section";
        self.components = [NSMutableArray<BFStreamComponent *><BFStreamComponent> new];
    }
    return self;
}

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

- (void)refreshComponents {
    self.components = [NSMutableArray<BFStreamComponent *><BFStreamComponent> new];
    
    // no posts -> skip entirely
    if (self.attributes.posts) {
        [self.components addObjectsFromArray:[self.attributes.posts toStreamComponents]];
    }
    else if (self.attributes.camps) {
        [self.components addObjectsFromArray:[self.attributes.camps toStreamComponents]];
    }
    else if (self.attributes.users) {
        [self.components addObjectsFromArray:[self.attributes.users toStreamComponents]];
    }
    else {
        return;
    }
        
    // add cta
    if (self.attributes.cta.text.length > 0) {
        BFStreamComponent *component = [[BFStreamComponent alloc] initWithSettings:nil className:NSStringFromClass([ButtonCell class]) detailLevel:BFComponentDetailLevelAll];
        [self.components addObject:component];
    }
}

- (BOOL)hasData {
    return (self.attributes.posts.count > 0 ||
            self.attributes.camps.count > 0 ||
            self.attributes.users.count > 0);
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
