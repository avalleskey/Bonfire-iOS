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
@property (nonatomic, strong) UIImageView *checkIcon;
@property (nonatomic, strong) UIView *lineSeparator;

@property (nonatomic) BOOL isSearching;

@end
