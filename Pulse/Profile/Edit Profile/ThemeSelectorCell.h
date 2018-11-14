//
//  ThemeSelectorCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThemeSelectorCell : UITableViewCell

- (id)initWithColor:(NSString *)color reuseIdentifier:(NSString *)reuseIdentifier;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *colors;
@property (strong, nonatomic) NSString *selectedColor;

@property (strong, nonatomic) UILabel *selectorLabel;

@end

NS_ASSUME_NONNULL_END
