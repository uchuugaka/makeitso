//
//  MISCriteria.h
//  MakeItSo
//
//  Created by Todd Ditchendorf on 12/25/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MISCriteriaType) {
    MISCriteriaTypeAnd = 0,
    MISCriteriaTypeOr,
};

typedef NS_ENUM(NSUInteger, MISCriteriaOperator) {
    MISCriteriaOperatorEqualTo = 0,
    MISCriteriaOperatorNotEqualTo,
    MISCriteriaOperatorLessThan,
    MISCriteriaOperatorGreaterThan,
    MISCriteriaOperatorLessThanOrEqualTo,
    MISCriteriaOperatorGreaterThanOrEqualTo,
    MISCriteriaOperatorLike,
};

@interface MISCriteria : NSObject
+ (instancetype)criteriaWithType:(MISCriteriaType)type lhs:(NSString *)lhs op:(MISCriteriaOperator)op rhs:(id)rhs;
- (instancetype)initWithType:(MISCriteriaType)type lhs:(NSString *)lhs op:(MISCriteriaOperator)op rhs:(id)rhs;

@property (nonatomic, assign, readonly) MISCriteriaType type;
@property (nonatomic, assign, readonly) MISCriteriaOperator op;
@property (nonatomic, copy, readonly) NSString *lhs;
@property (nonatomic, retain, readonly) NSString *rhs;

- (NSString *)generateSql;
@end
