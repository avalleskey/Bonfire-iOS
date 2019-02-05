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

// 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
// 1 = Room
// 2 = User
typedef enum {
    SearchResultCellTypeNone = 0,
    SearchResultCellTypeRoom = 1,
    SearchResultCellTypeUser = 2
} SearchResultCellType;
@property (nonatomic) SearchResultCellType type;

@property (nonatomic, strong) BFAvatarView *profilePicture;
@property (nonatomic, strong) UIImageView *checkIcon;


// ---- VIEWS ----

@end
