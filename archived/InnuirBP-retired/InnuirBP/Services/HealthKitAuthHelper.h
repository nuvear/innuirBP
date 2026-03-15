// HealthKitAuthHelper.h
// InnuirBP
//
// Objective-C helper to catch NSException from HealthKit's requestAuthorization.
// HealthKit throws NSException when the app lacks the HealthKit entitlement;
// Swift's do/catch cannot catch NSException.

#import <Foundation/Foundation.h>

@import HealthKit;

NS_ASSUME_NONNULL_BEGIN

/// Calls requestAuthorization(toShare:read:completion:) inside @try/@catch.
/// If HealthKit throws (e.g. missing entitlement), completion is called with success=NO and error.
///
/// Marked noinline to prevent LTO from inlining into Swift callers, which
/// would discard the Obj-C @try/@catch exception tables and allow the
/// NSException to propagate uncaught (SIGABRT).
void InnuirBPRequestHealthKitAuthorization(HKHealthStore *store,
                                          NSSet<HKObjectType *> * _Nullable typesToRead,
                                          void (^completion)(BOOL success, NSError * _Nullable error))
    __attribute__((noinline));

/// Lightweight pre-flight check: returns YES if requesting HealthKit
/// authorization is expected to succeed (entitlement present), NO otherwise.
/// Catches any NSException that HealthKit may throw during validation.
BOOL InnuirBPIsHealthKitEntitlementAvailable(HKHealthStore *store,
                                            NSError * _Nullable * _Nullable outError)
    __attribute__((noinline));

NS_ASSUME_NONNULL_END
