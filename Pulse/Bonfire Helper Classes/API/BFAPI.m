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
#import "Launcher.h"
#import "ComposeViewController.h"
#import "UIImage+fixOrientation.h"
#import "CampViewController.h"
#import "UIColor+Palette.h"
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

#pragma mark - User
+ (void)getUser:(void (^)(BOOL success))handler {
    NSString *url = @"users/me";
        
    [[HAWebService authenticatedManager] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error;
        
        User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:&error];
        if (error) { NSLog(@"GET -> /users/me; User error: %@", error); }
        
        [[Session sharedInstance] updateUser:user];
        
        handler(TRUE);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"❌ Failed to get User ID");
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", ErrorResponse);
        
        handler(FALSE);
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
+ (void)blockUser:(User *)user completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"block_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/block", user.identifier]; // sample data
    
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
+ (void)unblockUser:(User *)user completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"unblock_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/block", user.identifier]; // sample data
    
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
+ (void)reportUser:(User *)user completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"report_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/report", user.identifier]; // sample data
    
    // -> report also blocks the user
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: reportUser");
        NSLog(@"--------");
        
        handler(true, @{@"reported": @true});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(true, @{@"reported": @true});
        // TODO: Uncomment and remove the above line, once this exists on the backend
//        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)subscribeToUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, User *_Nullable user))handler {
    [FIRAnalytics logEventWithName:@"subscribe_to_user"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/notifications/subscription", user.identifier];
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
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
+ (void)reportBot:(Bot *_Nonnull)bot completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler {
    [FIRAnalytics logEventWithName:@"report_bot"
                            parameters:@{}];
        
    NSString *url = [NSString stringWithFormat:@"users/%@/report", bot.identifier]; // sample data
        
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        handler(true, @{@"reported": @true});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        handler(true, @{@"reported": @true});
        // TODO: Uncomment and remove the above line, once this exists on the backend
//        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
//        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)blockBot:(Bot *_Nonnull)bot completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler {
    [FIRAnalytics logEventWithName:@"block_bot"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/block", bot.identifier]; // sample data
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        handler(true, @{@"blocked": @true});
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)unblockBot:(Bot *_Nonnull)bot completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler {
    [FIRAnalytics logEventWithName:@"unblock_bot"
                        parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"users/%@/block", bot.identifier]; // sample data
    
    [[HAWebService authenticatedManager] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        handler(true, @{@"blocked": @false});
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
        
        NSLog(@"response object: %@", responseObject);
        
        // refresh my camps
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyCamps" object:nil];
        
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
                            [newNavController setRightAction:SNActionTypeShare];
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
        
        handler(false, @{@"error": ErrorResponse});
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
+ (void)createPost:(NSDictionary *)params postingIn:(Camp * _Nullable)postingIn replyingTo:(Post * _Nullable)replyingTo {
    [FIRAnalytics logEventWithName:@"create_post"
                        parameters:@{
                                     @"posted_to": (postingIn != nil) ? @"camp" : @"profile",
                                     @"is_reply": (replyingTo != nil) ? @"YES" : @"NO"
                                     }];
    
    // CREATE TEMP POST
    // --> This will place a temporary post at the top of related streams
    // --> Once the post has been created, we send a notification telling the View Controllers to remove the temporary post and replace it with the new post
    Post *tempPost = [[Post alloc] init];
    [tempPost createTempWithMessage:params[@"message"] media:params[@"media"] postedIn:postingIn parent:replyingTo];
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
            
            NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
            if (images.count > 0) {
                [attachments setObject:images forKey:@"media"];
            }
            if (params[@"url"]) {
                [attachments setObject:mutableParams[@"url"] forKey:@"link"];
                [mutableParams removeObjectForKey:@"url"];
            }
            
            if ([attachments allKeys].count > 0) {
                [mutableParams setObject:attachments forKey:@"attachments"];
            }
            
            [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:mutableParams progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"CommonTableViewController / getPosts() success! ✅");
                
                NSError *postError;
                Post *post = [[Post alloc] initWithDictionary:responseObject[@"data"] error:&postError];
                
                NSLog(@"response obj: %@", responseObject[@"data"]);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostCompleted" object:@{@"tempId": tempPost.tempId, @"post": post}];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"Session / createPost() - error: %@", error);
                // NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                [BFAPI createPost_failed:params postingIn:postingIn replyingTo:replyingTo tempPost:tempPost];
            }];
        }
        else {
            NSLog(@"image failure");
            [BFAPI createPost_failed:params postingIn:postingIn replyingTo:replyingTo tempPost:tempPost];
        }
    }];
}
+ (void)createPost_failed:(NSDictionary *)params postingIn:(Camp * _Nullable)postingIn replyingTo:(Post * _Nullable)replyingTo tempPost:(Post *)tempPost {
    // confirm action
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Issue Creating Post" message:@"Check your network settings and tap the button below to try again" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *tryAgain = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostFailed" object:tempPost];
        NSLog(@"try again with create params:: %@", params);
        [BFAPI createPost:params postingIn:postingIn replyingTo:replyingTo];
    }];
    [actionSheet addAction:tryAgain];
    
    UIAlertAction *cancelActionSheet = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostFailed" object:tempPost];
    }];
    [actionSheet addAction:cancelActionSheet];
    
    [[Launcher topMostViewController] presentViewController:actionSheet animated:YES completion:nil];

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
+ (void)reportPost:(NSString *)postId completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"post_report"
                            parameters:@{}];
        
    NSString *url = [NSString stringWithFormat:@"posts/%@/report", postId];
    
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
+ (void)votePost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"post_vote"
                        parameters:@{}];
    
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
    
    // update the UI
    NSDateFormatter *gmtDateFormatter = [[NSDateFormatter alloc] init];
    gmtDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    gmtDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSString *dateString = [gmtDateFormatter stringFromDate:[NSDate new]];
    
    BFContext *context = [[BFContext alloc] initWithDictionary:[post.attributes.context toDictionary] error:nil];
    BFContextPostVote *voteDict = [[BFContextPostVote alloc] initWithDictionary:@{@"created_at": dateString} error:nil];
    context.post.vote = voteDict;
    post.attributes.context = context;
    
    NSLog(@"post updated: %@", post);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
    
    /* test sending a notif
    BFNotificationObject *notificationObject = [BFNotificationObject notificationWithActivityType:USER_ACTIVITY_TYPE_USER_FOLLOW title:@"@hugo followed you" text:@"Tap to view Hugo Pakula's profile" action:^{
        NSLog(@"notification tapped");
    }];
    [[BFNotificationManager manager] presentNotification:notificationObject completion:^{
        NSLog(@"presentNotification() completion");
    }];*/
}
+ (void)unvotePost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"post_unvote"
                        parameters:@{}];
    
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
    
    // update the UI
    post.attributes.context.post.vote = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
}

#pragma mark - Misc.
+ (void)uploadImage:(BFMediaObject *)mediaObject copmletion:(void (^)(BOOL success, NSString *uploadedImageURL))handler {
    [self compressData:mediaObject.data completion:^(NSData *imageData) {
        NSLog(@"data class: %@", [imageData class]);
        
        if (imageData && [imageData isKindOfClass:[NSData class]]) {
            // has images
            NSLog(@"has image to upload -> upload them then continue");
            
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
                
                NSLog(@"MIME type: %@", mediaObject.MIME);
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"--------");
                NSLog(@"response object: %@", responseObject);
                NSLog(@"--------");
                
                if (responseObject[@"data"] && responseObject[@"data"] != [NSNull null] && [responseObject[@"data"] count] > 0) {
                    // successfully uploaded image -> pass completion info
                    handler(true, responseObject[@"data"][0][@"id"]);
                }
                else {
                    handler(false, nil);
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
                NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"%@",ErrorResponse);
                NSLog(@"%@", error);
                NSLog(@"idk: %@", task.response);
                
                handler(false, nil);
            }];
        }
        else {
            handler(false, nil);
        }
    }];
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

                remaining = remaining - 1;

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

+ (void)compressData:(NSData *)data completion:(void (^ _Nullable)(NSData *imageData))handler {
    __block NSData *imageData = data;
    
    UIImage *image = [UIImage imageWithData:imageData];
    NSString *mimeType = [self mimeTypeForData:imageData];
    
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 2436;
    float maxWidth = 2436;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.5;//50 percent compression
    
    if (actualHeight > maxHeight || actualWidth > maxWidth) {
        if(imgRatio < maxRatio){
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio){
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }else{
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    if ([mimeType isEqualToString:@"image/jpeg"]) {
        NSLog(@"jpeg");
        
        imageData = UIImageJPEGRepresentation(img, compressionQuality);
    }
    else if ([mimeType isEqualToString:@"image/png"]) {
        NSLog(@"png");
        
        imageData = UIImagePNGRepresentation([image fixOrientation]);
    }
    else if ([mimeType isEqualToString:@"image/gif"]) {
        NSLog(@"it's a gif we can't do anything about it.....");
    }
    
    UIGraphicsEndImageContext();
    
    handler(imageData);

    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        // run in the background
//        UIImage *image = [UIImage imageWithData:imageData];
//        NSLog(@"image orientation 1:: %ld", (long)image.imageOrientation);
//        NSString *mimeType = [self mimeTypeForData:imageData];
//
//        //Compress the image iteratively until either the maximum compression threshold (maxCompression) is reached or the maximum file size requirement is satisfied (maxSize)
//        CGFloat compression = 1.0f;
//        CGFloat maxCompression = 0.1f;
//        float maxSize = 5*1024*1024; //specified in bytes
//
//        NSLog(@"Actual Image Size: %.2f MB",(float)imageData.length/1024.0f/1024.0f);
//
//        if ([mimeType isEqualToString:@"image/jpeg"]) {
//            NSLog(@"jpeg");
//
//            imageData = UIImageJPEGRepresentation(image, compression);
//
//            UIImage *scaledImage = [UIImage imageWithData:imageData];
//            NSLog(@"image orientation 2:: %ld", (long)scaledImage.imageOrientation);
//
//            while ([imageData length] > maxSize && compression > maxCompression) {
//                compression -= 0.10;
//                imageData = UIImageJPEGRepresentation(image, compression);
//                NSLog(@"Compressed to: %.2f MB with Factor: %.2f",(float)imageData.length/1024.0f/1024.0f, compression);
//            }
//
//            UIImage *imageAfterCompression = [UIImage imageWithData:imageData];
//            imageAfterCompression = [imageAfterCompression fixOrientation];
//
//        }
//        else if ([mimeType isEqualToString:@"image/png"]) {
//            NSLog(@"png");
//
//            imageData = UIImagePNGRepresentation(image);
//            CGFloat scale = 1.0;
//            UIImage *updatedImage = [image fixOrientation];
//            while ([imageData length] > maxSize && compression > maxCompression) {
//                scale -= 0.10;
//                updatedImage = [self imageWithImage:image scaledToSize:CGSizeMake(image.size.width*scale, image.size.height*scale)];
//                [updatedImage fixOrientation];
//                imageData = UIImagePNGRepresentation(updatedImage);
//                NSLog(@"Compressed to: %.2f MB with Scale: %.2f",(float)imageData.length/1024.0f/1024.0f, scale);
//            }
//        }
//        else if ([mimeType isEqualToString:@"image/gif"]) {
//            NSLog(@"it's a gif we can't do anything about it.....");
//        }
//
//        NSLog(@"Final Image Size: %.2f MB",(float)imageData.length/1024.0f/1024.0f);
//        handler(imageData);
//    });
}

+ (NSString *)mimeTypeForData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    return nil;
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
