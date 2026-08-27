/*====================================================================
  FILE         : Git workspace.sql
  DESCRIPTION  : Add Git workspace
====================================================================*/

/*--------------------------------------------------------------------
  SECTION : API INTEGRATION
--------------------------------------------------------------------*/
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE API INTEGRATION API_INTEGRATION_GIT_REPOSITORY
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/aldoruizw/snowflake.git')
    API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)
    ENABLED = TRUE;

/*--------------------------------------------------------------------
  SECTION : Snowsight UI, add Git workspace
1. Next to Workspaces/Databases tab, you will find +
2. Git workspace
3. Repository URL -> https://github.com/aldoruizw/snowflake.git
   OAuth2
--------------------------------------------------------------------*/