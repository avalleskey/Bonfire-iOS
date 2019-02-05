//
//  InsightsLogger.h
//  Pulse
//
//  Created by Austin Valleskey on 1/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "InsightsLoggerTimeframe.h"

NS_ASSUME_NONNULL_BEGIN

@interface InsightsLogger : NSObject

+ (InsightsLogger *)sharedInstance;

// Currently active timeframes... no ts_end
@property (strong, nonatomic) NSMutableDictionary *activeTimeframes;

// Completed timeframes
@property (strong, nonatomic) NSMutableDictionary *completedTimeframes;

// Queued batches
@property (strong, nonatomic) NSMutableArray *queuedBatches;

- (nullable InsightsLoggerTimeframe *)activeTimeframeForPostId:(NSInteger)postId;
- (NSInteger)completedTimeframeCountForPostId:(NSInteger)postId;

- (void)openAllVisiblePostInsightsInTableView:(UITableView *)tableView seenIn:(NSString *)seenIn;

- (void)openPostInsight:(NSInteger)postId seenIn:(NSString *)seenIn;

- (void)closePostInsight:(NSInteger)postId action:(NSString * _Nullable)action;
- (void)closeAllPostInsights;
- (void)closeAllVisiblePostInsightsInTableView:(UITableView *)tableView;

- (void)uploadAllInsights;

@end

NS_ASSUME_NONNULL_END
