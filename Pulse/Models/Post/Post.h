/**
 * This file is generated using the remodel generation script.
 * The name of the input file is PostAttributes.value
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "Room.h"

@protocol Post;

@class Post;
@class PostAttributes;
@class PostDisplay;
@class PostStatus;
@class PostStatusDisplay;
@class PostCounts;
@class PostSummaries;
@class PostDetails;
@class PostDetails;
@class PostContext;
@class PostContextReplies;
@class PostContextVote;

@interface Post : JSONModel

@property (nonatomic) NSInteger identifier;

// Used when creating a post
@property (nonatomic) NSString <Optional> *tempId;

@property (nonatomic) NSString *type;
@property (nonatomic) PostAttributes *attributes;

@property (nonatomic) NSInteger rowHeight;

- (BOOL)requiresURLPreview;
- (void)createTempWithMessage:(NSString *)message images:(NSArray *)images postedIn:(Room * _Nullable)postedIn parent:(NSInteger)parentId;

@end

@interface PostAttributes : JSONModel

@property (nonatomic) PostDetails *details;
@property (nonatomic) PostStatus *status;
@property (nonatomic) PostSummaries <Optional> *summaries;
@property (nonatomic) PostContext <Optional> *context;

@end

@interface PostDisplay : JSONModel

@end

@interface PostStatus : JSONModel

@property (nonatomic) Room <Optional> *postedIn;
@property (nonatomic) NSString *createdAt;
@property (nonatomic) PostStatusDisplay <Optional> *display;

@end

@interface PostStatusDisplay : JSONModel

@property (nonatomic) NSString *reason;

@end

@interface PostCounts : JSONModel

@property (nonatomic) NSInteger replies;

@end

@interface PostSummaries : JSONModel

@property (nonatomic) NSArray <Post *> <Post> *replies;
@property (nonatomic) PostCounts *counts;

@end

@interface PostDetails : JSONModel

@property (nonatomic) NSString *message;
@property (nonatomic) BOOL hasMedia;
@property (nonatomic) User <Optional> *creator;
// parent post ID --> used for Post replies
@property (nonatomic) NSInteger parent;

- (NSString *)simpleMessage;

@end

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
