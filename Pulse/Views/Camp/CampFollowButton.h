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

// additional camp status that allows us to show "Edit Camp" if the user has editing priviledges
extern NSString * const CAMP_STATUS_CAN_EDIT;

- (void)updateStatus:(NSString *)status;

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *followString;

@end

NS_ASSUME_NONNULL_END
