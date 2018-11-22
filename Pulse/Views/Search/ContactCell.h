//
//  ContactCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactCell : UITableViewCell

// ---- VIEWS ----
@property (strong, nonatomic) UIImageView *checkIcon;
@property (strong, nonatomic) UIView *lineSeparator;

@property (nonatomic) BOOL isSearching;

@end
