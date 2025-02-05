#undef NO
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageProcessor : NSObject

+ (NSArray<NSNumber *> *)calculateHuMomentsFromUIImage:(UIImage *)image;
+ (NSString *)classifyImage:(UIImage *)image withCSV:(NSString *)csvPath;
+ (NSArray<NSNumber *> *)calculateZernikeMomentsFromImage:(UIImage *)image;

@end
