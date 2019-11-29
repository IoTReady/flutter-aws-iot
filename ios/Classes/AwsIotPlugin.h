#import <Flutter/Flutter.h>
#import "awsCore/AWSCategory.h"

@interface AwsIotPlugin : NSObject<FlutterPlugin>
+ (AWSRegionType)parseAWSRegion:(NSString*)region;
@end
