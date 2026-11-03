#!/bin/bash
set -e

req_member() {
    echo "Creating member request and key"
    openssl genpkey -algorithm EC -out member.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -nodes \
        -key member.key \
        -out member.csr \
        -config member.cnf
    openssl req -in member.csr -noout -verify
}

