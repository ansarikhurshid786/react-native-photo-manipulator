
#import "RNPhotoManipulator.h"
#import "ImageUtils.h"

#import <React/RCTConvert.h>
#import <React/RCTImageLoader.h>

#import <WCPhotoManipulator/UIImage+PhotoManipulator.h>
#import <WCPhotoManipulator/MimeUtils.h>

@implementation RNPhotoManipulator

@synthesize bridge = _bridge;

const CGFloat DEFAULT_QUALITY = 100;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(batch:(NSURLRequest *)uri
                  size:(NSDictionary *)size
                  quality:(NSInteger)quality
                  operations:(NSArray *)operations
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.imageLoader loadImageWithURLRequest:uri callback:^(NSError *error, UIImage *image) {
        if (error) {
            reject(@(error.code).stringValue, error.description, error);
            return;
        }
        
        UIImage *result = [image resize:[RCTConvert CGSize:size] scale:image.scale];
        
        for (NSDictionary *operation in operations) {
            result = [self processBatchOperation:result operation:operation];
        }
        
        NSString *uri = [ImageUtils saveTempFile:result mimeType:MimeUtils.JPEG quality:quality];
        resolve(uri);
    }];
}

- (UIImage *)processBatchOperation:(UIImage *)image operation:(NSDictionary *)operations {
    NSString *type = [RCTConvert NSString:operations[@"operation"]];
    NSDictionary *options = [RCTConvert NSDictionary:operations[@"options"]];
    
    if ([type isEqual:@"overlay"]) {
        NSURLRequest *overlay = [RCTConvert NSURLRequest:options[@"overlay"]];
        CGPoint position = [RCTConvert CGPoint:options[@"position"]];
        return image;
    } else if ([type isEqual:@"text"]) {
        NSString *text = [RCTConvert NSString:options[@"text"]];
        CGPoint position = [RCTConvert CGPoint:options[@"position"]];
        CGFloat textSize = [RCTConvert CGFloat:options[@"textSize"]];
        UIColor *color = [self toColor:[RCTConvert NSDictionary:options[@"color"]]];
        CGFloat thickness = [RCTConvert CGFloat:options[@"thickness"]];
        
        return [image drawText:text position:position color:color size:textSize thickness:thickness];
    }
    return nil;
}

- (UIColor *)toColor:(NSDictionary *)color {
    return [UIColor colorWithRed:[color[@"r"] doubleValue] green:[color[@"g"] doubleValue] blue:[color[@"b"] doubleValue] alpha:[color[@"a"] doubleValue] / 255];
}

RCT_EXPORT_METHOD(overlayImage:(NSURLRequest *)uri
                  icon:(NSURLRequest *)icon
                  position:(NSDictionary *)position
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    [self.bridge.imageLoader loadImageWithURLRequest:uri callback:^(NSError *error, UIImage *image) {
        if (error) {
            reject(@(error.code).stringValue, error.description, error);
            return;
        }
        
        [self->_bridge.imageLoader loadImageWithURLRequest:icon callback:^(NSError *error, UIImage *icon) {
            if (error) {
                reject(@(error.code).stringValue, error.description, error);
                return;
            }
            
            UIImage *result = [image overlayImage:icon position:[RCTConvert CGPoint:position]];
            
            NSString *uri = [ImageUtils saveTempFile:result mimeType:MimeUtils.JPEG quality:DEFAULT_QUALITY];
            resolve(uri);
        }];
    }];
}

RCT_EXPORT_METHOD(printText:(NSURLRequest *)uri
                  list:(NSArray *)list
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    resolve(uri);
}

RCT_EXPORT_METHOD(optimize:(NSURLRequest *)uri
                  quality:(NSInteger)quality
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    resolve(uri);
}

RCT_EXPORT_METHOD(resize:(NSURLRequest *)uri
                  targetSize:(NSDictionary *)targetSize
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    [self.bridge.imageLoader loadImageWithURLRequest:uri callback:^(NSError *error, UIImage *image) {
        if (error) {
            reject(@(error.code).stringValue, error.description, error);
            return;
        }
        
        UIImage *result = [image resize:[RCTConvert CGSize:targetSize] scale:image.scale];
        
        NSString *uri = [ImageUtils saveTempFile:result mimeType:MimeUtils.JPEG quality:DEFAULT_QUALITY];
        resolve(uri);
    }];
}

@end
