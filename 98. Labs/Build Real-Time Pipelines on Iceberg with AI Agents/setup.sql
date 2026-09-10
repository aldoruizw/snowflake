USE ROLE ACCOUNTADMIN;

-- The producer emits UTC. Set the account to UTC so every latency measurement
-- below reads correctly.
ALTER ACCOUNT SET TIMEZONE = 'UTC';

-- REQUIRED for the agent in Part 4. Set it now: a fresh account defaults to
-- DISABLED, which shrinks the available models and Cortex features.
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- One identity for both Cortex Code and the producer, so you manage one credential.
CREATE USER IF NOT EXISTS HOL_USER
  DEFAULT_ROLE = ACCOUNTADMIN
  COMMENT = 'Iceberg CDC VHOL lab user';
GRANT ROLE ACCOUNTADMIN TO USER HOL_USER;

-- Grant Cortex access explicitly. ACCOUNTADMIN does not imply it, and the
-- agent step needs it.
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER  TO ROLE ACCOUNTADMIN;
GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER TO ROLE ACCOUNTADMIN;

-- Attach a network policy before minting the token. A token only authenticates
-- if its user sits under one. This one is wide open because the account is a
-- throwaway lab account; do not copy it into anything real.
CREATE NETWORK POLICY IF NOT EXISTS HOL_NP ALLOWED_IP_LIST = ('0.0.0.0/0');
ALTER USER HOL_USER SET NETWORK_POLICY = HOL_NP;

ALTER USER HOL_USER
  ADD PROGRAMMATIC ACCESS TOKEN HOL_PAT
    ROLE_RESTRICTION = 'ACCOUNTADMIN'
    DAYS_TO_EXPIRY = 7
    COMMENT = 'Iceberg CDC VHOL lab token';