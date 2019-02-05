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
#import <Tweaks/FBTweakInline.h>
#import "Launcher.h"
#import "UIColor+Palette.h"

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
        
        self.textLabel.font = ROOM_HEADER_NAME_FONT;
        self.textLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        // username
        self.detailTextLabel.font = ROOM_HEADER_TAG_FONT;
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.47f alpha:1];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        self.descriptionLabel = [[UILabel alloc] init];
        self.descriptionLabel.font = ROOM_HEADER_DESCRIPTION_FONT;
        self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        self.descriptionLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.descriptionLabel];
        
        // general cell styling
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.roomPicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, ROOM_HEADER_EDGE_INSETS.top, ROOM_HEADER_AVATAR_SIZE, ROOM_HEADER_AVATAR_SIZE)];
        
        self.infoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        self.infoButton.layer.cornerRadius = self.infoButton.frame.size.height / 2;
        self.infoButton.layer.masksToBounds = true;
        self.infoButton.layer.borderColor = self.backgroundColor.CGColor;
        self.infoButton.layer.borderWidth = 2.f;
        self.infoButton.backgroundColor = [UIColor whiteColor];
        [self.infoButton setImage:[[UIImage imageNamed:@"infoIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.infoButton.hidden = true;
        [self.contentView addSubview:self.infoButton];
        
        self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.member2.allowAddUserPlaceholder = true;
        self.member2.tag = 0;
        self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.member3.allowAddUserPlaceholder = true;
        self.member3.tag = 1;
        
        self.member4 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member4.allowAddUserPlaceholder = true;
        self.member4.tag = 2;
        self.member5 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member5.allowAddUserPlaceholder = true;
        self.member5.tag = 3;
        
        self.member6 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member6.allowAddUserPlaceholder = true;
        self.member6.tag = 4;
        self.member7 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member7.allowAddUserPlaceholder = true;
        self.member7.tag = 5;
        
        [self.contentView addSubview:self.roomPicture];
        [self.contentView addSubview:self.member2];
        [self.contentView addSubview:self.member3];
        [self.contentView addSubview:self.member4];
        [self.contentView addSubview:self.member5];
        [self.contentView addSubview:self.member6];
        [self.contentView addSubview:self.member7];
        
        [self addTapHandlers:@[self.member2, self.member2, self.member3, self.member4, self.member5, self.member6, self.member7]];
        
        self.detailsLabel = [[BFDetailsLabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 16)];
        self.detailsLabel.layer.cornerRadius = 4.f;
        self.detailsLabel.layer.masksToBounds = true;
        [self.contentView addSubview:self.detailsLabel];
        
        self.followButton = [RoomFollowButton buttonWithType:UIButtonTypeCustom];
        
        [self.followButton bk_whenTapped:^{
            // update state if possible
            if ([self.followButton.status isEqualToString:ROOM_STATUS_MEMBER] ||
                [self.followButton.status isEqualToString:ROOM_STATUS_REQUESTED]) {
                // leave the room
                
                if ([self.followButton.status isEqualToString:ROOM_STATUS_MEMBER]) {
                    // confirm action
                    BOOL requiresConfirm = self.room.attributes.status.visibility.isPrivate;
                    
                    if (requiresConfirm) {
                        UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Are you sure you want to leave this Camp?" message:@"You will no longer have access to the posts" preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *confirmLeaveRoom = [UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                            [self.followButton updateStatus:ROOM_STATUS_LEFT];
                            [self decrementMembersCount];
                            [self leaveRoom];
                        }];
                        [confirmDeletePostActionSheet addAction:confirmLeaveRoom];
                        
                        UIAlertAction *cancelLeaveRoom = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                        [confirmDeletePostActionSheet addAction:cancelLeaveRoom];
                        
                        [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
                    }
                    else {
                        [self.followButton updateStatus:ROOM_STATUS_LEFT];
                        [self decrementMembersCount];
                        [self leaveRoom];
                    }
                    
                }
                else {
                    [self.followButton updateStatus:ROOM_STATUS_NO_RELATION];
                    [self leaveRoom];
                }
            }
            else if ([self.followButton.status isEqualToString:ROOM_STATUS_LEFT] ||
                     [self.followButton.status isEqualToString:ROOM_STATUS_NO_RELATION] ||
                     [self.followButton.status isEqualToString:ROOM_STATUS_INVITED] ||
                     self.followButton.status.length == 0) {
                // join the room
                if (self.room.attributes.status.visibility.isPrivate &&
                    ![self.followButton.status isEqualToString:ROOM_STATUS_INVITED]) {
                    [self.followButton updateStatus:ROOM_STATUS_REQUESTED];
                }
                else {
                    // since they've been invited already, jump straight to being a member
                    [self.followButton updateStatus:ROOM_STATUS_MEMBER];
                    [self incrementMembersCount];
                }
                [self updateRoomStatus];
                
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
            else if ([self.followButton.status isEqualToString:ROOM_STATUS_BLOCKED]) {
                // show alert maybe? --> ideally we don't even show the button.
            }
        }];
        [self.contentView addSubview:self.followButton];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self.contentView addSubview:self.lineSeparator];
    }
    return self;
}

- (void)addTapHandlers:(NSArray *)views {
    for (UIImageView *view in views) {
        view.userInteractionEnabled = true;
        [view bk_whenTapped:^{
            if (self.room.attributes.summaries.members.count > view.tag) {
                // open member
                User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)self.room.attributes.summaries.members[view.tag] error:nil];
                [[Launcher sharedInstance] openProfile:userForImageView];
            }
            else {
                // open invite friends
                [[Launcher sharedInstance] openInviteFriends:self.room];
            }
        }];
    }
}

- (void)updateRoomStatus {
    RoomContext *context = [[RoomContext alloc] initWithDictionary:[self.room.attributes.context toDictionary] error:nil];
    context.status = self.followButton.status;
    self.room.attributes.context = context;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:self.room];
}
- (void)incrementMembersCount {
    RoomCounts *counts = [[RoomCounts alloc] initWithDictionary:[self.room.attributes.summaries.counts toDictionary] error:nil];
    counts.members = counts.members + 1;
    self.room.attributes.summaries.counts = counts;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:self.room];
}
- (void)decrementMembersCount {
    // only decrement if they were a member before! requests don't count.
    RoomCounts *counts = [[RoomCounts alloc] initWithDictionary:[self.room.attributes.summaries.counts toDictionary] error:nil];
    counts.members = counts.members > 0 ? counts.members - 1 : 0;
    self.room.attributes.summaries.counts = counts;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:self.room];
}
- (void)leaveRoom {
    [[Session sharedInstance] unfollowRoom:self.room.identifier completion:^(BOOL success, id responseObject) {
        if (success) {
            if ([responseObject isKindOfClass:[RoomContext class]]) {
                NSLog(@"update the room context!");
                self.room.attributes.context = responseObject;
                //[[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:self.room];
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        }
    }];
    
    [self updateRoomStatus];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottomY;
    
    CGFloat maxWidth = self.frame.size.width - (ROOM_HEADER_EDGE_INSETS.left + ROOM_HEADER_EDGE_INSETS.right);
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - 1 / [UIScreen mainScreen].scale, self.frame.size.width, 1 / [UIScreen mainScreen].scale);
    
    self.contentView.frame = self.bounds;
    
    // profile pic collage
    self.roomPicture.center = CGPointMake(self.contentView.frame.size.width / 2, self.roomPicture.center.y);
    bottomY = self.roomPicture.frame.origin.y + self.roomPicture.frame.size.height;
    
    self.infoButton.frame = CGRectMake(self.roomPicture.frame.origin.x + self.roomPicture.frame.size.width - self.infoButton.frame.size.width - 2, self.roomPicture.frame.origin.y + self.roomPicture.frame.size.height - self.infoButton.frame.size.height - 2, self.infoButton.frame.size.width, self.infoButton.frame.size.height);
    
    self.member2.frame = CGRectMake(self.roomPicture.frame.origin.x - self.member2.frame.size.width - 24, 57, self.member2.frame.size.width, self.member2.frame.size.height);
    self.member3.frame = CGRectMake(self.frame.size.width - self.member2.frame.origin.x - self.member3.frame.size.width, 41, self.member3.frame.size.width, self.member3.frame.size.height);
    
    self.member4.frame = CGRectMake(self.member2.frame.origin.x - self.member4.frame.size.width - 16, 28, self.member4.frame.size.width, self.member4.frame.size.height);
    self.member5.frame = CGRectMake(self.frame.size.width - self.member4.frame.origin.x - self.member5.frame.size.width, 82, self.member5.frame.size.width, self.member5.frame.size.height);
    
    self.member6.frame = CGRectMake(self.member4.frame.origin.x - self.member6.frame.size.width - 8, 83, self.member6.frame.size.width, self.member6.frame.size.height);
    self.member7.frame = CGRectMake(self.frame.size.width - self.member6.frame.origin.x - self.member7.frame.size.width, 35, self.member7.frame.size.width, self.member7.frame.size.height);
    
    // text label
    CGRect nameLabelRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil];
    self.textLabel.frame = CGRectMake(ROOM_HEADER_EDGE_INSETS.left, bottomY + ROOM_HEADER_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(nameLabelRect.size.height));
    bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;

    // detail text label
    CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + ROOM_HEADER_NAME_BOTTOM_PADDING, self.textLabel.frame.size.width, ceilf(detailLabelRect.size.height));
    bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    
    if (self.descriptionLabel.text.length > 0) {
        // detail text label
        CGRect detailLabelRect = [self.descriptionLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.descriptionLabel.frame = CGRectMake(ROOM_HEADER_EDGE_INSETS.left, self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height + ROOM_HEADER_TAG_BOTTOM_PADDING, maxWidth, ceilf(detailLabelRect.size.height));
        bottomY = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height;
    }
    
    self.detailsLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + (self.descriptionLabel.text.length > 0 ? ROOM_HEADER_DESCRIPTION_BOTTOM_PADDING : ROOM_HEADER_TAG_BOTTOM_PADDING) + ROOM_HEADER_DETAILS_EDGE_INSETS.top, self.textLabel.frame.size.width, self.detailsLabel.frame.size.height);
    bottomY = self.detailsLabel.frame.origin.y + self.detailsLabel.frame.size.height;
    
    self.followButton.frame = CGRectMake(ROOM_HEADER_EDGE_INSETS.left, bottomY + ROOM_HEADER_FOLLOW_BUTTON_TOP_PADDING, maxWidth, 36);
}

- (void)styleMemberProfilePictureView:(UIImageView *)imageView  {
    BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", YES);
    if (circleProfilePictures) {
        [self continuityRadiusForView:imageView withRadius:imageView.frame.size.height * .5];
    }
    else {
        [self continuityRadiusForView:imageView withRadius:imageView.frame.size.height * .25];
    }
    
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

- (void)setRoom:(Room *)room {
    if (room != _room) {
        _room = room;
        
        self.tintColor = self.superview.tintColor;
        
        if (room.attributes.details.title) {
            self.textLabel.text = room.attributes.details.title.length > 0 ? room.attributes.details.title : @"Unknown Camp";
        }
        else if (room.attributes.details.identifier) {
            self.textLabel.text = [NSString stringWithFormat:@"#%@", room.attributes.details.identifier];
        }
        else {
            self.textLabel.text = @"Unknown Camp";
        }
        
        self.detailTextLabel.text = [NSString stringWithFormat:@"#%@", room.attributes.details.identifier];
        
        if (room.attributes.details.theDescription.length > 0) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:room.attributes.details.theDescription];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:ROOM_HEADER_DESCRIPTION_FONT range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:self.descriptionLabel.textColor range:NSMakeRange(0, attrString.length)];
            self.descriptionLabel.attributedText = attrString;
        }
        
        // set room picture
        self.roomPicture.room = room;
        
        // set profile pictures
        
        for (int i = 0; i < 6; i++) {
            BFAvatarView *avatarView;
            if (i == 0) { avatarView = self.member2; }
            else if (i == 1) { avatarView = self.member3; }
            else if (i == 2) { avatarView = self.member4; }
            else if (i == 3) { avatarView = self.member5; }
            else if (i == 4) { avatarView = self.member6; }
            else { avatarView = self.member7; }
            
            avatarView.hidden = !self.room.identifier;
            
            if (room.attributes.summaries.members.count > i) {
                NSError *userError;
                User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)room.attributes.summaries.members[i] error:&userError];
                
                avatarView.user = userForImageView;
                avatarView.dimsViewOnTap = true;
            }
            else {
                avatarView.user = nil;
                avatarView.dimsViewOnTap = false;
            }
        }
        
        NSMutableArray *details = [[NSMutableArray alloc] init];
        [details addObject:[BFDetailsLabel BFDetailWithType:(room.attributes.status.visibility.isPrivate ? BFDetailTypePrivacyPrivate : BFDetailTypePrivacyPublic) value:@"" action:nil]];
        
        BOOL canViewMembers = ([self.room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER] ||
                               !self.room.attributes.status.visibility.isPrivate);
        [details addObject:[BFDetailsLabel BFDetailWithType:BFDetailTypeMembers value:[NSNumber numberWithInteger:room.attributes.summaries.counts.members] action:canViewMembers?^(NSString *tappedString) {
            [[Launcher sharedInstance] openRoomMembersForRoom:room];
        }:nil]];
        self.detailsLabel.details = details;
    }
}

@end
