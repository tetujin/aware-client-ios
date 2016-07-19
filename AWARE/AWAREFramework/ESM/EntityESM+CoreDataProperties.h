//
//  EntityESM+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityESM.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityESM (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *double_esm_user_answer_timestamp;
@property (nullable, nonatomic, retain) NSString *esm_checkboxes;
@property (nullable, nonatomic, retain) NSNumber *esm_expiration_threshold;
@property (nullable, nonatomic, retain) NSString *esm_instructions;
@property (nullable, nonatomic, retain) NSNumber *esm_likert_max;
@property (nullable, nonatomic, retain) NSString *esm_likert_max_label;
@property (nullable, nonatomic, retain) NSString *esm_likert_min_label;
@property (nullable, nonatomic, retain) NSNumber *esm_likert_step;
@property (nullable, nonatomic, retain) NSString *esm_quick_answers;
@property (nullable, nonatomic, retain) NSString *esm_radios;
@property (nullable, nonatomic, retain) NSNumber *esm_scale_max;
@property (nullable, nonatomic, retain) NSString *esm_scale_max_label;
@property (nullable, nonatomic, retain) NSNumber *esm_scale_min;
@property (nullable, nonatomic, retain) NSString *esm_scale_min_label;
@property (nullable, nonatomic, retain) NSNumber *esm_scale_start;
@property (nullable, nonatomic, retain) NSNumber *esm_scale_step;
@property (nullable, nonatomic, retain) NSNumber *esm_status;
@property (nullable, nonatomic, retain) NSString *esm_submit;
@property (nullable, nonatomic, retain) NSString *esm_title;
@property (nullable, nonatomic, retain) NSString *esm_trigger;
@property (nullable, nonatomic, retain) NSNumber *esm_type;
@property (nullable, nonatomic, retain) NSString *esm_user_answer;
@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSNumber *esm_number;
@property (nullable, nonatomic, retain) NSString *esm_url;
@property (nullable, nonatomic, retain) NSNumber *esm_na;
@property (nullable, nonatomic, retain) NSString *esm_json;
@property (nullable, nonatomic, retain) EntityESMSchedule *esm_schedule;

@end

NS_ASSUME_NONNULL_END
