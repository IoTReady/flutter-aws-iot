#import "AwsIotPlugin.h"
#import <aws_iot/aws_iot-Swift.h>
#import "awsCore/AWSCategory.h"

@implementation AwsIotPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAwsIotPlugin registerWithRegistrar:registrar];
}
+ (AWSRegionType)parseAWSRegion:(NSString*)region {
    return [region aws_regionTypeValue];
}
@end
