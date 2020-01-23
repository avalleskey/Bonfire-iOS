//
//  BFComponent.h
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BFSectionHeaderObject.h"
#import "Post.h"
#import "Camp.h"
#import "Identity.h"
#import "User.h"
#import "Bot.h"
#import "BFLink.h"

NS_ASSUME_NONNULL_BEGIN

@class BFComponent;

@protocol BFComponentProtocol <NSObject>

@required
+ (CGFloat)heightForComponent:(BFComponent *)component;

@end

@interface BFComponent : NSObject

typedef enum {
    BFComponentDetailLevelAll, // include context
    BFComponentDetailLevelSome, // don't include any context
    BFComponentDetailLevelMinimum // truncate and keep to bare minimum
} BFComponentDetailLevel;

// Convenience methods for Posts
- (id)initWithPost:(Post *)post;
- (id)initWithPost:(Post *)post cellClass:(Class _Nullable)cellClass;
- (id)initWithPost:(Post *)post cellClass:(Class _Nullable)cellClass detailLevel:(BFComponentDetailLevel)detailLevel;

- (id)initWithObject:(id _Nullable)object cellClass:(Class)cellClass detailLevel:(BFComponentDetailLevel)detailLevel;

- (void)updateCellHeight;

// This tells the table view what kind of cell to render
@property (nonatomic, strong) Class <BFComponentProtocol> cellClass;
@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) BFComponentDetailLevel detailLevel;

// These provide the table view with the data needed to
// populate the cellClass
@property (nonatomic, strong) BFSectionHeaderObject *headerObject;
@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) Camp *camp;
@property (nonatomic, strong) Identity *identity;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) Bot *bot;
@property (nonatomic, strong) BFLink *link;

@end

NS_ASSUME_NONNULL_END
