//
//  ThemeSelectorCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ThemeSelectorDelegate <NSObject>

- (void)themeSelectionDidChange:(NSString *)newHex;

@end

@interface ThemeSelectorCell : UITableViewCell

@property (strong, nonatomic) UIView *scrollViewContainer;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *colors;
@property (strong, nonatomic) NSString *selectedColor;

@property (strong, nonatomic) UILabel *selectorLabel;

@property (nonatomic) BOOL canSetCustomColor;
@property (strong, nonatomic) UIImageView *customColorView;
@property (strong, nonatomic) UITextField *customColorTextField;

@property (nonatomic, weak) id <ThemeSelectorDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
