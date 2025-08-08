-- 1. Create secret
CREATE OR REPLACE SECRET SECRET_GIT_GIT_REPOSITORY_SNOWFLAKE
  TYPE = password
  USERNAME = 'GitHub username'
  PASSWORD = 'Personal access tokens (classic)';
