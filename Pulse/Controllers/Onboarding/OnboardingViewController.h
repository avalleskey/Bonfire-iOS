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

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UILabel *instructionLabel;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UILabel *nextBlockerInfoLabel;
@property (nonatomic, strong) UIButton *legalDisclosureLabel;

@property (nonatomic) BOOL loadingRoomSuggestions;
@property (nonatomic, strong) UICollectionView *roomSuggestionsCollectionView;

@property (nonatomic) BOOL signInLikely;

@end

NS_ASSUME_NONNULL_END
