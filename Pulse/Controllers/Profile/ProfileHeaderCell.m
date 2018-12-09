//
//  ProfileHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfileHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "Session.h"
#import "Launcher.h"
#import <Tweaks/FBTweakInline.h>

@implementation ProfileHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:32.f weight:UIFontWeightHeavy];
        self.textLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        self.statsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 48)];
        [self.contentView addSubview:self.statsView];
        
        self.statActionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.statActionButton.frame = CGRectMake(0, 0, self.frame.size.width / 2, 14);
        [self.statActionButton setTitleColor: [UIColor colorWithWhite:0 alpha:0.8f] forState:UIControlStateNormal];
        [self.statActionButton.titleLabel setFont:[UIFont systemFontOfSize:14.f weight:UIFontWeightBold]];
        [self.statActionButton setTitle:[NSString stringWithFormat:@"0 %@", [self isCurrentUser] ? @"following" : @"rooms"] forState:UIControlStateNormal];
        [self.statsView addSubview:self.statActionButton];
        
        self.postsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 2, 0, self.frame.size.width / 2, 14)];
        self.postsCountLabel.textAlignment = NSTextAlignmentCenter;
        self.postsCountLabel.textColor = [UIColor colorWithWhite:0 alpha:0.8f];
        self.postsCountLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.postsCountLabel.text = @"450 posts";
        [self.statsView addSubview:self.postsCountLabel];
        
        self.statsViewMiddleSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 0.5, 16, 1, 16)];
        self.statsViewMiddleSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
        self.statsViewMiddleSeparator.layer.cornerRadius = 1.f;
        self.statsViewMiddleSeparator.layer.masksToBounds = true;
        [self.statsView addSubview:self.statsViewMiddleSeparator];
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 24, 80, 80)];
        self.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.contentView addSubview:self.profilePicture];
        
        self.followButton = [UserFollowButton buttonWithType:UIButtonTypeCustom];
        
        [self.followButton bk_whenTapped:^{
            // update state if possible
            if ([self.followButton.status isEqualToString:USER_STATUS_ME]) {
                [[Launcher sharedInstance] openEditProfile];
            }
            else if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWS] ||
                     [self.followButton.status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
                // UNFOLLOW User
                if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWS]) {
                    [self.followButton updateStatus:USER_STATUS_NO_RELATION];
                }
                else if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
                    [self.followButton updateStatus:USER_STATUS_FOLLOWED];
                }
                [self updateUserStatus];
                
                [[Session sharedInstance] unfollowUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success unfollowing user");
                    }
                }];
            }
            else if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWED] ||
                     [self.followButton.status isEqualToString:USER_STATUS_NO_RELATION] ||
                     self.followButton.status.length == 0) {
                // follow the user
                
                // TODO: Add private user check -> "Requested"
                // (self.user.attributes.status.visibility.isPrivate) &&
                // ![self.followButton.status isEqualToString:USER_STATUS_FOLLOWED]
                
                if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWED]) {
                    [self.followButton updateStatus:USER_STATUS_FOLLOW_BOTH];
                }
                else {
                    [self.followButton updateStatus:USER_STATUS_FOLLOWS];
                }
                [self updateUserStatus];
                
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                [[Session sharedInstance] followUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success following user");
                    }
                }];
                
                SKView *spriteKitView = [self.contentView viewWithTag:99];
                if (spriteKitView == nil) {
                    spriteKitView = [[SKView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
                    spriteKitView.backgroundColor = [UIColor clearColor];
                    spriteKitView.userInteractionEnabled = false;
                    spriteKitView.tag = 99;
                    [self.contentView insertSubview:spriteKitView atIndex:0];
                    
                    SKScene *scene = [[SKScene alloc] init];
                    scene.scaleMode = SKSceneScaleModeAspectFit;
                    scene.backgroundColor = [UIColor clearColor];
                    scene.size = spriteKitView.bounds.size;
                    
                    [spriteKitView presentScene:scene];
                }
                
                SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"SparkAnimation" ofType:@"sks"]];
                emitter.position = CGPointMake(self.frame.size.width / 2 , self.followButton.center.y);
                [spriteKitView.scene addChild:emitter];
            }
            else if ([self.followButton.status isEqualToString:USER_STATUS_BLOCKED]) {
                // show alert maybe? --> ideally we don't even show the button.
            }
        }];
        [self.contentView addSubview:self.followButton];
        
        BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", NO);
        if (circleProfilePictures) {
            [self continuityRadiusForView:self.profilePicture withRadius:self.profilePicture.frame.size.height * .5];
        }
        else {
            [self continuityRadiusForView:self.profilePicture withRadius:self.profilePicture.frame.size.height * .25];
        }
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        [self.contentView addSubview:self.lineSeparator];
    }
    return self;
}

- (void)updateUserStatus {
    UserContext *context = [[UserContext alloc] initWithDictionary:[self.user.attributes.context toDictionary] error:nil];
    self.user.attributes.context = context;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdated" object:self.user];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.profilePicture.tintColor = self.tintColor;
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    // profile picture
    self.profilePicture.frame = CGRectMake(self.frame.size.width / 2 - self.profilePicture.frame.size.width / 2, self.profilePicture.frame.origin.y, self.profilePicture.frame.size.width, self.profilePicture.frame.size.height);
    
    // text label
    CGRect textLabelRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil];
    self.textLabel.frame = CGRectMake(24, 116, self.frame.size.width - 48, textLabelRect.size.height);
    
    // detail text label
    CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 4, self.textLabel.frame.size.width, detailLabelRect.size.height);
    
    self.followButton.frame = CGRectMake(20, self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height + 14, self.frame.size.width - (20 * 2), 36);
    
    self.statsView.frame = CGRectMake(0, self.followButton.frame.origin.y + self.followButton.frame.size.height, self.frame.size.width, self.statsView.frame.size.height);
    self.statsViewMiddleSeparator.frame = CGRectMake(self.statsView.frame.size.width / 2, self.statsViewMiddleSeparator.frame.origin.y, self.statsViewMiddleSeparator.frame.size.width, self.statsViewMiddleSeparator.frame.size.height);
    
    self.statActionButton.frame = CGRectMake(12, 0, self.statsView.frame.size.width / 2 - 12, self.statsView.frame.size.height);
    self.postsCountLabel.frame = CGRectMake(self.statsView.frame.size.width / 2, 0, self.statsView.frame.size.width / 2 - 12, self.statsView.frame.size.height);
    
    self.followButton.hidden = (self.user.identifier.length == 0);
    self.statsView.hidden = (self.user.identifier.length == 0);
}

- (void)styleMemberProfilePictureView:(UIImageView *)imageView  {
    imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    imageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    imageView.layer.cornerRadius = imageView.frame.size.height / 2;
    imageView.layer.masksToBounds = true;
    
    UIView * externalBorder = [[UIView alloc] init];
    externalBorder.frame = CGRectMake(imageView.frame.origin.x - 2, imageView.frame.origin.y - 2, imageView.frame.size.width+4, imageView.frame.size.height+4);
    externalBorder.backgroundColor = [UIColor whiteColor];
    externalBorder.layer.cornerRadius = externalBorder.frame.size.height / 2;
    externalBorder.layer.masksToBounds = true;
    
    [imageView.superview insertSubview:externalBorder belowSubview:imageView];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (BOOL)isCurrentUser {
    return [self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
}

@end
