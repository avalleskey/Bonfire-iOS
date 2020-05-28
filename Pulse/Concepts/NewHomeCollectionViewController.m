//
//  NewHomeCollectionViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/27/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "NewHomeCollectionViewController.h"
#import "UIColor+Palette.h"
#import "SmallCampCardCell.h"

@interface NewHomeCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation NewHomeCollectionViewController

static NSString * const blankCellReuseIdentifier = @"BlankCell";

static NSString * const smallMediumCardReuseIdentifier = @"SmallMediumCard";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    [self setupCollectionView];
    [self registerCellClasses];
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 12.f;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 23) collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
}
- (void)registerCellClasses {
    [self.collectionView registerClass:[SmallCampCardCell class] forCellWithReuseIdentifier:smallMediumCardReuseIdentifier];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:blankCellReuseIdentifier];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of items
    return 20;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    
    
    return cell;
}

@end
