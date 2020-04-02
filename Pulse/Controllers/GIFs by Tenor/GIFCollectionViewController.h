//
//  GIFCollectionViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 3/4/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class GIFCollectionViewController;

@protocol GIFCollectionViewControllerDelegate <NSObject>

- (void)GIFCollectionView:(GIFCollectionViewController *)gifCollectionViewController didSelectGIFWithData:(NSData *)data;

@end

@interface GIFCollectionViewController : UICollectionViewController

@property (nonatomic, weak) id <GIFCollectionViewControllerDelegate> delegate;

- (void)getSearchResults;

- (void)searchFieldDidBeginEditing;
- (void)searchFieldDidChange;
- (void)searchFieldDidEndEditing;
- (void)searchFieldDidReturn;

@end

NS_ASSUME_NONNULL_END
