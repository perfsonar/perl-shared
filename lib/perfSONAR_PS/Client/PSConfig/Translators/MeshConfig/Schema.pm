package perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Schema;


use strict;
use warnings;
use JSON;

use base 'Exporter';

our @EXPORT_OK = qw( meshconfig_json_schema );

=item meshconfig_json_schema()

Returns the JSON schema

=cut

sub meshconfig_json_schema() {

    my $raw_json = <<'EOF';
    {
        "id": "http://www.perfsonar.net/meshconfig-schema#",
        "$schema": "http://json-schema.org/draft-04/schema#",
        "title": "MeshConfig Legacy Schema",
        "description": "Schema for legacy MeshConfig",
        "type": "object",
        "additionalProperties": false,
        "required": [ "description", "organizations", "tests" ],
        "properties": {
        
            "description": {
                "type": "string"
            },
            
            "administrators": {
                "type": "array",
                "items": { "$ref": "#/MeshConfig/AdministratorSpecification" }
            },
            
            "organizations": {
                "type": "array",
                "items": { "$ref": "#/MeshConfig/OrganizationSpecification" }
            },
            
            "measurement_archives": {
                "type": "array",
                "items": { "$ref": "#/MeshConfig/MeasurementArchiveSpecification" }
            },
            
            "tests": {
                "type": "array",
                "items": { "$ref": "#/MeshConfig/TestSpecification" }
            },
            
            "hosts": {
                "type": "array",
                "items": { "$ref": "#/MeshConfig/HostSpecification" }
            },
            
            "host_classes": {
                "type": "array",
                "items": { "$ref": "#/MeshConfig/HostClassSpecification" }
            }
        },
        
        "MeshConfig": {
            
            "AddressSpecification": {
                "anyOf": [
                    { "$ref": "#/MeshConfig/Host" },
                    { "$ref": "#/MeshConfig/AddressObjectSpecification" }
                ]
            },
            
            "AddressObjectSpecification": {
                "type": "object",
                "properties": {
                    "address": { "$ref": "#/MeshConfig/Host"},
                    "bind_address": { "$ref": "#/MeshConfig/Host"},
                    "lead_bind_address": { "$ref": "#/MeshConfig/Host"},
                    "pscheduler_address": { "$ref": "#/MeshConfig/Host"},
                    "tags": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "bind_maps": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/BindMapSpecification" }
                    },
                    "pscheduler_address_maps": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/ServiceAddressMapSpecification" }
                    },
                    "maps": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/AddressMapSpecification" }
                    }
                },
                "additionalProperties": false,
                "required": [ "address" ]
            },
            
            "AddressMapSpecification": {
                "type": "object",
                "properties": {
                    "remote_address": { "$ref": "#/MeshConfig/Host"},
                    "fields": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/AddressMapFieldSpecification" }
                    }
                },
                "additionalProperties": false,
                "required": [ "remote_address", "fields" ]
            },
            
            "AddressMapFieldSpecification": {
                "type": "object",
                "properties": {
                    "name": { "type": "string" },
                    "value": { "type": "string" }
                },
                "additionalProperties": false,
                "required": [ "name", "value" ]
            },
            
            "AdministratorSpecification": {
                "type": "object",
                "properties": {
                    "email": { "$ref": "#/MeshConfig/StringNullable" },
                    "name": { "$ref": "#/MeshConfig/StringNullable" }
                },
                "additionalProperties": false
            },
            
            "BindMapSpecification": {
                "type": "object",
                "properties": {
                    "remote_address": { "$ref": "#/MeshConfig/Host"},
                    "bind_address": { "$ref": "#/MeshConfig/Host"},
                    "lead_bind_address": { "$ref": "#/MeshConfig/Host"}
                },
                "additionalProperties": false,
                "required": [ "remote_address" ]
            },
            
            "Boolean": {
                "oneOf": [
                    { "type": "string", "enum": ["0", "1", "true", "false"] },
                    { "type": "integer", "enum": [0, 1] },
                    { "type": "boolean" }
                ]
            },
            
            "ExpectedTestResultsSpecification": {
                "anyOf": [
                    { "$ref": "#/MeshConfig/ExpectedThroughputResult" },
                    { "$ref": "#/MeshConfig/ExpectedOWAMPResult" }
                ]
            },
            
            "ExpectedThroughputResult": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "perfsonarbuoy/bwctl" ]
                    },
                    "source": { "$ref": "#/MeshConfig/Host"},
                    "destination": { "$ref": "#/MeshConfig/Host"},
                    "acceptable_throughput": { "$ref": "#/MeshConfig/Number"},
                    "critical_throughput": { "$ref": "#/MeshConfig/Number"}
                },
                "additionalProperties": true
            },
            
            "ExpectedOWAMPResult": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "perfsonarbuoy/owamp" ]
                    },
                    "source": { "$ref": "#/MeshConfig/Host"},
                    "destination": { "$ref": "#/MeshConfig/Host"},
                    "acceptable_loss_rate": { "$ref": "#/MeshConfig/Number"},
                    "critical_loss_rate": { "$ref": "#/MeshConfig/Number"}
                },
                "additionalProperties": true
            },
            
            "GroupSpecification": {
                "anyOf": [
                    { "$ref": "#/MeshConfig/GroupDisjointSpecification" },
                    { "$ref": "#/MeshConfig/GroupMeshSpecification" },
                    { "$ref": "#/MeshConfig/GroupOrderedMeshSpecification" }
                ]
            },
            
            "GroupDisjointSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "disjoint" ]
                    },
                    "address_map_field": { "type": "string" },
                    "exclude_unmapped": { "$ref": "#/MeshConfig/Boolean" },
                    "a_members": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "b_members": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "no_agents": {
                        "type": "array",
                        "items": { "type": "string" }
                    }
                },
                "additionalProperties": false,
                "required": [ "type", "a_members", "b_members" ]
            },
            
            "GroupMeshSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "mesh" ]
                    },
                    "address_map_field": { "type": "string" },
                    "exclude_unmapped": { "$ref": "#/MeshConfig/Boolean" },
                    "members": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "no_agents": {
                        "type": "array",
                        "items": { "type": "string" }
                    }
                },
                "additionalProperties": false,
                "required": [ "type", "members" ]
            },
            
            "GroupOrderedMeshSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "mesh" ]
                    },
                    "address_map_field": { "type": "string" },
                    "exclude_unmapped": { "$ref": "#/MeshConfig/Boolean" },
                    "members": {
                        "type": "array",
                        "items": { "type": "string" }
                    }
                },
                "additionalProperties": false,
                "required": [ "type", "members" ]
            },
            
            "Host": {
                "anyOf": [
                    { "$ref": "#/MeshConfig/HostName" },
                    { "$ref": "#/MeshConfig/IPAddress" }
                ]
            },
            
            "HostClassSpecification": {
                "type": "object",
                "properties": {
                    "name": { "type": "string" },
                    "data_sources": { "type": "array", "items": {"$ref": "#/MeshConfig/HostClassDataSources"} },
                    "match_filters": { "type": "array", "items": {"$ref": "#/MeshConfig/HostClassFilters"} },
                    "exclude_filters": { "type": "array", "items": {"$ref": "#/MeshConfig/HostClassFilters"} },
                    "host_properties": { "$ref": "#/MeshConfig/Host"}
                },
                "additionalProperties": false,
                "required": [ "name", "data_sources" ]
            },
            
            "HostClassDataSources": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "current_mesh", "requesting_agent" ]
                    }
                },
                "additionalProperties": false,
                "required": [ "type" ]
            },
            
            "HostClassFilters": {
                "anyOf": [
                    { "$ref": "#/MeshConfig/HostClassFiltersAddressType" },
                    { "$ref": "#/MeshConfig/HostClassFiltersAnd" },
                    { "$ref": "#/MeshConfig/HostClassFiltersHostClass" },
                    { "$ref": "#/MeshConfig/HostClassFiltersNetmask" },
                    { "$ref": "#/MeshConfig/HostClassFiltersNot" },
                    { "$ref": "#/MeshConfig/HostClassFiltersOr" },
                    { "$ref": "#/MeshConfig/HostClassFiltersOrganization" },
                    { "$ref": "#/MeshConfig/HostClassFiltersSite" },
                    { "$ref": "#/MeshConfig/HostClassFiltersTag" }
                ]
            },
            
            "HostClassFiltersAddressType": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "address_type" ]
                    },
                    "address_type": { "type": "string", "enum": ["ipv4", "ipv6"] }
                },
                "additionalProperties": false,
                "required": [ "type", "address_type" ]
            },
            
            "HostClassFiltersAnd": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "and" ]
                    },
                    "filters": { 
                        "type": "array",
                        "items": {"$ref": "#/MeshConfig/HostClassFilters"}
                    }
                },
                "additionalProperties": false,
                "required": [ "type", "filters" ]
            },
            
            "HostClassFiltersHostClass": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "host_class" ]
                    },
                    "class": { "type": "string" }
                },
                "additionalProperties": false,
                "required": [ "type", "class" ]
            },
            
            "HostClassFiltersNetmask": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "netmask" ]
                    },
                    "netmask": { "type": "string" }
                },
                "additionalProperties": false,
                "required": [ "type", "netmask" ]
            },
            
            "HostClassFiltersNot": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "not" ]
                    },
                    "filters": { "$ref": "#/MeshConfig/HostClassFilters" }
                },
                "additionalProperties": false,
                "required": [ "type", "filters" ]
            },
            
            "HostClassFiltersOr": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "or" ]
                    },
                    "filters": { 
                        "type": "array",
                        "items": {"$ref": "#/MeshConfig/HostClassFilters"}
                    }
                },
                "additionalProperties": false,
                "required": [ "type", "filters" ]
            },
            
            "HostClassFiltersOrganization": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "organization" ]
                    },
                    "description": { "type": "string" },
                    "exact": { "$ref": "#/MeshConfig/Boolean" }
                },
                "additionalProperties": false,
                "required": [ "type", "description" ]
            },
            
            "HostClassFiltersSite": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "site" ]
                    },
                    "description": { "type": "string" },
                    "exact": { "$ref": "#/MeshConfig/Boolean" }
                },
                "additionalProperties": false,
                "required": [ "type", "description" ]
            },
            
            "HostClassFiltersTag": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "tag" ]
                    },
                    "tag": { "type": "string" },
                    "exact": { "$ref": "#/MeshConfig/Boolean" }
                },
                "additionalProperties": false,
                "required": [ "type", "tag" ]
            },
                    
            "HostName": {
                "type": "string",
                "format": "hostname"
            },
            
            "HostSpecification": {
                "type": "object",
                "properties": {
                    "description": { "$ref": "#/MeshConfig/StringNullable" },
                    "toolkit_url": { "type": "string" },
                    "no_agent": { "$ref": "#/MeshConfig/Boolean" },
                    "location": { "$ref": "#/MeshConfig/LocationSpecification" },
                    "bind_address": { "$ref": "#/MeshConfig/Host"},
                    "lead_bind_address": { "$ref": "#/MeshConfig/Host"},
                    "pscheduler_address": { "$ref": "#/MeshConfig/Host"},
                    "administrators": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/AdministratorSpecification" }
                    },
                    "tags": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "measurement_archives": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/MeasurementArchiveSpecification" }
                    },
                    "addresses": { 
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/AddressSpecification" }
                    }
                },
                "additionalProperties": false,
                "required": [ "addresses" ]
            },
            
            "Integer": {
                "oneOf": [
                    { "type": "string", "pattern": "^[0-9]+$" },
                    { "type": "integer" }
                ]
            },
            
            "IPAddress": {
                "oneOf": [
                    { "type": "string", "format": "ipv4" },
                    { "type": "string", "format": "ipv6" }
                ]
            },
            
            "LocationSpecification": {
                "type": "object",
                "properties": {
                    "street_address": { "$ref": "#/MeshConfig/StringNullable" },
                    "country": { "$ref": "#/MeshConfig/StringNullable" },
                    "city": { "$ref": "#/MeshConfig/StringNullable" },
                    "state": { "$ref": "#/MeshConfig/StringNullable" },
                    "latitude": { "$ref": "#/MeshConfig/StringNullable" },
                    "longitude": { "$ref": "#/MeshConfig/StringNullable" },
                    "postal_code": { "$ref": "#/MeshConfig/StringNullable" }
                },
                "additionalProperties": false
            },
            
            "MeasurementArchiveSpecification": {
                "type": "object",
                "properties": {
                    "type": { "type": "string" },
                    "read_url": { "type": "string" },
                    "write_url": { "type": "string" }
                },
                "additionalProperties": false,
                "required": [ "type", "read_url", "write_url" ]
            },
            
            "Number": {
                "oneOf": [
                    { "type": "string" },
                    { "type": "number" }
                ]
            },
            
            "OrganizationSpecification": {
                "type": "object",
                "properties": {
                    "description": { "$ref": "#/MeshConfig/StringNullable" },
                    "measurement_archives": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/MeasurementArchiveSpecification" }
                    },
                    "administrators": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/AdministratorSpecification" }
                    },
                    "tags": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "location": { "$ref": "#/MeshConfig/LocationSpecification" },
                    "hosts": { 
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/HostSpecification" }
                    },
                    "sites": { 
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/SiteSpecification" }
                    }
                },
                "additionalProperties": false
            },
            
            "ReferenceSpecification": {
                "type": "object",
                "properties": {
                    "name": { "type": "string" },
                    "value": { "type": "string" }
                },
                "additionalProperties": false,
                "required": [ "name", "value" ]
            },
            
            "ServiceAddressMapSpecification": {
                "type": "object",
                "properties": {
                    "remote_address": { "$ref": "#/MeshConfig/Host"},
                    "service_address": { "$ref": "#/MeshConfig/Host"}
                },
                "additionalProperties": false,
                "required": [ "remote_address", "service_address" ]
            },
            
            "SiteSpecification": {
                "type": "object",
                "properties": {
                    "description": { "$ref": "#/MeshConfig/StringNullable" },
                    "measurement_archives": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/MeasurementArchiveSpecification" }
                    },
                    "administrators": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/AdministratorSpecification" }
                    },
                    "tags": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "location": { "$ref": "#/MeshConfig/LocationSpecification" },
                    "hosts": { 
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/HostSpecification" }
                    }
                },
                "additionalProperties": false
            },
            
            "StringNullable": {
                "oneOf": [
                    { "type": "string" },
                    { "type": "null" }
                ]
            },
            
            "TestParametersSpecification": {
                "anyOf": [
                    { "$ref": "#/MeshConfig/TestParametersPSBBwctlSpecification" },
                    { "$ref": "#/MeshConfig/TestParametersPSBOwampSpecification" },
                    { "$ref": "#/MeshConfig/TestParametersPingerSpecification" },
                    { "$ref": "#/MeshConfig/TestParametersSimpleStreamSpecification" },
                    { "$ref": "#/MeshConfig/TestParametersTracerouteSpecification" }
                ]
            },
            
            "TestParametersPSBBwctlSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "perfsonarbuoy/bwctl" ]
                    },
                    "tool": { "type": "string" },
                    "duration": { "$ref": "#/MeshConfig/Integer" },
                    "interval": { "$ref": "#/MeshConfig/Integer" },
                    "streams": { "$ref": "#/MeshConfig/Integer" },
                    "tos_bits": { "$ref": "#/MeshConfig/Integer" },
                    "buffer_length": { "$ref": "#/MeshConfig/Integer" },
                    "report_interval": { "$ref": "#/MeshConfig/Integer" },
                    "protocol": { "type": "string" },
                    "udp_bandwidth": { "$ref": "#/MeshConfig/Integer" },
                    "window_size": { "$ref": "#/MeshConfig/Integer" },
                    "omit_interval": { "$ref": "#/MeshConfig/Integer" },
                    "force_bidirectional": { "$ref": "#/MeshConfig/Boolean" },
                    "ipv4_only": { "$ref": "#/MeshConfig/Boolean" },
                    "ipv6_only": { "$ref": "#/MeshConfig/Boolean" },
                    "latest_time": { "$ref": "#/MeshConfig/Integer" },
                    "random_start_percentage": { "$ref": "#/MeshConfig/Integer" },
                    "slip": { "$ref": "#/MeshConfig/Integer" },
                    "slip_randomize": { "$ref": "#/MeshConfig/Boolean" },
                    "time_slots": {
                        "type": "array",
                        "items": { "type": "string" }
                    },
                    "tcp_bandwidth": { "$ref": "#/MeshConfig/Integer" },
                    "mss": { "$ref": "#/MeshConfig/Integer" },
                    "dscp": { "$ref": "#/MeshConfig/Integer" },
                    "no_delay": { "$ref": "#/MeshConfig/Boolean" },
                    "congestion": { "type": "string" },
                    "flow_label": { "$ref": "#/MeshConfig/Integer" },
                    "client_cpu_affinity": { "$ref": "#/MeshConfig/Integer" },
                    "server_cpu_affinity": { "$ref": "#/MeshConfig/Integer" }
                },
                "additionalProperties": false,
                "required": [ "type" ]
            },
            
            "TestParametersPSBOwampSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "perfsonarbuoy/owamp" ]
                    },
                    "bucket_width": { "$ref": "#/MeshConfig/Number" },
                    "packet_interval": { "$ref": "#/MeshConfig/Number" },
                    "loss_threshold": { "$ref": "#/MeshConfig/Integer" },
                    "packet_padding": { "$ref": "#/MeshConfig/Integer" },
                    "session_count": { "$ref": "#/MeshConfig/Integer" },
                    "sample_count": { "$ref": "#/MeshConfig/Integer" },
                    "force_bidirectional": { "$ref": "#/MeshConfig/Boolean" },
                    "ipv4_only": { "$ref": "#/MeshConfig/Boolean" },
                    "ipv6_only": { "$ref": "#/MeshConfig/Boolean" },
                    "output_raw": { "$ref": "#/MeshConfig/Boolean" },
                    "tos_bits": { "$ref": "#/MeshConfig/Integer" }
                },
                "additionalProperties": false,
                "required": [ "type" ]
            },
            
            "TestParametersPingerSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "pinger" ]
                    },
                    "packet_size": { "$ref": "#/MeshConfig/Integer" },
                    "packet_ttl": { "$ref": "#/MeshConfig/Integer" },
                    "packet_count": { "$ref": "#/MeshConfig/Integer" },
                    "packet_interval": { "$ref": "#/MeshConfig/Number" },
                    "test_interval": { "$ref": "#/MeshConfig/Integer" },
                    "ipv4_only": { "$ref": "#/MeshConfig/Boolean" },
                    "ipv6_only": { "$ref": "#/MeshConfig/Boolean" },
                    "force_bidirectional": { "$ref": "#/MeshConfig/Boolean" },
                    "random_start_percentage": { "$ref": "#/MeshConfig/Integer" },
                    "slip": { "$ref": "#/MeshConfig/Integer" },
                    "slip_randomize": { "$ref": "#/MeshConfig/Boolean" },
                    "flowlabel": { "$ref": "#/MeshConfig/Integer" },
                    "hostnames": { "$ref": "#/MeshConfig/Boolean" },
                    "suppress_loopback": { "$ref": "#/MeshConfig/Boolean" },
                    "deadline": { "$ref": "#/MeshConfig/Integer" },
                    "timeout": { "$ref": "#/MeshConfig/Integer" },
                    "tos_bits": { "$ref": "#/MeshConfig/Integer" }
                },
                "additionalProperties": false,
                "required": [ "type" ]
            },
            
            "TestParametersSimpleStreamSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "simplestream" ]
                    },
                    "dawdle": { "$ref": "#/MeshConfig/Integer" },
                    "fail": { "$ref": "#/MeshConfig/Number" },
                    "test_material": { "type": "string" },
                    "timeout": { "$ref": "#/MeshConfig/Integer" },
                    "tool": { "type": "string" },
                    "force_bidirectional": { "$ref": "#/MeshConfig/Boolean" },
                    "random_start_percentage": { "$ref": "#/MeshConfig/Integer" },
                    "slip": { "$ref": "#/MeshConfig/Integer" },
                    "slip_randomize": { "$ref": "#/MeshConfig/Boolean" },
                    "interval": { "$ref": "#/MeshConfig/Integer" },
                    "ipv4_only": { "$ref": "#/MeshConfig/Boolean" },
                    "ipv6_only": { "$ref": "#/MeshConfig/Boolean" }
                },
                "additionalProperties": false,
                "required": [ "type" ]
            },
            
            "TestParametersTracerouteSpecification": {
                "type": "object",
                "properties": {
                    "type": { 
                        "type": "string",
                        "enum": [ "traceroute" ]
                    },
                    "test_interval": { "$ref": "#/MeshConfig/Integer" },
                    "tool": { "type": "string" },
                    "packet_size": { "$ref": "#/MeshConfig/Integer" },
                    "timeout": { "$ref": "#/MeshConfig/Integer" },
                    "waittime": { "$ref": "#/MeshConfig/Integer" },
                    "first_ttl": { "$ref": "#/MeshConfig/Integer" },
                    "max_ttl": { "$ref": "#/MeshConfig/Integer" },
                    "pause": { "$ref": "#/MeshConfig/Integer" },
                    "protocol": { "type": "string" },
                    "ipv4_only": { "$ref": "#/MeshConfig/Boolean" },
                    "ipv6_only": { "$ref": "#/MeshConfig/Boolean" },
                    "force_bidirectional": { "$ref": "#/MeshConfig/Boolean" },
                    "random_start_percentage": { "$ref": "#/MeshConfig/Integer" },
                    "slip": { "$ref": "#/MeshConfig/Integer" },
                    "slip_randomize": { "$ref": "#/MeshConfig/Boolean" },
                    "algorithm": { "type": "string" },
                    "as": { "$ref": "#/MeshConfig/Boolean" },
                    "fragment": { "$ref": "#/MeshConfig/Boolean" },
                    "hostnames": { "$ref": "#/MeshConfig/Boolean" },
                    "probe_type": { "type": "string" },
                    "queries": { "$ref": "#/MeshConfig/Integer" },
                    "sendwait": { "$ref": "#/MeshConfig/Integer" },
                    "wait": { "$ref": "#/MeshConfig/Integer" },
                    "tos_bits": { "$ref": "#/MeshConfig/Integer" }
                },
                "additionalProperties": false,
                "required": [ "type" ]
            },
            
            "TestSpecification": {
                "type": "object",
                "properties": {
                    "description": { "$ref": "#/MeshConfig/StringNullable" },
                    "members": { "$ref": "#/MeshConfig/GroupSpecification" },
                    "parameters": { "$ref": "#/MeshConfig/TestParametersSpecification" },
                    "disabled": { "$ref": "#/MeshConfig/Boolean" },
                    "expected_results": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/ExpectedTestResultsSpecification" }
                    },
                    "references": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/ReferenceSpecification" }
                    },
                    "measurement_archives": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/MeasurementArchiveSpecification" }
                    },
                    "administrators": {
                        "type": "array",
                        "items": { "$ref": "#/MeshConfig/AdministratorSpecification" }
                    }
                },
                "additionalProperties": false,
                "required": [ "members", "parameters" ]
            }
            
        }
    }
EOF

    return from_json($raw_json);
}
