//
//  BFDetailsLabel.h
//  Pulse
//
//  Created by Austin Valleskey on 1/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ResponsiveLabel/ResponsiveLabel.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    BFDetailTypePrivacyPublic = 1,
    BFDetailTypePrivacyPrivate = 2,
    BFDetailTypeMembers = 3,
    BFDetailTypeLocation = 4,
    BFDetailTypeWebsite = 5
} BFDetailType;

@interface BFDetailsLabel : ResponsiveLabel

@property (nonatomic, strong) NSArray *details;
+ (NSAttributedString *)attributedStringForDetails:(NSArray *)details linkColor:(UIColor * _Nullable)linkColor;

+ (NSDictionary *)BFDetailWithType:(BFDetailType)type value:(id)value action:(PatternTapResponder _Nullable)tapResponder;

@end

NS_ASSUME_NONNULL_END
