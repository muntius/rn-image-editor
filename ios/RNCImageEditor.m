#import "RNCImageEditor.h"

#import <UIKit/UIKit.h>

#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#include "ImageHelpers.h"

#import <React/RCTImageLoader.h>
#import <React/RCTImageStoreManager.h>
#import "RNCFileSystem.h"
#import "RNCImageUtils.h"
#if __has_include(<RCTImage/RCTImageUtils.h>)
#import <RCTImage/RCTImageUtils.h>
#else
#import "RCTImageUtils.h"
#endif

@implementation RNCImageEditor

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

/**
 * Crops an image and saves the result to temporary file. Consider using
 * CameraRoll API or other third-party module to save it in gallery.
 *
 * @param imageRequest An image URL
 * @param cropData Dictionary with `offset`, `size` and `displaySize`.
 *        `offset` and `size` are relative to the full-resolution image size.
 *        `displaySize` is an optimization - if specified, the image will
 *        be scaled down to `displaySize` rather than `size`.
 *        All units are in px (not points).
 */

RCT_EXPORT_METHOD(getBase64:(NSString *)linkUrl
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSData *imageData;
    if ([linkUrl hasPrefix:@"http"]) {
        NSURL *url = [NSURL URLWithString:linkUrl];
        imageData = [NSData dataWithContentsOfURL:url];
    } else {
        imageData = [NSData dataWithContentsOfFile:linkUrl];
    }
    if (!imageData) {
        reject(@"Error", @"Invalid URL or URI provided", nil);
        return;
    }
    UIImage *image = [UIImage imageWithData:imageData];
    NSString *strEncoded = encodeToBase64String(image);
    resolve(strEncoded);
}



RCT_EXPORT_METHOD(cropImage:(NSURLRequest *)imageRequest
                  cropData:(NSDictionary *)cropData
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  CGRect rect = {
    [RCTConvert CGPoint:cropData[@"offset"]],
    [RCTConvert CGSize:cropData[@"size"]]
  };

  [_bridge.imageLoader loadImageWithURLRequest:imageRequest callback:^(NSError *error, UIImage *image) {
    if (error) {
      reject(@(error.code).stringValue, error.description, error);
      return;
    }

    // Crop image
    CGSize targetSize = rect.size;
    CGRect targetRect = {{-rect.origin.x, -rect.origin.y}, image.size};
    CGAffineTransform transform = RCTTransformFromTargetRect(image.size, targetRect);
    UIImage *croppedImage = RCTTransformImage(image, targetSize, image.scale, transform);

    // Scale image
    if (cropData[@"displaySize"]) {
      targetSize = [RCTConvert CGSize:cropData[@"displaySize"]]; // in pixels
      RCTResizeMode resizeMode = [RCTConvert RCTResizeMode:cropData[@"resizeMode"] ?: @"contain"];
      targetRect = RCTTargetRect(croppedImage.size, targetSize, 1, resizeMode);
      transform = RCTTransformFromTargetRect(croppedImage.size, targetRect);
      croppedImage = RCTTransformImage(croppedImage, targetSize, image.scale, transform);
    }

    // Store image
    NSString *path = [RNCFileSystem generatePathInDirectory:[[RNCFileSystem cacheDirectoryPath] stringByAppendingPathComponent:@"ReactNative_cropped_image_"] withExtension:@".jpg"];

    NSData *imageData = UIImageJPEGRepresentation(croppedImage, 1);
    NSError *writeError;
    NSString *uri = [RNCImageUtils writeImage:imageData toPath:path error:&writeError];
      
    if (writeError != nil) {
        reject(@(writeError.code).stringValue, writeError.description, writeError);
        return;
    }
      
    resolve(uri);
  }];
}

RCT_EXPORT_METHOD(rotate:(NSString *)path
                  quality:(float)quality
                  rotation:(float)rotation
                  outputPath:(NSString *)outputPath
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        CGSize newSize = CGSizeMake(width, height);
        //Set image extension
        NSString *extension = @"jpg";
        NSString* fullPath;
        @try {
            fullPath = generateFilePath(extension, outputPath);
        } @catch (NSException *exception) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"failed generateFilePath" };
            NSError *error = [NSError errorWithDomain:@"generateFilePath"
                                                 code:-1
                                             userInfo:userInfo];
            reject(@"error", @"There were no events", error);
            return;
        }
        
        [_bridge.imageLoader loadImageWithURLRequest:[RCTConvert NSURLRequest:path] callback:^(NSError *error, UIImage *image) {
            if (error || image == nil) {
                if ([path hasPrefix:@"data:"] || [path hasPrefix:@"file:"]) {
                    NSURL *imageUrl = [[NSURL alloc] initWithString:path];
                    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
                } else {
                    image = [[UIImage alloc] initWithContentsOfFile:path];
                }
                if (image == nil) {
                    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"failed loadImageWithURLRequest" };
                    NSError *error = [NSError errorWithDomain:@"loadImageWithURLRequest"
                                                         code:-1
                                                     userInfo:userInfo];
                    reject(@"error", @"There were no events", error);
                    return;
                }
            }
            
            // Rotate image if rotation is specified.
            if (0 != (int)rotation) {
                image = rotateImage(image, rotation);
                if (image == nil) {
                    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"failed Can't rotate the image" };
                    NSError *error = [NSError errorWithDomain:@"rotateImage"
                                                         code:-1
                                                     userInfo:userInfo];
                    reject(@"error", @"failed Can't rotate the image", error);
                    return;
                }
            }
            
            // Do the resizing
//            UIImage * scaledImage = [image scaleToSize:newSize];
//            if (scaledImage == nil) {
//                resolve(@[@"Can't resize the image.", @""]);
//                return;
//            }
            
            // Compress and save the image
            if (!saveImage(fullPath, image, extension, quality)) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"failed saveImage" };
                NSError *error = [NSError errorWithDomain:@"saveImage"
                                                     code:-1
                                                 userInfo:userInfo];
                reject(@"error", @"failed Can't saveImage", error);
                return;
            }
            NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fullPath];
            NSString *fileName = fileUrl.lastPathComponent;
            NSError *attributesError = nil;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&attributesError];
            NSNumber *fileSize = fileAttributes == nil ? 0 : [fileAttributes objectForKey:NSFileSize];
            NSDictionary *response = @{@"path": fullPath,
                                       @"uri": fileUrl.absoluteString,
                                       @"name": fileName,
                                       @"size": fileSize == nil ? @(0) : fileSize
                                       };
            
            resolve(response);
        }];
    });
    }

RCT_EXPORT_METHOD(createThumbnailImage:(NSString *)path
                  width:(float)width
                  height:(float)height
                  format:(NSString *)format
                  quality:(float)quality
                  rotation:(float)rotation
                  outputPath:(NSString *)outputPath
                  callback:(RCTResponseSenderBlock)callback)
{
    CGSize newSize = CGSizeMake(width, height);
    
    //Set image extension
    NSString *extension = @"jpg";
    if ([format isEqualToString:@"PNG"]) {
        extension = @"jpg";
    }
    
    
    NSString* fullPath;
    @try {
        fullPath = generateFilePathThumbnailImage(extension, outputPath);
    } @catch (NSException *exception) {
        callback(@[@"Invalid output path.", @""]);
        return;
    }
    
    [_bridge.imageLoader loadImageWithURLRequest:[RCTConvert NSURLRequest:path] callback:^(NSError *error, UIImage *image) {
        if (error || image == nil) {
            if ([path hasPrefix:@"data:"] || [path hasPrefix:@"file:"]) {
                NSURL *imageUrl = [[NSURL alloc] initWithString:path];
                image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
            } else {
                image = [[UIImage alloc] initWithContentsOfFile:path];
            }
            if (image == nil) {
                callback(@[@"Can't retrieve the file from the path.", @""]);
                return;
            }
        }
        
        // Rotate image if rotation is specified.
        if (0 != (int)rotation) {
            image = rotateImage(image, rotation);
            if (image == nil) {
                callback(@[@"Can't rotate the image.", @""]);
                return;
            }
        }
        
        // Do the resizing
        UIImage * scaledImage = [image scaleToSize:newSize];
        if (scaledImage == nil) {
            callback(@[@"Can't resize the image.", @""]);
            return;
        }
        
        // Compress and save the image
        if (!saveImage(fullPath, scaledImage, format, quality)) {
            callback(@[@"Can't save the image. Check your compression format and your output path", @""]);
            return;
        }
        NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fullPath];
        NSString *fileName = fileUrl.lastPathComponent;
        NSError *attributesError = nil;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&attributesError];
        NSNumber *fileSize = fileAttributes == nil ? 0 : [fileAttributes objectForKey:NSFileSize];
        NSDictionary *response = @{@"path": fullPath,
                                   @"uri": fileUrl.absoluteString,
                                   @"name": fileName,
                                   @"size": fileSize == nil ? @(0) : fileSize
                                   };
        
        callback(@[[NSNull null], response]);
    }];
}


NSString * generateFilePathThumbnailImage(NSString * ext, NSString * outputPath)
{
    NSString* directory;
    directory = [outputPath stringByDeletingLastPathComponent];
    NSString* name = [outputPath lastPathComponent];
    NSString* fullName = [NSString stringWithFormat:@"%@.%@", name, ext];
    NSString* fullPath = [directory stringByAppendingPathComponent:fullName];
    
    
    return fullPath;
}

NSString * generateFilePath(NSString * ext, NSString * outputPath)
{
    NSString* directory;
    
    if ([outputPath length] == 0) {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        directory = [paths firstObject];
    } else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        if ([outputPath hasPrefix:documentsDirectory]) {
            directory = outputPath;
        } else {
            directory = [documentsDirectory stringByAppendingPathComponent:outputPath];
        }
        
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating documents subdirectory: %@", error);
            @throw [NSException exceptionWithName:@"InvalidPathException" reason:[NSString stringWithFormat:@"Error creating documents subdirectory: %@", error] userInfo:nil];
        }
    }
    
    NSString* name = [[NSUUID UUID] UUIDString];
    NSString* fullName = [NSString stringWithFormat:@"%@.%@", name, ext];
    NSString* fullPath = [directory stringByAppendingPathComponent:fullName];
    
    return fullPath;
}

NSString * generateDirectoryPath()
{
    NSString* directory;
    
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    directory = [paths firstObject];
    return directory;
    
}

UIImage * rotateImage(UIImage *inputImage, float rotationDegrees)
{
    
    // We want only fixed 0, 90, 180, 270 degree rotations.
    const int rotDiv90 = (int)round(rotationDegrees / 90);
    const int rotQuadrant = rotDiv90 % 4;
    const int rotQuadrantAbs = (rotQuadrant < 0) ? rotQuadrant + 4 : rotQuadrant;
    
    // Return the input image if no rotation specified.
    if (0 == rotQuadrantAbs) {
        return inputImage;
    } else {
        // Rotate the image by 80, 180, 270.
        UIImageOrientation orientation = UIImageOrientationUp;
        
        switch(rotQuadrantAbs) {
            case 1:
                orientation = UIImageOrientationRight; // 90 deg CW
                break;
            case 2:
                orientation = UIImageOrientationDown; // 180 deg rotation
                break;
            default:
                orientation = UIImageOrientationLeft; // 90 deg CCW
                break;
        }
        
        return [[UIImage alloc] initWithCGImage: inputImage.CGImage
                                          scale: 1.0
                                    orientation: orientation];
    }
}

bool saveImage(NSString * fullPath, UIImage * image, NSString * format, float quality)
{
    NSData* data = nil;
    data = UIImageJPEGRepresentation(image, quality / 100.0);
    
    if (data == nil) {
        return NO;
    }
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager createFileAtPath:fullPath contents:data attributes:nil];
}

NSString * encodeToBase64String(UIImage * image) {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}



@end
