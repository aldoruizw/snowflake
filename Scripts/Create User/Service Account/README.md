# Create Service Account User
## Key-pair authentication
### Generate the private keys
1. To generate an unencrypted version, use the following command:
   ```sh
   openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
   ```
2. The commands generate a private key in PEM format.
   ```text
   -----BEGIN ENCRYPTED PRIVATE KEY-----
   MIIE6T...
   -----END ENCRYPTED PRIVATE KEY-----
   ```
### Generate a public key
1. From the command line, generate the public key by referencing the private key. The following command assumes the private key is encrypted and contained in the file named `rsa_key.p8`.
   ```sh
   openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
   ```
2. The command generates the public key in PEM format.
   ```text
   -----BEGIN PUBLIC KEY-----
   MIIBIj...
   -----END PUBLIC KEY-----
   ```
### Assign the public key to a Snowflake user
1. To assign the public key to the user, execute an ALTER USER command to set the RSA_PUBLIC_KEY property of the user. For example:
   ```sql
   ALTER USER example_user SET RSA_PUBLIC_KEY='MIIBIjANBgkqh...';
   ```
2. You can also set the key when you create the user. For example:
   ```sql
   CREATE USER example_user
       TYPE = SERVICE
       COMMENT = "Service account user for XYZ"
       RSA_PUBLIC_KEY = "MIIBIjANBgkqh...";
   ```
>**Note**: Exclude the public key delimiters in the SQL statement.
## Programmatic access tokens (PATs)

## Resources
* [Key-pair authentication and key-pair rotation](https://docs.snowflake.com/en/user-guide/key-pair-auth)
