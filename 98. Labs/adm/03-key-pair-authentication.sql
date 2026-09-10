
-- 3.0.0   Key Pair Authentication
--         In this lab you will learn and practice the following:
--         - Generate Public and Private Keys using openssl
--         - Assign a Public Key to your Animal User
--         - Log in to Snowflake CLI with Key Pair Authentication
--         - Create a PAT using Snowflake CLI
--         - Log in to VS Code using PAT

-- 3.1.0   Load Lab SQL File

-- 3.1.1   To load the SQL file, in the left navigation bar, select Projects,
--         then, under My Workspace, select the lab SQL file corresponding to
--         this lab exercise.

-- 3.1.2   Set query tag for this session.

ALTER SESSION SET query_tag = '(PONY) lab - TOPIC: Key Pair Authentication';


-- 3.1.3   Confirm ADM_ROLE as the current role.

USE ROLE adm_role;


-- 3.2.0   Configuring a Service to Run Snowflake CLI Commands
--         This section will use a Snowpark Container Service to supply the
--         Snowflake CLI command line utility in this course. Typically, this is
--         installed on your local workstation and incorporated into your
--         development workflows. The training team provides this environment
--         for demonstration to give hands-on experience with the tool. We have
--         chosen an open-source version of Visual Studio Code as it provides an
--         interface where it is easy to review file contents and use the
--         command line utility we will use in subsequent exercises.

-- 3.2.1   Create database and schema for lab exercises.

CREATE DATABASE IF NOT EXISTS PONY_adm_db;

CREATE SCHEMA IF NOT EXISTS PONY_adm_db.vscode_snowcli;

USE SCHEMA PONY_adm_db.vscode_snowcli;


-- 3.2.2   Create a Virtual Warehouse to run queries.

CREATE OR REPLACE WAREHOUSE PONY_adm_wh
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE;


-- 3.2.3   Create stages that will act as the service’s workspace and extensions
--         volumes respectively.

CREATE STAGE IF NOT EXISTS volumes
  DIRECTORY = (ENABLE = TRUE);

CREATE STAGE IF NOT EXISTS extension
  DIRECTORY = (ENABLE = TRUE);


-- 3.2.4   Copy pre-built files for the service into the stages.

COPY FILES INTO @PONY_adm_db.vscode_snowcli.volumes
  FROM @training_db.native_app.snowflake_cli
  DETAILED_OUTPUT = TRUE;

COPY FILES INTO @PONY_adm_db.vscode_snowcli.volumes
  FROM @training_db.native_app.install_test/installing_testing_cli/
  DETAILED_OUTPUT = TRUE;

COPY FILES INTO @PONY_adm_db.vscode_snowcli.extension
  FROM @training_db.native_app.vscode_extension
  DETAILED_OUTPUT = TRUE;


-- 3.2.5   Create the vscode_server service to provide the Snowflake CLI command
--         prompt.

CREATE SERVICE PONY_adm_db.vscode_snowcli.vscode_server
    IN COMPUTE POOL vscode_cp
    FROM SPECIFICATION $$
    spec:
      container:
      - name: main
        image: /training_db/spcs/spcs_examples/vscode:latest
        volumeMounts:
          - name: vscode-workspace-volume
            mountPath: /config/workspace
          - name: vscode-extension-volume
            mountPath: /config/extensions
        env:
          SNOWFLAKE_WAREHOUSE: PONY_napp_wh
      endpoints:
        - name: vscode-endpoint
          port: 8443
          public: true
      volumes:
        - name: vscode-workspace-volume
          source: "@volumes"
          uid: 911
          gid: 911
        - name: vscode-extension-volume
          source: "@extension"
          uid: 911
          gid: 911
      logExporters:
        eventTableConfig:      
          logLevel: INFO
          $$
    external_access_integrations = (ALLOW_ALL_EAI);

--         It may take a few minutes for the endpoint to be generated.

-- 3.2.6   Get the service endpoint so we can connect to the service.

SHOW ENDPOINTS IN SERVICE PONY_adm_db.vscode_snowcli.vscode_server;

--         Once it populates it may take a minute or two), select the output of
--         the ingress_url column and click the copy button as shown here to
--         copy the URL for your vscode_server service.
--         Paste the URL obtained in the past step into your browser, and when
--         prompted login with your PONY user account credentials.

-- 3.2.7   Trust Authors of Files in Workspace
--         You may be prompted to trust the authors of files in the ~/workspace
--         directory. Check the checkbox and click Yes I trust the authors
--         Toggle the bottom panel of the vscode_server window by using the
--         small button in the upper right hand corner of the window.
--         If you find the font of the terminal too small:

-- 3.2.8   Run a couple of commands to configure the terminal.
--         snow –install-completion
--         export TERM=xterm-256color
--         bash
--         These commands install tab completion for Snowflake CLI and exports
--         the TERM environment variable to allow for the clear command and some
--         others to run if desired. The last command bash opens a new session
--         and applies the tab completion to the current terminal session.

-- 3.3.0   Create and Configure Key Pair Authentication
--         Before we can configure a Snowflake CLI connection, we need to create
--         the RSA Key Pair and configure your animal user with the public key.
--         Start in the terminal, and once the key pair is created, use
--         Snowsight to associate the public key with your animal user.

-- 3.3.1   Create an RSA Key Pair for Snowflake CLI authentication.
--         Execute the following commands in the VS Code terminal:
--         openssl genrsa -out rsa_key.pem 2048
--         openssl pkcs8 -topk8 -inform PEM -in rsa_key.pem -outform PEM
--         -nocrypt -out rsa_key.p8
--         openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
--         cat rsa_key.pub
--         Copy the output of the public key, and paste it someplace safe to use
--         in Snowsight.

-- 3.3.2   Associate the public key with your animal user.
--         Return to the Snowsight tab in your browser. Associate the public key
--         with your animal user by pasting the output of the cat command you
--         executed in the VS Code terminal session. Be sure to remove all line
--         breaks in the public key before executing the alter user command.
--         Since you must use an authorized account to perform this command, we
--         will substitute a secure stored procedure that does the same. The SQL
--         Used to execute this operation is:
--         USE ROLE ACCOUNTADMIN; ALTER USER PONY SET RSA_PUBLIC_KEY=;

CALL adm_db.admin.set_rsa_public_key('<paste_rsa_public_key_here>');


-- 3.3.3   Return to the terminal prompt, and explore some Snowflake CLI
--         commands. Use the snow --help option to find out what our options
--         are.
--         snow –help
--         This reports back several sub-commands we can run, each of which
--         likely has additional sub-commands for each in turn. We will start by
--         setting up the connection to our Snowflake training account.

-- 3.3.4   Run the --help option again to find out what the options are for
--         connections.
--         snow connection –help

-- 3.4.0   Configure the Snowflake CLI Connection
--         To use Snowflake CLI we must first set up a connection.
--         Ensure you have the following information ready:
--         In the terminal run this command:
--         snow connection add –default
--         You will be prompted for values interactively. Enter the following
--         values, replacing values shown below with the values you obtained
--         above. Use literal values specified below for any other prompt. If
--         you’re performing this lab using the workbook PDF, replace PONY
--         below with your assigned animal name.
--         Enter connection name: TrainingAccount Enter account: sfedu03- Enter
--         user: PONY Enter password: [enter] Enter role: adm_role **Enter
--         warehouse: PONY_adm_wh Enter database: PONY_adm_db Enter
--         schema: vscode_snowcli Enter host: [enter] Enter port: [enter] Enter
--         region: [enter] Enter authenticator: SNOWFLAKE_JWT Enter workload
--         identity provider: [enter] Enter private key file: rsa_key.p8 Enter
--         token file path: [enter]**
--         You should see a message in the terminal similar to the following:
--         Wrote new connection TrainingAccount to
--         /config/.snowflake/connections.toml

-- 3.4.1   Test the connection.
--         Enter the following command into the vscode_server terminal in the
--         browser:
--         snow connection test
--         You should see a message similar to the following:
--         If you make a mistake in the wizard setting up your connection, there
--         is not a snow connection delete command. Instead, you can just remove
--         or edit the connection you made in the file created. Demonstrated
--         here is a step that will edit the configuration profile in that file.
--         You only need to edit this file if you encounter an error.
--         Additionally, you may receive a popup to trust this file and then
--         select open.
--         code-linux.sh /config/.snowflake/connections.toml
--         You can correct the entries made in this file using the simple editor
--         that appears. Your changes are auto-saved and you can close the file
--         by selecting the X in the connections.toml tab.
--         Now that we have our connection created, let’s test a Snowflake CLI
--         command.
--         snow sql -q select firstname, lastname, member_id from
--         snowbearair_db.modeled.members limit 10;
--         You should see a table of results in the terminal window.

-- 3.5.0   Use Snowflake CLI to Create a Programmatic Access Token, and Use it
--         to Log In to the Snowflake VS Code Extension

-- 3.5.1   Set Up a Personal Authentication Token (PAT)
--         In order to configure our connection to Snowflake, we will need to
--         generate a Personal Authentication Token (PAT) to authenticate. There
--         are a few different authentication methods available. PAT was chosen
--         for this demonstration because it is easy to initially configure and
--         has options for token rotation where old tokens are replaced
--         periodically for security. Configuring PAT does require that a
--         Network Policy be in place, and that the user be restricted to a
--         specific role. Let’s first take a look at that network policy.

-- 3.5.2   Query the network policies on this training account:
--         Here we use a SECURE Stored Procedure so we can see the network
--         policies from the ACCOUNTADMIN perspective:
--         snow sql -q CALL adm_db.admin.show_network_policies();
--         A best-practice for setting this up as production is to provide a
--         limited range of IP addresses in the Network Policy.

-- 3.5.3   Create the PAT and copy the secret produced.
--         snow sql -q ALTER USER PONY ADD PAT sf_cli_token;
--         This command should produce a token_secret which we will copy and use
--         to authenticate with Snowflake. It is important to capture that value
--         as it cannot be viewed more than once.

-- 3.5.4   Configure the VS Code Snowflake extension to use a PAT.
--         In the left-hand pane of VS code find the Snowflake extension and
--         select it.
--         Since we configured token pair authentication in the terminal, the
--         Snowflake VS Code extension has picked up on that and configured
--         itself to do the same. Since we want to demonstrate connecting using
--         a PAT, we much first remove that connection. Click the Remove
--         Connection button.
--         Now we must define what account we are connecting to. In the Account
--         Identifier/URL field, enter the full account name. It should be
--         formatted as SFEDU03-[class_account_id].
--         Finally, enter your animal user name in the Username field and the
--         Programmatic Access Token in the Password field, then click Sign In.
--         You will be connected to your account and will see the Object
--         Explorer pane (below the account pane) populate with the database
--         hierarchy. Open a new SQL file by navigating to the hamburger menu at
--         the upper-left of the VS Code window, selecting File, then New File…,
--         and then Snowflake SQL File from the drop-down menu. To test the
--         connection, run the same query we executed in the terminal session:
--         select firstname, lastname, member_id from
--         snowbearair_db.modeled.members limit 10;
--         You should see a table of results in the VS Code window.

-- 3.6.0   Key Takeaways
--         - This lab showed how to create an RSA Key Pair and configure a
--         Snowflake CLI connection using key pair authentication to connect.
--         - This lab also demonstrated how to create a Programmatic Access
--         Token, and configure the Snowflake VS Code extension to connect using
--         the PAT.

