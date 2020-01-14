//
//  CampFollowButton.h
//  Pulse
//
//  Created by Austin Valleskey on 11/26/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "FollowButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface CampFollowButton : FollowButton

- (void)updateStatus:(NSString *)status;

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *followString;
@property (nonatomic, strong) NSString *followingString;

@end

NS_ASSUME_NONNULL_END
