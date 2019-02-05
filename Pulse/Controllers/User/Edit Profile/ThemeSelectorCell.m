//
//  ThemeSelectorCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ThemeSelectorCell.h"
#import "Session.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "EditProfileViewController.h"
#import "EditRoomViewController.h"
#import "UIColor+Palette.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@implementation ThemeSelectorCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.selectorLabel = [[UILabel alloc] init];
        self.selectorLabel.text = @"Theme Color";
        self.selectorLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.selectorLabel.textColor = [UIColor colorWithWhite:0.47f alpha:1];
        [self.contentView addSubview:self.selectorLabel];
        
        NSArray *colorList = @[[UIColor bonfireBlueWithLevel:500],  // 0
                               [UIColor bonfireViolet],  // 1
                               [UIColor fromHex:@"F5498B"],  // 3
                               [UIColor bonfireRed],  // 2
                               [UIColor bonfireOrange],  // 3
                               [UIColor colorWithRed:0.96 green:0.76 blue:0.23 alpha:1.00],  // yellow
                               [UIColor colorWithRed:0.16 green:0.72 blue:0.01 alpha:1.00], // cash green
                               [UIColor bonfireGreenWithLevel:800],  // 4
                               [UIColor bonfireCyanWithLevel:800],  // 7
                               [UIColor brownColor],  // 5
                               [UIColor bonfireGrayWithLevel:900]]; // 8
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 98)];
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
        self.scrollView.showsHorizontalScrollIndicator = false;
        self.scrollView.showsVerticalScrollIndicator = false;
        [self.contentView addSubview:self.scrollView];
        
        CGFloat buttonSize = 40;
        CGFloat buttonSpacing = 8;
        
        self.colors = [[NSMutableArray alloc] init];
        for (int i = 0; i < [colorList count]; i++) {
            NSMutableDictionary *colorDict = [[NSMutableDictionary alloc] init];
            
            [colorDict setObject:colorList[i] forKey:@"color"];
            
            // create view
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(i * (buttonSize + buttonSpacing), 42, buttonSize, buttonSize)];
            colorOption.layer.cornerRadius = colorOption.frame.size.height / 2;
            colorOption.backgroundColor = colorList[i];
            colorOption.tag = i;
            colorOption.userInteractionEnabled = true;
            [self.scrollView addSubview:colorOption];
            
            [colorDict setObject:colorOption forKey:@"view"];
            
            [colorOption bk_whenTapped:^{
                [HapticHelper generateFeedback:FeedbackType_Selection];
                self.selectedColor = [UIColor toHex:self.colors[colorOption.tag][@"color"]];
            }];
            
            [self.colors addObject:colorDict];
        }
        
        if (!self.selectedColor) {
            self.selectedColor = [Session sharedInstance].currentUser.attributes.details.color;
        }
        
        self.scrollView.contentSize = CGSizeMake((colorList.count * (buttonSize + buttonSpacing)) - buttonSpacing, self.scrollView.frame.size.height);
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.selectorLabel.frame = CGRectMake(16, 12, self.frame.size.width - 32, 24);
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (void)setColor:(UIView *)sender withAnimation:(BOOL)animated {
    NSDictionary *color = self.colors.count > sender.tag ? self.colors[sender.tag] : nil;
    
    if (color && (!animated || ![[UIColor toHex:(UIColor *)color[@"color"]] isEqualToString:self.selectedColor])) {
        // remove previously selected color
        for (int i = 0; i < [self.colors count]; i++) {
            if ([self.colors[i][@"view"] viewWithTag:999]) {
                UIImageView *imageView = [self.colors[i][@"view"] viewWithTag:999];
                [UIView animateWithDuration:animated?0.25f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    imageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    imageView.alpha = 0;
                } completion:^(BOOL finished) {
                    [imageView removeFromSuperview];
                }];
            }
        }
        
        // add check image view
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-4, -4, sender.frame.size.width + 8, sender.frame.size.height + 8)];
        checkView.contentMode = UIViewContentModeCenter;
        checkView.image = [UIImage imageNamed:@"selectedColorCheck_small"];
        checkView.tag = 999;
        checkView.layer.cornerRadius = checkView.frame.size.height / 2;
        checkView.layer.borderColor = sender.backgroundColor.CGColor;
        checkView.layer.borderWidth = 2.f;
        checkView.backgroundColor = [UIColor clearColor];
        [sender addSubview:checkView];
        
        checkView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        checkView.alpha = 0;
        
        // call delegate method
        if ([UIViewParentController(self) isKindOfClass:[EditProfileViewController class]]) {
            EditProfileViewController *parentVC = (EditProfileViewController *)UIViewParentController(self);
            [parentVC updateBarColor:color[@"color"] withAnimation:2 statusBarUpdateDelay:0];
        }
        else if ([UIViewParentController(self) isKindOfClass:[EditRoomViewController class]]) {
            EditRoomViewController *parentVC = (EditRoomViewController *)UIViewParentController(self);
            [parentVC updateBarColor:color[@"color"] withAnimation:2 statusBarUpdateDelay:0];
        }
        
        [UIView animateWithDuration:animated?0.6f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            checkView.transform = CGAffineTransformMakeScale(1, 1);
            checkView.alpha = 1;
        } completion:nil];
    }
    
}

- (void)setSelectedColor:(NSString *)selectedColor {
    if (![selectedColor isEqualToString:_selectedColor]) {
        _selectedColor = selectedColor;
        
        NSLog(@"selected color: %@", _selectedColor);
        
        for (int i = 0; i < self.colors.count; i++) {
            NSLog(@"%@ : %@", [UIColor toHex:self.colors[i][@"color"]], self.selectedColor);
            if ([self.selectedColor isEqualToString:[UIColor toHex:self.colors[i][@"color"]]]) {
                [self setColor:self.colors[i][@"view"] withAnimation:false];
            }
        }
    }
}

@end
