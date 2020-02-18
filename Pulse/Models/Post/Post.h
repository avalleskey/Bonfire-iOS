/**
 * This file is generated using the remodel generation script.
 * The name of the input file is PostAttributes.value
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BFJSONModel.h"
#import "Camp.h"
#import "BFMedia.h"
#import "BFHostedVersions.h"
#import "BFContext.h"
#import "BFLink.h"
#import "Bot.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Post;
@protocol PostAttachmentsMedia;
@protocol PostEntity;

@class Post;
@class PostAttributes;
@class PostAttributesThread;
@class PostDisplay;
@class PostDisplayFormat;
@class PostCounts;
@class PostSummaries;
@class PostAttachments;
@class PostAttachmentsMedia;
@class PostAttachmentsMediaAtributes;
@class PostAttachmentsMediaAtributesRawMedia;
@class PostEntity;

@interface Post : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;

// Used when creating a post
@property (nonatomic) NSString <Optional> *tempId;

@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) PostAttributes <Optional> *attributes;

- (BOOL)hasLinkAttachment;
- (BOOL)hasUserAttachment;
- (BOOL)hasCampAttachment;
- (BOOL)hasPostAttachment;
- (BOOL)isRemoved;

- (void)createTempWithMessage:(NSString *)message media:(BFMedia *)media postedIn:(Camp * _Nullable)postedIn parent:(Post *)parent attachments:(PostAttachments * _Nullable)attachments;
+ (NSString *_Nullable)trimString:(NSString *_Nullable)string;

- (BOOL)isEmojiPost;

@property (nonatomic) BOOL containsMention;
@property (nonatomic) BOOL isCreator;
@property (nonatomic) NSString <Optional> *themeColor;

- (void)report;

- (void)mute;
- (void)muteWithCmpletion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

- (void)unMute;
- (void)unMuteWithCmpletion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

@end

@interface PostAttributes : BFJSONModel

@property (nonatomic) PostSummaries <Optional> *summaries;
@property (nonatomic) BFContext <Optional> *context;

// details
@property (nonatomic) NSString <Optional> *message;
@property (nonatomic) PostAttachments <Optional> *attachments;
@property (nonatomic) NSArray <PostEntity *> <PostEntity, Optional> *entities;
@property (nonatomic) NSString <Optional> *url;
@property (nonatomic) BOOL hasMedia;
@property (nonatomic) NSArray <Optional> *media;
// parent post ID --> used for Post replies
@property (nonatomic) Post <Optional> *parent;
@property (nonatomic) NSString <Optional> *parentId;
@property (nonatomic) NSString <Optional> *parentCreatorUsername;

@property (nonatomic) PostAttributesThread <Optional> *thread;
@property (nonatomic) NSArray <Post *> <Post, Optional> * _Nullable replies;
@property (nonatomic) Identity <Optional> * _Nullable creator;

// status
@property (nonatomic) Camp <Optional> *postedIn;
@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) PostDisplay <Optional> *display;

// removed
@property (nonatomic) NSString <Optional> *removedAt;
@property (nonatomic) NSString <Optional> *removedReason;

#pragma mark - Generated properties
// if the source is a user, sourceUser will exist
@property (nonatomic) User <Optional> * _Nullable creatorUser;
// if the source is a bot, creatorBot will exist
@property (nonatomic) Bot <Optional> * _Nullable creatorBot;

@property (nonatomic) BOOL emojify;

#pragma mark - Getter methods
- (NSString *)simpleMessage;
- (NSString *)simpleMessageWithTruncationLimit:(NSInteger)truncationLimit;

@end

@interface PostAttributesThread : BFJSONModel

@property (nonatomic) NSString <Optional> *prevCursor;

@end

@interface PostDisplay : BFJSONModel

extern NSString * const POST_DISPLAY_CREATOR_CAMP;
@property (nonatomic) NSString <Optional> *creator;

@property (nonatomic) PostDisplayFormat <Optional> *format;

@end

@interface PostDisplayFormat : BFJSONModel

extern NSString * const POST_DISPLAY_FORMAT_ICEBREAKER;
extern NSString * const POST_DISPLAY_FORMAT_;
@property (nonatomic) NSString <Optional> *type;

@end

@interface PostCounts : BFJSONModel

@property (nonatomic) NSInteger replies;
@property (nonatomic) NSInteger score;

@end

@interface PostSummaries : BFJSONModel

@property (nonatomic) NSArray <Post *> <Post, Optional> *replies;
@property (nonatomic) PostCounts <Optional> *counts;

@end

@interface PostAttachments : BFJSONModel

@property (nonatomic) NSArray <PostAttachmentsMedia *> <PostAttachmentsMedia, Optional> *media;
@property (nonatomic) BFLink <Optional> *link;
@property (nonatomic) Camp <Optional> *camp;
@property (nonatomic) User <Optional> *user;
@property (nonatomic) Post <Optional> *post;

@end

@interface PostAttachmentsMedia : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) PostAttachmentsMediaAtributes <Optional> *attributes;

@end

@interface PostAttachmentsMediaAtributes : BFJSONModel

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

@interface PostAttachmentsMediaAtributesRawMedia : BFJSONModel

@property (nonatomic) NSString <Optional> *value;

@end

@interface PostEntity : BFJSONModel

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
