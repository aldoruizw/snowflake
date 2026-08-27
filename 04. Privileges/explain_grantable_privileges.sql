/*====================================================================
  OBJET        : explain_grantable_privileges.sql
  DOMAINE      : ?
  AUTEUR       : ?
  DESCRIPTION  : ?
====================================================================*/

/*--------------------------------------------------------------------
  SECTION : It calls EXPLAIN_GRANTABLE_PRIVILEGES() for several object types (ACCOUNT, DATABASE, SCHEMA, TABLE, etc) to inspect what privileges can be granted on each.
--------------------------------------------------------------------*/

SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'ACCOUNT'));
SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'DATABASE'));
SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'SCHEMA'));
SELECT PARSE_JSON(EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'TABLE'));

/*--------------------------------------------------------------------
  SECTION : Flattened query that extracts individual privilege names from the SCHEMA result into rows.
--------------------------------------------------------------------*/

WITH raw AS (
SELECT EXPLAIN_GRANTABLE_PRIVILEGES(object_type => 'SCHEMA') AS json_result
)
SELECT p.key AS privilege,
--ARRAY_TO_STRING(p.value, ', ') AS grant_types
FROM raw,
LATERAL FLATTEN(input => PARSE_JSON(json_result)) f,
LATERAL FLATTEN(input => f.value:"privileges") p
ORDER BY privilege;