//
//  SelectAPostViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 7/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Camp.h"
#import "Post.h"
#import "ThemedTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SetAnIcebreakerViewController;

@protocol SetAnIcebreakerViewControllerDelegate <NSObject>

@optional
- (void)setAnIcebreakerViewController:(SetAnIcebreakerViewController *)viewController didSelectPost:(Post *)post;

@end

@interface SetAnIcebreakerViewController : ThemedTableViewController <BFComponentTableViewDelegate>

@property (nonatomic, strong) Camp *camp;

@property (nonatomic, weak) id <SetAnIcebreakerViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
