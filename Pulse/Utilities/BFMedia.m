//
//  BFMedia.m
//  Pulse
//
//  Created by Austin Valleskey on 4/14/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFMedia.h"
#import "Launcher.h"
@import MobileCoreServices.UTType;

@implementation BFMedia

- (id)init {
    self = [super init];
    if (self) {
        self.objects = [[NSMutableArray alloc] init];
        self.images = [[NSMutableArray alloc] init];
        self.GIFs = [[NSMutableArray alloc] init];
        
        [self initDefaults];
    }
    return self;
}

- (void)initDefaults {
    self.maxImages = 4;
    self.maxGIFs = 1;
}

- (NSArray *)toDataArray {
    if (self.objects.count == 0) return @[];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.objects.count; i++) {
        [array addObject:self.objects[i].data];
    }
    
    return [array copy];
}

- (void)addAsset:(PHAsset *)asset {
    NSLog(@"asset type: %ld", (long)[asset mediaType]);
    NSLog(@"asset subtypes: %lu", (unsigned long)[asset mediaSubtypes]);
    BFMediaObject *mediaObject = [[BFMediaObject alloc] initWithAsset:asset];
    
    // validate
    if (!mediaObject.data) {
        return;
    }
    
    NSLog(@"mediaObject.MIME: %@", mediaObject.MIME);
    if ([mediaObject.MIME isEqualToString:BFMediaObjectMIME_JPEG] || [mediaObject.MIME isEqualToString:BFMediaObjectMIME_PNG]) {
        if ([self canAddImage]) {
            [self.images addObject:mediaObject];
        }
        else {
            return;
        }
    }
    else if ([mediaObject.MIME isEqualToString:BFMediaObjectMIME_GIF]) {
        if ([self canAddGIF]) {
            [self.GIFs addObject:mediaObject];
        }
        else {
            return;
        }
    }
    else {
        return;
    }
    
    // add asset
    [self.objects addObject:mediaObject];
    
    // notify delegate
    [self.delegate mediaObjectAdded:mediaObject];
}
- (void)addImage:(UIImage *)image {
    BFMediaObject *mediaObject = [[BFMediaObject alloc] initWithImage:image];
    
    if ([self canAddImage]) {
        [self.images addObject:mediaObject];
        
        // add asset
        [self.objects addObject:mediaObject];
        
        // notify delegate
        [self.delegate mediaObjectAdded:mediaObject];
    }
}

- (void)removeObject:(BFMediaObject *)object {
    [self.objects removeObject:object];
    
    if ([object.MIME isEqualToString:BFMediaObjectMIME_JPEG] || [object.MIME isEqualToString:BFMediaObjectMIME_PNG]) {
        [self.images removeObject:object];
        
        return;
    }
    if ([object.MIME isEqualToString:BFMediaObjectMIME_GIF]) {
        [self.GIFs removeObject:object];
        
        return;
    }
}

- (BOOL)canAddImage {
    NSLog(@"self.images: %lu < self.maxImages: %ld", (unsigned long)self.images.count, (long)self.maxImages);
    return self.GIFs.count == 0 && self.images.count < self.maxImages;
}

- (BOOL)canAddGIF {
    NSLog(@"self.GIFs: %lu < self.maxGIFs: %ld", (unsigned long)self.GIFs.count, (long)self.maxGIFs);
    return self.images.count == 0 && self.GIFs.count < self.maxGIFs;
}

- (BOOL)canAddMedia {
    return [self canAddImage] || [self canAddGIF];
}

@end

@implementation BFMediaObject

NSString * const BFMediaObjectMIME_JPEG = @"image/jpeg";
NSString * const BFMediaObjectMIME_PNG = @"image/png";
NSString * const BFMediaObjectMIME_GIF = @"image/gif";

- (id)initWithAsset:(PHAsset *)asset {
    self = [self init];
    if (self) {
        if (asset) {
            self.MIME = [self MIMETypeFromFileName:[NSString stringWithFormat:@"%@", [asset valueForKey:@"filename"]]];
            NSLog(@"self.MIME: %@", self.MIME);
            
            
            PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
            imageRequestOptions.synchronous = YES;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:imageRequestOptions resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info)
             {
                 NSLog(@"info = %@", info);
                 NSLog(@"data uti: %@", dataUTI);
                 NSLog(@"path extension: %@", [[asset valueForKey:@"filename"] pathExtension]);

                 if ([self.MIME isEqualToString:BFMediaObjectMIME_JPEG] || [self.MIME isEqualToString:BFMediaObjectMIME_PNG]) {
                     self.data = imageData;
                 }
                 else {
                     NSData *data = imageData;
                     UIImage *imageFromData = [UIImage imageWithData:data];
                     NSData *jpgData = UIImageJPEGRepresentation(imageFromData, 1.0);
                     
                     self.MIME = BFMediaObjectMIME_JPEG;
                     self.data = jpgData;
                     
                     NSLog(@"set the mime to jpeg and data to jpg");
                 }
             }];
        }
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    self = [self init];
    if (self) {
        self.MIME = BFMediaObjectMIME_JPEG;
        self.data = UIImageJPEGRepresentation(image, 1.0);
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.MIME = BFMediaObjectMIME_JPEG;
        self.data = nil;
    }
    return self;
}

- (NSString *)MIMETypeFromFileName:(NSString *)fileName {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fileName pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return (__bridge NSString *)(MIMEType);
}

@end
