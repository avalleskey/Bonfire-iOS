/**
 * This file is generated using the remodel generation script.
 * The name of the input file is PostAttributes.value
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "Camp.h"
#import "BFMedia.h"
#import "BFHostedVersions.h"
#import "BFContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Post;
@protocol PostAttachmentsMedia;
@protocol PostEntity;

@class Post;
@class PostAttributes;
@class PostStatus;
@class PostStatusDisplay;
@class PostCounts;
@class PostSummaries;
@class PostDetails;
@class PostDetails;
@class PostAttachments;
@class PostAttachmentsMedia;
@class PostAttachmentsMediaAtributes;
@class PostAttachmentsMediaAtributesRawMedia;
@class PostEntity;

@interface Post : JSONModel

@property (nonatomic) NSString *identifier;

// Used when creating a post
@property (nonatomic) NSString <Optional> *tempId;

@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) PostAttributes <Optional> *attributes;

- (BOOL)requiresURLPreview;
- (void)createTempWithMessage:(NSString *)message media:(BFMedia *)media postedIn:(Camp * _Nullable)postedIn parentId:(NSString *)parentId;
+ (NSString *_Nullable)trimString:(NSString *_Nullable)string;
- (BOOL)isEmojiPost;

@property (nonatomic) NSString <Optional> *prevCursor;
@property (nonatomic) NSString <Optional> *nextCursor;

@end

@interface PostAttributes : JSONModel

@property (nonatomic) PostDetails <Optional> *details;
@property (nonatomic) PostStatus <Optional> *status;
@property (nonatomic) PostSummaries <Optional> *summaries;
@property (nonatomic) BFContext <Optional> *context;

@end

@interface PostDetails : JSONModel

@property (nonatomic) NSString <Optional> *message;
@property (nonatomic) PostAttachments <Optional> *attachments;
@property (nonatomic) NSArray <PostEntity *> <PostEntity, Optional> *entities;
@property (nonatomic) NSString <Optional> *url;
@property (nonatomic) BOOL hasMedia;
@property (nonatomic) NSArray <Optional> *media;
@property (nonatomic) User <Optional> *creator;
// parent post ID --> used for Post replies
@property (nonatomic) NSString <Optional> *parentId;
@property (nonatomic) NSString <Optional> *parentUsername;
@property (nonatomic) NSArray <Post *> <Post, Optional> * _Nullable replies;

@property (nonatomic) BOOL emojify;

- (NSString *)simpleMessage;

@end

@interface PostStatus : JSONModel

@property (nonatomic) Camp <Optional> *postedIn;
@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) PostStatusDisplay <Optional> *display;

@end

@interface PostStatusDisplay : JSONModel

extern NSString * const POST_CHOSEN_RECENT;
extern NSString * const POST_CHOSEN_POPULAR;
extern NSString * const POST_CHOSEN_FOLLOWED;
extern NSString * const POST_CHOSEN_SUGGESTED;
extern NSString * const POST_CHOSEN_SPONSORED;
@property (nonatomic) NSString <Optional> *reason;

@end

@interface PostCounts : JSONModel

@property (nonatomic) NSInteger replies;
@property (nonatomic) NSInteger live;

@end

@interface PostSummaries : JSONModel

@property (nonatomic) NSArray <Post *> <Post, Optional> *replies;
@property (nonatomic) PostCounts <Optional> *counts;

@end

@interface PostAttachments : JSONModel

@property (nonatomic) NSArray <PostAttachmentsMedia *> <PostAttachmentsMedia, Optional> *media;

@end

@interface PostAttachmentsMedia : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) PostAttachmentsMediaAtributes <Optional> *attributes;

@end

@interface PostAttachmentsMediaAtributes : JSONModel

typedef enum {
    PostAttachmentMediaTypeImage = 1,
    PostAttachmentMediaTypeGIF = 2,
    PostAttachmentMediaTypeVideo = 3,
    PostAttachmentMediaTypeText = 4,
    PostAttachmentMediaTypeLink = 5
} PostAttachmentMediaType;

@property (nonatomic) PostAttachmentMediaType type;
@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) NSString <Optional> *expiresAt;
@property (nonatomic) BFHostedVersions <Optional> *hostedVersions;
@property (nonatomic) PostAttachmentsMediaAtributesRawMedia <Optional> *rawMedia;
@property (nonatomic) NSArray <Optional> *owners;

@end

@interface PostAttachmentsMediaAtributesRawMedia : JSONModel

@property (nonatomic) NSString <Optional> *value;

@end

@interface PostEntity : JSONModel

extern NSString * const POST_ENTITY_TYPE_PROFILE;
extern NSString * const POST_ENTITY_TYPE_CAMP;
extern NSString * const POST_ENTITY_TYPE_URL;
@property (nonatomic) NSString <Optional> *type;

@property (nonatomic) NSString <Optional> *displayText;
@property (nonatomic) NSString <Optional> *expandedUrl;
@property (nonatomic) NSString <Optional> *actionUrl;
@property (nonatomic) NSArray <Optional> *indices;

@end

NS_ASSUME_NONNULL_END
