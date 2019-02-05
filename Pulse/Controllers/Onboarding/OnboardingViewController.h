//
//  OnboardingViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OnboardingViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) UIButton *closeButton;

@property (strong, nonatomic) UILabel *instructionLabel;

@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UILabel *nextBlockerInfoLabel;

@property (nonatomic) BOOL loadingRoomSuggestions;
@property (strong, nonatomic) UICollectionView *roomSuggestionsCollectionView;

@end

NS_ASSUME_NONNULL_END
