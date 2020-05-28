//
//  InviteFriendsViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 8/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "InviteFriendsViewController.h"
#import "UIColor+Palette.h"
#import "Configuration.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>
#import "BFMiniNotificationManager.h"

@interface InviteFriendsViewController ()

@property (nonatomic) NSInteger invites;

@end

@implementation InviteFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    
    [self setup];
    
    self.invites = ([Session sharedInstance].currentUser.attributes.invites) ? [Session sharedInstance].currentUser.attributes.invites.numAvailable : 0;
    
    wait(0.2f, (^{
        [BFAPI getUser:^(BOOL success) {
            if (success) {
//                UserAttributesInvites *invites = [[UserAttributesInvites alloc] initWithDictionary:@{@"num_available": @(4), @"friend_code": @"austin230"} error:nil];
//                [Session sharedInstance].currentUser.attributes.invites = invites;
                self.invites = [Session sharedInstance].currentUser.attributes.invites.numAvailable;
                
                [self.shareField setTitle:[Session sharedInstance].currentUser.attributes.invites.friendCode forState:UIControlStateNormal];
            }
        }];
    }));
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // support dark mode
    [self setGradientForLabel:self.invitesLeftLabel];
}

- (void)setup {
    UIEdgeInsets safeAreaInsets = [[UIApplication sharedApplication] keyWindow].safeAreaInsets;
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, safeAreaInsets.top + 2, 44, 44);
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor bonfirePrimaryColor];
    self.closeButton.adjustsImageWhenHighlighted = false;
    self.closeButton.contentMode = UIViewContentModeCenter;
    [self.closeButton bk_whenTapped:^{
        [self.view endEditing:TRUE];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.view addSubview:self.closeButton];
    
    self.infoView = [[UIView alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - 48, 100)]; // we adjust the height and y origin later on
    [self.view addSubview:self.infoView];
    
    // create the invites label
    self.invitesLeftLabel = [self newInvitesLabel];
    self.invitesLeftLabel.text = @"";
    
    self.inviteTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.invitesLeftLabel.frame.origin.y + self.invitesLeftLabel.frame.size.height + (self.invitesLeftLabel.frame.size.height * 0.2), self.infoView.frame.size.width, 30)];
    self.inviteTitleLabel.text = @"Invites";
    self.inviteTitleLabel.font = [UIFont systemFontOfSize:40.f weight:UIFontWeightBold];
    self.inviteTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteTitleLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.infoView addSubview:self.inviteTitleLabel];
    
    self.inviteDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.infoView.frame.size.width * .05, self.inviteTitleLabel.frame.origin.y + self.inviteTitleLabel.frame.size.height + 16, self.infoView.frame.size.width * .9, 30)];
    self.inviteDescriptionLabel.font =  [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
    self.inviteDescriptionLabel.textColor = [UIColor bonfireSecondaryColor];
    self.inviteDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteDescriptionLabel.numberOfLines = 0;
    self.inviteDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.infoView addSubview:self.inviteDescriptionLabel];
    
    CGFloat infoViewHeight = self.inviteDescriptionLabel.frame.origin.y + self.inviteDescriptionLabel.frame.size.height;
    self.infoView.frame = CGRectMake(self.infoView.frame.origin.x, self.view.frame.size.height / 2 - infoViewHeight / 2 - 48, self.infoView.frame.size.width, infoViewHeight);
        
    [self initShareBlock];
    [self layoutViews];
}

- (void)initShareBlock {
    UIView *shareBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 24 - [[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom - 116, self.view.frame.size.width, 116)];
    [self.view addSubview:shareBlock];
    
    self.shareField = [[UIButton alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
    self.shareField.backgroundColor = [UIColor cardBackgroundColor];
    self.shareField.layer.cornerRadius = 12.f;
    self.shareField.layer.masksToBounds = false;
    self.shareField.layer.shadowRadius = 2.f;
    [self.shareField setTitle:[Session sharedInstance].currentUser.attributes.invites.friendCode forState:UIControlStateNormal];
    self.shareField.layer.shadowOffset = CGSizeMake(0, 1);
    self.shareField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    self.shareField.layer.shadowOpacity = 1.f;
    [self.shareField setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    self.shareField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.shareField.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 84);
    self.shareField.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.shareField.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
    self.shareField.tag = 10;
    [shareBlock addSubview:self.shareField];
    [self.shareField bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.shareField.alpha = 0.75;
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.shareField bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.shareField.alpha = 1;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.shareField bk_whenTapped:^{
        if (self.shareField.currentTitle.length > 0) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.shareField.currentTitle;
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
            
            BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Copied!" action:nil];
            [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
        }
    }];
    
    UILabel *copyLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.shareField.frame.size.width - 20 - 64, 0, 64, self.shareField.frame.size.height)];
    copyLabel.textAlignment = NSTextAlignmentRight;
    copyLabel.text = @"Copy";
    copyLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
    copyLabel.tag = 12;
    copyLabel.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:copyLabel topLeftColor:[UIColor colorWithDisplayP3Red:0 green:0.73 blue:1 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0 green:0.46 blue:1 alpha:1]]];
    [self.shareField addSubview:copyLabel];
    
    NSMutableArray *buttons = [NSMutableArray new];
    
    BOOL hasInstagram = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram-stories://"]];
    BOOL hasSnapchat = false; //[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"snapchat://"]];
    BOOL hasTwitter = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    
    if (hasTwitter) {
        [buttons addObject:@{@"id": @"twitter", @"image": [UIImage imageNamed:@"share_twitter"], @"color": [UIColor fromHex:@"1DA1F2" adjustForOptimalContrast:false]}];
    }
    
    [buttons addObject:@{@"id": @"facebook", @"image": [UIImage imageNamed:@"share_facebook"], @"color": [UIColor fromHex:@"3B5998" adjustForOptimalContrast:false]}];
      
    if (hasInstagram) {
        [buttons addObject:@{@"id": @"instagram", @"image": [UIImage imageNamed:@"share_instagram"], @"color": [UIColor fromHex:@"DC3075" adjustForOptimalContrast:false]}];
    }
    
    if (hasSnapchat) {
        [buttons addObject:@{@"id": @"snapchat", @"image": [UIImage imageNamed:@"share_snapchat"], @"color": [UIColor fromHex:@"fffc00" adjustForOptimalContrast:false]}];
    }
    
    if (buttons.count < 4) {
        [buttons addObject:@{@"id": @"imessage", @"image": [UIImage imageNamed:@"share_imessage"], @"color": [UIColor fromHex:@"36DB52" adjustForOptimalContrast:false]}];
    }
    
    [buttons addObject:@{@"id": @"more", @"image": [[UIImage imageNamed:@"share_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate], @"color": [UIColor tableViewSeparatorColor]}];
    
    CGFloat buttonPadding = 12;
    CGFloat buttonDiameter = MIN(56, (self.view.frame.size.width - (self.shareField.frame.origin.x * 2) - (20 * 2) - ((buttons.count - 1) * buttonPadding)) / buttons.count);

    CGFloat newWidth = buttonDiameter * buttons.count + (buttonPadding * (MAX(1, buttons.count) - 1));
    CGFloat buttonOffset = (shareBlock.frame.size.width - newWidth) / 2;
    CGFloat newHeight = self.shareField.frame.origin.y + self.shareField.frame.size.height + (buttonPadding * 1.5) + buttonDiameter;
    
    shareBlock.frame = CGRectMake(shareBlock.frame.origin.x, self.view.frame.size.height - 24 - [[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom - newHeight, shareBlock.frame.size.width, newHeight);
    for (NSInteger i = 0; i < buttons.count; i++) {
        NSDictionary *buttonDict = buttons[i];
        NSString *identifier = buttonDict[@"id"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(buttonOffset + i * (buttonDiameter + buttonPadding), shareBlock.frame.size.height - buttonDiameter, buttonDiameter, buttonDiameter);
        button.layer.cornerRadius = button.frame.size.width / 2;
        button.backgroundColor = buttonDict[@"color"];
        button.adjustsImageWhenHighlighted = false;
        button.layer.masksToBounds = true;
        button.tintColor = [UIColor bonfirePrimaryColor];
        [button setImage:buttonDict[@"image"] forState:UIControlStateNormal];
        button.contentMode = UIViewContentModeCenter;
        [shareBlock addSubview:button];
        
        [button bk_addEventHandler:^(id sender) {
            [HapticHelper generateFeedback:FeedbackType_Selection];
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.transform = CGAffineTransformMakeScale(0.92, 0.92);
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
                
        [button bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.transform = CGAffineTransformIdentity;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        [button bk_whenTapped:^{
            NSString *downloadURL;
            NSString *message;
            if ([Session sharedInstance].currentUser.attributes.invites.friendCode) {
                downloadURL = [NSString stringWithFormat:@"https://bonfire.camp/invite?friend_code=%@", [Session sharedInstance].currentUser.attributes.invites.friendCode];
                message = [NSString stringWithFormat:@"Join me on Bonfire with my friend code: %@ 🔥 %@", [Session sharedInstance].currentUser.attributes.invites.friendCode, downloadURL];
            }
            else {
                downloadURL = @"https://bonfire.camp/download";
                message = [NSString stringWithFormat:@"Join me on Bonfire 🔥 %@", downloadURL];
            }
            
            if ([identifier isEqualToString:@"twitter"]) {
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://post"]]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]]] options:@{} completionHandler:nil];
                }
                else {
                    DLog(@"can't open twitter posts");
                }
            }
            else if ([identifier isEqualToString:@"instagram"]) {
                [Launcher shareOnInstagram];
            }
            else if ([identifier isEqualToString:@"imessage"]) {
                downloadURL = @"https://apps.apple.com/us/app/bonfire-groups-and-news/id1438702812";
                [Launcher shareOniMessage:message image:nil];
            }
            else if ([identifier isEqualToString:@"snapchat"]) {
                [Launcher shareOnSnapchat];
            }
            else if ([identifier isEqualToString:@"more"]) {
                UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[message] applicationActivities:nil];
                controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                
                [[Launcher topMostViewController] presentViewController:controller animated:YES completion:nil];
            }
        }];
    }
}

- (void)setInvites:(NSInteger)invites {
    if (invites != _invites || self.invitesLeftLabel.text.length == 0) {
        if (self.invitesLeftLabel.text.length > 0 && _invites == 0 && invites > _invites) {
            // 0 invites to > 0 invites
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        }
            
        _invites = invites;
        
        [self updateInvites:invites animated:self.invitesLeftLabel.text.length > 0];
    }
}

- (UILabel *)newInvitesLabel {
    UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.infoView.frame.size.width, 86)];
    newLabel.textAlignment = NSTextAlignmentCenter;
    newLabel.clipsToBounds = false;
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; // this line is important!
    NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInteger:self.invites]];
    
    newLabel.text = formatted;
    
    NSInteger fontSize = MIN(156, MAX(80, ceilf(((self.infoView.frame.size.width * .8) / newLabel.text.length) * (10 / 7))));
    newLabel.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightHeavy];
    DLog(@"New label font size: %lu", (long)fontSize);
    
    CGSize newLabelSize = [newLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, newLabel.font.lineHeight) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: newLabel.font} context:nil].size;
    CGFloat newWidth = ceilf(newLabelSize.width);
    CGFloat newHeight = ceilf(newLabelSize.height);
    newLabel.frame = CGRectMake(self.infoView.frame.size.width / 2 - newWidth / 2, newLabel.frame.origin.y, newWidth, newHeight);
    
    [self setGradientForLabel:newLabel];
    
    return newLabel;
}

- (void)updateInvites:(NSInteger)invites animated:(BOOL)animated {
    UILabel *newInvitesLabel = [self newInvitesLabel];
    newInvitesLabel.alpha = 0;
    [self.infoView addSubview:newInvitesLabel];
    
    UILabel *oldLabel = self.invitesLeftLabel;
    
    BOOL rankHeightChange = (self.newInvitesLabel.frame.size.height != newInvitesLabel.frame.size.height);
    
    [UIView animateWithDuration:animated?0.3f:0 delay:0.25f options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (oldLabel) {
            oldLabel.transform = CGAffineTransformMakeScale(0.1, 0.1);
            oldLabel.alpha = 0;
        }
        
        self.inviteDescriptionLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.invitesLeftLabel = newInvitesLabel;
        newInvitesLabel.alpha = 0;
        newInvitesLabel.transform = CGAffineTransformIdentity;
        
        if (invites == 0) {
            [self updateInviteLabelText:@"Help your friends move up the Bonfire waitlist using your Friend Code below"];
        }
        else  {
            [self updateInviteLabelText:@"Give your friends instant access to Bonfire using your Friend Code below"];
        }
        
        [UIView animateWithDuration:rankHeightChange?0.3f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutViews];
        } completion:^(BOOL finished) {
            newInvitesLabel.transform = CGAffineTransformMakeScale(0.1, 0.1);
            
            [UIView animateWithDuration:animated?0.9f:0 delay:0 usingSpringWithDamping:0.65 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                newInvitesLabel.alpha = 1;
                newInvitesLabel.transform = CGAffineTransformIdentity;
            } completion:nil];
            
            self.inviteDescriptionLabel.alpha = 1.0;
        }];
    }];
}

- (void)layoutViews {
    CGAffineTransform transform_before = self.infoView.transform;
    self.infoView.transform = CGAffineTransformIdentity;
    
    self.invitesLeftLabel.center = CGPointMake(self.infoView.frame.size.width / 2, self.invitesLeftLabel.center.y);
    
    self.inviteTitleLabel.frame = CGRectMake(0, self.invitesLeftLabel.frame.origin.y + self.invitesLeftLabel.frame.size.height - (self.invitesLeftLabel.frame.size.height * 0.2) + 32, self.infoView.frame.size.width, self.inviteTitleLabel.frame.size.height);
    
    self.inviteDescriptionLabel.frame = CGRectMake(0, self.inviteTitleLabel.frame.origin.y + self.inviteTitleLabel.frame.size.height + 12, self.infoView.frame.size.width, self.inviteDescriptionLabel.frame.size.height);
    
    CGFloat newHeight = self.inviteDescriptionLabel.frame.origin.y + self.inviteDescriptionLabel.frame.size.height;
    self.infoView.frame = CGRectMake(self.infoView.frame.origin.x, self.closeButton.frame.origin.y + self.closeButton.frame.size.height + (self.shareField.superview.frame.origin.y - (self.closeButton.frame.origin.y + self.closeButton.frame.size.height)) / 2 - newHeight / 2, self.infoView.frame.size.width, newHeight);
    
    self.infoView.transform = transform_before;
}

- (void)setGradientForLabel:(UILabel *)label {
    // light mode: 77 -> 99
    // dark mode:  23 -> 01
    
    if (self.invites == 0) {
        if (@available(iOS 13.0, *)) {
            if ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) {
                label.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:label topLeftColor:[[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.01] bottomRightColor:[[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.23]]];
            }
            else {
                label.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:label topLeftColor:[[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.23] bottomRightColor:[[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.01]]];
            }
        }
        else {
            label.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:label topLeftColor:[[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.23] bottomRightColor:[[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.01]]];
        }
    }
    else {
        label.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:label topLeftColor:[UIColor colorWithDisplayP3Red:1 green:0.35 blue:0.93 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0.90 green:0 blue:0 alpha:1]]];
    }
}
- (void)updateInviteLabelText:(NSString *)text {
    self.inviteDescriptionLabel.text = text;
    
    CGFloat descriptionHeight = ceilf([self.inviteDescriptionLabel.text boundingRectWithSize:CGSizeMake(self.inviteDescriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.inviteDescriptionLabel.font} context:nil].size.height);
    self.inviteDescriptionLabel.frame = CGRectMake(self.inviteDescriptionLabel.frame.origin.x, self.inviteDescriptionLabel.frame.origin.y, self.inviteDescriptionLabel.frame.size.width, descriptionHeight);
    
    CGFloat infoViewHeight = self.inviteDescriptionLabel.frame.origin.y + self.inviteDescriptionLabel.frame.size.height;
    
    self.infoView.frame = CGRectMake(self.infoView.frame.origin.x, self.view.frame.size.height / 2 - infoViewHeight / 2 - 48, self.infoView.frame.size.width, infoViewHeight);
}

- (UIImage *)gradientImageForView:(UIView *)view topLeftColor:(UIColor *)topLeftColor bottomRightColor:(UIColor *)bottomRightColor {
    CGSize size = view.frame.size;
    CGFloat width = size.width;
    CGFloat height = size.height;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    NSArray *colors = @[(__bridge id)topLeftColor.CGColor, (__bridge id)bottomRightColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(width, height), 0);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);

    return image;
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
