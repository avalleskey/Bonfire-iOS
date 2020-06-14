//
//  NewHomeCollectionViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 5/27/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemedViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CampsCollectionViewController : ThemedViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
+ (UICollectionViewFlowLayout *)layout;

@end

NS_ASSUME_NONNULL_END
