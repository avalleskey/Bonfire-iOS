//
//  MiniAvatarCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MiniAvatarListCell.h"
#import "Session.h"
#import "Launcher.h"
#import "MiniAvatarCell.h"
#import "ComplexNavigationController.h"
#import "UIColor+Palette.h"
#import <UIImageView+WebCache.h>

#define padding 24

@interface MiniAvatarListCell ()

@end

@implementation MiniAvatarListCell

static NSString * const reuseIdentifier = @"AvatarCell";

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
    
    self.camps = [[NSMutableArray alloc] init];
    self.loading = true;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, MINI_CARD_HEIGHT) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.contentInset = UIEdgeInsetsMake(0, 2, 0, 2);
    [_collectionView registerClass:[MiniAvatarCell class] forCellWithReuseIdentifier:reuseIdentifier];
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.clipsToBounds = false;
    _collectionView.scrollEnabled = true;
    self.errorLoading = false;
    
    [self.contentView addSubview:_collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loading && self.camps.count == 0 && self.users.count == 0) {
        return 6;
    }
    else if (self.camps.count > 0) {
        return self.camps.count + ([self includeShowAllAction] ? 1 : 0);
    }
    else if (self.users.count > 0) {
        return self.users.count + ([self includeShowAllAction] ? 1 : 0);
    }
    
    return 0;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MiniAvatarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (self.loading && self.camps.count == 0 && self.users.count == 0) {
        cell.loading = true;
        
        cell.campTitleLabel.text = @"Camp";
        cell.campAvatar.camp = nil;
        cell.campAvatar.tintColor = [UIColor bonfireGrayWithLevel:100];
    }
    else {
        NSInteger adjustedIndex = indexPath.item - ([self includeShowAllAction] ? 1 : 0);
        
        cell.loading = false;
        
        if ([self includeShowAllAction] && indexPath.item == 0) {
            [cell.campAvatar.imageView sd_setImageWithURL:nil];
            cell.campAvatar.imageView.backgroundColor = [UIColor whiteColor];
            cell.campAvatar.imageView.image = [UIImage imageNamed:@"miniListShowAllIcon"];
            cell.campTitleLabel.text = @"My Camps";
            
            cell.campAvatar.imageView.layer.borderWidth = 1;
        }
        else if (self.camps != nil) {
            Camp *camp = [[Camp alloc] initWithDictionary:self.camps[adjustedIndex] error:nil];
            
            cell.campAvatar.camp = camp;
            cell.campTitleLabel.text = [@"#" stringByAppendingString:camp.attributes.details.identifier];
        }
        else if (self.users != nil) {
            User *user = [[User alloc] initWithDictionary:self.users[adjustedIndex] error:nil];
            
            cell.campAvatar.user = user;
            cell.campTitleLabel.text = [@"@" stringByAppendingString:user.attributes.details.identifier];
        }
    }
    
    return cell;
}

- (BOOL)includeShowAllAction {
    return self.camps.count > 8;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(80, MINI_CARD_HEIGHT);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((!self.loading && (self.camps.count > 0 || self.users.count > 0)) && !self.errorLoading) {
        NSInteger adjustedIndex = indexPath.row - ([self includeShowAllAction] ? 1 : 0);
        
        if ([self includeShowAllAction] && indexPath.row == 0) {
            self.shiowAllAction();
        }
        else if (self.camps.count > indexPath.row) {
            // animate the cell user tapped on
            Camp *camp = [[Camp alloc] initWithDictionary:self.camps[adjustedIndex] error:nil];
            
            [Launcher openCamp:camp];
        }
        else if (self.users.count > indexPath.row) {
            // animate the cell user tapped on
            User *user = [[User alloc] initWithDictionary:self.users[adjustedIndex] error:nil];
            
            [Launcher openProfile:user];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.frame = CGRectMake(0, 0, self.frame.size.width, MINI_CARD_HEIGHT);
}

- (void)setCamps:(NSMutableArray *)camps {
    if (camps != _camps) {
        _camps = camps;
        _users = nil;
        
        [self.collectionView reloadData];
    }
}
- (void)setUsers:(NSMutableArray *)users {
    if (users != _users) {
        _users = users;
        _camps = nil;
        
        [self.collectionView reloadData];
    }
}

@end
