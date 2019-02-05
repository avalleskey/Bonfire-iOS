//
//  MiniRoomCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MiniRoomsListCell.h"
#import "Session.h"
#import "Launcher.h"
#import "MiniRoomCell.h"
#import "ChannelCell.h"
#import "ComplexNavigationController.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

#define padding 24

@interface MiniRoomsListCell ()

@end

@implementation MiniRoomsListCell

static NSString * const reuseIdentifier = @"RoomCell";

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
    self.loading = true;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 116) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
    [_collectionView registerClass:[MiniRoomCell class] forCellWithReuseIdentifier:reuseIdentifier];
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.clipsToBounds = false;
    _collectionView.scrollEnabled = true;
    self.errorLoading = false;
    
    [self.contentView addSubview:_collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loading) {
        return 2;
    }
    else {
        return self.rooms.count;
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MiniRoomCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.loading = self.loading;
    
    if (cell.loading) {
        cell.roomTitleLabel.text = @"Camp";
        cell.roomPicture.room = nil;
        cell.roomPicture.tintColor = [UIColor bonfireGrayWithLevel:500];
    }
    else {
        Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
        
        cell.roomPicture.room = room;
        cell.roomTitleLabel.text = room.attributes.details.title;
    }
    
    CGSize titleSize = [cell.roomTitleLabel.text boundingRectWithSize:CGSizeMake(cell.frame.size.width - 8, MAXFLOAT) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:cell.roomTitleLabel.font} context:nil].size;
    cell.roomTitleLabel.frame = CGRectMake(cell.roomTitleLabel.frame.origin.x, cell.roomTitleLabel.frame.origin.y, cell.frame.size.width - (cell.roomTitleLabel.frame.origin.x * 2), ceilf(titleSize.height));
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(96, 116);
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
        [self.collectionView setContentOffset:CGPointMake(-12, 0)];
        self.collectionView.scrollEnabled = false;
        self.errorLoading = false;
        
        [self.collectionView reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.frame = CGRectMake(0, 0, self.frame.size.width, 116);
}

@end
