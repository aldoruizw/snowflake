/***
Explores grantable privileges — It calls EXPLAIN_GRANTABLE_PRIVILEGES() for several object types (ACCOUNT, DATABASE, SCHEMA, TABLE, etc) to inspect what privileges can be granted on each. It also includes a flattened query that extracts individual privilege names from the SCHEMA result into rows.
*///

SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'ACCOUNT'));
SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'DATABASE'));
SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'SCHEMA'));
SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'TABLE'));
SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'SEQUENCE'));

WITH raw AS (
SELECT EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'SCHEMA') AS json_result
)
SELECT p.key AS privilege,
--ARRAY_TO_STRING(p.value, ', ') AS grant_types
FROM raw,
LATERAL FLATTEN(input => PARSE_JSON(json_result)) f,
LATERAL FLATTEN(input => f.value:"privileges") p
ORDER BY privilege;