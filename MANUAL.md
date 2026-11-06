# Manual

## Authority

### Initialize PKI

Creates Root CA, Intermediate CA, and certificates for RA, VA and Televote

```
$ mkdir linuxumu-vote && cd linuxumu-vote
$ ../openssl/ca.sh init ../openssl
```

Prompting questions for information

### Distribute certificate request script to members

`member_req_dist.tar`

### Verify member, sign and register certificate

In person, receive CSR and place it in `ra/requests`

Verify and approve (or reject) member CSR

```
$ ../openssl/ra.sh arf20
[...]
Approve (y/n)?: y
```

CSR is copied to `ra/approved`. Sign member CSR

```
$ ../openssl/ca.sh sign arf20
```

Resulting signed certificate is copied to `ra/signed`, which is handed back to
the member

## Member

### Receive and untar request script distributable

```
tar xf member_req_dist.tar
```

### Create CSR

```
./member.sh
```

Prompts questions about member

