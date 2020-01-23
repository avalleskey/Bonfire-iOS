//
//  BFComponent.m
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFComponent.h"
#import "StreamPostCell.h"

@interface BFComponent ()

@property (nonatomic) BOOL changes;

@end

@implementation BFComponent

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
    
    return [self initWithObject:post cellClass:cellClass detailLevel:detailLevel];
}

- (id)initWithObject:(id _Nullable)object cellClass:(Class)cellClass detailLevel:(BFComponentDetailLevel)detailLevel {
    if (self = [super init]) {
        if ([object isKindOfClass:[BFSectionHeaderObject class]]) {
            self.headerObject = (BFSectionHeaderObject *)object;
        }
        else if ([object isKindOfClass:[Post class]]) {
            self.post = (Post *)object;
        }
        else if ([object isKindOfClass:[Camp class]]) {
            self.camp = (Camp *)object;
        }
        else if ([object isKindOfClass:[Identity class]]) {
            self.identity = (Identity *)object;
        }
        else if ([object isKindOfClass:[User class]]) {
            self.user = (User *)object;
        }
        else if ([object isKindOfClass:[Bot class]]) {
            self.bot = (Bot *)object;
        }
        else if ([object isKindOfClass:[BFLink class]]) {
            self.link = (BFLink *)object;
        }
                
        self.cellClass = cellClass;
        self.detailLevel = detailLevel;
        
        [self updateCellHeight];
    }
    
    return self;
}

- (void)updateCellHeight {
    if ([self.cellClass conformsToProtocol:@protocol(BFComponentProtocol)]) {
        NSInvocationOperation *invo = [[NSInvocationOperation alloc] initWithTarget:self.cellClass selector:@selector(heightForComponent:) object:self];
        [invo start];
        CGFloat f = 0;
        [invo.result getValue:&f];
        
        self.cellHeight = f;
    }
    else {
        DLog(@"!!!! %@ does not conform to BFComponentProtocol", NSStringFromClass(self.cellClass.class));
        self.cellHeight = 0;
    }
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString new];
    [string appendString:@"<BFComponent>"];
    
    if (self.cellClass) {
        [string appendFormat:@"\n[cellClass]: %@", self.cellClass];
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
