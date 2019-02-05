//
//  RoomSuggestionsListCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomSuggestionsListCell.h"
#import "MiniChannelCell.h"
#import "ComplexNavigationController.h"
#import "UIColor+Palette.h"
#import "Launcher.h"

#define padding 24

@implementation RoomSuggestionsListCell

static NSString * const reuseIdentifier = @"MiniChannel";

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
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 10;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    [_collectionView registerClass:[MiniChannelCell class] forCellWithReuseIdentifier:reuseIdentifier];
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.layer.masksToBounds = true;
    _collectionView.backgroundColor = [UIColor clearColor];
    
    [self.contentView addSubview:_collectionView];
    
    self.lineSeparator = [[UIView alloc] init];
    self.lineSeparator.backgroundColor = [UIColor separatorColor];
    [self.contentView addSubview:self.lineSeparator];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loading) {
        return 4;
    }
    else {
        return self.roomSuggestions.count;
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MiniChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (self.loading) {
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        cell.profilePicture.image = [UIImage new];
        cell.profilePicture.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
        cell.title.layer.cornerRadius = 6.f;
        cell.title.layer.masksToBounds = true;
        cell.title.backgroundColor = [UIColor whiteColor];
        cell.title.text = @"Loading";
        cell.title.textColor = [UIColor clearColor];
        
        cell.ticker.hidden = true;
        cell.membersView.hidden = true;
    }
    else {
        Room *room = [[Room alloc] initWithDictionary:self.roomSuggestions[indexPath.row] error:nil];
        
        cell.room = room;
        
        cell.membersView.hidden = false;
        
        cell.profilePicture.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.profilePicture.tintColor = [UIColor whiteColor];
        cell.profilePicture.backgroundColor = [UIColor clearColor];
        cell.profilePicture.layer.shadowOpacity = 0;
        
        cell.title.text = cell.room.attributes.details.title;
        cell.title.textColor = [UIColor whiteColor];
        cell.title.backgroundColor = [UIColor clearColor];
        
        if (cell.room.attributes.summaries.counts.live < [Session sharedInstance].defaults.room.liveThreshold) {
            cell.ticker.hidden = true;
        }
        else {
            cell.ticker.hidden = false;
            [cell.ticker setTitle:[NSString stringWithFormat:@"%ld live", (long)cell.room.attributes.summaries.counts.live] forState:UIControlStateNormal];
        }
        
        for (int i = 0; i < cell.membersView.subviews.count; i++) {
            if ([cell.membersView.subviews[i] isKindOfClass:[UIImageView class]]) {
                UIImageView *imageView = cell.membersView.subviews[i];
                
                if (cell.room.attributes.summaries.members.count > imageView.tag) {
                    imageView.hidden = false;
                    
                    User *member = [[User alloc] initWithDictionary:cell.room.attributes.summaries.members[imageView.tag] error:nil];
                    NSString *picURL = member.attributes.details.media.profilePicture;
                    if (picURL.length > 0) {
                        [imageView sd_setImageWithURL:[NSURL URLWithString:picURL]];
                    }
                    else {
                        [imageView setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                        imageView.tintColor = [UIColor fromHex:member.attributes.details.color];
                    }
                }
                else {
                    imageView.hidden = true;
                }
            }
        }
        
        cell.backgroundColor = [UIColor fromHex:cell.room.attributes.details.color];
        
        cell.clipsToBounds = false;
        [cell layoutSubviews];
    }
    
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(180, 240);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading) {
        Room *room = [[Room alloc] initWithDictionary:self.roomSuggestions[indexPath.row] error:nil];
        
        [[Launcher sharedInstance] openRoom:room];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale);
}

@end
