//
//  PostStream.h
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "Post.h"

@class PostStream;
@class PostStreamPage;

@interface PostStream : NSObject

@property (strong, nonatomic) NSMutableArray <PostStreamPage *> *pages;
@property (strong, nonatomic) NSArray <Post *> *posts;

- (void)prependPage:(PostStreamPage *)page;
- (void)appendPage:(PostStreamPage *)page;

- (BOOL)updatePost:(Post *)post;
- (void)removePost:(Post *)post;
- (void)updateRoomObjects:(Room *)room;

@end

@interface PostStreamPage : JSONModel

@property (nonatomic) NSArray<Post *> *data;

@property (nonatomic) NSInteger topId;
@property (nonatomic) NSInteger bottomId;

@end
