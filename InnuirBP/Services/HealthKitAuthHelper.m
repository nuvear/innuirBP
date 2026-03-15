// HealthKitAuthHelper.m
// InnuirBP
//
// Catches NSException from HealthKit so the app doesn't crash when the
// HealthKit entitlement is missing from the provisioning profile.

#import "HealthKitAuthHelper.h"

static NSString *const kDefaultMessage =
    @"Blood pressure sync requires HealthKit access. "
    @"Please ensure Health access is enabled in Settings > Privacy & Security > Health. "
    @"If the app was just installed, you may need to use the InnuirBP HealthKit Dev provisioning profile.";

static NSError *InnuirBPHealthKitError(NSException *exception) {
    NSString *reason = exception.reason ?: @"(unknown)";
    NSString *fullMessage = [NSString stringWithFormat:@"%@\n\nTechnical: %@", kDefaultMessage, reason];
    return [NSError errorWithDomain:@"InnuirBP.HealthKit"
                               code:-1
                           userInfo:@{
        NSLocalizedDescriptionKey: fullMessage,
        @"NSExceptionReason": reason
    }];
}

__attribute__((noinline))
void InnuirBPRequestHealthKitAuthorization(HKHealthStore *store,
                                          NSSet<HKObjectType *> * _Nullable typesToRead,
                                          void (^completion)(BOOL success, NSError * _Nullable error)) {
    @try {
        [store requestAuthorizationToShareTypes:nil
                                      readTypes:typesToRead
                                     completion:^(BOOL success, NSError * _Nullable error) {
            if (completion) {
                completion(success, error);
            }
        }];
    } @catch (NSException *exception) {
        if (completion) {
            completion(NO, InnuirBPHealthKitError(exception));
        }
    }
}
