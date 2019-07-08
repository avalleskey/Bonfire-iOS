//
//  CampCardsListCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CampCardsListCell.h"
#import "Session.h"
#import "Launcher.h"

#import "NSDictionary+Clean.h"

#import "ComplexNavigationController.h"
#import "UIColor+Palette.h"

#define padding 24

@interface CampCardsListCell ()

@end

@implementation CampCardsListCell

static NSString * const smallCardReuseIdentifier = @"SmallCard";
static NSString * const mediumCardReuseIdentifier = @"MediumCard";
static NSString * const largeCardReuseIdentifier = @"LargeCard";

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const emptyCampCellReuseIdentifier = @"EmptyCampCell";
static NSString * const errorCampCellReuseIdentifier = @"ErrorCampCell";

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
    
    [_collectionView registerClass:[SmallCampCardCell class] forCellWithReuseIdentifier:smallCardReuseIdentifier];
    [_collectionView registerClass:[MediumCampCardCell class] forCellWithReuseIdentifier:mediumCardReuseIdentifier];
    [_collectionView registerClass:[LargeCampCardCell class] forCellWithReuseIdentifier:largeCardReuseIdentifier];
    
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
            return self.camps.count;
        }
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loading || self.camps.count > 0) {
        if (self.size == CAMP_CARD_SIZE_SMALL) {
            SmallCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:smallCardReuseIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[SmallCampCardCell alloc] init];
            }
            
            cell.loading = self.loading;
            
            if (!cell.loading) {
                NSError *error;
                cell.camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.item] error:&error];
            }
            
            return cell;
        }
        else if (self.size == CAMP_CARD_SIZE_MEDIUM) {
            MediumCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:mediumCardReuseIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[MediumCampCardCell alloc] init];
            }
            
            cell.loading = self.loading;
            
            if (!cell.loading) {
                NSError *error;
                cell.camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.item] error:&error];
            }
            
            return cell;
        }
        else if (self.size == CAMP_CARD_SIZE_LARGE) {
            LargeCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:largeCardReuseIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[LargeCampCardCell alloc] init];
            }
            
            cell.loading = self.loading;
            
            if (!cell.loading) {
                NSError *error;
                cell.camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.item] error:&error];
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
    BOOL useFullWidthCell = self.errorLoading || (!self.loading && self.camps.count == 0);
    
    return CGSizeMake(useFullWidthCell?self.frame.size.width - 32:268, [self cardHeight]);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && !self.errorLoading && self.camps.count > 0) {
        // animate the cell user tapped on
        Camp *camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.row] error:nil];
        
        [Launcher openCamp:camp];
    }
    else if (self.errorLoading) {
        // tap to try loading again
        self.camps = [[NSMutableArray alloc] init];
        
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
        case CAMP_CARD_SIZE_SMALL:
            return SMALL_CARD_HEIGHT;
        case CAMP_CARD_SIZE_MEDIUM:
            return MEDIUM_CARD_HEIGHT;
        case CAMP_CARD_SIZE_LARGE:
            return LARGE_CARD_HEIGHT;
    }
    
    return 0;
}

- (void)setCamps:(NSMutableArray *)camps {
    if (camps != _camps) {
        _camps = camps;
        
        [self.collectionView reloadData];
    }
}

@end