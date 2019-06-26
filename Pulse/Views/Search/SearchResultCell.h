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

typedef enum {
    SearchResultCellTypeNone = 0,
    SearchResultCellTypeCamp = 1,
    SearchResultCellTypeUser = 2
} SearchResultCellType;
@property (nonatomic) SearchResultCellType type;

@property (nonatomic, strong) BFAvatarView *profilePicture;
@property (nonatomic, strong) UIImageView *checkIcon;

// ---- VIEWS ----

@end
