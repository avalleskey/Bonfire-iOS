//
//  ThemeSelectorInputCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ThemeSelectorInputCell.h"
#import "Session.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "EditProfileViewController.h"
#import "EditCampViewController.h"
#import "UIColor+Palette.h"
#import "BFColorPickerViewController.h"
#import "Launcher.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@interface ThemeSelectorInputCell() <UIScrollViewDelegate> {
    CAGradientLayer *gradientLayer;
    UIView *customLineSeparator;
}

@end

@implementation ThemeSelectorInputCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.canSetCustomColor = true;
        
        self.selectorLabel = [[UILabel alloc] init];
        self.selectorLabel.text = @"Color";
        self.selectorLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.selectorLabel.textColor = [UIColor bonfireSecondaryColor];
        [self.contentView addSubview:self.selectorLabel];
        
        NSArray *colorList = @[[UIColor bonfireBlue],  // 0
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
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
        self.scrollView.showsHorizontalScrollIndicator = false;
        self.scrollView.showsVerticalScrollIndicator = false;
        self.scrollView.delegate = self;
        [self.contentView addSubview:self.scrollView];
        
        CGFloat buttonSize = 40;
        CGFloat buttonSpacing = 8;
        
        self.customColorView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 42, buttonSize, buttonSize)];
        self.customColorView.layer.cornerRadius = self.customColorView.frame.size.height / 2;
        self.customColorView.userInteractionEnabled = true;
        self.customColorView.layer.masksToBounds = true;
        self.customColorView.image = [UIImage imageNamed:@"customColorGradient"];
        [self.customColorView bk_whenTapped:^{
            [self setColor:self.customColorView withAnimation:true];
        }];
        [self.contentView addSubview:self.customColorView];
        
        customLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.customColorView.frame.origin.x + self.customColorView.frame.size.width + buttonSpacing + 4, self.customColorView.frame.origin.y + (self.customColorView.frame.size.height / 2) - 12, 2, 24)];
        customLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        customLineSeparator.layer.cornerRadius = customLineSeparator.frame.size.width / 2;
        [self.contentView addSubview:customLineSeparator];
        
        UIView *gradientSeparator = [[UIView alloc] initWithFrame:CGRectMake(customLineSeparator.frame.origin.x + customLineSeparator.frame.size.width, 39, (buttonSpacing + 4) * 2, buttonSize + 6)];
        
        NSArray *gradientColors = [NSArray arrayWithObjects:(id)[UIColor contentBackgroundColor].CGColor, (id)[[UIColor contentBackgroundColor] colorWithAlphaComponent:0].CGColor, nil];

        gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = gradientColors;
        gradientLayer.startPoint = CGPointMake(0.1, 0.5);
        gradientLayer.endPoint = CGPointMake(0.5, 0.5);
        gradientLayer.frame = gradientSeparator.bounds;
        [gradientSeparator.layer addSublayer:gradientLayer];
        [self.contentView insertSubview:gradientSeparator belowSubview:gradientSeparator];
        
        self.scrollView.frame = CGRectMake(customLineSeparator.frame.origin.x + customLineSeparator.frame.size.width, self.scrollView.frame.origin.y, self.contentView.frame.size.width - (customLineSeparator.frame.origin.x + customLineSeparator.frame.size.width), self.scrollView.frame.size.height);
        
        
        self.colors = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < [colorList count]; i++) {
            NSMutableDictionary *colorDict = [[NSMutableDictionary alloc] init];
            
            [colorDict setObject:colorList[i] forKey:@"color"];
            
            // create view
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(4 + i * (buttonSize + buttonSpacing), 42, buttonSize, buttonSize)];
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
            self.selectedColor = [Session sharedInstance].currentUser.attributes.color;
        }
        
        self.scrollView.contentSize = CGSizeMake(4 + (colorList.count * (buttonSize + buttonSpacing)) - buttonSpacing, self.scrollView.frame.size.height);
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.selectorLabel.frame = CGRectMake(12, 12, self.frame.size.width - 24, 24);
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, 0, self.frame.size.width - self.scrollView.frame.origin.x, self.frame.size.height);
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)[UIColor contentBackgroundColor].CGColor, (id)[[UIColor contentBackgroundColor] colorWithAlphaComponent:0].CGColor, nil];
    gradientLayer.colors = gradientColors;
}

- (void)setColor:(UIView *)sender withAnimation:(BOOL)animated {
    NSDictionary *color = self.colors.count > sender.tag ? self.colors[sender.tag] : nil;
    
    if (color && (!animated || ![[UIColor toHex:(UIColor *)color[@"color"]] isEqualToString:self.selectedColor])) {
        // remove previously selected color
        for (NSInteger i = 0; i < [self.colors count]; i++) {
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
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-3, -3, sender.frame.size.width + 6, sender.frame.size.height + 6)];
        checkView.contentMode = UIViewContentModeCenter;
        checkView.image = [UIImage imageNamed:@"selectedColorCheck_small"];
        checkView.tag = 999;
        checkView.layer.cornerRadius = checkView.frame.size.height / 2;
        checkView.layer.borderColor = [((UIColor *)color[@"color"]) colorWithAlphaComponent:0.25].CGColor;
        checkView.layer.borderWidth = 3.f;
        checkView.backgroundColor = [UIColor clearColor];
        checkView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.16].CGColor;
        checkView.layer.shadowOffset = CGSizeMake(0, 1);
        checkView.layer.shadowRadius = 1.f;
        checkView.layer.shadowOpacity = 1.f;
        [sender addSubview:checkView];
        
        checkView.transform = CGAffineTransformMakeScale(0.7, 0.7);
        checkView.alpha = 0;
        
        [UIView animateWithDuration:animated?0.6f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            checkView.transform = CGAffineTransformMakeScale(1, 1);
            checkView.alpha = 1;
        } completion:nil];
    }
    
}

- (void)setSelectedColor:(NSString *)selectedColor {
    if (![selectedColor isEqualToString:_selectedColor]) {
        _selectedColor = selectedColor;
        
        _isCustomColor = true;
        for (NSInteger i = 0; i < self.colors.count; i++) {
            if ([self.selectedColor isEqualToString:[UIColor toHex:self.colors[i][@"color"]]]) {
                [self setColor:self.colors[i][@"view"] withAnimation:false];
                _isCustomColor = false;
            }
        }
        if (_isCustomColor) {
            self.customColorView.image = nil;
            self.customColorView.backgroundColor = [UIColor fromHex:self.selectedColor];
            [self setColor:self.customColorView withAnimation:false];
        }
        else {
            self.customColorView.image = [UIImage imageNamed:@"customColorGradient"];
        }
        
        [self.delegate themeSelectionDidChange:self.selectedColor];
    }
}

- (void)setIsCustomColor:(BOOL)isCustomColor {
    if (isCustomColor != _isCustomColor) {
        _isCustomColor = isCustomColor;
        
        if (_isCustomColor) {
            self.customColorView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            self.scrollView.frame = CGRectMake(100, self.scrollView.frame.origin.y, self.frame.size.width - 100, self.scrollView.frame.size.height);
            customLineSeparator.frame = CGRectMake(self.scrollView.frame.origin.x - customLineSeparator.frame.size.width, customLineSeparator.frame.origin.y, customLineSeparator.frame.size.width, customLineSeparator.frame.size.height);
        }
        else {
            self.customColorView.transform = CGAffineTransformMakeScale(1, 1);
            self.scrollView.frame = CGRectMake(customLineSeparator.frame.origin.x + customLineSeparator.frame.size.width, self.scrollView.frame.origin.y, self.frame.size.width - 100, self.scrollView.frame.size.height);
            customLineSeparator.frame = CGRectMake(self.scrollView.frame.origin.x - customLineSeparator.frame.size.width, customLineSeparator.frame.origin.y, customLineSeparator.frame.size.width, customLineSeparator.frame.size.height);
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGFloat p = MAX(MIN(x / gradientLayer.frame.size.width, 1), 0);
    
    gradientLayer.endPoint = CGPointMake(0.5 + (0.5 * p), gradientLayer.endPoint.y);
    
    NSLog(@"p : %f", p);
}

@end
