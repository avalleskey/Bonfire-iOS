//
//  HomebaseCollectionViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/27/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "CampsCollectionViewController.h"
#import "UIColor+Palette.h"
#import "SmallMediumCampCardCell.h"
#import "CampListStream.h"
#import <PINCache.h>
#import "Session.h"
#import "Launcher.h"
#import "BFVisualErrorView.h"
#import "BFActivityIndicatorView.h"
#import "CampCardsListCollectionViewCell.h"
#import "BFTipsManager.h"
#import "BFAlertController.h"
#import "BFHeaderView.h"

#define MY_CAMPS_CACHE_KEY @"my_camps_paged_cache"

@import Firebase;

@interface CampsCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

// Views
@property (nonatomic, strong) UIView *navigationBar;
@property (nonatomic, strong) BFVisualErrorView *errorView;
@property (nonatomic, strong) BFActivityIndicatorView *spinner;

// Properties
@property (nonatomic, strong) CampListStream *stream;
@property (nonatomic) BOOL loadingMoreCamps;

@property (nonatomic, strong) NSMutableArray <Camp *> *suggestedCamps;
@property (nonatomic, strong) NSMutableArray <Camp *> *favoritedCamps;

@end

@implementation CampsCollectionViewController

#define CARD_ITEM_SPACING 12

static NSString * const blankCellReuseIdentifier = @"BlankCell";
static NSString * const campsListCellReuseIdentifier = @"CampsListCell";
static NSString * const smallMediumCardReuseIdentifier = @"SmallMediumCard";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    self.animateLoading = true;
    
    [self setup];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Home" screenClass:nil];
    
    // Listeners
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentsUpdated:) name:@"RecentsUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyCamps:) name:@"refreshMyCamps" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // first time
        
//        wait(0.6f, ^{
//            if ([Launcher activeViewController] == self && // ensure the view is still in the foreground
//                ![BFTipsManager hasSeenTip:@"how_to_favorite_camps"] && [Session sharedInstance].currentUser.attributes.summaries.counts.camps > 4) {
//                BFAlertController *about = [BFAlertController alertControllerWithIcon:[UIImage imageNamed:@"alert_icon_star"] title:@"How to Favorite Camps" message:@"Tap and hold your favorite Camps to save them for quicker access!" preferredStyle:BFAlertControllerStyleActionSheet];
//
//                BFAlertAction *gotIt = [BFAlertAction actionWithTitle:@"Got it" style:BFAlertActionStyleCancel handler:nil];
//                [about addAction:gotIt];
//
//                [about show];
//            }
//        });
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - NSNotificationCenter
- (void)recentsUpdated:(NSNotification *)sender {
    [self loadSuggestedCamps];
    
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    self.errorView.hidden = !(!self.loading && self.stream.camps.count == 0 && self.suggestedCamps.count == 0);
}
- (void)refreshMyCamps:(NSNotification *)sender {
    [self getCampsWithCursor:StreamPagingCursorTypeNone];
}

#pragma mark - Setup
- (void)setup {
    [self setupCollectionView];
    [self setupStream];
}
- (void)setupCollectionView {
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:[CampsCollectionViewController layout]];
    [self.view addSubview:self.collectionView];
    self.collectionView.backgroundColor = self.view.backgroundColor;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    self.collectionView.contentInset = UIEdgeInsetsMake(CARD_ITEM_SPACING, CARD_ITEM_SPACING, 40 + 16 + 16, CARD_ITEM_SPACING);
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"SeparatorFooter"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"PaginationFooter"];
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BlankView_header"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"BlankView_footer"];
    
    [self registerCellClasses];
}
- (void)registerCellClasses {
    [self.collectionView registerClass:[CampCardsListCollectionViewCell class] forCellWithReuseIdentifier:campsListCellReuseIdentifier];
    [self.collectionView registerClass:[SmallMediumCampCardCell class] forCellWithReuseIdentifier:smallMediumCardReuseIdentifier];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:blankCellReuseIdentifier];
}
- (void)setupStream {
    self.stream = [[CampListStream alloc] init];
    [self loadCache];
    [self loadSuggestedCamps];
    [self getCampsWithCursor:StreamPagingCursorTypeNone];
}
#pragma mark - Cache
- (void)saveCacheIfNeeded {
    NSMutableArray *newCache = [NSMutableArray new];
    
    for (NSInteger i = 0; i < self.stream.pages.count; i++) {
        [newCache addObject:[self.stream.pages[i] toDictionary]];
    }
    
    [[PINCache sharedCache] setObject:[newCache copy] forKey:MY_CAMPS_CACHE_KEY];
}
- (void)loadCache {
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"my_camps_paged_cache"];
    
    self.stream = [[CampListStream alloc] init];
    if (cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:pageDict error:nil];
            [self.stream appendPage:page];
        }
        
        [self.collectionView reloadData];
    }
}
- (void)loadSuggestedCamps {
    NSDictionary *opens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"camp_opens"];
    NSDictionary *lastOpens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"camp_last_opens"];
    NSArray *recentsCamps = [[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_camps"];
    
    if ((!self.stream.camps && recentsCamps.count == 0) ||
        (self.stream.camps.count < 4 && recentsCamps.count == 0)) return;
    
    // combine the arrays!
    NSMutableArray <Camp *> *campsArray = [[NSMutableArray <Camp *> alloc] initWithArray:self.stream.camps];
    if (recentsCamps.count > 0) {
        NSMutableArray *arrayOfCampIDs = [NSMutableArray new];
        for (Camp *camp in self.stream.camps) {
            [arrayOfCampIDs addObject:camp.identifier];
        }
        // add in the recents
        for (id camp in recentsCamps) {
            if ([camp isKindOfClass:[NSDictionary class]]) {
                Camp *c = [[Camp alloc] initWithDictionary:((NSDictionary *)camp) error:nil];
                if (![arrayOfCampIDs containsObject:c.identifier]) {
                    [campsArray addObject:c];
                    [arrayOfCampIDs addObject:c.identifier];
                }
            }
            else if ([camp isKindOfClass:[Camp class]]) {
                if (![arrayOfCampIDs containsObject:((Camp *)camp).identifier]) {
                    [campsArray addObject:camp];
                    [arrayOfCampIDs addObject:((Camp *)camp).identifier];
                }
            }
        }
    }
            
    for (NSInteger i = 0; i < campsArray.count; i++) {
        Camp *camp = campsArray[i];
        
        if ([opens objectForKey:camp.identifier]) {
            campsArray[i].opens = [opens[camp.identifier] integerValue];
        }
        else {
            campsArray[i].opens = 0;
        }
        
        if ([lastOpens objectForKey:camp.identifier]) {
            campsArray[i].lastOpened = lastOpens[camp.identifier];
        }
    }

    NSArray *sortedSuggestedCamps = [campsArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastOpened" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"opens" ascending:NO]]];
    if (sortedSuggestedCamps.count > 5) {
        sortedSuggestedCamps = [sortedSuggestedCamps subarrayWithRange:NSMakeRange(0, 5)];
    }
    
    self.suggestedCamps = [[NSMutableArray alloc] initWithArray:sortedSuggestedCamps];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0 && !self.loading && self.suggestedCamps.count > 0) {
        return (self.suggestedCamps.count > 0 ? 1 : 0);
    }
    else if (section == 1) {
        return self.stream.camps.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.item == 0 && !self.loading && self.suggestedCamps.count > 0) {
        CampCardsListCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:campsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (!cell) {
            cell = [[CampCardsListCollectionViewCell alloc] init];
        }
            
        cell.contentView.backgroundColor = self.collectionView.backgroundColor;
        cell.size = CAMP_CARD_SIZE_MEDIUM;
        cell.camps = self.suggestedCamps;
        cell.lineSeparator.hidden = true;
        
        cell.clipsToBounds = false;
        cell.contentView.clipsToBounds = false;
        cell.layer.zPosition = 2;
        
        return cell;
    }
    else if (indexPath.section == 1) {
        if (indexPath.item < self.stream.camps.count) {
            SmallMediumCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:smallMediumCardReuseIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[SmallMediumCampCardCell alloc] init];
            }
                    
            cell.camp = self.stream.camps[indexPath.item];
            [cell layoutSubviews];
            
            return cell;
        }
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:blankCellReuseIdentifier forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor cardBackgroundColor];
    cell.layer.cornerRadius = 10.f;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.item == 0 && !self.loading && self.suggestedCamps.count > 0) {
        return CGSizeMake(collectionView.frame.size.width, MEDIUM_CARD_HEIGHT);
    }
    else if (indexPath.section == 1) {
        CGFloat width = (collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right - CARD_ITEM_SPACING) / 2;
        return CGSizeMake(width, SMALL_MEDIUM_CARD_HEIGHT);
    }
    
    return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.item < self.stream.camps.count) {
        [Launcher openCamp:self.stream.camps[indexPath.item]];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && indexPath.section == 1 && self.stream.camps.count > 0) {
        if (kind == UICollectionElementKindSectionHeader) {
            UICollectionReusableView *reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
            
            BFHeaderView *header = [reusableView viewWithTag:10];
            if (!header) {
                header = [[BFHeaderView alloc] initWithFrame:CGRectMake(-self.collectionView.contentInset.left, 0, reusableView.frame.size.width + self.collectionView.contentInset.left + self.collectionView.contentInset.right, [BFHeaderView height])];
                header.tag = 10;
                header.title = @"All Camps";
                header.tableViewHasSeparators = true;
                [reusableView addSubview:header];
            }
            
            return reusableView;
        }
        else if (kind == UICollectionElementKindSectionFooter) {
            CampListStream *stream = self.stream;
                
            if (indexPath.section == 1) {
                // last row
                BOOL hasAnotherPage = stream.pages.count > 0 && stream.nextCursor.length > 0;
                BOOL showLoadingFooter = self.loading || (self.loadingMoreCamps || hasAnotherPage);
                
                if (showLoadingFooter) {
                    UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"PaginationFooter" forIndexPath:indexPath];
                    
                    BFActivityIndicatorView *spinner = [footer viewWithTag:10];
                    if (!spinner) {
                        spinner = [[BFActivityIndicatorView alloc] init];
                        spinner.tag = 10;
                        spinner.color = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.5];
                        [footer addSubview:spinner];
                    }
                    spinner.frame = CGRectMake(footer.frame.size.width / 2 - 12, ((footer.frame.size.height + collectionView.contentInset.left) / 2) - 12, 24, 24);
                    [spinner startAnimating];
                    
                    if (!self.loadingMoreCamps && stream.pages.count > 0 && stream.nextCursor.length > 0) {
                        [self getCampsWithCursor:StreamPagingCursorTypeNext];
                    }
                    
                    return footer;
                }
            }
        }
    }
    
    UICollectionReusableView *blankView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:[@"BlankView_" stringByAppendingString:(kind==UICollectionElementKindSectionFooter?@"footer":@"header")] forIndexPath:indexPath];
    return blankView;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (!self.loading && section == 1 && self.stream.camps.count > 0) {
        return CGSizeMake(collectionView.frame.size.width, [BFHeaderView height]);
    }
    
    return CGSizeZero;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (!self.loading && section == 1) {
        CampListStream *stream = self.stream;
        
        // last row
        BOOL hasAnotherPage = stream.pages.count > 0 && stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || (self.loadingMoreCamps || hasAnotherPage);
        
        if (showLoadingFooter) {
            return CGSizeMake(collectionView.frame.size.width, collectionView.contentInset.left + 52);
        }
    }
    
    return CGSizeZero;
}

#pragma mark - Requests
- (void)getCampsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"users/me/camps"];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    __block CampListStream *stream = self.stream;
    
    NSString *nextCursor = [stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loadingMoreCamps = true;
        [stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"next_cursor"];
    }
    else if (self.stream.camps.count == 0) {
        self.loading = true;
    }
    
    [[[HAWebService manager] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (cursorType == StreamPagingCursorTypeNone || !stream) {
            stream = [[CampListStream alloc] init];
        }
        
        if (page.data.count > 0) {
            if ([params objectForKey:@"next_cursor"]) {
                self.loadingMoreCamps = false;
            }
            
            [stream appendPage:page];
        }
        
        self.stream = stream;
        
        if (page.data.count > 0) {
            [self saveCacheIfNeeded];
            [self loadSuggestedCamps];
        }
                        
        self.loading = false;
        
        [self update];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getRequests() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if (nextCursor.length > 0) {
            [stream removeLoadedCursor:nextCursor];
        }
        self.loading = false;
        
        [self update];
    }];
}

- (void)update {
    [self.collectionView reloadData];
    
    CampListStream *stream = self.stream;
    if (!self.loading && stream.camps.count == 0 && self.suggestedCamps.count == 0) {
        // empty state
        if (!self.errorView) {
            [self setupErrorView];
        }
        
        self.errorView.hidden = false;
        
        if ([HAWebService hasInternet]) {
            [self showErrorViewWithType:ErrorViewTypeHeart title:@"My Camps" description:@"The Camps you join or subscribe to will show up here" actionTitle:@"Discover Camps" actionBlock:^{
                [Launcher openDiscover];
            }];
        }
        else {
            [self showErrorViewWithType:ErrorViewTypeNoInternet title:@"No Internet" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refreshMyCamps:nil];
            }];
        }
        
        [self positionErrorView];
    }
    else {
        self.errorView.hidden = true;
    }
}

#pragma mark - Error View
- (void)setupErrorView {
    self.errorView = [[BFVisualErrorView alloc] initWithFrame:CGRectMake(16, 0, (self.collectionView.frame.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right) - 32, 100)];
    [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
        [self refreshMyCamps:nil];
    }];
    self.errorView.center = self.collectionView.center;
    self.errorView.hidden = true;
    [self.collectionView addSubview:self.errorView];
}
- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.errorView.actionButton bk_removeAllAssociatedObjects];
    self.errorView.visualError = visualError;
    
    self.errorView.hidden = false;
    [self positionErrorView];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake((self.collectionView.frame.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right) / 2, (self.collectionView.frame.size.height - self.collectionView.adjustedContentInset.top - self.collectionView.adjustedContentInset.bottom) / 2);
}

#pragma mark - Collection View Layout
+ (UICollectionViewFlowLayout *)layout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = CARD_ITEM_SPACING;
    flowLayout.minimumInteritemSpacing = CARD_ITEM_SPACING;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    return flowLayout;
}

@end
