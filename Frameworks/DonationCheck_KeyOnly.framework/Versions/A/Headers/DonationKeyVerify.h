//
//  DonationKeyVerify.h
//  DonationCheck
//
//  Created by 小鳥遊六花 on 4/17/18.
//  Copyright © 2018 Moy IT Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DonationKeyVerify : NSObject
+ (bool)checkLicense:(NSString *)name withDonationKey:(NSString *)key  isUpgradeLicense:(bool)isupgrade;
+ (bool)checkMALULicense:(NSString *)name withDonationKey:(NSString *)key;
+ (bool)checkHachidoriLicense:(NSString *)name withDonationKey:(NSString *)key;
@end
