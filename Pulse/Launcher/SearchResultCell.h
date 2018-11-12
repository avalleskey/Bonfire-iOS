//
//  SearchResultCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchResultCell : UITableViewCell

// ---- VALUES ----

// 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
// 1 = Room
// 2 = User
@property (nonatomic) int type;


// ---- VIEWS ----
@property (strong, nonatomic) UIView *selectionBackground;
@property (strong, nonatomic) UIView *lineSeparator;

@end
