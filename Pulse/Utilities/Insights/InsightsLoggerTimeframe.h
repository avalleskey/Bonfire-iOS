//
//  InsightsLoggerTimeframe.h
//  Pulse
//
//  Created by Austin Valleskey on 1/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InsightsLoggerTimeframe : NSObject <NSCoding> {
    NSDate *ts_start;
    NSDate *ts_end;
    NSString *seen_in;
    NSArray *actions;
}

extern NSString * const InsightActionTypeMediaOpen;
extern NSString * const InsightActionTypeProfileOpen;
extern NSString * const InsightActionTypeDetailExpand;
extern NSString * const InsightActionTypeLinkOpen;

extern NSString * const InsightSeenInCampView;
extern NSString * const InsightSeenInPostView;
extern NSString * const InsightSeenInProfileView;
extern NSString * const InsightSeenInHomeView; // /streams/me

@property (nonatomic, copy) NSDate *ts_start;
@property (nonatomic, copy) NSDate *ts_end;
@property (nonatomic, copy) NSString *seen_in;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy, nullable) NSArray *actions;

@end

NS_ASSUME_NONNULL_END
