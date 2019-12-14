//
//  OutOfDateClientViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 8/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "OutOfDateClientViewController.h"
#import "UIColor+Palette.h"
#import "Configuration.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@interface OutOfDateClientViewController ()

@end

@implementation OutOfDateClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    [self setup];
}

- (void)setup {
    UIEdgeInsets safeAreaInsets = [[UIApplication sharedApplication] keyWindow].safeAreaInsets;
    
    self.topInfoPill = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 66 / 2, safeAreaInsets.top + 24, 66, 34)];
    self.topInfoPill.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
    self.topInfoPill.layer.cornerRadius = self.topInfoPill.frame.size.height / 2;
    self.topInfoPill.layer.masksToBounds = true;
    self.topInfoPill.textAlignment = NSTextAlignmentCenter;
    self.topInfoPill.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
    self.topInfoPill.textColor = [UIColor bonfirePrimaryColor];
    self.topInfoPill.text = @"NEW";
    [self.view addSubview:self.topInfoPill];
    
    self.infoView = [[UIView alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - 48, 100)]; // we adjust the height and y origin later on
    [self.view addSubview:self.infoView];
    
    UIImageView *appIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.infoView.frame.size.width / 2 - 128 / 2, 0, 128, 128)];
    appIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"AppIcon%@_Large", [Configuration configuration]]];
    appIcon.contentMode = UIViewContentModeScaleAspectFill;

    CALayer *mask = [CALayer layer];
    mask.contents = (id)[[UIImage imageNamed:@"AppIconMask"] CGImage];
    mask.frame = CGRectMake(0, 0, appIcon.frame.size.width, appIcon.frame.size.height);
    appIcon.layer.mask = mask;
    appIcon.layer.masksToBounds = YES;
    
    [self.infoView addSubview:appIcon];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, appIcon.frame.origin.y + appIcon.frame.size.height + 16, self.infoView.frame.size.width, 30)];
    titleLabel.text = @"Update Required";
    titleLabel.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle1].pointSize weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor bonfirePrimaryColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.infoView addSubview:titleLabel];
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.infoView.frame.size.width * .05, titleLabel.frame.origin.y + titleLabel.frame.size.height + 6, self.infoView.frame.size.width * .9, 30)];
    descriptionLabel.text = @"Install the latest update to continue using Bonfire!";
    descriptionLabel.font =  [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    descriptionLabel.textColor = [UIColor bonfireSecondaryColor];
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGFloat descriptionHeight = ceilf([descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: descriptionLabel.font} context:nil].size.height);
    descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, descriptionHeight);
    [self.infoView addSubview:descriptionLabel];
    
    CGFloat infoViewHeight = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height;
    self.infoView.frame = CGRectMake(self.infoView.frame.origin.x, self.view.frame.size.height / 2 - infoViewHeight / 2 - 24, self.infoView.frame.size.width, infoViewHeight);
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(24, self.view.frame.size.height - 48 - safeAreaInsets.bottom - (HAS_ROUNDED_CORNERS ? 12 : 24), self.view.frame.size.width - (24 * 2), 48);
    self.nextButton.backgroundColor = [self.view tintColor];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.nextButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateDisabled];
    [self continuityRadiusForView:self.nextButton withRadius:14.f];
    if ([Configuration isRelease]) {
        [self.nextButton setTitle:@"Open App Store" forState:UIControlStateNormal];
    }
    else {
        [self.nextButton setTitle:@"Open TestFlight" forState:UIControlStateNormal];
    }
    [self.nextButton bk_whenTapped:^{
        NSURL *url;
        if ([Configuration isRelease]) {
            url = [NSURL URLWithString:@"https://itunes.apple.com/app/1438702812"];
        }
        else {
            url = [NSURL URLWithString:@"https://beta.itunes.apple.com/v1/app/1438702812"];
        }
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            NSLog(@"opened url!");
        }];
    }];
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 0.8;
            self.nextButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 1;
            self.nextButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.view addSubview:self.nextButton];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
