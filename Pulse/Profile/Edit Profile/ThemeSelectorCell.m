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

- (id)initWithColor:(NSString *)color reuseIdentifier:(NSString *)reuseIdentifier {
    self.selectedColor = color;
    
    return [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.selectorLabel = [[UILabel alloc] init];
        self.selectorLabel.text = @"Favorite Color";
        self.selectorLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.selectorLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        [self.contentView addSubview:self.selectorLabel];
        
        NSArray *colorList = @[[UIColor bonfireBlue],  // 0
                               [UIColor bonfireViolet],  // 1
                               [UIColor bonfireRed],  // 2
                               [UIColor bonfireOrange],  // 3
                               [UIColor bonfireGreenWithLevel:700],  // 4
                               [UIColor brownColor],  // 5
                               [UIColor bonfireYellow],  // 6
                               [UIColor bonfireCyanWithLevel:800],  // 7
                               [UIColor bonfireGrayWithLevel:900]]; // 8
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 106)];
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
        self.scrollView.showsHorizontalScrollIndicator = false;
        self.scrollView.showsVerticalScrollIndicator = false;
        [self.contentView addSubview:self.scrollView];
        
        CGFloat buttonSize = 46;
        CGFloat buttonSpacing = 12;
        
        if (!self.selectedColor) {
            self.selectedColor = [Session sharedInstance].currentUser.attributes.details.color;
        }
        
        self.colors = [[NSMutableArray alloc] init];
        for (int i = 0; i < [colorList count]; i++) {
            NSMutableDictionary *colorDict = [[NSMutableDictionary alloc] init];
            
            [colorDict setObject:colorList[i] forKey:@"color"];
            
            // create view
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(i * (buttonSize + buttonSpacing), 44, buttonSize, buttonSize)];
            colorOption.layer.cornerRadius = colorOption.frame.size.height / 2;
            colorOption.backgroundColor = colorList[i];
            colorOption.tag = i;
            colorOption.userInteractionEnabled = true;
            [self.scrollView addSubview:colorOption];
            
            [colorDict setObject:colorOption forKey:@"view"];
            
            [colorOption bk_whenTapped:^{
                [HapticHelper generateFeedback:FeedbackType_Selection];
                [self setColor:colorOption withAnimation:true];
            }];
            
            [self.colors addObject:colorDict];
        }
        
        self.scrollView.contentSize = CGSizeMake((colorList.count * (buttonSize + buttonSpacing)) - buttonSpacing, self.scrollView.frame.size.height);
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.selectorLabel.frame = CGRectMake(16, 16, self.frame.size.width - 32, 19);
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    for (int i = 0; i < [self.colors count]; i++) {
        NSDictionary *color = self.colors[i];
        if ([[UIColor toHex:(UIColor *)color[@"color"]] isEqualToString:self.selectedColor]) {
            [self setColor:color[@"view"] withAnimation:false];
        }
    }
}

- (void)setColor:(UIView *)sender withAnimation:(BOOL)animated {
    NSDictionary *color = self.colors.count > sender.tag ? self.colors[sender.tag] : nil;
    
    if (color && (!animated || ![[UIColor toHex:(UIColor *)color[@"color"]] isEqualToString:self.selectedColor])) {
        NSLog(@"set the color: %@", color);
        
        // remove previously selected color
        NSDictionary *previousColor;
        for (NSDictionary *colorDict in self.colors) {
            if ([[UIColor toHex:(UIColor *)colorDict[@"color"]] isEqualToString:self.selectedColor]) {
                previousColor = colorDict;
                break;
            }
        }
        NSLog(@"previousColor: %@", previousColor);
        
        if (previousColor) {
            UIView *previousColorView = previousColor[@"view"];
            
            for (UIImageView *imageView in previousColorView.subviews) {
                NSLog(@"imageView unda: %@", imageView);
                if (imageView.tag == 999) {
                    [UIView animateWithDuration:animated?0.25f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        imageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                        imageView.alpha = 0;
                    } completion:^(BOOL finished) {
                        [imageView removeFromSuperview];
                    }];
                    break;
                }
            }
        }
        
        self.selectedColor = [UIColor toHex:color[@"color"]];
        
        // add check image view
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, sender.frame.size.width + 12, sender.frame.size.height + 12)];
        checkView.contentMode = UIViewContentModeCenter;
        checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
        checkView.tag = 999;
        checkView.layer.cornerRadius = checkView.frame.size.height / 2;
        checkView.layer.borderColor = sender.backgroundColor.CGColor;
        checkView.layer.borderWidth = 3.f;
        checkView.backgroundColor = [UIColor clearColor];
        [sender addSubview:checkView];
        
        checkView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        checkView.alpha = 0;
        
        // call delegate method
        EditProfileViewController *parentVC = (EditProfileViewController *)UIViewParentController(self);
        NSLog(@"parentVC: %@", parentVC);
        [parentVC updateBarColor:color[@"color"] withAnimation:2 statusBarUpdateDelay:0];
        
        [UIView animateWithDuration:animated?0.6f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            checkView.transform = CGAffineTransformMakeScale(1, 1);
            checkView.alpha = 1;
        } completion:nil];
    }
    
}

@end
