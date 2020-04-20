//
//  GIFCollectionViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 3/4/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "GIFCollectionViewController.h"
#import "UIColor+Palette.h"
#import "BFVisualErrorView.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "Launcher.h"
#import "GIFCollectionViewCell.h"
@import Firebase;

@interface GIFCollectionViewController ()

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *trendingResults;
@property (nonatomic, strong) BFVisualErrorView *errorView;

@property (nonatomic) CGFloat currentKeyboardHeight;

@end

@implementation GIFCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (id)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsZero;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    CGFloat squareSize = ([UIScreen mainScreen].bounds.size.width - layout.sectionInset.left - layout.sectionInset.right - (layout.minimumInteritemSpacing * 2)) / 3;
    layout.itemSize = CGSizeMake(squareSize, squareSize);
    
    if (self = [super initWithCollectionViewLayout:layout]) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    [self setupErrorView];
    [self setupSearch];
    [self positionErrorView];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"GIF Search" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)loadTrending {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager GET:[NSString stringWithFormat:@"https://api.tenor.com/v1/trending?key=%@&limit=%d&locale=%@&content_filter=medium&media_filter=minimal", @"B9M4E1XRFFSI", 18, [[NSLocale preferredLanguages] firstObject]] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([self currentSearchText].length == 0) {
            self.loading = false;
        }
                
        self.trendingResults = [NSMutableArray new];
        if (responseObject[@"results"]) {
            [self.trendingResults addObjectsFromArray:responseObject[@"results"]];
        }
        
        [self.collectionView reloadData];
        [self determineErrorViewVisibility];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self currentSearchText].length == 0) {
            self.loading = false;
            
            NSLog(@"SearchTableViewController / getPosts() - error: %@", error);
            //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            [self.collectionView reloadData];
            [self determineErrorViewVisibility];
        }
    }];
}

- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"No Results Found" description:nil actionTitle:nil actionBlock:nil];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, (self.collectionView.frame.size.height - self.collectionView.adjustedContentInset.top - self.collectionView.adjustedContentInset.bottom) / 2);
    self.errorView.hidden = true;
    [self.collectionView addSubview:self.errorView];
}

- (void)setupSearch {
    [self addAttribution];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[GIFCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    self.collectionView.contentInset = UIEdgeInsetsZero;
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    self.collectionView.backgroundColor = self.view.backgroundColor;
    
    // Register cell classes
    self.loading = true;
    [self.collectionView reloadData];
    
    // Do any additional setup after loading the view.
    [self loadTrending];
}

- (void)addAttribution {
    UIView *attributionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width - 24, 42)];
    descriptionLabel.text = @"Powered by Tenor";
    descriptionLabel.textColor = [UIColor bonfireSecondaryColor];
    descriptionLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold];
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize labelSize = [descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:descriptionLabel.font} context:nil].size;
    descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, ceilf(labelSize.height));
    [attributionView addSubview:descriptionLabel];
    
    CGFloat attributionViewHeight = descriptionLabel.frame.size.height;
    attributionView.frame = CGRectMake(0, -attributionViewHeight - 24, self.collectionView.frame.size.width, attributionViewHeight);
    
    [self.collectionView addSubview:attributionView];
}

- (void)getSearchResults {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *searchText = [self currentSearchText];
    
    if (searchText.length == 0) {
        self.loading = false;
        self.searchResults = [[NSMutableArray alloc] init];
        [self.collectionView reloadData];
    }
    else {
        self.loading = true;
        
        NSString *url = [NSString stringWithFormat:@"https://api.tenor.com/v1/search?key=%@&limit=%d&locale=%@&content_filter=medium&media_filter=minimal", @"B9M4E1XRFFSI", 18, [[NSLocale preferredLanguages] firstObject]];
        NSString *originalSearchText = searchText;
        
        [manager GET:url parameters:@{@"q": searchText} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([originalSearchText isEqualToString:[self currentSearchText]]) {
                self.loading = false;
                
                self.searchResults = [NSMutableArray new];
                if (responseObject[@"results"]) {
                    [self.searchResults addObjectsFromArray:responseObject[@"results"]];
                }
                
                [self.collectionView reloadData];
                [self determineErrorViewVisibility];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if ([originalSearchText isEqualToString:[self currentSearchText]]) {
                self.loading = false;
                
                NSLog(@"SearchTableViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                [self.collectionView reloadData];
                [self determineErrorViewVisibility];
            }
        }];
    }
}

//- (CGSize)collectionView:(UICollectionView *)collectionView
//                  layout:(UICollectionViewLayout *)collectionViewLayout
//  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
//    CGFloat width = ([UIScreen mainScreen].bounds.size.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing) / 2;
//    CGFloat height = width;
//
//    NSArray *dims;
//    if ([self showTrending] && indexPath.item < self.trendingResults.count) {
//        dims = self.trendingResults[indexPath.item][@"media"][0][@"gif"][@"dims"];
//    }
//    else if (indexPath.item < self.searchResults.count) {
//        dims = self.trendingResults[indexPath.item][@"media"][0][@"gif"][@"dims"];
//    }
//
//    if (dims && dims.count == 2) {
//        CGFloat w = [dims[0] floatValue];
//        CGFloat h = [dims[1] floatValue];
//
//        height = CLAMP(roundf(width * (h / w)), 160, 400);
//    }
//
//    return CGSizeMake(width, height);
//}

- (void)searchFieldDidBeginEditing {
    
}
- (void)searchFieldDidChange {
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    NSLog(@"searchText: %@", searchText);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (searchText.length > 0) {
        self.loading = true;
        
        CGFloat delay = (searchText.length == 1) ? 0 : 0.1f;
        [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        [self performSelector:@selector(getSearchResults) withObject:nil afterDelay:delay];
    }
    else {
        self.loading = false;
        self.searchResults = [[NSMutableArray alloc] init];
    }
    
    [self.collectionView reloadData];
    [self determineErrorViewVisibility];
}
- (void)searchFieldDidEndEditing {
    [self.collectionView reloadData];
}
- (void)searchFieldDidReturn {
    BFSearchView *searchView;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchView = ((SearchNavigationController *)self.navigationController).searchView;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchView = ((ComplexNavigationController *)self.navigationController).searchView;
    }
    
    if (!searchView) {
        return;
    }
    
    
    if (searchView.textField.text.length == 0) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    [self positionErrorView];
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
//        self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.currentKeyboardHeight, self.collectionView.contentInset.right);
//        self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
        
        [self positionErrorView];
    } completion:nil];
}

- (void)determineErrorViewVisibility {
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    if (!self.loading && searchText.length > 0 && self.searchResults.count == 0 && !([self showTrending] &&  self.trendingResults.count == 0)) {
        // Error: No posts yet!
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"No Results Found" description:nil actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
        self.errorView.hidden = false;
    }
    else if (!self.loading && searchText.length == 0 && [self collectionView:self.collectionView numberOfItemsInSection:0] == 0) {
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeSearch title:@"Start typing..." description:nil actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
        self.errorView.hidden = false;
    }
    else {
        self.errorView.hidden = true;
    }
    
    if (![self.errorView isHidden]) {
        [self positionErrorView];
    }
}

- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, (self.collectionView.frame.size.height - _currentKeyboardHeight) / 2);
}

- (BOOL)showTrending  {
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    return (searchText.length == 0);
}

- (NSString *)currentSearchText {
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        return ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    return @"";
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section != 0) return 0;
    
    if ([self currentSearchText].length == 0 && self.loading) {
        return 18;
    }
    else if ([self showTrending]) {
        return self.trendingResults.count;
    }
    else {
        return self.searchResults.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GIFCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    if ([self showTrending] && indexPath.item < self.trendingResults.count) {
        cell.gifUrl = self.trendingResults[indexPath.item][@"media"][0][@"tinygif"][@"url"];
        cell.fullGifUrl = self.trendingResults[indexPath.item][@"media"][0][@"gif"][@"url"];
    }
    else if (indexPath.item < self.searchResults.count) {
        cell.gifUrl = self.searchResults[indexPath.item][@"media"][0][@"tinygif"][@"url"];
        cell.fullGifUrl = self.searchResults[indexPath.item][@"media"][0][@"gif"][@"url"];
    }
    else {
        cell.loading = true;
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    GIFCollectionViewCell *cell = (GIFCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (cell && !cell.loading) {
        [self.view endEditing:true];
        
        // start loading the full version
        cell.fetchingFullGif = true;
        
        [cell.gifPlayerView sd_setImageWithURL:[NSURL URLWithString:cell.fullGifUrl] placeholderImage:cell.gifPlayerView.image options:SDWebImageAvoidAutoSetImage|SDWebImageHighPriority completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (!error) {
                NSData *data = ((SDAnimatedImage *)image).animatedImageData;
                
                CGFloat gifSize = (float)data.length/1024.0f/1024.0f;
                if (gifSize > 8) { // full size gif is too large, use tiny gif instead
                    data = ((SDAnimatedImage *)cell.gifPlayerView.image).animatedImageData;
                }
                
                if ([self.delegate respondsToSelector:@selector(GIFCollectionView:didSelectGIFWithData:)]) {
                    [self.delegate GIFCollectionView:self didSelectGIFWithData:data];
                }
                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                
                cell.fetchingFullGif = false;
            }
        }];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    GIFCollectionViewCell *cell = (GIFCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (cell && !cell.loading) {
        cell.touchDown = true;
    }
}
- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    GIFCollectionViewCell *cell = (GIFCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (cell && !cell.loading) {
        cell.touchDown = false;
    }
}

@end
