//
//  BFTableViewCellExporter.h
//  Pulse
//
//  Created by Austin Valleskey on 8/30/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFViewExporter : NSObject <UITableViewDelegate, UITableViewDataSource>

+ (UIImage *)imageForCell:(id)cell size:(CGSize)size;

+ (UIImage *)imageForView:(UIView *)view container:(BOOL)container;
+ (UIImage *)imageForView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
