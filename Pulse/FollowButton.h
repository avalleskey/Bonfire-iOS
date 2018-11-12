//
//  FollowButton.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FollowButton : UIButton

@property (nonatomic, strong) NSString *status;

- (void)updateStatus:(NSString *)status;

@end
