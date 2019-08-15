#import "RNCImageUtils.h"

@implementation RNCImageUtils

+ (id)writeImage:(id)image toPath:(id)path error:(NSError **)error
{
    BOOL res = [image writeToFile:path atomically:YES];
    if (res == NO) {
        *error = [NSError errorWithDomain:@"org.imageeditor.imageeditor.writeToFileError" code:101 userInfo:[NSDictionary dictionary]];
        return nil;
    }
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    return [fileURL absoluteString];
}

@end
