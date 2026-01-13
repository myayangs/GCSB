>Scenario: The Cymbal DevOps team is building their deployment pipeline for the MCP Toolbox on Cloud Run. The database password and the entire tools.yaml configuration file are considered sensitive secrets. They must not be stored in the container image or in source control. What is the secure and operationally sound method to provide this configuration to the Cloud Run service at runtime?

```
Store the database password and the complete tools.yaml file as separate secrets in Google Secret Manager. Use the --set-secrets flag in the gcloud run deploy command to mount both secrets into the running container.
```

>Scenario: The Cymbal Insurance security team is reviewing the plan for the new AI agent. Their primary concern is that allowing an LLM to interact with their production claims database creates a massive risk of SQL injection and data exfiltration, where a malicious prompt could trick the agent into running unauthorized queries (like SELECT * FROM users;). How does the MCP Toolbox for Databases architecturally prevent this specific risk?

```
The Toolbox acts as a secure control plane by abstracting the database. The LLM does not generate SQL; it selects a pre-defined tool (e.g., get_claim_history) by its name and description. The Toolbox then executes a pre-approved, parameterized SQL query defined in tools.yaml, ensuring only safe, intended operations are run.
```

>Scenario: During the deployment of the MCP Toolbox to Cloud Run, the Cymbal infrastructure team needs to ensure two things: 1) The service has no public IP address and stays within the private VPC. 2) The service must be allowed to make outbound connections to download necessary updates or connect to Google APIs.

```
Deploying the service with a VPC Connector (to access the VPC) and using Cloud NAT (to provide secure, one-way egress for outbound traffic without a public IP).
```

>Scenario: A data engineer at Cymbal Insurance is defining a new capability in the tools.yaml file. The goal is to allow the agent to get the details for a specific claim ID provided by the user. Which tool definition correctly and securely implements this using PostgreSQL syntax?

```
```- name: get_claim_details description: Gets details for a specific claim ID. source: claims_db statement: "SELECT * FROM claims WHERE claim_id = $1" parameters: - name: claim_id type: string```
```

>Scenario: A Cymbal database administrator is configuring the AlloyDB database that will store claims and policy data. To implement defense-in-depth, they must create the database-level user (named toolbox_user) that the MCP Toolbox will use to connect. Which SQL command correctly implements the principle of least privilege for this user?

```
GRANT SELECT ON TABLE claims, policies TO toolbox_user;
```