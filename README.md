# arfvote
 
 - Voter has a personal certificate from a CA
 - Voter obtains ballot (anonymous sign key) with certificate, Central authority expedites it
 - Voter fills ballot template and signs with ballot key
 - Voter submits ballot anonymously to central authority
 - Central authority verifies all ballot signatures and publishes the counting results incl. ballots

## PKI

Voters are centrally registered because the authority must know who are allowed
to vote

```
                   Certificate Authority Root
                               |
                               v
               Certificate Authority Inermediate
                               |
       +-----------------------+----+--------------------+
       |                            |                    |
       v                            v                    v
Registration Authority   Verification Authority       Members
                                                       ...
```

All certificates are valid for only 30 days

### CA

Signs certificates for RA, VA and members

### Member RA

Verifies members and creates CSRs for CA to sign

### Voter VA and RA

Verifies member certificate and emits anonymous ballots

## Cryptography

secp384r1 (ECDSA)

