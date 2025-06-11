Test Task for Infrastructure Support Engineer
You need to set up a test lab consisting of two servers:
● A server with an LDAP server, preferably using FreeIPA.
● An application server with Docker installed.
The test environment should be deployed in any public cloud of your choice (free tier). Access must be provided..
Configuration Requirements:
1. Application Server:
● Use LVM.
● Create a separate partition for applications, mount it to /app.
● Install Docker.
● Change Docker's working directory to /app.
● Enable Docker to start automatically.
2. LDAP Configuration:
● Create three users in LDAP with the following permissions:
user1: SSH access to the application server + read permission on Docker’s working directory.
user2: SSH access to the application server + write permission on Docker’s working directory.
user3: SSH access to the application server + read and write permissions on Docker’s working directory.
You need to document the process of setting up this environment and provide it in any convenient format for review.