//
//  PaginationCell.h
//  Hallway App
//
//  Created by Austin Valleskey on 6/18/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PaginationCell : UITableViewCell

@property BOOL loading;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end
