//
//  BFTextField.m
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFSearchView.h"
#import "UIColor+Palette.h"
#import "Session.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "SearchNavigationController.h"
#import "SearchTableViewController.h"
#import "ComplexNavigationController.h"

@implementation BFSearchView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 12.f;
        self.layer.masksToBounds = true;
        
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.textField.placeholder = @"Search";
        self.textField.textAlignment = NSTextAlignmentLeft;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightBold];
        self.textField.returnKeyType = UIReturnKeyGo;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.userInteractionEnabled = false;
        [self addSubview:self.textField];
        
        self.searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.textField.frame.size.height / 2 - 7, 14, 14)];
        self.searchIcon.image = [[UIImage imageNamed:@"miniSearchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        self.theme = BFTextFieldThemeDark;
        self.originalFrame = frame;
        
        [self showSearchIcon:false];
        [self setPosition:BFSearchTextPositionCenter];
        
        [self bk_whenTapped:^{
            if (self.openSearchControllerOntap) {
                if ([[Launcher sharedInstance].activeViewController isKindOfClass:[ComplexNavigationController class]]) {
                    SearchTableViewController *viewController = [[SearchTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    viewController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
                    viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    
                    NSLog(@"active view controller: %@", [Launcher sharedInstance].activeViewController);
                    
                    ComplexNavigationController *complexController = (ComplexNavigationController *)[Launcher sharedInstance].activeViewController;
                    [complexController.searchView updateSearchText:@""];
                    [complexController pushViewController:viewController animated:NO];
                    [complexController updateBarColor:[UIColor whiteColor] withAnimation:1 statusBarUpdateDelay:0];
                    
                    complexController.searchView.textField.userInteractionEnabled = true;
                    [complexController.searchView.textField becomeFirstResponder];
                    [complexController updateNavigationBarItemsWithAnimation:YES];
                }
            }
            else {
                self.textField.userInteractionEnabled = true;
                [self.textField becomeFirstResponder];
            }
        }];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchDown = YES;
    
    UIColor *textFieldBackgroundColor;
    if (self.theme == BFTextFieldThemeLight) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
    }
    else if (self.theme == BFTextFieldThemeDark) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
    }
    else {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnLight];
    }
    
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [textFieldBackgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    [UIView animateWithDuration:0.2f animations:^{
        self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha*2];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered when touch is released
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered if touch leaves view
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchCancel {
    UIColor *textFieldBackgroundColor;
    if (self.theme == BFTextFieldThemeLight) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
    }
    else if (self.theme == BFTextFieldThemeDark) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
    }
    else {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnLight];
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        self.backgroundColor = textFieldBackgroundColor;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}
- (void)hideSearchIcon:(BOOL)animated {
    self.searchIcon.hidden = true;
    
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    self.textField.leftView = leftPaddingView;
    
    CGRect textLabelRect = [self textFieldRect];
    self.textField.frame = CGRectMake((self.originalFrame.size.width / 2) - ((textLabelRect.size.width + self.textField.leftView.frame.size.width) / 2), self.textField.frame.origin.y, textLabelRect.size.width + self.textField.leftView.frame.size.width, self.textField.frame.size.height);
}
- (void)showSearchIcon:(BOOL)animated {
    self.searchIcon.hidden = false;
    
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14 + 8, self.frame.size.height)];
    self.searchIcon.tintColor = self.textField.textColor;
    [leftView addSubview:self.searchIcon];
    self.textField.leftView = leftView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    
    CGRect textLabelRect = [self textFieldRect];
    self.textField.frame = CGRectMake((self.originalFrame.size.width / 2) - ((textLabelRect.size.width + self.textField.leftView.frame.size.width) / 2), self.textField.frame.origin.y, textLabelRect.size.width + self.textField.leftView.frame.size.width, self.textField.frame.size.height);
}
- (void)updateSearchText:(NSString *)newSearchText {
    [self showSearchIcon:false];
    
    self.textField.text = newSearchText;
    CGRect textLabelRect = [self textFieldRect];
    
    self.textField.frame = CGRectMake((self.originalFrame.size.width / 2) - ((textLabelRect.size.width + self.textField.leftView.frame.size.width) / 2), self.textField.frame.origin.y, textLabelRect.size.width + self.textField.leftView.frame.size.width, self.textField.frame.size.height);
    
    NSLog(@"update serach text");
}

- (void)setPosition:(BFSearchTextPosition)position {
    if (position != _position) {
        _position = position;
        
        if (position == BFSearchTextPositionCenter) {
            // center align
            CGRect textLabelRect = [self textFieldRect];
            
            self.textField.frame = CGRectMake((self.originalFrame.size.width / 2) - ((textLabelRect.size.width + self.textField.leftView.frame.size.width) / 2), self.textField.frame.origin.y, textLabelRect.size.width + self.textField.leftView.frame.size.width, self.textField.frame.size.height);
        }
        else {
            // left align
           self.textField.frame = CGRectMake(16, self.textField.frame.origin.y, self.frame.size.width - 16, self.textField.frame.size.height);
        }
    }
}
- (CGRect)textFieldRect {
    NSString *text = self.textField.text.length > 0 ? self.textField.text : self.textField.placeholder;
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(self.originalFrame.size.width - self.textField.leftView.frame.size.width - self.textField.rightView.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textField.font} context:nil];
    return CGRectMake(self.originalFrame.size.width / 2 - rect.size.width / 2, self.textField.frame.origin.y, ceilf(rect.size.width), self.textField.frame.size.height);
}

- (void)setTheme:(BFTextFieldTheme)theme {
    if (theme != _theme) {
        _theme = theme;
        
        if (theme == BFTextFieldThemeLight) {
            self.backgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
            
            self.tintColor =
            self.textField.textColor = [UIColor whiteColor];
            self.searchIcon.alpha = 0.75;
        }
        else if (theme == BFTextFieldThemeDark) {
            self.backgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
            
            self.tintColor = [Session sharedInstance].themeColor;
            self.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchIcon.alpha = 0.25;
        }
        else {
            self.backgroundColor = [UIColor bonfireTextFieldBackgroundOnLight];
            
            self.tintColor =
            self.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchIcon.alpha = 0.25;
        }
        self.searchIcon.tintColor = self.textField.textColor;
        //self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:self.searchIcon.alpha],
        //                 NSFontAttributeName: self.textField.font}];
    }
}

@end
