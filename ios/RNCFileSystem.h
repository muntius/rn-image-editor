#ifndef RNCFileSystem_h
#define RNCFileSystem_h

#import <Foundation/Foundation.h>

@interface RNCFileSystem : NSObject

+ (BOOL)ensureDirExistsWithPath:(NSString *)path;
+ (NSString *)generatePathInDirectory:(NSString *)directory withExtension:(NSString *)extension;
+ (NSString *)cacheDirectoryPath;

@end

#endif /* RNCFileSystem_h */
