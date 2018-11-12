//
//  PostContext.h
//  Pulse
//
//  Created by Austin Valleskey on 11/7/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@class PostContext;
@class PostContextReplies;
@class PostContextVote;

@interface PostContext : JSONModel

@property (nonatomic) PostContextReplies *replies;
@property (nonatomic) PostContextVote <Optional> *vote;

@end

@interface PostContextReplies : JSONModel

@property (nonatomic) NSInteger count;

@end

@interface PostContextVote : JSONModel

@property (nonatomic) NSString *createdAt;

@end
