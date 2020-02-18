//
//  BFComponent.m
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFPostStreamComponent.h"
#import "StreamPostCell.h"

@implementation BFPostStreamComponent

- (id)initWithPost:(Post *)post {
    return [self initWithPost:post cellClass:nil];
}
- (id)initWithPost:(Post *)post cellClass:(Class _Nullable)cellClass {
    return [self initWithPost:post cellClass:cellClass detailLevel:BFComponentDetailLevelAll];
}
- (id)initWithPost:(Post *)post cellClass:(Class _Nullable)cellClass detailLevel:(BFComponentDetailLevel)detailLevel {
    if (!cellClass) {
        cellClass = [StreamPostCell class];
    }
    
    return [self initWithObject:post className:NSStringFromClass(cellClass) detailLevel:detailLevel];
}

- (void)updateCellHeight {
    if ([NSClassFromString(self.className) conformsToProtocol:@protocol(BFComponentProtocol)]) {
        NSInvocationOperation *invo = [[NSInvocationOperation alloc] initWithTarget:NSClassFromString(self.className) selector:@selector(heightForComponent:) object:self];
        [invo start];
        CGFloat f = 0;
        [invo.result getValue:&f];
        
        self.cellHeight = f;
    }
    else {
        DLog(@"!!!! %@ does not conform to BFComponentProtocol", NSStringFromClass(self.className.class));
        self.cellHeight = 0;
    }
}

// custom getters
- (BFSectionHeaderObject *)headerObject  {
    if ([self.object isKindOfClass:[BFSectionHeaderObject class]]) {
        return (BFSectionHeaderObject *)self.object;
    }
    
    return nil;
}
- (Post *)post  {
    if ([self.object isKindOfClass:[Post class]]) {
        return (Post *)self.object;
    }
    
    return nil;
}
- (Camp *)camp  {
    if ([self.object isKindOfClass:[Camp class]]) {
        return (Camp *)self.object;
    }
    
    return nil;
}
- (Identity *)identity  {
    if ([self.object isKindOfClass:[Identity class]]) {
        return (Identity *)self.object;
    }
    
    return nil;
}
- (User *)user  {
    if ([self.object isKindOfClass:[User class]]) {
        return (User *)self.object;
    }
    
    return nil;
}
- (Bot *)bot  {
    if ([self.object isKindOfClass:[Bot class]]) {
        return (Bot *)self.object;
    }
    
    return nil;
}
- (BFLink *)link  {
    if ([self.object isKindOfClass:[BFLink class]]) {
        return (BFLink *)self.object;
    }
    
    return nil;
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString new];
    [string appendString:@"<BFComponent>"];
    
    if (self.className) {
        [string appendFormat:@"\n[className]: %@", self.className];
    }
    
    if (self.post) {
        [string appendFormat:@"\n[post]: %@", self.post];
    }
    if (self.camp) {
        [string appendFormat:@"\n[camp]: %@", self.camp];
    }
    if (self.identity) {
        [string appendFormat:@"\n[identity]: %@", self.identity];
    }
    if (self.user) {
        [string appendFormat:@"\n[user]: %@", self.user];
    }
    if (self.bot) {
        [string appendFormat:@"\n[bot]: %@", self.bot];
    }
    if (self.link) {
        [string appendFormat:@"\n[link]: %@", self.link];
    }
    
    return string;
}

@end
