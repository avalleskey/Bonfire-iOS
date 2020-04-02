//
//  BFMedia.m
//  Pulse
//
//  Created by Austin Valleskey on 4/14/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFMedia.h"
#import "Launcher.h"
#import "UIImage+fixOrientation.m"
@import MobileCoreServices.UTType;

@implementation BFMedia

- (id)init {
    self = [super init];
    if (self) {
        [self flush];
        [self initDefaults];
    }
    return self;
}

- (void)initDefaults {
    self.maxImages = 4;
    self.maxGIFs = 1;
}

- (void)flush {
    self.objects = [[NSMutableArray alloc] init];
    self.images = [[NSMutableArray alloc] init];
    self.GIFs = [[NSMutableArray alloc] init];
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
    BFMediaObject *mediaObject = [[BFMediaObject alloc] initWithAsset:asset];
    
    // validate
    if (!mediaObject.data) {
        return;
    }
    
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
- (void)addGIFData:(NSData *)data {
    BFMediaObject *mediaObject = [[BFMediaObject alloc] initWithGIFData:data];
    
    // validate
    if (!mediaObject.data) {
        return;
    }
    
    if ([mediaObject.MIME isEqualToString:BFMediaObjectMIME_GIF]) {
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
    return self.GIFs.count == 0 && self.images.count < 4;
}

- (BOOL)canAddGIF {
    return self.images.count == 0 && self.GIFs.count < 1;
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
            PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
            imageRequestOptions.synchronous = YES;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:imageRequestOptions resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info)
             {
                CFStringRef dataUTIRef = (__bridge CFStringRef)dataUTI;
                CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(dataUTIRef, kUTTagClassMIMEType);
                
                self.MIME = (__bridge NSString *)MIMEType;
                
                CFRelease(dataUTIRef);
                CFRelease(MIMEType);

                if ([self.MIME isEqualToString:BFMediaObjectMIME_JPEG] || [self.MIME isEqualToString:BFMediaObjectMIME_PNG]) {
                    self.MIME = BFMediaObjectMIME_JPEG;
                    self.data = [BFMediaObject compressData:imageData mimeType:self.MIME];
                }
                else if ([self.MIME isEqualToString:BFMediaObjectMIME_GIF]) {
                    self.data = imageData;
                }
                else {
                    NSData *data = imageData;
                    UIImage *imageFromData = [UIImage imageWithData:data];
                    imageFromData = [imageFromData fixOrientation];
                     
                    NSData *jpgData = UIImageJPEGRepresentation(imageFromData, 1.0);
                    
                    self.MIME = BFMediaObjectMIME_JPEG;
                    self.data = [BFMediaObject compressData:jpgData mimeType:self.MIME];
                }
            }];
        }
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    self = [self init];
    if (self) {
        image = [image fixOrientation];
        
        NSData *jpgData = UIImageJPEGRepresentation(image, 1.0);
        
        self.MIME = BFMediaObjectMIME_JPEG;
        self.data = [BFMediaObject compressData:jpgData mimeType:self.MIME];
    }
    return self;
}

- (id)initWithGIFData:(NSData *)data {
    self = [self init];
    if (self) {
        self.MIME = BFMediaObjectMIME_GIF;
        self.data = data;
        
        NSLog(@"GIF Size (before): %.2f MB",(float)data.length/1024.0f/1024.0f);
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

+ (NSData *)compressData:(NSData *)data mimeType:(NSString *)mimeType {
    __block NSData *imageData = data;
    
    UIImage *image = [UIImage imageWithData:imageData];
    
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 2436;
    float maxWidth = 2436;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.5;//50 percent compression
    
    if (actualHeight > maxHeight || actualWidth > maxWidth) {
        if(imgRatio < maxRatio){
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio){
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }else{
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    
    NSLog(@"Actual Image Size (before): %.2f MB",(float)imageData.length/1024.0f/1024.0f);
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setFill];
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    
    [image drawInRect:rect];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *newData;
    if ([mimeType isEqualToString:@"image/jpeg"] ||
        [mimeType isEqualToString:@"image/png"]) {
        NSLog(@"treat as jpeg");
        
        newData = UIImageJPEGRepresentation(img, compressionQuality);
        if (newData && newData.length < imageData.length) {
            imageData = newData;
        }
    }
    else if ([mimeType isEqualToString:@"image/gif"]) {
        NSLog(@"it's a gif we can't do anything about it.....");
    }
    
    DLog(@"size(%f, %f)", actualWidth, actualHeight);
    NSLog(@"Actual Image Size (after): %.2f MB",(float)imageData.length/1024.0f/1024.0f);
        
    return imageData;
}

//- (NSString *)MIMETypeFromFileName:(NSString *)fileName {
//    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fileName pathExtension], NULL);
//    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
//    CFRelease(UTI);
//    if (!MIMEType) {
//        return @"application/octet-stream";
//    }
//    return (__bridge NSString *)(MIMEType);
//}

@end
