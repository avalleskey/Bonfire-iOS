//
//  BFComponent.h
//  Pulse
//
//  Created by Austin Valleskey on 1/19/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BFComponent.h"
#import "BFSectionHeaderObject.h"
#import "Post.h"
#import "Camp.h"
#import "User.h"
#import "Bot.h"
#import "BFLink.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BFStreamComponent;

@interface BFStreamComponent : BFComponent

// Convenience methods for Posts
- (id)initWithPost:(Post *)post;
- (id)initWithPost:(Post *)post cellClass:(Class _Nullable)cellClass;
- (id)initWithPost:(Post *)post cellClass:(Class _Nullable)cellClass detailLevel:(BFComponentDetailLevel)detailLevel;

// These provide the table view with the data needed to
// populate the cellClass
@property (nonatomic, strong) BFSectionHeaderObject * _Nullable headerObject;
- (Post * _Nullable)post;
- (Camp * _Nullable)camp;
- (Identity * _Nullable)identity;
- (User * _Nullable)user;
- (Bot * _Nullable)bot;
- (BFLink * _Nullable)link;

@end

NS_ASSUME_NONNULL_END
