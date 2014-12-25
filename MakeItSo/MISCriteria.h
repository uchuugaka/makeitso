//
//  MISCriteria.h
//  MakeItSo
//
//  Created by Todd Ditchendorf on 12/25/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MISCriteriaOperator) {
    MISCriteriaOperatorEqualTo = 0,
    MISCriteriaOperatorLessThan,
    MISCriteriaOperatorGreaterThan,
    MISCriteriaOperatorLessThanOrEqualTo,
    MISCriteriaOperatorGreaterThanOrEqualTo,
};

@interface MISCriteria : NSObject
+ (instancetype)equalTo:(id)arg;
+ (instancetype)lessThan:(id)arg;
+ (instancetype)greaterThan:(id)arg;
+ (instancetype)lessThanOrEqualTo:(id)arg;
+ (instancetype)greaterThanOrEqualTo:(id)arg;

- (instancetype)initWithOperator:(MISCriteriaOperator)op argument:(id)arg;
@end
