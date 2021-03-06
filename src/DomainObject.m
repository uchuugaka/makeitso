//
//  DomainObject.m
//  MakeItSo
//
//  Created by Todd Ditchendorf on 12/25/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import "DomainObject.h"

#import "MISUnitOfWork.h"

@interface DomainObject ()
- (void)markPristine;
- (void)markClean;
- (void)markDirty;
- (void)markRemoved;

@property (nonatomic, retain, readwrite) NSNumber *objectID;
@end

@implementation DomainObject

+ (NSString *)collectionName {
    TDAssertDatabaseThread();

    static NSString *sName = nil;
    if (!sName) {
        NSString *clsName = NSStringFromClass(self);
        sName = [[NSString alloc] initWithFormat:@"%@%@", [[clsName substringToIndex:1] lowercaseString], [clsName substringFromIndex:1]];
    }
    return sName;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        [self markPristine];
    }
    return self;
}


- (void)dealloc {
    self.objectID = nil;
    [super dealloc];
}


- (void)remove {
    [self markRemoved];
}


- (void)markPristine {
    [[MISUnitOfWork current] registerPristine:self];
}


- (void)markClean {
    [[MISUnitOfWork current] registerClean:self];
}


- (void)markDirty {
    [[MISUnitOfWork current] registerDirty:self];
}


- (void)markRemoved {
    [[MISUnitOfWork current] registerRemoved:self];
}

@end
