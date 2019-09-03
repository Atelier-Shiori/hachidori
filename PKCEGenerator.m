//
//  PKCEGenerator.m
//  MAL Updater OS X
//
//  Created by 小鳥遊六花 on 4/25/18.
//

#import "PKCEGenerator.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation PKCEGenerator
+ (NSString *)createVerifierString {
    NSMutableData *data = [NSMutableData dataWithLength:32];
    int result = SecRandomCopyBytes(kSecRandomDefault, 32, data.mutableBytes);
    return [[[[data base64EncodedStringWithOptions:0]
                            stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
                           stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
                          stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
}
+ (NSString *)generateCodeChallenge:(NSString *)verifier {
    u_int8_t buffer[CC_SHA256_DIGEST_LENGTH * sizeof(u_int8_t)];
    memset(buffer, 0x0, CC_SHA256_DIGEST_LENGTH);
    NSData *data = [verifier dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256([data bytes], (CC_LONG)[data length], buffer);
    NSData *hash = [NSData dataWithBytes:buffer length:CC_SHA256_DIGEST_LENGTH];
    return [[[[hash base64EncodedStringWithOptions:0]
                             stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
                            stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
                           stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
}
@end
