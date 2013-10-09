//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "MTLJSONAdapter.h"
#import "MTLModel.h"
#import "MTLValueTransformer.h"

NSString * const MTLURLValueTransformerName = @"MTLURLValueTransformerName";
NSString * const MTLBooleanValueTransformerName = @"MTLBooleanValueTransformerName";

NSString * const MTLPredefinedTransformerErrorDomain = @"MTLPredefinedTransformerErrorDomain";

const NSInteger MTLURLValueTransformerFailed = 1;
const NSInteger MTLBooleanValueTransformerFailed = 2;
const NSInteger MTLJSONDictionaryTransformerFailed = 3;
const NSInteger MTLJSONArrayTransformerFailed = 4;

@implementation NSValueTransformer (MTLPredefinedTransformerAdditions)

#pragma mark Category Loading

+ (void)load {
	@autoreleasepool {
		MTLValueTransformer *URLValueTransformer = [MTLValueTransformer
			reversibleTransformerWithForwardTransformation:^ id (NSString *str, BOOL *success, NSError **error) {
				if (![str isKindOfClass:NSString.class]) {
					if (error != NULL) {
						NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected an NSString, got: %@.", @""), str];

						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert string", @""),
							NSLocalizedFailureReasonErrorKey: failureReason,
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLURLValueTransformerFailed userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				return [NSURL URLWithString:str];
			}
			reverseTransformation:^ id (NSURL *URL, BOOL *success, NSError **error) {
				if (![URL isKindOfClass:NSURL.class]) {
					if (error != NULL) {
						NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected an NSURL, got: %@.", @""), URL];

						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert URL", @""),
							NSLocalizedFailureReasonErrorKey: failureReason,
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLURLValueTransformerFailed userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				return URL.absoluteString;
			}];
		
		[NSValueTransformer setValueTransformer:URLValueTransformer forName:MTLURLValueTransformerName];

		MTLValueTransformer *booleanValueTransformer = [MTLValueTransformer
			reversibleTransformerWithTransformation:^ id (NSNumber *boolean, BOOL *success, NSError **error) {
				if (![boolean isKindOfClass:NSNumber.class]) {
					if (error != NULL) {
						NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected an NSNumber, got: %@.", @""), boolean];

						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert number", @""),
							NSLocalizedFailureReasonErrorKey: failureReason,
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLBooleanValueTransformerFailed userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				return (NSNumber *)(boolean.boolValue ? kCFBooleanTrue : kCFBooleanFalse);
			}];

		[NSValueTransformer setValueTransformer:booleanValueTransformer forName:MTLBooleanValueTransformerName];
	}
}

#pragma mark Customizable Transformers

+ (NSValueTransformer *)mtl_JSONDictionaryTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);

	return [MTLValueTransformer
		reversibleTransformerWithForwardTransformation:^ id (id JSONDictionary, BOOL *success, NSError **error) {
			if (JSONDictionary == nil) return nil;

			if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary, got: %@.", @""), JSONDictionary];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON dictionary", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLJSONDictionaryTransformerFailed userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			return [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];
		}
		reverseTransformation:^ id (id model, BOOL *success, NSError **error) {
			if (model == nil) return nil;

			if (![model isKindOfClass:MTLModel.class] || ![model conformsToProtocol:@protocol(MTLJSONSerializing)]) {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel object conforming to <MTLJSONSerializing>, got: %@.", @""), model];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model object", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLJSONDictionaryTransformerFailed userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			return [MTLJSONAdapter JSONDictionaryFromModel:model];
		}];
}

+ (NSValueTransformer *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass {
	NSValueTransformer<MTLTransformerErrorHandling> *dictionaryTransformer = (NSValueTransformer<MTLTransformerErrorHandling> *)[self mtl_JSONDictionaryTransformerWithModelClass:modelClass];

	return [MTLValueTransformer
		reversibleTransformerWithForwardTransformation:^ id (NSArray *dictionaries, BOOL *success, NSError **error) {
			if (dictionaries == nil) return nil;

			if (![dictionaries isKindOfClass:NSArray.class]) {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), dictionaries];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLJSONArrayTransformerFailed userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			NSMutableArray *models = [NSMutableArray arrayWithCapacity:dictionaries.count];
			for (id JSONDictionary in dictionaries) {
				if (JSONDictionary == NSNull.null) {
					[models addObject:NSNull.null];
					continue;
				}

				if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
					if (error != NULL) {
						NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary or an NSNull, got: %@.", @""), JSONDictionary];

						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array", @""),
							NSLocalizedFailureReasonErrorKey: failureReason,
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLJSONArrayTransformerFailed userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}

				id model = [dictionaryTransformer transformedValue:JSONDictionary success:success error:error];

				if (*success == NO) return nil;

				if (model == nil) continue;

				[models addObject:model];
			}

			return models;
		}
		reverseTransformation:^ id (NSArray *models, BOOL *success, NSError **error) {
			if (models == nil) return nil;

			if (![models isKindOfClass:NSArray.class]) {
				if (error != NULL) {
					NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), models];

					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model array", @""),
						NSLocalizedFailureReasonErrorKey: failureReason,
					};

					*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLJSONArrayTransformerFailed userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:models.count];
			for (id model in models) {
				if (model == NSNull.null) {
					[dictionaries addObject:NSNull.null];
					continue;
				}

				if (![model isKindOfClass:MTLModel.class]) {
					if (error != NULL) {
						NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel or an NSNull, got: %@.", @""), model];

						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array", @""),
							NSLocalizedFailureReasonErrorKey: failureReason,
						};

						*error = [NSError errorWithDomain:MTLPredefinedTransformerErrorDomain code:MTLJSONArrayTransformerFailed userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}

				NSDictionary *dict = [dictionaryTransformer reverseTransformedValue:model success:success error:error];

				if (*success == NO) return nil;

				if (dict == nil) continue;

				[dictionaries addObject:dict];
			}

			return dictionaries;
		}];
}

+ (NSValueTransformer *)mtl_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary {
	NSParameterAssert(dictionary != nil);
	NSParameterAssert(dictionary.count == [[NSSet setWithArray:dictionary.allValues] count]);

	return [MTLValueTransformer reversibleTransformerWithForwardTransformation:^(id<NSCopying> key, BOOL *success, NSError **error) {
		return dictionary[key];
	} reverseTransformation:^(id object, BOOL *success, NSError **error) {
		__block id result = nil;
		[dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id anObject, BOOL *stop) {
			if ([object isEqual:anObject]) {
				result = key;
				*stop = YES;
			}
		}];
		return result;
	}];
}

@end
