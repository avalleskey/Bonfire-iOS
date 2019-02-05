//
//  RoomSuggestionsListCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomCardsListCell.h"
#import "Session.h"
#import "Launcher.h"
#import "ChannelCell.h"

#import "SmallRoomCardCell.h"
#import "MediumRoomCardCell.h"
#import "LargeRoomCardCell.h"
#import "NSDictionary+Clean.h"

#import "ErrorChannelCell.h"
#import "EmptyChannelCell.h"
#import "ComplexNavigationController.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

#define padding 24

@interface RoomCardsListCell ()

@end

@implementation RoomCardsListCell

static NSString * const smallCardReuseIdentifier = @"SmallCard";
static NSString * const mediumCardReuseIdentifier = @"MediumCard";
static NSString * const largeCardReuseIdentifier = @"LargeCard";

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const emptyRoomCellReuseIdentifier = @"EmptyRoomCell";
static NSString * const errorRoomCellReuseIdentifier = @"ErrorRoomCell";

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.clipsToBounds = false;
    self.contentView.clipsToBounds = false;
    self.backgroundColor = [UIColor clearColor];
    
    self.rooms = [[NSMutableArray alloc] init];
    self.manager = [HAWebService manager];
    self.loading = false;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 12.f;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, [self cardHeight]) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    
    [_collectionView registerClass:[SmallRoomCardCell class] forCellWithReuseIdentifier:smallCardReuseIdentifier];
    [_collectionView registerClass:[MediumRoomCardCell class] forCellWithReuseIdentifier:mediumCardReuseIdentifier];
    [_collectionView registerClass:[LargeRoomCardCell class] forCellWithReuseIdentifier:largeCardReuseIdentifier];
    
    [_collectionView registerClass:[EmptyChannelCell class] forCellWithReuseIdentifier:emptyRoomCellReuseIdentifier];
    [_collectionView registerClass:[ErrorChannelCell class] forCellWithReuseIdentifier:errorRoomCellReuseIdentifier];
    
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:blankCellIdentifier];
    
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.clipsToBounds = false;
    _collectionView.scrollEnabled = true;
    self.errorLoading = false;
    
    [self.contentView addSubview:_collectionView];
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loading) {
        return 3;
    }
    else {
        if (self.errorLoading) {
            return 1;
        }
        else {
            return self.rooms.count;
        }
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loading || self.rooms.count > 0) {
        if (self.size == ROOM_CARD_SIZE_SMALL) {
            SmallRoomCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:smallCardReuseIdentifier forIndexPath:indexPath];
            
            cell.loading = self.loading;
            
            if (!cell.loading) {
                NSError *error;
                cell.room = [[Room alloc] initWithDictionary:self.rooms[indexPath.item] error:&error];
                cell.tintColor = [UIColor fromHex:cell.room.attributes.details.color];
                
                cell.themeLine.layer.borderColor = [UIColor fromHex:cell.room.attributes.details.color].CGColor;
                
                cell.roomTitleLabel.text = cell.room.attributes.details.title;
                cell.roomDescriptionLabel.text = cell.room.attributes.details.theDescription;
                
                cell.profilePicture.room = cell.room;
                
                DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
                if (cell.room.attributes.summaries.counts.members) {
                    NSInteger members = cell.room.attributes.summaries.counts.members;
                    cell.membersLabel.text = [NSString stringWithFormat:@"%ld %@", members, members == 1 ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString]];
                    
                    if (members > 0) {
                        // setup the replies view
                        for (int i = 0; i < 3; i++) {
                            BFAvatarView *avatarView;
                            if (i == 0) avatarView = cell.member1;
                            if (i == 1) avatarView = cell.member2;
                            if (i == 2) avatarView = cell.member3;
                            
                            if (cell.room.attributes.summaries.members.count > i) {
                                avatarView.hidden = false;
                                
                                User *userForImageView = [[User alloc] initWithDictionary:cell.room.attributes.summaries.members[i] error:nil];
                                
                                avatarView.user = userForImageView;
                            }
                            else {
                                avatarView.hidden = true;
                            }
                        }
                    }
                }
                else {
                    cell.membersLabel.text = [NSString stringWithFormat:@"0 %@", [membersTitle.plural lowercaseString]];
                }
                
                [cell layoutSubviews];
            }
            
            return cell;
        }
        else if (self.size == ROOM_CARD_SIZE_MEDIUM) {
            MediumRoomCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:mediumCardReuseIdentifier forIndexPath:indexPath];
            
            cell.loading = self.loading;
            
            if (!cell.loading) {
                NSError *error;
                cell.room = [[Room alloc] initWithDictionary:self.rooms[indexPath.item] error:&error];
                cell.tintColor = [UIColor fromHex:cell.room.attributes.details.color];
                
                cell.roomHeaderView.backgroundColor = [UIColor fromHex:cell.room.attributes.details.color];
                // set profile pictures
                for (int i = 0; i < 4; i++) {
                    BFAvatarView *avatarView;
                    if (i == 0) { avatarView = cell.member1; }
                    else if (i == 1) { avatarView = cell.member2; }
                    else if (i == 2) { avatarView = cell.member3; }
                    else { avatarView = cell.member4; }
                    
                    if (cell.room.attributes.summaries.members.count > i) {
                        avatarView.superview.hidden = false;
                        
                        User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)cell.room.attributes.summaries.members[i] error:nil];
                        
                        avatarView.user = userForImageView;
                    }
                    else {
                        avatarView.superview.hidden = true;
                    }
                }
                
                cell.roomTitleLabel.text = cell.room.attributes.details.title;
                cell.roomDescriptionLabel.text = cell.room.attributes.details.theDescription;
                
                cell.profilePicture.room = cell.room;
                
                [cell layoutSubviews];
            }
            
            return cell;
        }
        else if (self.size == ROOM_CARD_SIZE_LARGE) {
            LargeRoomCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:largeCardReuseIdentifier forIndexPath:indexPath];
            
            cell.loading = self.loading;
            
            if (!cell.loading) {
                NSError *error;
                cell.room = [[Room alloc] initWithDictionary:self.rooms[indexPath.item] error:&error];
                cell.tintColor = [UIColor fromHex:cell.room.attributes.details.color];
                
                cell.roomHeaderView.backgroundColor = [UIColor fromHex:cell.room.attributes.details.color];
                // set profile pictures
                for (int i = 0; i < 4; i++) {
                    BFAvatarView *avatarView;
                    if (i == 0) { avatarView = cell.member1; }
                    else if (i == 1) { avatarView = cell.member2; }
                    else if (i == 2) { avatarView = cell.member3; }
                    else { avatarView = cell.member4; }
                    
                    if (cell.room.attributes.summaries.members.count > i) {
                        avatarView.superview.hidden = false;
                        
                        NSError *userError;
                        User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)cell.room.attributes.summaries.members[i] error:&userError];
                        
                        avatarView.user = userForImageView;
                    }
                    else {
                        avatarView.superview.hidden = true;
                    }
                }
                
                cell.roomTitleLabel.text = cell.room.attributes.details.title;
                cell.roomDescriptionLabel.text = cell.room.attributes.details.theDescription;
                
                cell.profilePicture.room = cell.room;
                
                if (cell.room.attributes.status.isBlocked) {
                    [cell.followButton updateStatus:ROOM_STATUS_ROOM_BLOCKED];
                }
                else if (self.loading && cell.room.attributes.context == nil) {
                    [cell.followButton updateStatus:ROOM_STATUS_LOADING];
                }
                else {
                    [cell.followButton updateStatus:cell.room.attributes.context.status];
                }
                
                DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
                if (cell.room.attributes.summaries.counts.members) {
                    NSInteger members = cell.room.attributes.summaries.counts.members;
                    cell.membersLabel.text = [NSString stringWithFormat:@"%ld %@", members, members == 1 ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString]];
                    cell.membersLabel.alpha = 1;
                }
                else {
                    cell.membersLabel.text = [NSString stringWithFormat:@"0 %@", [membersTitle.plural lowercaseString]];
                    cell.membersLabel.alpha = 0.5;
                }
                
                if (cell.room.attributes.summaries.counts.posts) {
                    NSInteger posts = (long)cell.room.attributes.summaries.counts.posts;
                    cell.postsCountLabel.text = [NSString stringWithFormat:@"%ld %@", posts, posts == 1 ? @"post" : @"posts"];
                    cell.postsCountLabel.alpha = 1;
                }
                else {
                    cell.postsCountLabel.text = @"0 posts";
                    cell.postsCountLabel.alpha = 0.5;
                }
                
                [cell layoutSubviews];
            }
            
            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UICollectionViewCell *blankCell = [collectionView dequeueReusableCellWithReuseIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL useFullWidthCell = self.errorLoading || (!self.loading && self.rooms.count == 0);
    
    return CGSizeMake(useFullWidthCell?self.frame.size.width - 32:268, [self cardHeight]);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && !self.errorLoading && self.rooms.count > 0) {
        // animate the cell user tapped on
        Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
        
        [[Launcher sharedInstance] openRoom:room];
    }
    else if (self.errorLoading) {
        // tap to try loading again
        self.rooms = [[NSMutableArray alloc] init];
        
        self.loading = true;
        [self.collectionView setContentOffset:CGPointMake(-16, 0)];
        self.collectionView.scrollEnabled = false;
        self.errorLoading = false;
        
        [self.collectionView reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.frame = CGRectMake(0, 0, self.frame.size.width, [self cardHeight]);
}

- (CGFloat)cardHeight {
    switch (self.size) {
        case ROOM_CARD_SIZE_SMALL:
            return 94;
        case ROOM_CARD_SIZE_MEDIUM:
            return 226;
        case ROOM_CARD_SIZE_LARGE:
            return 304;
    }
    
    return 0;
}

@end
