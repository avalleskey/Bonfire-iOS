//
//  InsightsLogger.m
//  Pulse
//
//  Created by Austin Valleskey on 1/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "InsightsLogger.h"
#import "ExpandedPostCell.h"
#import "PostCell.h"
#import "Session.h"
#import "HAWebService.h"

@implementation InsightsLogger

static InsightsLogger *logger;

+ (InsightsLogger *)sharedInstance {
    if (!logger) {
        logger = [[InsightsLogger alloc] init];
        
        logger.activeTimeframes = [[NSMutableDictionary alloc] init];
        
        NSDictionary *completedTimeframes = [logger defaultsForKey:@"insights_completed_timeframes"];
        logger.completedTimeframes = [[NSMutableDictionary alloc] initWithDictionary:completedTimeframes];
        
        NSArray *queuedBatches = [logger defaultsForKey:@"insights_queued_batches"];
        logger.queuedBatches = [[NSMutableArray alloc] initWithArray:queuedBatches];
        // NSLog(@"queued batches: %ld", logger.queuedBatches.count);
        
        // IF NEEDED: create a new batch of timeframes that have exceeded max_length_hrs default
        [logger queueExceededLengthTimeframes];
        
        if (logger.queuedBatches.count > 0) {
            [logger uploadBatches];
        }
    }
    return logger;
}

- (void)queueExceededLengthTimeframes {
    /*
     END RESULT
     ––––––––––
     
     completedTimeframes =>
        remove: exceeded length timeframes
     
     newBatch =>
        add: exceeded length timeframes
     
     queuedBatches =>
        add: newBatch
     */
    NSInteger MAX_LENGTH_HRS = [Session sharedInstance].defaults.logging.insights.impressions.batching.max_length_hrs;
    
    // NSLog(@"completed timeframes count (before): %ld", (long)[self completedTimeframesCount]);
    
    NSMutableDictionary *newBatch = [[NSMutableDictionary alloc] init];
    
    NSArray *keys = logger.completedTimeframes.allKeys;
    for (NSInteger i = 0; i < keys.count; i++) {
        NSString *postId = keys[i];
        
        NSMutableArray *completedTimeframesForPost = [[NSMutableArray alloc] initWithArray:logger.completedTimeframes[postId]];
        NSMutableArray *exceededPostTimeframes = [[NSMutableArray alloc] init];
        
        for (int p = (int)completedTimeframesForPost.count - 1; p >= 0; p--) {
            InsightsLoggerTimeframe *timeframe = completedTimeframesForPost[p];
            // NSLog(@"%f / %ld", [timeframe.ts_end timeIntervalSinceNow], -1 * (MAX_LENGTH_HRS * 60 * 60));
            
            if ([timeframe.ts_end timeIntervalSinceNow] <= -1 * (MAX_LENGTH_HRS * 60 * 60)) {
                // exceeded time length
                // NSLog(@"––––– exceeded time length! –––––");
                [exceededPostTimeframes addObject:timeframe];
                [completedTimeframesForPost removeObjectAtIndex:p];
            }
        }
        
        if (exceededPostTimeframes.count > 0) {
            [newBatch setObject:exceededPostTimeframes forKey:keys[i]];
            [logger.completedTimeframes setObject:completedTimeframesForPost forKey:postId];
        }
    }
    
    // NSLog(@"exceeded timeframes batch: %@", newBatch);
    // NSLog(@"completed timeframes count (after): %ld", (long)[self completedTimeframesCount]);
    
    if (newBatch.allKeys.count > 0) {
        [logger.queuedBatches addObject:newBatch];
    }
}

- (nullable InsightsLoggerTimeframe *)activeTimeframeForPostId:(NSInteger)postId {
    NSString *idString = [self stringifyId:postId];
    if ([logger.activeTimeframes objectForKey:idString]) {
        return logger.activeTimeframes[idString];
    }
    
    return nil;
}
- (NSInteger)completedTimeframeCountForPostId:(NSInteger)postId {
    NSString *idString = [self stringifyId:postId];
    if ([logger.completedTimeframes objectForKey:idString]) {
        return ((NSArray *)logger.completedTimeframes[idString]).count;
    }
    
    return 0;
}
- (NSArray *)completedTimeframesForPostId:(NSInteger)postId {
    NSString *idString = [self stringifyId:postId];
    if ([logger.completedTimeframes objectForKey:idString]) {
        return ((NSArray *)logger.completedTimeframes[idString]);
    }
    
    return @[];
}
- (NSString *)stringifyId:(NSInteger)postId {
    return [NSString stringWithFormat:@"%ld", (long)postId];
}

- (void)openPostInsight:(NSInteger)postId seenIn:(NSString *)seenIn {
    // don't open post insight if one is already open
    if ([self activeTimeframeForPostId:postId]) {
        return;
    }
    
    // add new timeframe to current batch
    InsightsLoggerTimeframe *newTimeframe = [[InsightsLoggerTimeframe alloc] init];
    newTimeframe.seen_in = seenIn;
    
    // NSLog(@"✳️ openPostInsight(%li) seenIn(%@)", postId, seenIn);
    
    [logger.activeTimeframes setObject:newTimeframe forKey:[self stringifyId:postId]];
}
- (void)openAllVisiblePostInsightsInTableView:(UITableView *)tableView seenIn:(NSString *)seenIn {
    // NSLog(@"openAllVisiblePostInsightsInTableView()");
    NSArray *visibleCells = [tableView visibleCells];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (UITableViewCell *cell in visibleCells) {
            Post *post;
            if ([cell isKindOfClass:[PostCell class]]) {
                PostCell *postCell = (PostCell *)cell;
                post = postCell.post;
            } else if ([cell isKindOfClass:[ExpandedPostCell class]]) {
                ExpandedPostCell *PostCell = (ExpandedPostCell *)cell;
                post = PostCell.post;
            }
            else {
                continue;
            }
            
            // skip logging if invalid post identifier (most likely due to a loading cell)
            if (!post.identifier) continue;
            
            [logger openPostInsight:post.identifier seenIn:seenIn];
        }
    });
}

- (void)closePostInsight:(NSInteger)postId action:(NSString * _Nullable)action {
    NSString *idString = [self stringifyId:postId];
    if (![logger.activeTimeframes objectForKey:idString]) {
        // NSLog(@"attempted to close non-existent post insight (%ld)", (long)postId);
        return;
    }
    
    InsightsLoggerTimeframe *timeframe = logger.activeTimeframes[idString];
    timeframe.ts_end = [NSDate new];
    
    // NSLog(@"❌ closePostInsight(%li) action(%@)", postId, action);
    if (action) {
        timeframe.action = action;
    }
    
    // -- remove timeframe from activeTimeframes
    [logger.activeTimeframes removeObjectForKey:idString];
    
    // min of 1s on screen
    if ([timeframe.ts_end timeIntervalSinceDate:timeframe.ts_start] >= 1) {
        // NSLog(@"❌ closePostInsight(%li) END", postId);
        
        // -- add timeframe to completedTimeframes
        NSMutableArray *mutableCompletedTimeframes = [[NSMutableArray alloc] initWithArray:[self completedTimeframesForPostId:postId]];
        [mutableCompletedTimeframes addObject:timeframe];
        [logger.completedTimeframes setObject:mutableCompletedTimeframes forKey:idString];
        [self updateCompletedDefaults];
        
        // determine if completed timeframes meets criteria to upload
        [logger sync];
    }
    else {
        // NSLog(@"🗑 cancelPostInsight(%li) END", postId);
    }
}

- (void)closeAllPostInsights {
    // NSLog(@"closeAllPostInsights()");
    
    for (NSString *key in [logger.activeTimeframes allKeys]) {
        [self closePostInsight:[key integerValue] action:nil];
    }
}
- (void)closeAllVisiblePostInsightsInTableView:(UITableView *)tableView {
    // NSLog(@"closeAllVisiblePostInsightsInTableView()");
    
    NSArray *visibleCells = [tableView visibleCells];
    
    for (UITableViewCell *cell in visibleCells) {
        Post *post;
        if ([cell isKindOfClass:[PostCell class]]) {
            PostCell *postCell = (PostCell *)cell;
            post = postCell.post;
        } else if ([cell isKindOfClass:[ExpandedPostCell class]]) {
            ExpandedPostCell *postCell = (ExpandedPostCell *)cell;
            post = postCell.post;
        }
        else {
            continue;
        }
        
        // skip logging if invalid post identifier (most likely due to a loading cell)
        if (!post.identifier) continue;
        
        [InsightsLogger.sharedInstance closePostInsight:post.identifier action:nil];
    }
}

- (void)sync {
    BOOL createBatch = false;
    
    NSInteger MAX_TIMEFRAMES = [Session sharedInstance].defaults.logging.insights.impressions.batching.max_timeframes;
    
    // NSLog(@"%ld out of %ld", (long)[self completedTimeframesCount], (long)MAX_TIMEFRAMES);
    
    if ([self completedTimeframesCount] >= MAX_TIMEFRAMES) {
        // NSLog(@"🚨🚨🚨 copmletedTimeframes(%ld) > MAX_TIMEFRAMES(%ld) 🚨🚨🚨", (long)[self completedTimeframesCount], (long)MAX_TIMEFRAMES);
        createBatch = true;
    }
    
    if (createBatch) {
        [self addCurrentBatchToQueue];
    }
}
- (void)addCurrentBatchToQueue {
    if (logger.completedTimeframes.count > 0) {
        [logger.queuedBatches addObject:logger.completedTimeframes];
        
        logger.completedTimeframes = [[NSMutableDictionary alloc] init];
        
        [logger updateDefaults];
        
        [self uploadBatches];
    }
}
- (void)uploadAllInsights {
    [self closeAllPostInsights];
    [self addCurrentBatchToQueue];
}
- (void)uploadBatches {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableArray *queuedBatchesCopy = [[NSMutableArray alloc] initWithArray:logger.queuedBatches];
        for (NSDictionary *batch in logger.queuedBatches) {
            // simulate a POST request finishing successfully
            
            // remove object from queued batches to avoid duplicates
            [queuedBatchesCopy removeObject:batch];
            
            [Session authenticate:^(BOOL success, NSString *token) {
                HAWebService *insightsManager = [[HAWebService alloc] init];
                
                NSLog(@"set up the manager");
                
                [insightsManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                insightsManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
                
                NSDictionary *normalizedBatch = [self normalizeBatch:batch];
                [insightsManager POST:@"insights/impressions" parameters:@{@"impressions": normalizedBatch} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    // success
                    NSLog(@"successfully uploaded batch");
                    NSLog(@"response: %@", responseObject);
                    [self sync];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"failed to uploaded batch");
                    NSLog(@"error:");
                    NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    NSLog(@"%@", ErrorResponse);
                    
                    NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                    NSInteger statusCode = httpResponse.statusCode;
                    if (statusCode != 401) {
                        if (![logger.queuedBatches containsObject:batch]) {
                            [logger.queuedBatches addObject:batch];
                            [logger updateQueuedDefaults];
                        }
                    }
                }];
            }];
        }
        
        logger.queuedBatches = queuedBatchesCopy;
    });
}
- (NSDictionary *)normalizeBatch:(NSDictionary *)batch {
    NSMutableDictionary *mutableBatch = [[NSMutableDictionary alloc] init];
    
    NSArray *keys = [batch allKeys];
    for (NSInteger i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSArray *timeframes = batch[key];
        
        NSMutableArray *jsonTimeframes = [[NSMutableArray alloc] init];
        for (InsightsLoggerTimeframe *timeframe in timeframes) {
            NSMutableDictionary *jsonTimeframe = [[NSMutableDictionary alloc] init];
            if (!timeframe.ts_start || !timeframe.ts_end) continue;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            [jsonTimeframe setObject:[dateFormatter stringFromDate:timeframe.ts_start] forKey:@"ts_start"];
            [jsonTimeframe setObject:[dateFormatter stringFromDate:timeframe.ts_end] forKey:@"ts_end"];
            
            if (timeframe.seen_in) {
                [jsonTimeframe setObject:timeframe.seen_in forKey:@"seen_in"];
            }
            
            if (timeframe.action) {
                [jsonTimeframe setObject:timeframe.action forKey:@"action"];
            }
            
            [jsonTimeframes addObject:jsonTimeframe];
        }
        
        if (jsonTimeframes.count > 0) {
            [mutableBatch setObject:@{@"timeframes": jsonTimeframes} forKey:key];
        }
    }
    
    // NSLog(@"normalized batch: ");
    // NSLog(@"%@", [mutableBatch copy]);
    
    return [mutableBatch copy];
}

- (NSInteger)completedTimeframesCount {
    NSInteger completed = 0;
    for (NSString *postId in [logger.completedTimeframes allKeys]) {
        NSArray *timeframeArray = logger.completedTimeframes[postId];
        completed = completed + [timeframeArray count];
    }
    
    return completed;
}

- (void)updateDefaults {
    // NSLog(@"--- updateDefaults() ---");
    // NSLog(@"logger.completedTimeframes: %@", logger.completedTimeframes);
    [self updateCompletedDefaults];
    [self updateQueuedDefaults];
}
- (void)updateCompletedDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:[self archive:logger.completedTimeframes] forKey:@"insights_completed_timeframes"];
}
- (void)updateQueuedDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:[self archive:logger.queuedBatches] forKey:@"insights_queued_batches"];
}

- (id)defaultsForKey:(NSString *)key {
    return [self unarchive:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
}
- (NSData *)unarchive:(id)object {
    if (!object) return nil;
    
    NSData *data = [NSKeyedUnarchiver unarchiveObjectWithData:object];
    return data;
}
- (NSData *)archive:(id)object {
    if (!object) return nil;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    return data;
}

@end
