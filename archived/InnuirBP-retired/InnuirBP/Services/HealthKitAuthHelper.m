// HealthKitAuthHelper.m
// InnuirBP
//
// Catches NSException from HealthKit so the app doesn't crash when the
// HealthKit entitlement is missing from the provisioning profile.
//
// CRITICAL: Every function here MUST be __attribute__((noinline)).
// LTO can inline C functions into Swift callers, which discards the
// Obj-C @try/@catch exception handling tables. The C++ unwinder then
// finds no matching catch handler and calls std::terminate → SIGABRT.

#import "HealthKitAuthHelper.h"

static NSString *const kDefaultMessage =
    @"Blood pressure sync requires HealthKit access. "
    @"Please ensure Health access is enabled in Settings > Privacy & Security > Health.";

static NSError *InnuirBPHealthKitError(NSException *exception) {
    return [NSError errorWithDomain:@"InnuirBP.HealthKit"
                               code:-1
                           userInfo:@{
        NSLocalizedDescriptionKey: kDefaultMessage,
        @"NSExceptionReason": exception.reason ?: @"(unknown)"
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

__attribute__((noinline))
BOOL InnuirBPIsHealthKitEntitlementAvailable(HKHealthStore *store,
                                            NSError * _Nullable * _Nullable outError) {
    @try {
        HKQuantityType *systolicType =
            [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
        // authorizationStatusForType: does not require the HealthKit entitlement
        // on most OS versions, but _can_ throw on some. Wrap defensively.
        [store authorizationStatusForType:systolicType];
        return YES;
    } @catch (NSException *exception) {
        if (outError) {
            *outError = InnuirBPHealthKitError(exception);
        }
        return NO;
    }
}
