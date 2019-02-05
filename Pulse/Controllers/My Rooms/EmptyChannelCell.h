//
//  EmptyChannelCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ErrorView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EmptyChannelCell : UICollectionViewCell

@property (strong, nonatomic) ErrorView *errorView;

@end

NS_ASSUME_NONNULL_END
