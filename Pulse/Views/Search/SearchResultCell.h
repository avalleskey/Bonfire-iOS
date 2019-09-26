//
//  SearchResultCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

@interface SearchResultCell : UITableViewCell

// ---- VALUES ----

@property (nonatomic, strong) BFAvatarView *profilePicture;
@property (nonatomic, strong) UIImageView *checkIcon;

@property (nonatomic, strong) UIView *lineSeparator;

@property (nonatomic, strong) Camp *camp;
@property (nonatomic, strong) User *user;

// ---- VIEWS ----

@end
