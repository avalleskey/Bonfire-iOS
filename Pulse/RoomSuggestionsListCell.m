//
//  RoomSuggestionsListCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomSuggestionsListCell.h"
#import "MiniChannelCell.h"
#import "LauncherNavigationViewController.h"

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
    flowLayout.minimumLineSpacing = 8.f;
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
    self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    [self.contentView addSubview:self.lineSeparator];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loading) {
        return 4;
    }
    else {
        return 10;
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MiniChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (self.loading) {
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        cell.title.layer.cornerRadius = 6.f;
        cell.title.layer.masksToBounds = true;
        cell.title.backgroundColor = [UIColor whiteColor];
        cell.title.text = @"Loading";
        cell.title.textColor = [UIColor clearColor];
        
        cell.ticker.hidden = true;
    }
    else {
        // NSDictionary *channel = self.roomSuggestions[indexPath.item];
        
        if (indexPath.row == 0) {
            cell.backgroundColor = [UIColor colorWithDisplayP3Red:0 green:0.46 blue:1 alpha:1.0];
        }
        else if (indexPath.row == 1) {
            cell.backgroundColor = [UIColor colorWithDisplayP3Red:0.98 green:0.42 blue:0.14 alpha:1];
        }
        else {
            cell.backgroundColor = [UIColor colorWithDisplayP3Red:0.44 green:0.29 blue:0.89 alpha:1.0];
        }
        
        cell.title.text = @"Room Name";
        cell.title.textColor = [UIColor whiteColor];
        cell.title.backgroundColor = [UIColor clearColor];
        
        [cell.ticker setTitle:@"24" forState:UIControlStateNormal];
        // cell.membersView.text = @"650 members";
        
        cell.ticker.hidden = false;
        
        [cell layoutSubviews];
    }
    
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(152, 156);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading) {
        // animate the cell user tapped on
        
        // [(LauncherNavigationViewController *)self.navigationController openRoom:self.channels[indexPath.row]];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale);
}

@end
