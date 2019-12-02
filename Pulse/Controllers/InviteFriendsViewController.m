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
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface InviteFriendsViewController ()

@property (nonatomic) NSInteger invites;

@end

@implementation InviteFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self setup];
    
    wait(1.f, ^{
        self.invites = 2;
    });
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
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.invitesLeftLabel.frame.origin.y + self.invitesLeftLabel.frame.size.height - 12, self.infoView.frame.size.width, 30)];
    titleLabel.text = @"Invites";
    titleLabel.font = [UIFont systemFontOfSize:40.f weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.infoView addSubview:titleLabel];
    
    self.inviteDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.infoView.frame.size.width * .05, titleLabel.frame.origin.y + titleLabel.frame.size.height + 16, self.infoView.frame.size.width * .9, 30)];
    self.inviteDescriptionLabel.font =  [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
    self.inviteDescriptionLabel.textColor = [UIColor bonfireSecondaryColor];
    self.inviteDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.inviteDescriptionLabel.numberOfLines = 0;
    self.inviteDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.infoView addSubview:self.inviteDescriptionLabel];
    
    CGFloat infoViewHeight = self.inviteDescriptionLabel.frame.origin.y + self.inviteDescriptionLabel.frame.size.height;
    self.infoView.frame = CGRectMake(self.infoView.frame.origin.x, self.view.frame.size.height / 2 - infoViewHeight / 2 - 48, self.infoView.frame.size.width, infoViewHeight);
    
    self.invites = 0;
    
    [self initShareBlock];
}

- (void)initShareBlock {
    UIView *shareBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 24 - [[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom - 116, self.view.frame.size.width, 116)];
    [self.view addSubview:shareBlock];
    
    UIButton *shareField = [[UIButton alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
    shareField.backgroundColor = [UIColor cardBackgroundColor];
    shareField.layer.cornerRadius = 12.f;
    shareField.layer.masksToBounds = false;
    shareField.layer.shadowRadius = 2.f;
    [shareField setTitle:@"austin630" forState:UIControlStateNormal];
    shareField.layer.shadowOffset = CGSizeMake(0, 1);
    shareField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    shareField.layer.shadowOpacity = 1.f;
    [shareField setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    shareField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    shareField.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 84);
    shareField.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    shareField.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
    shareField.tag = 10;
    [shareBlock addSubview:shareField];
    [shareField bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            shareField.alpha = 0.75;
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [shareField bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            shareField.alpha = 1;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [shareField bk_whenTapped:^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = shareField.currentTitle;
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        HUD.tintColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.textLabel.text = @"Copied Link!";
        HUD.vibrancyEnabled = false;
        HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        
        [HUD showInView:self.view animated:YES];
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        [HUD dismissAfterDelay:1.5f];
    }];
    
    UILabel *copyLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareField.frame.size.width - 20 - 64, 0, 64, shareField.frame.size.height)];
    copyLabel.textAlignment = NSTextAlignmentRight;
    copyLabel.text = @"Copy";
    copyLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
    copyLabel.tag = 12;
    copyLabel.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:copyLabel topLeftColor:[UIColor colorWithDisplayP3Red:0 green:0.73 blue:1 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0 green:0.46 blue:1 alpha:1]]];
    [shareField addSubview:copyLabel];
    
    NSArray *buttons = @[
//                        @{@"id": @"bonfire", @"image": [UIImage imageNamed:@"share_bonfire"], @"color": [UIColor fromHex:@"FF513C" adjustForOptimalContrast:false]},
                        @{@"id": @"snapchat", @"image": [UIImage imageNamed:@"share_snapchat"], @"color": [UIColor fromHex:@"fffc00" adjustForOptimalContrast:false]},
                        @{@"id": @"facebook", @"image": [UIImage imageNamed:@"share_facebook"], @"color": [UIColor fromHex:@"3B5998" adjustForOptimalContrast:false]},
                        @{@"id": @"twitter", @"image": [UIImage imageNamed:@"share_twitter"], @"color": [UIColor fromHex:@"1DA1F2" adjustForOptimalContrast:false]},
                        @{@"id": @"imessage", @"image": [UIImage imageNamed:@"share_imessage"], @"color": [UIColor fromHex:@"36DB52" adjustForOptimalContrast:false]},
                        @{@"id": @"more", @"image": [UIImage imageNamed:@"share_more"], @"color": [UIColor tableViewSeparatorColor]}
                        ];
    
    CGFloat buttonPadding = 12;
    CGFloat buttonDiameter = (self.view.frame.size.width - (shareField.frame.origin.x * 2) - (20 * 2) - ((buttons.count - 1) * buttonPadding)) / buttons.count;
    
    CGFloat newHeight = shareField.frame.origin.y + shareField.frame.size.height + (buttonPadding * 1.5) + buttonDiameter;
    shareBlock.frame = CGRectMake(shareBlock.frame.origin.x, self.view.frame.size.height - 24 - [[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom - newHeight, shareBlock.frame.size.width, newHeight);
    for (NSInteger i = 0; i < buttons.count; i++) {
        NSDictionary *buttonDict = buttons[i];
        NSString *identifier = buttonDict[@"id"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(shareField.frame.origin.x + 20 + i * (buttonDiameter + buttonPadding), shareBlock.frame.size.height - buttonDiameter, buttonDiameter, buttonDiameter);
        button.layer.cornerRadius = button.frame.size.width / 2;
        button.backgroundColor = buttonDict[@"color"];
        button.adjustsImageWhenHighlighted = false;
        button.layer.masksToBounds = true;
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
            NSString *message = [NSString stringWithFormat:@"Join me on Bonfire 🔥 https://bonfire.camp/download"];
            if ([identifier isEqualToString:@"twitter"]) {
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://post"]]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", message]] options:@{} completionHandler:nil];
                }
            }
            else if ([identifier isEqualToString:@"facebook"]) {
                FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                content.contentURL = [NSURL URLWithString:@"https://bonfire.camp/download"];
                content.hashtag = [FBSDKHashtag hashtagWithString:@"#Bonfire"];
                [FBSDKShareDialog showFromViewController:self
                                              withContent:content
                                                                 delegate:nil];
            }
            else if ([identifier isEqualToString:@"imessage"]) {
                [Launcher shareOniMessage:message image:nil];
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
    UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.infoView.frame.size.width, 187)];
    newLabel.font = [UIFont systemFontOfSize:156.f weight:UIFontWeightHeavy];
    newLabel.textAlignment = NSTextAlignmentCenter;
    
    return newLabel;
}

- (void)updateInvites:(NSInteger)invites animated:(BOOL)animated {
    UILabel *newInvitesLeftLabel = [self newInvitesLabel];
    newInvitesLeftLabel.text = [NSString stringWithFormat:@"%lu", (long)invites];
    CGFloat dynamicWidth = ceilf([newInvitesLeftLabel.text boundingRectWithSize:CGSizeMake(self.invitesLeftLabel.superview.frame.size.width, newInvitesLeftLabel.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: newInvitesLeftLabel.font} context:nil].size.width);
    SetWidth(newInvitesLeftLabel, dynamicWidth);
    newInvitesLeftLabel.center = CGPointMake(self.infoView.frame.size.width / 2, newInvitesLeftLabel.center.y);
    
    if (invites == 0) {
        newInvitesLeftLabel.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:newInvitesLeftLabel topLeftColor:[UIColor colorWithDisplayP3Red:0.77 green:0.77 blue:0.77 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0.99 green:0.99 blue:0.99 alpha:1]]];
    }
    else {
        newInvitesLeftLabel.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:newInvitesLeftLabel topLeftColor:[UIColor colorWithDisplayP3Red:1 green:0.66 blue:0.24 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:1 green:0 blue:0.92 alpha:1]]];
    }
    
    newInvitesLeftLabel.alpha = 0;
    [self.infoView addSubview:newInvitesLeftLabel];
    newInvitesLeftLabel.transform = CGAffineTransformMakeScale(0.01, 0.01);
    
    [UIView animateWithDuration:animated?0.7f:0 delay:0 usingSpringWithDamping:0.65 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        newInvitesLeftLabel.alpha = 1;
        newInvitesLeftLabel.transform = CGAffineTransformIdentity;
        
        if (self.invitesLeftLabel) {
            self.invitesLeftLabel.transform = CGAffineTransformMakeScale(0.01, 0.01);
            self.invitesLeftLabel.alpha = 0;
        }
        
        self.inviteDescriptionLabel.alpha = 0.0;
        self.inviteDescriptionLabel.transform = CGAffineTransformMakeTranslation(0, 8);
    } completion:^(BOOL finished) {
        if (self.invitesLeftLabel != newInvitesLeftLabel) {
            self.invitesLeftLabel = newInvitesLeftLabel;
        }
    }];
    
    [UIView animateWithDuration:animated?0.6f:0 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.inviteDescriptionLabel.alpha = 0.0;
        self.inviteDescriptionLabel.transform = CGAffineTransformMakeTranslation(0, 12);
    } completion:^(BOOL finished) {
        if (invites == 0) {
            [self updateInviteLabelText:@"Help your friends move up the Bonfire waitlist using your Friend Code below"];
        }
        else  {
            [self updateInviteLabelText:@"Give your friends instant access to Bonfire using your Friend Code below"];
        }
        
        [UIView animateWithDuration:animated?0.6f:0 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.inviteDescriptionLabel.alpha = 1.0;
            self.inviteDescriptionLabel.transform = CGAffineTransformMakeTranslation(0, 0);
        } completion:nil];
    }];
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
