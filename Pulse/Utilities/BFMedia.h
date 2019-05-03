//
//  BFMedia.h
//  Pulse
//
//  Created by Austin Valleskey on 4/14/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@class BFMediaObject;

NS_ASSUME_NONNULL_BEGIN

@protocol BFMediaDelegate <NSObject>

- (void)mediaObjectAdded:(BFMediaObject *)object;

@end

@interface BFMedia : NSObject

#pragma mark - Properties
@property (nonatomic, strong) NSMutableArray <BFMediaObject *> *objects;
@property (nonatomic, strong) NSMutableArray <BFMediaObject *> *images;
@property (nonatomic, strong) NSMutableArray <BFMediaObject *> *GIFs;

@property (nonatomic) NSInteger maxImages;
@property (nonatomic) NSInteger maxGIFs;

#pragma mark - Methods
- (void)addAsset:(PHAsset *)asset;
- (void)addImage:(UIImage *)image;
- (void)removeObject:(BFMediaObject *)object;
- (NSArray *)toDataArray;
- (BOOL)canAddImage;
- (BOOL)canAddGIF;
- (BOOL)canAddMedia;

@property (nonatomic, weak) id <BFMediaDelegate> delegate;

@end

@interface BFMediaObject : NSObject

- (id)initWithAsset:(PHAsset *)asset;
- (id)initWithImage:(UIImage *)image;

// supported MIME types
extern NSString * const BFMediaObjectMIME_JPEG;
extern NSString * const BFMediaObjectMIME_PNG;
extern NSString * const BFMediaObjectMIME_GIF;

@property (nonatomic, strong) NSString *MIME;
@property (nonatomic, strong) NSData * _Nullable data;

@end

NS_ASSUME_NONNULL_END
