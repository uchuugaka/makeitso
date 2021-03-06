//
//  Player.h
//  MakeItSo
//
//  Created by Todd Ditchendorf on 12/27/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import <MakeItSo/DomainObject.h>

@class Team;

@interface Player : DomainObject

@property (nonatomic, copy) NSString *firstName MIS_PROPERTY;
@property (nonatomic, copy) NSString *lastName MIS_PROPERTY;

@property (nonatomic, retain) Team *team MIS_ONE_TO_ONE;
@end
