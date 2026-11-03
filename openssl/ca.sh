#!/bin/bash
set -e

DAYS=20

make_ca() {
    echo "Creating Self-Signed Root CA certificate and key"
    openssl genpkey -algorithm EC -out ca-root.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -noenc \
        -digest sha3-512
        -x509 \
        -key ca-root.key \
        -out ca-root.crt \
        -config ca-root.cnf \
        -extensions v3_req \
        -days $DAYS
}

make_int() {
    echo "Creating intermediate CA certificate and key"
    openssl genpkey -algorithm EC -out ca-int.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -nodes \
        -digest sha3-512
        -key ca-int.key \
        -out ca-int.csr \
        -config ca-int.cnf \
        -extensions v3_req
    openssl req -in ca-int.csr -noout -verify
    openssl x509 \
        -req \
        -CA ca-root.crt \
        -CAkey ca-root.key \
        -CAcreateserial \
        -in ca-int.csr \
        -out ca-int.crt \
        -extfile ca-int.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile ca-root.crt ca-int.crt
    echo "Creating CA chain"
    cat ca-int.crt ca-root.crt > ca-chain.pem
}

make_ra() {
    echo "Creating register authority certificate and key"
    openssl genpkey -algorithm EC -out ra.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -nodes \
        -key ra.key \
        -out ra.csr \
        -config ra.cnf
    openssl req -in ra.csr -noout -verify
    openssl x509 \
        -req \
        -CA ca-int.crt \
        -CAkey ca-int.key \
        -CAcreateserial \
        -in ra.csr \
        -out ra.crt \
        -extfile ra.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile ca-root.pem ra.crt
}

sign_member() {
    echo "Sign member certificate"
    openssl req -in member.csr -noout -verify
    openssl x509 \
        -req \
        -CA ca-root.crt \
        -CAkey ca-root.key \
        -CAcreateserial \
        -in member.csr \
        -out member.crt \
        -extfile member.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile ca-root.pem member.crt
}

# MAIN
make_ca
make_int
make_ra

