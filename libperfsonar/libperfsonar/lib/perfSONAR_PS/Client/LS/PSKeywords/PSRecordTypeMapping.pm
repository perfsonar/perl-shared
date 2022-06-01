package perfSONAR_PS::Client::LS::PSKeywords::PSRecordTypeMapping;

use base 'SimpleLookupService::Keywords::RecordTypeMapping';

use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;
use SimpleLookupService::Keywords::Values;

# Record keys
use constant {
	
	RECORDMAP => {
					(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_SERVICE) => "perfSONAR_PS::Client::LS::PSRecords::PSService",
   					(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_HOST) => "perfSONAR_PS::Client::LS::PSRecords::PSHost",
                    (SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_INTERFACE) => "perfSONAR_PS::Client::LS::PSRecords::PSInterface",
                    (SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_PERSON) => "perfSONAR_PS::Client::LS::PSRecords::PSPerson",
                    (perfSONAR_PS::Client::LS::PSKeywords::PSValues::LS_VALUE_TYPE_PSTEST) => "perfSONAR_PS::Client::LS::PSRecords::PSTest",
				}
		
};
1;
