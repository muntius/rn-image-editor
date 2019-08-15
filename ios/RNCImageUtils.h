#ifndef RNCImageUtils_h
#define RNCImageUtils_h

#import <Foundation/Foundation.h>

@interface RNCImageUtils : NSObject

+ (NSString *)writeImage:(NSData *)image toPath:(NSString *)path error:(NSError **)error;

@end


#endif /* RNCImageUtils_h */
