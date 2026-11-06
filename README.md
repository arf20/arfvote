# arfvote

 - Verifiable: voter can check his ballot was included in the tally
 - Secret: no one party -not even authorities- can know what a voter voted
 - Standard: Implementation based in X.509 certificates, LDAP and JWTs

## Roles

Voters are centrally registered because the authority must know who are allowed
to vote

```
                       Certificate Authority Root
X.509 PKI                          |
                                   v
                   Certificate Authority Inermediate
                                   |
           +-----------------------+----+--------------------+-----------------+
           |                            |                    |                 |
           v                            v                    v                 v
--- Registration Authority -- Verification Authority -- Televoting System -- Members ---
           |                                                                   v
                                                                               |
           +...............................................................> Ballot

JWT
```

All certificates are valid for only 30 days

### Certificate Authorities

#### CA Root

Signs intermediate

#### CA Intermediate

Signs certificates for Registration Authority, Verification Authority, Televoting System and Members

### Member Registration Authority

Verifies member certificate requests, approving or rejecting them

Requires interactive physical presence of registration official and requester member

### Member Verification Authority (LDAP?)

Verifies and authenticates member certificates

### Televoting System

#### Voter Registration Authority

Verifies member certificates against VA and emits anonymous ballot keys
for an specific vote

#### Tally System

Checks signatures of ballots, if uncotested, add to the count

If there are multiple ballots signed with the same key, drop them

#### Ballot Box

Gathers blind ballots from voters

### Member

Creates private key and certificate signing request. Submits to RA, gets signed member certificate back

### Voter

Authenticates via Voter Registration Authority against VA, obtains single ballot key for specific vote

Generates random ballot number and encrypts it with certificate public key

Fills ballot with vote and encrypted number and signs it with ballot key

Submits ballot to Tally System

## Cryptography

secp384r1 (ECDSA)

