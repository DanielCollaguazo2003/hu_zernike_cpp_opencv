#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZernikeBridge : NSObject

// Método para predecir la categoría de la imagen usando momentos de Zernike
- (NSString *)predictWithImage:(UIImage *)image csvPath:(NSString *)csvPath;

@end

NS_ASSUME_NONNULL_END