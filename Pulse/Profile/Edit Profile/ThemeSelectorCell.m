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
        self.selectorLabel.text = @"Favorite Color";
        self.selectorLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.selectorLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        [self.contentView addSubview:self.selectorLabel];
        
        NSArray *colorList = @[@"0076FF",  // 0
                               @"9013FE",  // 1
                               @"FD1F61",  // 2
                               @"FC6A1E",  // 3
                               @"29C350",  // 4
                               @"8B572A",  // 5
                               @"F5C123",  // 6
                               @"2A6C8B",  // 7
                               @"333333"]; // 8
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 106)];
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
        self.scrollView.showsHorizontalScrollIndicator = false;
        self.scrollView.showsVerticalScrollIndicator = false;
        [self.contentView addSubview:self.scrollView];
        
        CGFloat buttonSize = 46;
        CGFloat buttonSpacing = 12;
        self.colors = [[NSMutableArray alloc] init];
        for (int i = 0; i < [colorList count]; i++) {
            NSMutableDictionary *colorDict = [[NSMutableDictionary alloc] init];
            
            [colorDict setObject:colorList[i] forKey:@"color"];
            
            // create view
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(i * (buttonSize + buttonSpacing), 44, buttonSize, buttonSize)];
            colorOption.layer.cornerRadius = colorOption.frame.size.height / 2;
            colorOption.backgroundColor = [self colorFromHexString:colorList[i]];
            colorOption.tag = i;
            colorOption.userInteractionEnabled = true;
            [self.scrollView addSubview:colorOption];
            
            if ([[colorList[i] lowercaseString] isEqualToString:[[Session sharedInstance].currentUser.attributes.details.color lowercaseString]]) {
                // add check image view
                UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, colorOption.frame.size.width + 12, colorOption.frame.size.height + 12)];
                checkView.contentMode = UIViewContentModeCenter;
                checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
                checkView.tag = 999;
                checkView.layer.cornerRadius = checkView.frame.size.height / 2;
                checkView.layer.borderColor = colorOption.backgroundColor.CGColor;
                checkView.layer.borderWidth = 3.f;
                checkView.backgroundColor = [UIColor clearColor];
                [colorOption addSubview:checkView];
                
                self.selectedColor = colorList[i];
            }
            
            [colorDict setObject:colorOption forKey:@"view"];
            
            [colorOption bk_whenTapped:^{
                NSLog(@"taaaaped");
                [self setColor:colorOption];
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
}

- (void)setColor:(UIView *)sender {
    NSDictionary *color = self.colors.count > sender.tag ? self.colors[sender.tag] : nil;
    
    if (color && ![color[@"color"] isEqualToString:self.selectedColor]) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        
        // remove previously selected color
        NSDictionary *previousColor;
        for (NSDictionary *colorDict in self.colors) {
            if ([colorDict[@"color"] isEqualToString:self.selectedColor]) {
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
                    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        imageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                        imageView.alpha = 0;
                    } completion:^(BOOL finished) {
                        [imageView removeFromSuperview];
                    }];
                    break;
                }
            }
        }
        
        self.selectedColor = color[@"color"];
        
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
        
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            checkView.transform = CGAffineTransformMakeScale(1, 1);
            checkView.alpha = 1;
        } completion:nil];
    }
    
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor blackColor];
    }
}

@end
