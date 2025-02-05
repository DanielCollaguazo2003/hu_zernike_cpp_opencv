#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FilterApplicatorBridge : NSObject

- (UIImage *)apply_filter:(UIImage *)image;

- (void *)loadAndResizeImages:(NSArray<NSString *> *)imagePaths subFrameSize:(CGSize)subFrameSize;

- (void)releaseMat:(void *)matPtr;

- (UIImage *)apply_filter:(UIImage *)image useClahe:(int)useClahe withReferenceMat:(void *)referenceMatPtr;

@end
