------------------------------------------------------------------------------
-- Grant lineage visibility across all databases WITHOUT granting data access
--
-- Verified behavior of SNOWFLAKE.CORE.GET_LINEAGE:
--   * Starting object : role needs USAGE on db + schema AND at least one
--                       privilege on the object itself, otherwise the call
--                       fails with "does not exist or not authorized".
--   * Neighbor objects: appear in the graph but MASKED as '***' with
--                       SOURCE_STATUS/TARGET_STATUS = 'MASKED' unless the role
--                       holds a privilege on them too.
--   * REFERENCES is sufficient to unmask, and does NOT permit SELECT.
------------------------------------------------------------------------------

USE ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------------------
-- STEP 1. Role + account-level privilege
-- ---------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS LINEAGE_VIEWER;

-- Required to use GET_LINEAGE / the Snowsight Lineage tab at all.
-- Often already held via PUBLIC; granting explicitly is harmless.
GRANT VIEW LINEAGE ON ACCOUNT TO ROLE LINEAGE_VIEWER;

GRANT ROLE LINEAGE_VIEWER TO ROLE <target_role_or_user>;


-- ---------------------------------------------------------------------------
-- STEP 2. DRY RUN - review the statements before applying anything
-- ---------------------------------------------------------------------------
SHOW DATABASES;

WITH DBS AS (
    SELECT "name" AS DB
    FROM   TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    WHERE  "kind" = 'STANDARD'          -- excludes APPLICATION / IMPORTED / PERSONAL
      AND  NVL("origin",'') = ''        -- excludes shared inbound databases
      AND  "name" NOT IN ('SNOWFLAKE_LEARNING_DB')
)
SELECT S.STMT
FROM DBS,
LATERAL (
    SELECT 'GRANT USAGE ON DATABASE "'                     || DB || '" TO ROLE LINEAGE_VIEWER;' AS STMT
    UNION ALL SELECT 'GRANT USAGE ON ALL SCHEMAS IN DATABASE "'    || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE "' || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON ALL TABLES IN DATABASE "'               || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON FUTURE TABLES IN DATABASE "'            || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON ALL VIEWS IN DATABASE "'                || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON FUTURE VIEWS IN DATABASE "'             || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON ALL MATERIALIZED VIEWS IN DATABASE "'   || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON FUTURE MATERIALIZED VIEWS IN DATABASE "'|| DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON ALL EXTERNAL TABLES IN DATABASE "'      || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT REFERENCES ON FUTURE EXTERNAL TABLES IN DATABASE "'   || DB || '" TO ROLE LINEAGE_VIEWER;'
    -- Dynamic tables do not accept REFERENCES ("Invalid object type
    -- 'DYNAMIC_TABLE' for privilege 'REFERENCES'"). MONITOR is accepted and
    -- grants no data read; SELECT would work but exposes data.
    UNION ALL SELECT 'GRANT MONITOR ON ALL DYNAMIC TABLES IN DATABASE "'          || DB || '" TO ROLE LINEAGE_VIEWER;'
    UNION ALL SELECT 'GRANT MONITOR ON FUTURE DYNAMIC TABLES IN DATABASE "'       || DB || '" TO ROLE LINEAGE_VIEWER;'
) S;


-- ---------------------------------------------------------------------------
-- STEP 3. APPLY - loops every standard database and applies the grants.
--         Per-statement errors are swallowed so one bad database does not
--         abort the whole run; the summary reports counts.
-- ---------------------------------------------------------------------------
DECLARE
    ok      INTEGER DEFAULT 0;
    failed  INTEGER DEFAULT 0;
BEGIN
    SHOW DATABASES;

    LET rs RESULTSET := (
        SELECT "name" AS DB
        FROM   TABLE(RESULT_SCAN(LAST_QUERY_ID()))
        WHERE  "kind" = 'STANDARD'
          AND  NVL("origin",'') = ''
          AND  "name" NOT IN ('SNOWFLAKE_LEARNING_DB')
    );

    LET cur CURSOR FOR rs;

    FOR r IN cur DO
        LET db STRING := REPLACE(r.DB, '"', '""');

        LET stmts ARRAY := ARRAY_CONSTRUCT(
            'GRANT USAGE ON DATABASE "'                        || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT USAGE ON ALL SCHEMAS IN DATABASE "'         || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE "'      || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON ALL TABLES IN DATABASE "'                || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON FUTURE TABLES IN DATABASE "'             || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON ALL VIEWS IN DATABASE "'                 || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON FUTURE VIEWS IN DATABASE "'              || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON ALL MATERIALIZED VIEWS IN DATABASE "'    || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON FUTURE MATERIALIZED VIEWS IN DATABASE "' || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON ALL EXTERNAL TABLES IN DATABASE "'       || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT REFERENCES ON FUTURE EXTERNAL TABLES IN DATABASE "'    || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT MONITOR ON ALL DYNAMIC TABLES IN DATABASE "'           || db || '" TO ROLE LINEAGE_VIEWER',
            'GRANT MONITOR ON FUTURE DYNAMIC TABLES IN DATABASE "'        || db || '" TO ROLE LINEAGE_VIEWER'
        );

        FOR i IN 0 TO ARRAY_SIZE(:stmts) - 1 DO
            LET s STRING := GET(:stmts, :i)::STRING;
            BEGIN
                EXECUTE IMMEDIATE :s;
                ok := :ok + 1;
            EXCEPTION
                WHEN OTHER THEN
                    failed := :failed + 1;
            END;
        END FOR;
    END FOR;

    RETURN 'grants applied: ' || :ok || ', failed/skipped: ' || :failed;
END;


-- ---------------------------------------------------------------------------
-- STEP 4. Verify as the target role
-- ---------------------------------------------------------------------------
-- USE ROLE LINEAGE_VIEWER;
-- USE SECONDARY ROLES NONE;   -- important: secondary roles can mask the test
-- SELECT * FROM TABLE(SNOWFLAKE.CORE.GET_LINEAGE('<DB>.<SCHEMA>.<TABLE>','TABLE','UPSTREAM',3));
--
-- Any row with SOURCE_STATUS or TARGET_STATUS = 'MASKED' and '***' names
-- indicates an object the role still lacks a privilege on.