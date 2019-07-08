//
//  CreateCampViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CreateCampViewController : UIViewController <UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UILabel *instructionLabel;

@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic) BOOL loadingSimilarCamps;
@property (nonatomic, strong) UICollectionView *similarCampsCollectionView;

@end

NS_ASSUME_NONNULL_END
