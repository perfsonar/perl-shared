package perfSONAR_PS::Client::PSConfig::Schema;


use strict;
use warnings;
use JSON;

use base 'Exporter';

our @EXPORT_OK = qw( psconfig_json_schema );

sub psconfig_json_schema() {

    my $raw_json = <<'EOF';
{
    "id": "http://www.perfsonar.net/psconfig-schema#",
    "$schema": "http://json-schema.org/draft-04/schema#",
    "title": "pSConfig Schema",
    "description": "Schema for pSConfig test configuration files",
    "type": "object",
    "required": [ "addresses", "groups", "tests", "tasks" ],
    "properties": {
        
        "addresses": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/AddressSpecification" }
            }
        },
        
        "address-classes": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/AddressClassSpecification" }
            }
        },
        
        "archives": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/ArchiveSpecification" }
            }
        },
        
        "contexts": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/ContextSpecification" }
            }
        },
        
        "groups": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/GroupSpecification" }
            }
        },
        
        "hosts": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/HostSpecification" }
            }
        },
        
        "includes": {
            "type": "array",
            "items": { "type": "string", "format": "uri" }
        },
        
        "schedules": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/ScheduleSpecification" }
            }
        },
        
        "subtasks": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/SubtaskSpecification" }
            }
        },
        
        "tasks": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/TaskSpecification" }
            }
        },
        
        "tests": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/TestSpecification" }
            }
        },
        
        "_meta": { "$ref": "#/pSConfig/AnyJSON" }
    },
    
    "pSConfig": {
        
        "AddressClassSpecification": {
            "type": "object",
            "properties": {
                "data-source": { "$ref": "#/pSConfig/AddressClassDataSourceSpecification" },
                "match-filter": { "$ref": "#/pSConfig/AddressClassFilterSpecification" },
                "exclude-filter": { "$ref": "#/pSConfig/AddressClassFilterSpecification" },
                "archives": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "data-source" ]
        },
        
        "AddressClassDataSourceSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "current-config", "requesting-agent" ]
                }
            },
            "additionalProperties": false,
            "required": [ "type" ]
        },
        
        "AddressClassFilterSpecification": {
            "anyOf": [
                { "$ref": "#/pSConfig/AddressClassFilterAddressClassSpecification" },
                { "$ref": "#/pSConfig/AddressClassFilterHostSpecification" },
                { "$ref": "#/pSConfig/AddressClassFilterIPVersionSpecification" },
                { "$ref": "#/pSConfig/AddressClassFilterNetmaskSpecification" },
                { "$ref": "#/pSConfig/AddressClassFilterOperandSpecification" },
                { "$ref": "#/pSConfig/AddressClassFilterNotSpecification" },
                { "$ref": "#/pSConfig/AddressClassFilterTagSpecification" }
            ]
        },
        
        "AddressClassFilterAddressClassSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "address-class" ]
                },
                "class": { "$ref": "#/pSConfig/NameType" }
            },
            "additionalProperties": false,
            "required": [ "type", "class" ]
        },
        
        "AddressClassFilterHostSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "host" ]
                },
                "site": { "type": "string" },
                "no-agent": { "type": "boolean" },
                "tag": { "type": "string" }
            },
            "additionalProperties": false,
            "required": [ "type" ]
        },
        
        "AddressClassFilterIPVersionSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "ip-version" ]
                },
                "ip-version": { 
                    "type": "integer",
                    "enum": [ 4, 6 ]
                }
            },
            "additionalProperties": false,
            "required": [ "type", "ip-version" ]
        },
        
        "AddressClassFilterNetmaskSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "netmask" ]
                },
                "netmask": { "$ref": "#/pSConfig/IPCIDR"}
            },
            "additionalProperties": false,
            "required": [ "type", "netmask" ]
        },
        
        "AddressClassFilterOperandSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "and", "or" ]
                },
                "filters": { 
                    "type": "array",
                    "items": { "$ref": "#/pSConfig/AddressClassFilterSpecification" }
                }
            },
            "additionalProperties": false,
            "required": [ "type", "filters"]
        },
        
        "AddressClassFilterNotSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "not" ]
                },
                "filter": { "$ref": "#/pSConfig/AddressClassFilterSpecification" }
            },
            "additionalProperties": false,
            "required": [ "type", "filter"]
        },
        
        "AddressClassFilterTagSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "tag" ]
                },
                "tag": { "type": "string" }
            },
            "additionalProperties": false,
            "required": [ "type", "tag" ]
        },
        
        "AddressSelector": {
            "oneOf": [
                { "$ref": "#/pSConfig/AddressSelectorClass" },
                { "$ref": "#/pSConfig/AddressSelectorNameLabel" }
            ]
        },
        
        "AddressSelectorClass": {
            "type": "object",
            "properties": {
                "class": { "$ref": "#/pSConfig/NameType" },
                "disabled": { "type": "boolean" }
            },
            "additionalProperties": false,
            "required": [ "class" ]
        },
        
        "AddressSelectorNameLabel": {
            "type": "object",
            "properties": {
                "name": { "$ref": "#/pSConfig/NameType" },
                "label": { "$ref": "#/pSConfig/NameType" },
                "disabled": { "type": "boolean" }
            },
            "additionalProperties": false,
            "required": [ "name" ]
        },
        
        "AddressSpecification": {
            "type": "object",
            "properties": {
                "address": { "$ref": "#/pSConfig/Host" },
                "host": { "$ref": "#/pSConfig/NameType" },
                "labels": { "$ref": "#/pSConfig/AddressSpecificationLabelMap" },
                "remote-addresses": { "$ref": "#/pSConfig/AddressSpecificationRemoteMap" },
                "agent-bind-address": { "$ref": "#/pSConfig/Host" },
                "lead-bind-address": { "$ref": "#/pSConfig/Host" },
                "pscheduler-address": { "$ref": "#/pSConfig/URLHostPort" },
                "contexts": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "tags": { "type": "array", "items": { "type": "string" } },
                "disabled": { "type": "boolean" },
                "no-agent": { "type": "boolean" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "address" ]
        },
        
        "AddressSpecificationLabelMap": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/AddressSpecificationLabelMapItem" }
            },
            "additionalProperties": false
        },
        
        "AddressSpecificationLabelMapItem": {
            "type": "object",
            "properties": {
                "address": { "$ref": "#/pSConfig/Host" },
                "agent-bind-address": { "$ref": "#/pSConfig/Host" },
                "lead-bind-address": { "$ref": "#/pSConfig/Host" },
                "pscheduler-address": { "$ref": "#/pSConfig/URLHostPort" },
                "contexts": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "disabled": { "type": "boolean" },
                "no-agent": { "type": "boolean" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "address" ]
        },
        
        "AddressSpecificationRemoteMap": {
            "type": "object",
            "patternProperties": { 
                "^[a-zA-Z0-9:._\\-]+$": { "$ref": "#/pSConfig/AddressSpecificationRemoteMapItem" }
            },
            "additionalProperties": false
        },
        
        "AddressSpecificationRemoteMapItem": {
            "type": "object",
            "properties": {
                "address": { "$ref": "#/pSConfig/Host" },
                "labels": { "$ref": "#/pSConfig/AddressSpecificationLabelMap" },
                "agent-bind-address": { "$ref": "#/pSConfig/Host" },
                "lead-bind-address": { "$ref": "#/pSConfig/Host" },
                "pscheduler-address": { "$ref": "#/pSConfig/URLHostPort" },
                "contexts": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "disabled": { "type": "boolean" },
                 "no-agent": { "type": "boolean" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false
        },
        
        "AnyJSON": {
            "anyOf": [
                { "type": "array" },
                { "type": "boolean" },
                { "type": "integer" },
                { "type": "null" },
                { "type": "number" },
                { "type": "object" },
                { "type": "string" }
            ]
        },
        
        "ArchiveSpecification": {
            "type": "object",
            "properties": {
                "archiver": { "type": "string" },
                "data": { "$ref": "#/pSConfig/AnyJSON" },
                "transform": { "$ref": "#/pSConfig/JQTransformSpecification" },
                "ttl": { "$ref": "#/pSConfig/Duration" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "archiver", "data"]
        },
        
        "Cardinal": {
            "type": "integer",
            "minimum": 1
        },
        
        "ContextSpecification": {
            "type": "object",
            "properties": {
                "context": { "type": "string" },
                "data": { "$ref": "#/pSConfig/AnyJSON" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "context", "data" ]
        },
    
        "Duration": {
            "type": "string",
            "pattern": "^P(?:\\d+(?:\\.\\d+)?W)?(?:\\d+(?:\\.\\d+)?D)?(?:T(?:\\d+(?:\\.\\d+)?H)?(?:\\d+(?:\\.\\d+)?M)?(?:\\d+(?:\\.\\d+)?S)?)?$",
            "x-invalid-message": "'%s' is not a valid ISO 8601 duration."
        },
        
        "ExcludesSelfScope": {
            "type": "string",
            "enum": ["host", "address", "disabled"]
        },
        
        "ExcludesAddressPair": {
            "type": "object",
            "properties": {
                "local-address": { "$ref": "#/pSConfig/AddressSelector" },
                "target-addresses": { "type": "array", "items": { "$ref": "#/pSConfig/AddressSelector" } }
            },
            "additionalProperties": false,
            "required": [ "local-address", "target-addresses" ]
        },
        
        "ExcludesAddressPairList": {
            "type": "array",
            "items": { "$ref": "#/pSConfig/ExcludesAddressPair" }
        },
        
        "GroupDisjointSpecification": {
            "type": "object",
            "properties": {
                "default-address-label": { "type": "string" },
                "flip": { "type": "boolean" },
                "unidirectional": { "type": "boolean" },
                "type": { 
                    "type": "string",
                    "enum": ["disjoint"]
                },
                "a-addresses": { "type": "array", "items": { "$ref": "#/pSConfig/AddressSelector" } },
                "b-addresses": { "type": "array", "items": { "$ref": "#/pSConfig/AddressSelector" } },
                "excludes-self": { "$ref": "#/pSConfig/ExcludesSelfScope" },
                "excludes": { "$ref": "#/pSConfig/ExcludesAddressPairList" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "type", "a-addresses", "b-addresses" ]
        },
        
        "GroupListSpecification": {
            "type": "object",
            "properties": {
                "default-address-label": { "type": "string" },
                "type": { 
                    "type": "string",
                    "enum": ["list"]
                },
                "addresses": { "type": "array", "items": { "$ref": "#/pSConfig/AddressSelector" } },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "type", "addresses" ]
        },
        
        "GroupMeshSpecification": {
            "type": "object",
            "properties": {
                "default-address-label": { "type": "string" },
                "flip": { "type": "boolean" },
                "type": { 
                    "type": "string",
                    "enum": ["mesh"]
                },
                "addresses": { "type": "array", "items": { "$ref": "#/pSConfig/AddressSelector" } },
                "excludes-self": { "$ref": "#/pSConfig/ExcludesSelfScope" },
                "excludes": { "$ref": "#/pSConfig/ExcludesAddressPairList" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "type", "addresses" ]
        },
        
        "GroupSpecification": {
            "anyOf": [
                { "$ref": "#/pSConfig/GroupDisjointSpecification" },
                { "$ref": "#/pSConfig/GroupListSpecification" },
                { "$ref": "#/pSConfig/GroupMeshSpecification" }
            ]
        },
        
        "Host": {
            "anyOf": [
                { "$ref": "#/pSConfig/HostName" },
                { "$ref": "#/pSConfig/IPAddress" }
            ]
        },
        
        "HostName": {
            "type": "string",
            "format": "hostname"
        },

        "HostNamePort": {
            "type": "string",
            "pattern": "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])(:[0-9]+)?$"
        },

        "HostSpecification": {
            "type": "object",
            "properties": {
                "site": { "type": "string" },
                "archives": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "tags": { "type": "array", "items": { "type": "string" } },
                "no-agent": { "type": "boolean" },
                "disabled": { "type": "boolean" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false
        },

        "IPAddress": {
            "oneOf": [
                { "type": "string", "format": "ipv4" },
                { "type": "string", "format": "ipv6" }
            ]
        },

        "IPv4": { "type": "string", "format": "ipv4" },

        "IPv6": { "type": "string", "format": "ipv6" },

        "IPv6RFC2732": {
            "type": "string",
            "pattern": "^\\[(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\\](:[0-9]+)?$"
        },

        "IPv4CIDR": {
            "type": "string",
            "pattern":"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/([0-9]|[1-2][0-9]|3[0-2]))$"
            },

        "IPv6CIDR": {
            "type": "string",
            "pattern": "^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))$"
        },

        "IPCIDR": {
            "oneOf": [
                { "$ref": "#/pSConfig/IPv4CIDR" },
                { "$ref": "#/pSConfig/IPv6CIDR" }
            ]
        },

        "IPCIDRList": {
            "type": "array",
            "items": { "$ref": "#/pSConfig/IPCIDR" }
        },
        
        "JQTransformSpecification": {
            "type": "object",
            "properties": {
                "script":    { "type": "string" },
                "output-raw": { "type": "boolean" }
            },
            "additionalProperties": false,
            "required": [ "script" ]
        },
        
        "NameType": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9:._\\-]+$"
        },
        
        "ScheduleOffsetSpecification": {
            "type": "object",
            "properties": {
                "type": { 
                    "type": "string",
                    "enum": [ "start", "end"] 
                },
                "relation": { 
                    "type": "string",
                    "enum": [ "before", "after"] 
                },
                "offset": { "$ref": "#/pSConfig/Duration" }
            },
            "additionalProperties": false
        },
        
        "ScheduleSpecification": {
            "type": "object",
            "properties": {
                "start":    { "$ref": "#/pSConfig/TimestampAbsoluteRelative" },
                "slip":     { "$ref": "#/pSConfig/Duration" },
                "sliprand": { "type": "boolean" },
                "repeat":   { "$ref": "#/pSConfig/Duration" },
                "until":    { "$ref": "#/pSConfig/TimestampAbsoluteRelative" },
                "max-runs": { "$ref": "#/pSConfig/Cardinal" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false
        },
        
        "SubtaskSpecification": {
            "type": "object",
            "properties": {
                "test": { "$ref": "#/pSConfig/NameType" },
                "schedule-offset": { "$ref": "#/pSConfig/ScheduleOffsetSpecification" },
                "disabled": { "type": "boolean" },
                "archives": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "tools": { "type": "array", "items": { "type": "string" } },
                "reference": { "$ref": "#/pSConfig/AnyJSON" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "test" ]
        },
        
        "TaskSpecification": {
            "type": "object",
            "properties": {
                "group": { "$ref": "#/pSConfig/NameType" },
                "test": { "$ref": "#/pSConfig/NameType" },
                "schedule": { "$ref": "#/pSConfig/NameType" },
                "disabled": { "type": "boolean" },
                "archives": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "tools": { "type": "array", "items": { "type": "string" } },
                "subtasks": { "type": "array", "items": { "$ref": "#/pSConfig/NameType" } },
                "reference": { "$ref": "#/pSConfig/AnyJSON" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "group", "test" ]
        },
        
        "TestSpecification": {
            "type": "object",
            "properties": {
                "type": { "type": "string" },
                "spec": { "$ref": "#/pSConfig/AnyJSON" },
                "_meta": { "$ref": "#/pSConfig/AnyJSON" }
            },
            "additionalProperties": false,
            "required": [ "type", "spec" ]
        },
        
        "Timestamp": {
            "type": "string",
            "pattern": "^([\\+-]?\\d{4}(?!\\d{2}\\b))((-?)((0[1-9]|1[0-2])(\\3([12]\\d|0[1-9]|3[01]))?|W([0-4]\\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\\d|[12]\\d{2}|3([0-5]\\d|6[1-6])))([T\\s]((([01]\\d|2[0-3])((:?)[0-5]\\d)?|24\\:?00)([\\.,]\\d+(?!:))?)?(\\17[0-5]\\d([\\.,]\\d+)?)?([zZ]|([\\+-])([01]\\d|2[0-3]):?([0-5]\\d)?)?)?)?$"
        },

        "TimestampAbsoluteRelative": {
            "oneOf" : [
                { "$ref": "#/pSConfig/Timestamp" },
                { "$ref": "#/pSConfig/Duration" },
                {
                    "type": "string",
                    "pattern": "^@(R\\d*/)?P(?:\\d+(?:\\.\\d+)?Y)?(?:\\d+(?:\\.\\d+)?M)?(?:\\d+(?:\\.\\d+)?W)?(?:\\d+(?:\\.\\d+)?D)?(?:T(?:\\d+(?:\\.\\d+)?H)?(?:\\d+(?:\\.\\d+)?M)?(?:\\d+(?:\\.\\d+)?S)?)?$"
                }
            ]
        },
        
        "URLHostPort": {
            "anyOf": [
                { "$ref": "#/pSConfig/HostNamePort" },
                { "$ref": "#/pSConfig/IPv6RFC2732" }
            ]
        },
    
        "Version": {
            "type": "string",
            "pattern": "^[0-9]+(\\.[0-9]+)*[A-Za-z0-9-+]*$"
        }
    }
}
EOF

    return from_json($raw_json);
}