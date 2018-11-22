//
//  CreateRoomViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HAWebService.h"

NS_ASSUME_NONNULL_BEGIN

@interface CreateRoomViewController : UIViewController <UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) UIButton *closeButton;

@property (strong, nonatomic) UILabel *instructionLabel;

@property (strong, nonatomic) UIButton *nextButton;

@property (nonatomic) BOOL loadingSimilarRooms;
@property (strong, nonatomic) UICollectionView *similarRoomsCollectionView;

@end

NS_ASSUME_NONNULL_END
