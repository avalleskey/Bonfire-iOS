//
//  StartCampUpsellView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "StartCampUpsellView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "Launcher.h"
#import <FBSDKShareKit/FBSDKShareKit.h>

@implementation StartCampUpsellView

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.campAvatarContainer = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - (66 / 2), 0, 66, 66)];
    self.campAvatarContainer.backgroundColor = [UIColor contentBackgroundColor];
    self.campAvatarContainer.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.campAvatarContainer.layer.shadowOffset = CGSizeMake(0, 1);
    self.campAvatarContainer.layer.shadowRadius = 1.f;
    self.campAvatarContainer.layer.shadowOpacity = 1;
//    UIImageView *campAvatarDottedOutline = [[UIImageView alloc] initWithFrame:self.campAvatarContainer.bounds];
//    campAvatarDottedOutline.image = [UIImage imageNamed:@"campDottedOutline"];
//    campAvatarDottedOutline.contentMode = UIViewContentModeScaleAspectFill;
//    [self.campAvatarContainer addSubview:campAvatarDottedOutline];
    self.campAvatarContainer.layer.cornerRadius = self.campAvatarContainer.frame.size.height / 2;
    self.campAvatarContainer.layer.masksToBounds = false;
    [self addSubview:self.campAvatarContainer];
    
    CGFloat campAvatarPadding = 4;
    self.campAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(campAvatarPadding, campAvatarPadding, self.campAvatarContainer.frame.size.width - (campAvatarPadding * 2), self.campAvatarContainer.frame.size.height - (campAvatarPadding * 2))];
    [self.campAvatarView bk_whenTapped:^{
        [Launcher shareCamp:self.camp];
    }];
    [self.campAvatarContainer addSubview:self.campAvatarView];
    
    self.campAvatarPlusIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.campAvatarContainer.frame.size.width - 24, self.campAvatarContainer.frame.size.height - 24, 24, 24)];
    self.campAvatarPlusIcon.backgroundColor = [UIColor contentBackgroundColor];
    self.campAvatarPlusIcon.image = [[UIImage imageNamed:@"shareIcon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.campAvatarPlusIcon.layer.cornerRadius = self.campAvatarPlusIcon.frame.size.height / 2;
    self.campAvatarPlusIcon.layer.shadowColor = [UIColor blackColor].CGColor;
    self.campAvatarPlusIcon.layer.shadowOffset = CGSizeMake(0, 1);
    self.campAvatarPlusIcon.layer.shadowRadius = 2.f;
    self.campAvatarPlusIcon.layer.shadowOpacity = 0.12;
    self.campAvatarPlusIcon.layer.masksToBounds = false;
    self.campAvatarPlusIcon.contentMode = UIViewContentModeCenter;
    [self.campAvatarContainer addSubview:self.campAvatarPlusIcon];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.campAvatarContainer.frame.origin.y + self.campAvatarContainer.frame.size.height + 16, self.frame.size.width, 30)];
    self.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleLabel.text = @"Start the Fire";
    [self addSubview:self.titleLabel];
    
    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width * .1, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 6, self.frame.size.width * .8, 30)];
    self.descriptionLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    self.descriptionLabel.textColor = [UIColor bonfireSecondaryColor];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.descriptionLabel.text = @"Invite at least 1 other to join the Camp before posting!";
    [self addSubview:self.descriptionLabel];
    
    self.actionsView = [[UIView alloc] initWithFrame:CGRectMake(0, self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 24, self.frame.size.width, 42)];
    [self addSubview:self.actionsView];
    
    NSMutableArray *buttons = [NSMutableArray new];
  
    [buttons addObject:@{@"id": @"bonfire", @"image": [UIImage imageNamed:@"share_bonfire"], @"color": [UIColor fromHex:@"FF513C" adjustForOptimalContrast:false]}];

    BOOL hasInstagram = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram-stories://"]];
    BOOL hasSnapchat = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"snapchat://"]];
    BOOL hasTwitter = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    
    if (hasInstagram) {
        [buttons addObject:@{@"id": @"instagram", @"image": [UIImage imageNamed:@"share_instagram"], @"color": [UIColor fromHex:@"DC3075" adjustForOptimalContrast:false]}];
    }

    if (hasTwitter && (![self.camp.attributes isPrivate] || !hasSnapchat)) {
        [buttons addObject:@{@"id": @"twitter", @"image": [UIImage imageNamed:@"share_twitter"], @"color": [UIColor fromHex:@"1DA1F2" adjustForOptimalContrast:false]}];
    }
    
    if (hasSnapchat) {
        [buttons addObject:@{@"id": @"snapchat", @"image": [UIImage imageNamed:@"share_snapchat"], @"color": [UIColor fromHex:@"fffc00" adjustForOptimalContrast:false]}];
    }
    
    if ([self.camp.attributes isPrivate] || !hasTwitter || !hasSnapchat) {
        [buttons addObject:@{@"id": @"imessage", @"image": [UIImage imageNamed:@"share_imessage"], @"color": [UIColor fromHex:@"36DB52" adjustForOptimalContrast:false]}];
    }
    
    if (buttons.count < 4) {
        // add facebook
        [buttons addObject:@{@"id": @"facebook", @"image": [UIImage imageNamed:@"share_facebook"], @"color": [UIColor fromHex:@"3B5998" adjustForOptimalContrast:false]}];
    }
    
    [buttons addObject:@{@"id": @"more", @"image": [[UIImage imageNamed:@"share_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate], @"color": [UIColor tableViewSeparatorColor]}];
    
    for (NSInteger i = 0; i < buttons.count; i++) {
        NSDictionary *buttonDict = buttons[i];
        NSString *identifier = buttonDict[@"id"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = buttonDict[@"color"];
        button.adjustsImageWhenHighlighted = false;
        button.layer.masksToBounds = true;
        button.tintColor = [UIColor bonfirePrimaryColor];
        [button setImage:buttonDict[@"image"] forState:UIControlStateNormal];
        
        button.contentMode = UIViewContentModeCenter;
        [self.actionsView addSubview:button];
        
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
            NSString *campShareLink = [NSString stringWithFormat:@"https://bonfire.camp/c/%@", self.camp.identifier];
            if ([identifier isEqualToString:@"bonfire"]) {
                [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:self.camp];
            }
            else if ([identifier isEqualToString:@"instagram"]) {
                [Launcher shareCampOnInstagram:self.camp];
            }
            else if ([identifier isEqualToString:@"twitter"]) {
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://post"]]) {
                    NSString *message = [[NSString stringWithFormat:@"Help me start a Camp on @yourbonfire! Join %@: %@", self.camp.attributes.title, campShareLink] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"]];
                    
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", message]] options:@{} completionHandler:nil];
                }
            }
            else if ([identifier isEqualToString:@"snapchat"]) {
                [Launcher shareCampOnSnapchat:self.camp];
            }
            else if ([identifier isEqualToString:@"imessage"]) {
                [Launcher shareOniMessage:[NSString stringWithFormat:@"Help me start a Camp on Bonfire! Join %@: %@", self.camp.attributes.title, campShareLink] image:nil];
            }
            else if ([identifier isEqualToString:@"facebook"]) {
                FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                content.contentURL = [NSURL URLWithString:campShareLink];
                content.hashtag = [FBSDKHashtag hashtagWithString:@"#Bonfire"];
                [FBSDKShareDialog showFromViewController:[Launcher topMostViewController]
                                             withContent:content
                                                delegate:nil];
            }
            else if ([identifier isEqualToString:@"more"]) {
                [Launcher shareCamp:self.camp];
            }
        }];
    }
    
    [self resize];
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        self.campAvatarView.camp = camp;
        [self updateDescriptionLabel];
        self.campAvatarPlusIcon.tintColor = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true];
//        self.campAvatarContainer.backgroundColor = [UIColor whiteColor]; //[[UIColor fromHex:self.camp.attributes.color] colorWithAlphaComponent:0.25]
        
        UIView *pulse = [[UIView alloc] initWithFrame:self.campAvatarContainer.frame];
        pulse.backgroundColor = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true];
        pulse.layer.cornerRadius = pulse.frame.size.height / 2;
        pulse.alpha = 0.4;
        [self insertSubview:pulse belowSubview:self.campAvatarContainer];
        [UIView animateWithDuration:1.8f delay:0.6f options:(UIViewAnimationOptionCurveEaseOut) animations:^{
            pulse.backgroundColor = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true];
            pulse.transform = CGAffineTransformMakeScale(1.45, 1.45);
            pulse.alpha = 0;
        } completion:^(BOOL finished) {
            //[pulse removeFromSuperview];
        }];
        
        [self resize];
    }
}

- (void)updateDescriptionLabel {
    BOOL isMember = [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER];
    NSInteger threshold = [Session sharedInstance].defaults.camp.membersThreshold;
    NSInteger members = self.camp.attributes.summaries.counts.members;
    NSInteger friendsNeeded = threshold - members;
    
    if ([self.camp isPrivate]) {
        self.titleLabel.text = @"Invite your Friends";
        self.descriptionLabel.text = @"Private Camps are more fun with friends!";
    }
    else {
        self.titleLabel.text = @"Start the Fire";
        
        if (friendsNeeded == 0) {
            self.descriptionLabel.text = @"Invite more friends to join the Camp before posting!";
        }
        else if (isMember) {
            self.descriptionLabel.text = [NSString stringWithFormat:@"Invite at least %lu other friend%@ to join the Camp before posting!", friendsNeeded, (friendsNeeded == 1 ? @"" : @"s")];
        }
        else {
            self.descriptionLabel.text = [NSString stringWithFormat:@"This Camp needs at least %lu other%@ to join the Camp!", friendsNeeded, (friendsNeeded == 1 ? @"" : @"s")];
        }
    }
}

- (void)resize {
    CGPoint oldCenter = self.center;
    
    CGFloat height = 0;
    CGFloat prevPadding = 0; // padding underneath the last positioned item
    
    if (![self.campAvatarContainer isHidden]) {
        height = self.campAvatarContainer.frame.origin.y + self.campAvatarContainer.frame.size.height;
        prevPadding = 12;
    }
    
    if (self.titleLabel.text.length > 0) {
        CGRect titleRect = [self.titleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.titleLabel.font} context:nil];
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, height + prevPadding, self.frame.size.width, ceilf(titleRect.size.height));
        prevPadding = 6;
        
        height = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height;
    }
    
    if (self.descriptionLabel.text.length > 0) {
        CGRect descriptionRect = [self.descriptionLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width * .8, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.descriptionLabel.font} context:nil];
        self.descriptionLabel.frame = CGRectMake(self.frame.size.width * .1, height + prevPadding, self.frame.size.width * .8, ceilf(descriptionRect.size.height));
        prevPadding = 20;
        
        height = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height;
    }
    
    if (![self.actionsView isHidden]) {
        [self layoutActionsView];
        self.actionsView.frame = CGRectMake(self.actionsView.frame.origin.x, height + prevPadding, self.actionsView.frame.size.width, self.actionsView.frame.size.height);
        
        height = self.actionsView.frame.origin.y + self.actionsView.frame.size.height;
    }
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    
    self.center = oldCenter;
}

- (void)layoutActionsView {
    CGFloat actionsViewMaxWidth = self.frame.size.width - (self.frame.origin.x * 2);
    
    NSArray *buttons = self.actionsView.subviews;
    
    CGFloat buttonPadding = 12;
    CGFloat buttonDiameter = (actionsViewMaxWidth - ((buttons.count - 1) * buttonPadding)) / buttons.count;
    CGFloat buttonMaxDiameter = 48;
    if (buttonDiameter > buttonMaxDiameter) {
        buttonDiameter = buttonMaxDiameter;
    }
    
    // inside loop
    for (NSInteger i = 0; i < buttons.count; i++) {
        UIButton *button = buttons[i];
        button.frame = CGRectMake(i * (buttonDiameter + buttonPadding), 0, buttonDiameter, buttonDiameter);
        button.layer.cornerRadius = button.frame.size.width / 2;
    }
    
    CGFloat actionsViewWidth = ((buttonDiameter + buttonPadding) * buttons.count) - buttonPadding; // remove last padding
    self.actionsView.frame = CGRectMake(self.frame.size.width / 2 - actionsViewWidth / 2, self.actionsView.frame.origin.y, actionsViewWidth, buttonDiameter);
}

@end
