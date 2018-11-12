//
//  RoomHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "Defaults.h"
#import <SpriteKit/SpriteKit.h>
#import "RoomViewController.h"

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
        })

@implementation RoomHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        //self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        self.backgroundColor = [UIColor whiteColor];
        
        self.contentView.layer.masksToBounds = false;
        self.layer.masksToBounds = false;
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy];
        self.nameLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.numberOfLines = 0;
        self.nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.nameLabel];
        
        self.descriptionLabel = [[UILabel alloc] init];
        self.descriptionLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        self.descriptionLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.descriptionLabel];
        
        self.statsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 48)];
        [self.contentView addSubview:self.statsView];
        
        self.membersLabel = [UIButton buttonWithType:UIButtonTypeSystem];
        self.membersLabel.frame = CGRectMake(0, 0, self.frame.size.width / 2, 14);
        [self.membersLabel setTitleColor: [UIColor colorWithWhite:0 alpha:0.8f] forState:UIControlStateNormal];
        [self.membersLabel.titleLabel setFont:[UIFont systemFontOfSize:14.f weight:UIFontWeightBold]];
        [self.membersLabel setTitle:[NSString stringWithFormat:@"0 %@", [Session sharedInstance].defaults.room.membersTitle.plural] forState:UIControlStateNormal];
        [self.statsView addSubview:self.membersLabel];
        
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
        
        self.actionsBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 32)];
        [self.contentView addSubview:self.actionsBarView];
        
        self.membersContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.actionsBarView.frame.size.width, self.actionsBarView.frame.size.height)];
        [self.actionsBarView addSubview:self.membersContainer];
        
        self.member1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        self.member1.layer.cornerRadius = self.member1.frame.size.height / 2;
        self.member1.layer.masksToBounds = true;
        
        self.infoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        self.infoButton.layer.cornerRadius = self.infoButton.frame.size.height / 2;
        self.infoButton.layer.masksToBounds = true;
        self.infoButton.layer.borderColor = self.backgroundColor.CGColor;
        self.infoButton.layer.borderWidth = 2.f;
        self.infoButton.backgroundColor = [UIColor whiteColor];
        [self.infoButton setImage:[[UIImage imageNamed:@"infoIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.infoButton.hidden = true;
        [self.contentView addSubview:self.infoButton];
        
        self.member2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.member3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        
        self.member4 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member5 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        
        self.member6 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member7 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        
        [self.membersContainer addSubview:self.member1];
        [self.membersContainer addSubview:self.member2];
        [self.membersContainer addSubview:self.member3];
        [self.membersContainer addSubview:self.member4];
        [self.membersContainer addSubview:self.member5];
        [self.membersContainer addSubview:self.member6];
        [self.membersContainer addSubview:self.member7];
        
        [self styleMemberProfilePictureView:self.member1];
        [self styleMemberProfilePictureView:self.member2];
        [self styleMemberProfilePictureView:self.member3];
        [self styleMemberProfilePictureView:self.member4];
        [self styleMemberProfilePictureView:self.member5];
        [self styleMemberProfilePictureView:self.member6];
        [self styleMemberProfilePictureView:self.member7];
        
        self.followButton = [FollowButton buttonWithType:UIButtonTypeCustom];
        
        [self.followButton bk_whenTapped:^{
            // update state if possible
            if ([self.followButton.status isEqualToString:STATUS_MEMBER] ||
                [self.followButton.status isEqualToString:STATUS_REQUESTED]) {
                // leave the room
                [self.followButton updateStatus:STATUS_LEFT];
                
                [[Session sharedInstance] unfollowRoom:self.room.identifier completion:^(BOOL success, id responseObject) {
                    if (success) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
                    }
                }];
            }
            else if ([self.followButton.status isEqualToString:STATUS_LEFT] ||
                     [self.followButton.status isEqualToString:STATUS_NO_RELATION] ||
                     [self.followButton.status isEqualToString:STATUS_INVITED] ||
                     self.followButton.status.length == 0) {
                // join the room
                if (self.room.attributes.status.discoverability.isPrivate &&
                    ![self.followButton.status isEqualToString:STATUS_INVITED]) {
                    [self.followButton updateStatus:STATUS_REQUESTED];
                }
                else {
                    // since they've been invited already, jump straight to being a member
                    [self.followButton updateStatus:STATUS_MEMBER];
                    
                    /* TODO: Reload table view and remvoe locked error view
                    if ([UIViewParentController(self) isKindOfClass:[RoomViewController class]]) {
                        RoomViewController *parentRoomVC = (RoomViewController *)UIViewParentController(self);
                        [parentRoomVC.tableView reloadData];
                    }*/
                }
                
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                [[Session sharedInstance] followRoom:self.room.identifier completion:^(BOOL success, id responseObject) {
                    if (success) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
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
            else if ([self.followButton.status isEqualToString:STATUS_BLOCKED]) {
                // show alert maybe? --> ideally we don't even show the button.
            }
        }];
        [self.contentView addSubview:self.followButton];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        [self.contentView addSubview:self.lineSeparator];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - 1 / [UIScreen mainScreen].scale, self.frame.size.width, 1 / [UIScreen mainScreen].scale);
    
    self.contentView.frame = self.bounds;
    
    // profile pic collage
    self.member1.frame = CGRectMake(self.frame.size.width / 2 - (self.member1.frame.size.width / 2), 24, self.member1.frame.size.width, self.member1.frame.size.height);
    
    self.infoButton.frame = CGRectMake(self.member1.frame.origin.x + self.member1.frame.size.width - self.infoButton.frame.size.width - 2, self.member1.frame.origin.y + self.member1.frame.size.height - self.infoButton.frame.size.height - 2, self.infoButton.frame.size.width, self.infoButton.frame.size.height);
    
    self.member2.frame = CGRectMake(self.member1.frame.origin.x - self.member2.frame.size.width - 32, 49, self.member2.frame.size.width, self.member2.frame.size.height);
    self.member3.frame = CGRectMake(self.frame.size.width - self.member2.frame.origin.x - self.member3.frame.size.width, 33, self.member3.frame.size.width, self.member3.frame.size.height);
    
    self.member4.frame = CGRectMake(self.member2.frame.origin.x - self.member4.frame.size.width - 24, 20, self.member4.frame.size.width, self.member4.frame.size.height);
    self.member5.frame = CGRectMake(self.frame.size.width - self.member4.frame.origin.x - self.member5.frame.size.width, 74, self.member5.frame.size.width, self.member5.frame.size.height);
    
    self.member6.frame = CGRectMake(self.member4.frame.origin.x - self.member6.frame.size.width - 8, 75, self.member6.frame.size.width, self.member6.frame.size.height);
    self.member7.frame = CGRectMake(self.frame.size.width - self.member6.frame.origin.x - self.member7.frame.size.width, 27, self.member7.frame.size.width, self.member7.frame.size.height);
    
    // text label
    CGRect textLabelRect = [self.nameLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.nameLabel.font} context:nil];
    self.nameLabel.frame = CGRectMake(24, 116, self.frame.size.width - (24 * 2), ceilf(textLabelRect.size.height));
    
    // detail text label
    CGRect detailLabelRect = [self.descriptionLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (12 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.descriptionLabel.font} context:nil];
    self.descriptionLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, self.nameLabel.frame.size.width, ceilf(detailLabelRect.size.height));
    
    self.followButton.frame = CGRectMake(12, self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 14, self.frame.size.width - 24, 40);
    
    self.statsView.frame = CGRectMake(0, self.followButton.frame.origin.y + self.followButton.frame.size.height, self.frame.size.width, self.statsView.frame.size.height);
    self.statsViewMiddleSeparator.frame = CGRectMake(self.statsView.frame.size.width / 2, self.statsViewMiddleSeparator.frame.origin.y, self.statsViewMiddleSeparator.frame.size.width, self.statsViewMiddleSeparator.frame.size.height);
    
    self.membersLabel.frame = CGRectMake(12, 0, self.statsView.frame.size.width / 2 - 12, self.statsView.frame.size.height);
    self.postsCountLabel.frame = CGRectMake(self.statsView.frame.size.width / 2, 0, self.statsView.frame.size.width / 2 - 12, self.statsView.frame.size.height);
}

- (void)styleMemberProfilePictureView:(UIImageView *)imageView  {
    [self continuityRadiusForView:imageView withRadius:imageView.frame.size.height * .25];
    imageView.backgroundColor = [UIColor whiteColor];
//    imageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end