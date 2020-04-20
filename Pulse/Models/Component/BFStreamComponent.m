//
//  BFComponent.m
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFStreamComponent.h"
#import "StreamPostCell.h"

@implementation BFStreamComponent

// Posts
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
    
    BFStreamComponent *component = [self initWithSettings:nil className:NSStringFromClass(cellClass) detailLevel:detailLevel];
    component.post = post;
    return component;
}

- (void)updateCellHeight {
    if (!self.className || self.className.length == 0) {
        self.cellHeight = 0;
        return;
    }
    
    if ([NSClassFromString(self.className) conformsToProtocol:@protocol(BFComponentProtocol)]) {
        NSInvocationOperation *invo = [[NSInvocationOperation alloc] initWithTarget:NSClassFromString(self.className) selector:@selector(heightForComponent:) object:self];
        [invo start];
        CGFloat f = 0;
        [invo.result getValue:&f];
        
        self.cellHeight = f;
    }
    else {
        DLog(@"!!!! %@ does not conform to BFComponentProtocol", self.className);
        self.cellHeight = 0;
    }
}

// custom getters
- (void)setPost:(Post<Optional> *)post {
    if (post != _post) {
        _post = post;
        
        [self updateCellHeight];
    }
}
- (void)setCamp:(Camp<Optional> *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        [self updateCellHeight];
    }
}
- (void)setIdentity:(Identity<Optional> *)identity {
    if (identity != _identity) {
        _identity = identity;
        
        [self updateCellHeight];
    }
}
- (void)setUser:(User<Optional> *)user {
    if (user != _user) {
        _user = user;
        
        [self updateCellHeight];
    }
}
- (void)setBot:(Bot<Optional> *)bot {
    if (bot != _bot) {
        _bot = bot;
        
        [self updateCellHeight];
    }
}
- (void)setLink:(BFLink<Optional> *)link {
    if (link != _link) {
        _link = link;
        
        [self updateCellHeight];
    }
}
- (void)setCampArray:(NSArray<Camp *><Camp,Optional> *)campArray {
    if (campArray != _campArray) {
        _campArray = campArray;
        
        [self updateCellHeight];
    }
}
- (void)setUserArray:(NSArray<User *><User,Optional> *)userArray {
    if (userArray != _userArray) {
        _userArray = userArray;
        
        [self updateCellHeight];
    }
}
- (void)setDictionary:(NSDictionary<Optional> *)dictionary {
    if (dictionary != _dictionary) {
        _dictionary = dictionary;
        
        [self updateCellHeight];
    }
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
    if (self.campArray) {
        [string appendFormat:@"\n[campArray]: %@", self.campArray];
    }
    if (self.userArray) {
        [string appendFormat:@"\n[userArray]: %@", self.userArray];
    }
    if (self.dictionary) {
        [string appendFormat:@"\n[dictionary]: %@", self.dictionary];
    }
    
    return string;
}

@end
