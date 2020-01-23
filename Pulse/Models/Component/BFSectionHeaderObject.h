//
//  BFSectionHeaderObject.h
//  Pulse
//
//  Created by Austin Valleskey on 1/21/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFSectionHeaderObject : NSObject

- (id)initWithTitle:(NSString * _Nullable)title text:(NSString * _Nullable)text target:(id _Nullable)target;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) id target;

@end

NS_ASSUME_NONNULL_END
