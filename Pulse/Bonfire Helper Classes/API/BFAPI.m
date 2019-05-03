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
        
        NSLog(@"fetched new user");
        
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
    
    NSLog(@"url: %@", url);
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: followUser");
        NSLog(@"--------");
        
        // refresh user object
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        //NSError *error;
        //RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        //if (!error) { NSLog(@"room context reponse:"); NSLog(@"%@", roomContextResponse); };
        
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
        
        // refresh user object
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        //NSError *error;
        //RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        //if (!error) { NSLog(@"room context reponse:"); NSLog(@"%@", roomContextResponse); };
        
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
        
        // refresh user object
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        //NSError *error;
        //RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        //if (!error) { NSLog(@"room context reponse:"); NSLog(@"%@", roomContextResponse); };
        
        handler(true, @{@"blocked": @false});
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
    
    NSString *url = [NSString stringWithFormat:@"users/%@/unblock", user.identifier]; // sample data
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: unblockUser");
        NSLog(@"--------");
        
        // refresh user object
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        //NSError *error;
        //RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        //if (!error) { NSLog(@"room context reponse:"); NSLog(@"%@", roomContextResponse); };
        
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
        
        // refresh user object
        
        //NSError *error;
        //RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        //if (!error) { NSLog(@"room context reponse:"); NSLog(@"%@", roomContextResponse); };
        
        handler(true, @{@"reported": @true});
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
        UserContextFollowSubscription *subscription = [[UserContextFollowSubscription alloc] initWithDictionary:@{@"created_at": created_at} error:nil];
        user.attributes.context.follow.me.subscription = subscription;
        
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
        user.attributes.context.follow.me.subscription = nil;
        
        handler(true, user);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, nil);
    }];
}


#pragma mark - Room
+ (void)followRoom:(Room *)room completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"join_room"
                        parameters:@{}];
    
    Room *r = [room copy];
    
    NSString *url = [NSString stringWithFormat:@"rooms/%@/members", r.identifier];
    NSDictionary *params = @{};
    
    [[HAWebService authenticatedManager] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: followRoom");
        NSLog(@"--------");
        
        NSLog(@"response object: %@", responseObject);
        
        // refresh my rooms
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        NSError *error;
        RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"][@"context"] error:&error];
        
        if (!error) {
            r.attributes.context = roomContextResponse;
        }
        
        if (!r.attributes.status.visibility.isPrivate) {
            r.attributes.summaries.counts.members = r.attributes.summaries.counts.members + 1;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:r];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FetchNewTimelinePosts" object:nil];
        
        handler(true, r);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}
+ (void)unfollowRoom:(Room *)room completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"leave_room"
                        parameters:@{}];
    
    Room *r = [room copy];
    
    NSString *url = [NSString stringWithFormat:@"rooms/%@/members", r.identifier];
    NSDictionary *params = @{};
    
    [[HAWebService authenticatedManager] DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: unfollowRoom");
        NSLog(@"--------");
        
        // refresh my rooms
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        NSError *error;
        RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"][@"context"] error:&error];
        
        if (!error) {
            r.attributes.context = roomContextResponse;
        }
        
        r.attributes.summaries.counts.members = r.attributes.summaries.counts.members - 1;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:r];
        
        handler(true, r);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}

#pragma mark - Post
+ (void)createPost:(NSDictionary *)params postingIn:(Room * _Nullable)postingIn replyingTo:(Post * _Nullable)replyingTo {
    [FIRAnalytics logEventWithName:@"create_post"
                        parameters:@{
                                     @"posted_to": (postingIn != nil) ? @"room" : @"profile",
                                     @"is_reply": (replyingTo != nil) ? @"YES" : @"NO"
                                     }];
    
    // CREATE TEMP POST
    // --> This will place a temporary post at the top of related streams
    // --> Once the post has been created, we send a notification telling the View Controllers to remove the temporary post and replace it with the new post
    Post *tempPost = [[Post alloc] init];
    [tempPost createTempWithMessage:params[@"message"] media:params[@"media"] postedIn:postingIn parentId:replyingTo.identifier];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostBegan" object:tempPost];
    
    [self uploadImages:params[@"media"] copmletion:^(BOOL imageSuccess, NSArray *images) {
        if (imageSuccess) {
            NSLog(@"image success");
            NSString *url;
            if ([postingIn isKindOfClass:[Room class]]) {
                // post in Room
                Room *room = postingIn;
                if (replyingTo) {
                    url = [NSString stringWithFormat:@"rooms/%@/posts/%ld/replies", room.identifier, replyingTo.identifier];
                }
                else {
                    url = [NSString stringWithFormat:@"rooms/%@/posts", room.identifier];
                }
            }
            else {
                // post to user profile
                if (replyingTo) {
                    User *user = replyingTo.attributes.details.creator;
                    NSLog(@"reply to @%@", user.attributes.details.identifier);
                    url = [NSString stringWithFormat:@"users/%@/posts/%ld/replies", user.identifier, replyingTo.identifier];
                }
                else {
                    url = @"users/me/posts";
                }
            }
            
            NSLog(@"images we've received: %@", images);
            NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] initWithDictionary:params];
            [mutableParams removeObjectForKey:@"media"];
            
            if (images.count > 0) {
                NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
                [attachments setObject:images forKey:@"media"];
                
                [mutableParams setObject:attachments forKey:@"attachments"];
            }
            NSLog(@"mutableParams: %@", mutableParams);
            
            [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:mutableParams progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"CommonTableViewController / getPosts() success! ✅");
                
                NSError *postError;
                Post *post = [[Post alloc] initWithDictionary:responseObject[@"data"] error:&postError];
                
                NSLog(@"response obj: %@", responseObject[@"data"]);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostCompleted" object:@{@"tempId": tempPost.tempId, @"post": post}];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"Session / createPost() - error: %@", error);
                // NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostFailed" object:tempPost];
            }];
        }
        else {
            NSLog(@"image failure");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPostFailed" object:tempPost];
        }
    }];
}
+ (void)deletePost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"delete_post"
                        parameters:@{}];
    
    NSString *url;
    if (post.attributes.status.postedIn) {
        // posted in a room
        url = [NSString stringWithFormat:@"rooms/%@/posts/%ld", post.attributes.status.postedIn.identifier, (long)post.identifier];
    }
    else {
        // posted on a profile
        url = [NSString stringWithFormat:@"users/%@/posts/%ld", post.attributes.details.creator.attributes.details.identifier, (long)post.identifier];
    }
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
+ (void)reportPost:(NSInteger)postId completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    handler(true, @{});
}
+ (void)sparkPost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"spark_post"
                        parameters:@{}];
    
    NSString *url;
    if (post.attributes.status.postedIn) {
        // posted in a room
        url = [NSString stringWithFormat:@"rooms/%@/posts/%ld/votes", post.attributes.status.postedIn.identifier, (long)post.identifier];
    }
    else {
        // posted on a profile
        url = [NSString stringWithFormat:@"users/%@/posts/%ld/votes", post.attributes.details.creator.attributes.details.identifier, (long)post.identifier];
    }
    
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
    
    PostContextVote *voteDict = [[PostContextVote alloc] initWithDictionary:@{@"created_at": dateString} error:nil];
    post.attributes.context.vote = voteDict;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
    
    // create tip
    BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireTip creator:nil title:@"Sparks help posts go viral 🚀" text:@"Sparks anonymously invite more people to join the conversation. Only the creator will see how man sparks a post has." action:^{
        NSLog(@"tip tapped");
    }];
    [[BFTipsManager manager] presentTip:tipObject completion:^{
        NSLog(@"presentTip() completion");
    }];
}
+ (void)unsparkPost:(Post *)post completion:(void (^ _Nullable)(BOOL success, id responseObject))handler {
    [FIRAnalytics logEventWithName:@"unspark_post"
                        parameters:@{}];
    
    NSString *url;
    if (post.attributes.status.postedIn) {
        // posted in a room
        url = [NSString stringWithFormat:@"rooms/%@/posts/%ld/votes", post.attributes.status.postedIn.identifier, (long)post.identifier];
    }
    else {
        // posted on a profile
        url = [NSString stringWithFormat:@"users/%@/posts/%ld/votes", post.attributes.details.creator.attributes.details.identifier, (long)post.identifier];
    }
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
    NSMutableDictionary *contextDict = [[NSMutableDictionary alloc] initWithDictionary:[post.attributes.context toDictionary]];
    [contextDict removeObjectForKey:@"vote"];
    PostContext *newContext = [[PostContext alloc] initWithDictionary:contextDict error:nil];
    post.attributes.context = newContext;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
}

#pragma mark - Misc.
+ (void)uploadImage:(BFMediaObject *)mediaObject copmletion:(void (^)(BOOL success, NSString *uploadedImageURL))handler {
    NSData *imageData = mediaObject.data;
    
    NSLog(@"data class: %@", [imageData class]);
    
    if (imageData && [imageData isKindOfClass:[NSData class]]) {
        // has images
        NSLog(@"has image to upload -> upload them then continue");
        
        [[HAWebService authenticatedManager].requestSerializer setValue:@"" forHTTPHeaderField:@"Content-Type"];
        [[HAWebService authenticatedManager] POST:kIMAGE_UPLOAD_URL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSLog(@"MIME: %@", mediaObject.MIME);
            if ([mediaObject.MIME isEqualToString:@"image/jpeg"]) {
                NSLog(@"jpeg");
                [formData appendPartWithFileData:imageData name:@"media" fileName:@"image.jpg" mimeType:mediaObject.MIME];
            }
            else if ([mediaObject.MIME isEqualToString:@"image/gif"]) {
                NSLog(@"gif");
                [formData appendPartWithFileData:imageData name:@"media" fileName:@"image.gif" mimeType:mediaObject.MIME];
            }
            else if ([mediaObject.MIME isEqualToString:@"image/png"]) {
                NSLog(@"png");
                [formData appendPartWithFileData:imageData name:@"media" fileName:@"image.png" mimeType:mediaObject.MIME];
            }
            
            NSLog(@"MIME type: %@", mediaObject.MIME);
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"--------");
            NSLog(@"response object:");
            NSLog(@"%@", responseObject);
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
}

+ (void)uploadImages:(BFMedia *)media copmletion:(void (^)(BOOL success, NSArray *uploadedImages))handler {
    __block NSUInteger remaining = media.objects.count;
    NSMutableArray *uploadedImages = [[NSMutableArray alloc] init];
    
    if (remaining == 0) {
        handler(true, nil);
    }
    
    for (NSInteger i = 0; i < remaining; i++) {
        BFMediaObject *mediaObject = media.objects[i];
        
        [self uploadImage:mediaObject copmletion:^(BOOL success, NSString *uploadedImageURL) {
            NSLog(@"upload image %li...", i + 1);
            if (success) {
                if (uploadedImageURL && uploadedImageURL.length > 0) {
                    [uploadedImages addObject:uploadedImageURL];
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



+ (NSData *)compressAndEncodeToData:(UIImage *)image
{
    //Scale Image to some width (xFinal)
    float ratio = image.size.width/image.size.height;
    float xFinal = image.size.width;
    if (image.size.width > 1125) {
        xFinal = 1125; //Desired max image width
    }
    float yFinal = xFinal/ratio;
    UIImage *scaledImage = [self imageWithImage:image scaledToSize:CGSizeMake(xFinal, yFinal)];
    
    //Compress the image iteratively until either the maximum compression threshold (maxCompression) is reached or the maximum file size requirement is satisfied (maxSize)
    CGFloat compression = 1.0f;
    CGFloat maxCompression = 0.1f;
    float maxSize = 2*1024*1024; //specified in bytes
    
    NSData *imageData = UIImageJPEGRepresentation(scaledImage, compression);
    while ([imageData length] > maxSize && compression > maxCompression) {
        compression -= 0.10;
        imageData = UIImageJPEGRepresentation(scaledImage, compression);
        NSLog(@"Compressed to: %.2f MB with Factor: %.2f",(float)imageData.length/1024.0f/1024.0f, compression);
    }
    NSLog(@"Final Image Size: %.2f MB",(float)imageData.length/1024.0f/1024.0f);
    return imageData;
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
