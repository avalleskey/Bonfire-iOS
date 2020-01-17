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

@property (nonatomic) int currentPage;

@end

@implementation CampCardsListCell

static NSString * const smallCardReuseIdentifier = @"SmallCard";
static NSString * const smallMediumCardReuseIdentifier = @"SmallMediumCard";
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
    _collectionView.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
    
    [_collectionView registerClass:[SmallCampCardCell class] forCellWithReuseIdentifier:smallCardReuseIdentifier];
    [_collectionView registerClass:[SmallMediumCampCardCell class] forCellWithReuseIdentifier:smallMediumCardReuseIdentifier];
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
            
            //cell.loading = self.loading;
            
            if (indexPath.item < self.camps.count) {
                cell.camp = self.camps[indexPath.item];
                
                [cell layoutSubviews];
            }
            
            return cell;
        }
        else if (self.size == CAMP_CARD_SIZE_SMALL_MEDIUM) {
            SmallMediumCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:smallMediumCardReuseIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[SmallMediumCampCardCell alloc] init];
            }
                        
            if (indexPath.item < self.camps.count) {
                cell.camp = self.camps[indexPath.item];
                
                [cell layoutSubviews];
            }
            
            return cell;
        }
        else if (self.size == CAMP_CARD_SIZE_MEDIUM) {
            MediumCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:mediumCardReuseIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[MediumCampCardCell alloc] init];
            }
            
            //cell.loading = self.loading;
            
            if (indexPath.item < self.camps.count) {
                cell.camp = self.camps[indexPath.item];
                
                [cell layoutSubviews];
            }
            
            return cell;
        }
        else if (self.size == CAMP_CARD_SIZE_LARGE) {
            LargeCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:largeCardReuseIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[LargeCampCardCell alloc] init];
            }
            
            //cell.loading = self.loading;
            
            if (indexPath.item < self.camps.count) {
                cell.camp = self.camps[indexPath.item];
                
                [cell layoutSubviews];
            }
            
            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UICollectionViewCell *blankCell = [collectionView dequeueReusableCellWithReuseIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if ([[collectionView cellForItemAtIndexPath:indexPath] isKindOfClass:[CampCardCell class]]) {
        Camp *camp = ((CampCardCell *)[collectionView cellForItemAtIndexPath:indexPath]).camp;
        
        if (camp) {
            UIAction *shareViaAction = [UIAction actionWithTitle:@"Share Camp via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher shareCamp:camp];
            }];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[shareViaAction]];
            
            CampViewController *campVC = [Launcher campViewControllerForCamp:camp];
            campVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:indexPath previewProvider:^(){return campVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    NSIndexPath *indexPath = (NSIndexPath *)configuration.identifier;
    [animator addCompletion:^{
        Camp *camp;
        if ([[collectionView cellForItemAtIndexPath:indexPath] isKindOfClass:[CampCardCell class]]) {
            camp = ((CampCardCell *)[collectionView cellForItemAtIndexPath:indexPath]).camp;
        }
        wait(0, ^{
            if (camp) {
               [Launcher openCamp:camp];
            }
        });
    }];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([self cardWidth], [self cardHeight]);
}

- (CGFloat)cardWidth {
    if (self.size == CAMP_CARD_SIZE_SMALL_MEDIUM) {
        return 148;
    }
    
    return 268;
}
- (CGFloat)cardHeight {
    switch (self.size) {
        case CAMP_CARD_SIZE_SMALL:
            return SMALL_CARD_HEIGHT;
        case CAMP_CARD_SIZE_SMALL_MEDIUM:
            return SMALL_MEDIUM_CARD_HEIGHT;
        case CAMP_CARD_SIZE_MEDIUM:
            return MEDIUM_CARD_HEIGHT;
        case CAMP_CARD_SIZE_LARGE:
            return LARGE_CARD_HEIGHT;
    }
    
    return 268;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && !self.errorLoading && self.camps.count > 0) {
        // animate the cell user tapped on
        Camp *camp = self.camps[indexPath.row];
        
        [Launcher openCamp:camp];
    }
    else if (self.errorLoading) {
        // tap to try loading again
        self.camps = [[NSMutableArray alloc] init];
        
        self.loading = true;
        [self.collectionView setContentOffset:CGPointMake(-12, 0)];
        self.collectionView.scrollEnabled = false;
        self.errorLoading = false;
        
        [self.collectionView reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.frame = CGRectMake(0, self.collectionView.frame.origin.y, self.frame.size.width, [self cardHeight]);
}

- (void)setCamps:(NSMutableArray *)camps {
    if (camps != _camps) {
        _camps = camps;
        
        [self.collectionView reloadData];
    }
}

@end
