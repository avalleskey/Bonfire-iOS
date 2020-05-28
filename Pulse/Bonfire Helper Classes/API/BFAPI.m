//
//  BFAPI.m
//  Pulse
//
//  Created by Austin Valleskey on 4/13/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAPI.h"
#import "Session.h"
#import "BFMedia.h"
#import "BFTipsManager.h"
#import "BFNotificationManager.h"
#import "BFMiniNotificationManager.h"
#import "Launcher.h"
#import "ComposeViewController.h"
#import "UIImage+fixOrientation.h"
#import "CampViewController.h"
#import "UIColor+Palette.h"
#import <PINCache/PINCache.h>
#import "BFAlertController.h"
#import <JGProgressHUD.h>
@import Firebase;

@interface BFAPI ()

@end

@implementation BFAPI

+ (BFAPI *)sharedInstance {
    static BFAPI *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

+ (Session *)session {
    return [Session sharedInstance];
}

#pragma mark - Identity
+ (void)blockIdentity:(Identity *)identity completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"block_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/block", identity.identifier]; // sample data
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: blockUser");
        NSLog(@"--------");
        
        handler(true, @{@"blocked": @true});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)unblockIdentity:(Identity *)identity completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"unblock_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/block", identity.identifier]; // sample data
    
    [[HAWebService authenticatedManager] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: unblockUser");
        NSLog(@"--------");
                
        handler(true, @{@"blocked": @false});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}

#pragma mark - User
+ (void)getUser:(void (^ _Nullable)(BOOL success))handler {
    NSString *url = @"users/me";
        
    [[HAWebService authenticatedManager] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error;
        
        User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:&error];
        if (error) { NSLog(@"GET -> /users/me; User error: %@", error); }
        
        [[Session sharedInstance] updateUser:user];
        
        if (handler) {
            handler(TRUE);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"❌ Failed to get User ID");
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", ErrorResponse);
        
        if (handler) {
            handler(FALSE);
        }
    }];
}
+ (void)followUser:(User *)user completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"follow_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/follow", user.identifier]; // sample data
        
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: followUser");
        NSLog(@"--------");
        
        // refresh user object
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyCamps" object:nil];
        
        //NSError *error;
        //CampContext *campContextResponse = [[CampContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        //if (!error) { NSLog(@"camp context reponse:"); NSLog(@"%@", campContextResponse); };
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FetchNewTimelinePosts" object:nil];
        
        handler(true, @{@"following": @true});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)unfollowUser:(User *)user completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"unfollow_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/follow", user.identifier]; // sample data
    
    [[HAWebService authenticatedManager] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: unfollowUser");
        NSLog(@"--------");
        
        handler(true, @{@"following": @false});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)subscribeToUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, User *_Nullable user))handler {
    [FIRAnalytics logEventWithName:@"subscribe_to_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/notifications/subscription", user.identifier];
    
    [[HAWebService authenticatedManager] POST:url parameters:@{@"vendor": @"APNS", @"token": [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: subscribeToUser");
        NSLog(@"--------");
        
        NSLog(@"response object: %@", responseObject);
        
        // update object
        NSDate *date = [NSDate new];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *created_at = [dateFormatter stringFromDate:date];
        BFContextMeFollowMeSubscription *subscription = [[BFContextMeFollowMeSubscription alloc] initWithDictionary:@{@"created_at": created_at} error:nil];
        user.attributes.context.me.follow.me.subscription = subscription;
        
        handler(true, user);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, nil);
    }];
}
+ (void)unsubscribeFromUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, User *_Nullable user))handler {
    [FIRAnalytics logEventWithName:@"unsubscribe_from_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/notifications/subscription", user.identifier];
    
    [[HAWebService authenticatedManager] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: unsubscribeFromUser");
        NSLog(@"--------");
        
        NSLog(@"responseObject: %@", responseObject);
        
        // update object
        user.attributes.context.me.follow.me.subscription = nil;
        
        handler(true, user);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        handler(false, nil);
    }];
}

#pragma mark - Bot
+ (void)addBot:(Bot *_Nonnull)bot toCamp:(Camp *)camp completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler {
    [FIRAnalytics logEventWithName:@"add_bot_to_camp"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/add", bot.identifier]; // sample data
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        handler(true, @{@"blocked": @true});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        handler(false, @{@"error": ErrorResponse});
    }];
}

#pragma mark - Camp
+ (void)followCamp:(Camp *)camp completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"join_camp"
                        parameters:@{}];
    
    Camp *r = [camp copy];
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members", r.identifier];
    NSDictionary *params = @{};
    
    [[HAWebService authenticatedManager] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: followCamp");
        NSLog(@"--------");
        
        DLog(@"response object: %@", responseObject);
        
        // refresh my camps
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyCamps" object:nil];
        [[PINCache sharedCache] removeObjectForKey:MY_CAMPS_CAN_POST_KEY];
        
        if ([responseObject objectForKey:@"data"]) {
            if ([responseObject[@"data"] objectForKey:@"context"]) {
                NSError *error;
                BFContextCamp *campContextResponse = [[BFContextCamp alloc] initWithDictionary:responseObject[@"data"][@"context"] error:&error];
                
                if (!error) {
                    r.attributes.context.camp = campContextResponse;
                    
                    if ([r.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]) {
                        r.attributes.summaries.counts.members = r.attributes.summaries.counts.members + 1;
                        
                        if (r.attributes.summaries.members.count < 6) {
                            // add yourself as a user, so we can update the canvas pic!
                            NSMutableArray <User *><User, Optional> *mutableSummariesMembersArray = [r.attributes.summaries.members mutableCopy];
                            [mutableSummariesMembersArray addObject:[Session sharedInstance].currentUser];
                            r.attributes.summaries.members = mutableSummariesMembersArray;
                        }
                    }
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:r];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FetchNewTimelinePosts" object:nil];
            }
            
            if ([responseObject[@"data"] objectForKey:@"prompt"] && [responseObject[@"data"] objectForKey:@"prompt"] != [NSNull null]) {
                // open icebreaker prompt if given one!
                
                if ([[Launcher activeViewController] isKindOfClass:[CampViewController class]]) {
                    if ([responseObject[@"data"][@"prompt"] objectForKey:@"type"] && [[NSString stringWithFormat:@"%@", responseObject[@"data"][@"prompt"][@"type"]] isEqualToString:@"post"]) {
                        BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeCamp creator:r title:[NSString stringWithFormat:@"Welcome to the Camp! 👋"] text:@"Help others in the Camp get to know you better! Tap here to answer the Camp Icebreaker" cta:nil imageUrl:nil action:^{
                            Post *post = [[Post alloc] initWithDictionary:responseObject[@"data"][@"prompt"] error:nil];
                            
                            ComposeViewController *epvc = [[ComposeViewController alloc] init];
                            epvc.postingIn = post.attributes.postedIn;
                            epvc.replyingTo = post;
                            epvc.replyingToIcebreaker = true;
                            
                            SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
                            newNavController.transitioningDelegate = [Launcher sharedInstance];
                            [newNavController setLeftAction:SNActionTypeCancel];
                            newNavController.view.tintColor = epvc.view.tintColor;
                            newNavController.currentTheme = [UIColor contentBackgroundColor];
                            [Launcher present:newNavController animated:YES];
                        }];
                        [[BFTipsManager manager] presentTip:tipObject completion:^{
                            NSLog(@"presentTip() completion");
                        }];
                    }
                }
            }
        }
        
        handler(true, r);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)unfollowCamp:(Camp *)camp completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"leave_camp"
                        parameters:@{}];
    
    Camp *r = [camp copy];
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members", r.identifier];
    NSDictionary *params = @{};
    
    [[HAWebService authenticatedManager] DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: unfollowCamp");
        NSLog(@"--------");
        
        NSLog(@"response object:: %@", responseObject);
        
        // refresh my camps
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyCamps" object:nil];
        [[PINCache sharedCache] removeObjectForKey:MY_CAMPS_CAN_POST_KEY];
        
        NSError *error;
        BFContextCamp *campContextResponse = [[BFContextCamp alloc] initWithDictionary:responseObject[@"data"][@"context"] error:&error];
        
        if (!error) {
            r.attributes.context.camp = campContextResponse;
        }
                
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:r];
        
        handler(true, r);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": error});
    }];
    
    // update it instantly
    if ([r.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]) {
        r.attributes.summaries.counts.members = r.attributes.summaries.counts.members - 1;
        
        // remove the user from the summaries (if needed)
        NSMutableArray <User *> *mutableSummariesMembersArray = [NSMutableArray array];
        NSString *userIdentifier = [Session sharedInstance].currentUser.identifier;
        for (User *user in r.attributes.summaries.members) {
            if (![user.identifier isEqualToString:userIdentifier]) {
                [mutableSummariesMembersArray addObject:user];
            }
        }
        r.attributes.summaries.members = [mutableSummariesMembersArray copy];
    }
    r.attributes.context.camp.permissions.post = @[];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:r];
}

#pragma mark - Post
+ (void)createPost:(NSDictionary *)params postingIn:(Camp * _Nullable)postingIn replyingTo:(Post * _Nullable)replyingTo attachments:(PostAttachments * _Nullable)attachments {
    [FIRAnalytics logEventWithName:@"create_post"
                        parameters:@{
                                     @"posted_to": (postingIn != nil) ? @"camp" : @"profile",
                                     @"is_reply": (replyingTo != nil) ? @"YES" : @"NO"
                                     }];
    
    // CREATE TEMP POST
    // --> This will place a temporary post at the top of related streams
    // --> Once the post has been created, we send a notification telling the View Controllers to remove the temporary post and replace it with the new post
    Post *tempPost = [[Post alloc] init];
    [tempPost createTempWithMessage:params[@"message"] media:params[@"media"] postedIn:postingIn parent:replyingTo attachments:attachments];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostBegan" object:tempPost];
    
    [self uploadImages:params[@"media"] copmletion:^(BOOL imageSuccess, NSArray *images) {
        if (imageSuccess) {
            NSLog(@"image success");
            NSString *url;
            if (replyingTo) {
                url = [NSString stringWithFormat:@"posts/%@/replies", replyingTo.identifier];
            }
            else if ([postingIn isKindOfClass:[Camp class]]) {
                // post in Camp
                Camp *camp = postingIn;
                url = [NSString stringWithFormat:@"camps/%@/posts", camp.identifier];
            }
            else {
                // post to user profile
                url = @"users/me/posts";
            }
            
            NSLog(@"images we've received: %@", images);
            NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] initWithDictionary:params];
            [mutableParams removeObjectForKey:@"media"];
            
            NSMutableDictionary *attachmentsDict = [NSMutableDictionary new];
            if (params[@"attachments"]) {
                [attachmentsDict addEntriesFromDictionary:params[@"attachments"]];
            }
            
            if (images.count > 0) {
                [attachmentsDict setObject:images forKey:@"media"];
                
                [mutableParams setObject:attachmentsDict forKey:@"attachments"];
            }
                        
            [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:mutableParams progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"CommonTableViewController / getPosts() success! ✅");
                
                NSError *postError;
                Post *post = [[Post alloc] initWithDictionary:responseObject[@"data"] error:&postError];
                                
                BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Posted!" action:^{
                    NSLog(@"mini notification action!!!");
                    [Launcher openPost:post withKeyboard:false];
                }];
                [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:^{
                    NSLog(@"presentNotification() completion");
                }];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostCompleted" object:@{@"tempId": tempPost.tempId, @"post": post}];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"Session / createPost() - error: %@", error);
                // NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                NSInteger errorCode = [error bonfireErrorCode];
                NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                NSInteger statusCode = httpResponse.statusCode;
                
                if (errorCode == POST_INACCESSIBLE) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostFailed" object:tempPost];
                    
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Error Creating Post" message:@"The post you were replying to is no longer available" preferredStyle:BFAlertControllerStyleAlert];
                    
                    BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:cancelActionSheet];
                    
                    [actionSheet show];
                }
                else if (statusCode != 504) {
                    [BFAPI createPost_failed:params postingIn:postingIn replyingTo:replyingTo tempPost:tempPost attachments:attachments];
                }
            }];
        }
        else {
            NSLog(@"image failure");
            [BFAPI createPost_failed:params postingIn:postingIn replyingTo:replyingTo tempPost:tempPost attachments:attachments];
        }
    }];
}
+ (void)createPost_failed:(NSDictionary *)params postingIn:(Camp * _Nullable)postingIn replyingTo:(Post * _Nullable)replyingTo tempPost:(Post *)tempPost attachments:(PostAttachments * _Nullable)attachments {
    // confirm action
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Issue Creating Post" message:@"Check your network settings and tap the button below to try again" preferredStyle:BFAlertControllerStyleAlert];
    
    BFAlertAction *tryAgain = [BFAlertAction actionWithTitle:@"Try Again" style:BFAlertActionStyleDefault handler:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostFailed" object:tempPost];
        NSLog(@"try again with create params:: %@", params);
        [BFAPI createPost:params postingIn:postingIn replyingTo:replyingTo attachments:attachments];
    }];
    [actionSheet addAction:tryAgain];
    
    BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostFailed" object:tempPost];
    }];
    [actionSheet addAction:cancelActionSheet];
    
    [actionSheet show];

}
+ (void)deletePost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"delete_post"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@", post.identifier];
    NSDictionary *params = @{};
    
    NSLog(@"url:: %@", url);
    
    [[HAWebService authenticatedManager] DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: delete post");
        NSLog(@"--------");
        
        handler(true, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostDeleted" object:post];
}
+ (void)votePost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"post_vote"
                        parameters:@{}];
    
    // update the UI
    NSDateFormatter *gmtDateFormatter = [[NSDateFormatter alloc] init];
    gmtDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    gmtDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSString *dateString = [gmtDateFormatter stringFromDate:[NSDate new]];
    
    BFContext *context = [[BFContext alloc] initWithDictionary:[post.attributes.context toDictionary] error:nil];
    BFContextPost *contextPost = [[BFContextPost alloc] initWithDictionary:[post.attributes.context.post toDictionary] error:nil];
    BFContextPostVote *voteDict = [[BFContextPostVote alloc] initWithDictionary:@{@"created_at": dateString} error:nil];
    contextPost.vote = voteDict;
    context.post = contextPost;
    post.attributes.context = context;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@/votes", post.identifier];
    
    NSDictionary *params = @{};
    
    NSLog(@"url:: %@", url);
    
    [[HAWebService authenticatedManager] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: upvote");
        NSLog(@"--------");
        
        handler(true, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)unvotePost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"post_unvote"
                        parameters:@{}];
    
    BFContext *context = [[BFContext alloc] initWithDictionary:[post.attributes.context toDictionary] error:nil];
    BFContextPost *contextPost = [[BFContextPost alloc] initWithDictionary:[post.attributes.context.post toDictionary] error:nil];
    contextPost.vote = nil;
    context.post = contextPost;
    post.attributes.context = context;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@/votes", post.identifier];
    NSDictionary *params = @{};
    
    [[HAWebService authenticatedManager] DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: downvote");
        NSLog(@"--------");
        
        handler(true, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}

#pragma mark - Misc.
+ (void)uploadImage:(BFMediaObject *)mediaObject copmletion:(void (^)(BOOL success, NSString *uploadedImageURL))handler {
    NSData *imageData = mediaObject.data;
    
    if (imageData && [imageData isKindOfClass:[NSData class]]) {
        // has images
        DLog(@"has image to upload -> upload them then continue");
        
        [[HAWebService authenticatedManager].requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [[HAWebService authenticatedManager] POST:kIMAGE_UPLOAD_URL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            if ([mediaObject.MIME isEqualToString:@"image/jpeg"]) {
                [formData appendPartWithFileData:imageData name:@"media" fileName:@"media.jpg" mimeType:mediaObject.MIME];
            }
            else if ([mediaObject.MIME isEqualToString:@"image/gif"]) {
                [formData appendPartWithFileData:imageData name:@"media" fileName:@"media.gif" mimeType:mediaObject.MIME];
            }
            else if ([mediaObject.MIME isEqualToString:@"image/png"]) {
                [formData appendPartWithFileData:imageData name:@"media" fileName:@"media.png" mimeType:mediaObject.MIME];
            }
            
            DLog(@"MIME type: %@", mediaObject.MIME);
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            DLog(@"--------");
            DLog(@"response object: %@", responseObject);
            DLog(@"--------");
            
            if (responseObject[@"data"] && responseObject[@"data"] != [NSNull null] && [responseObject[@"data"] count] > 0) {
                // successfully uploaded image -> pass completion info
                handler(true, responseObject[@"data"][0][@"id"]);
            }
            else {
                handler(false, nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            DLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            DLog(@"%@",ErrorResponse);
            DLog(@"%@", error);
            DLog(@"idk: %@", task.response);
            
            handler(false, nil);
        }];
    }
    else {
        handler(false, nil);
    }
}

+ (void)uploadImages:(BFMedia *)media copmletion:(void (^)(BOOL success, NSArray *uploadedImages))handler {
    __block NSUInteger remaining = media.objects.count;
    NSMutableArray *uploadedImages = [[NSMutableArray alloc] initWithArray:media.objects];

    if (remaining == 0) {
        handler(true, nil);
    }

    for (NSInteger i = 0; i < remaining; i++) {
        NSInteger localIndex = i;
        BFMediaObject *mediaObject = media.objects[i];

        [self uploadImage:mediaObject copmletion:^(BOOL success, NSString *uploadedImageURL) {
            NSLog(@"upload image %li...", localIndex + 1);
            if (success) {
                if (uploadedImageURL && uploadedImageURL.length > 0) {
                    [uploadedImages replaceObjectAtIndex:localIndex withObject:uploadedImageURL];
                }

                remaining -= 1;

                if (remaining == 0) {
                    handler(true, uploadedImages);
                }
            }
            else {
                if (remaining == 0) {
                    handler(true, uploadedImages);
                }

                handler(false, nil);
            }
        }];
    }
}

// Ancillary method to scale an image based on a CGSize
+ (UIImage *)imageWithImage:(UIImage*)originalImage scaledToSize:(CGSize)newSize;
{
    @synchronized(self)
    {
        UIGraphicsBeginImageContext(newSize);
        [originalImage drawInRect:CGRectMake(0,0,newSize.width, newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    return nil;
}

@end
