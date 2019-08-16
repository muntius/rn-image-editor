#include <UIKit/UIKit.h>

extern const CGBitmapInfo kDefaultCGBitmapInfo;
extern const CGBitmapInfo kDefaultCGBitmapInfoNoAlpha;

float			GetScaleForProportionalResize( CGSize theSize, CGSize intoSize, bool onlyScaleDown, bool maximize );
CGContextRef	CreateCGBitmapContextForWidthAndHeight( unsigned int width, unsigned int height, CGColorSpaceRef optionalColorSpace, CGBitmapInfo optionalInfo );

CGImageRef		CreateCGImageFromUIImageScaled( UIImage* inImage, float scaleFactor );

@interface UIImage (scale)
-(UIImage*)scaleToSize:(CGSize)toSize;
@end
