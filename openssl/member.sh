#!/bin/bash
set -e

DEF_UID="arf20"
DEF_MAIL="arf20@arf20.com"

prompt_member() {
    read -p "Member User Identifier [$DEF_UID]: " MEMBER_UID
    read -p "Member e-mail [$DEF_MAIL]: " MEMBER_MAIL
    read -p "Member private key password [$DEF_ENC]: " MEMBER_ENC
    MEMBER_UID=${MEMBER_UID:-"$DEF_UID"}
    MEMBER_MAIL=${MEMBER_MAIL:-"$DEF_MAIL"}
    MEMBER_ENC=${MEMBER_ENC:-"$DEF_ENC"}
}

req_member() {
    echo "-- Creating member request and key"
    mkdir private
    env ENC=$MEMBER_ENC openssl genpkey -algorithm EC -out private/${MEMBER_UID}_key.pem \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve \
       -pass env:ENC -aes-256-cbc
    chmod -R go-rwx private

    env ENC=$MEMBER_ENC openssl req \
        -new \
        -key private/${MEMBER_UID}_key.pem \
        -out $MEMBER_UID.csr \
        -config member.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$MEMBER_OU/UID=$MEMBER_UID" \
        -addext "subjectAltName=email:$MEMBER_MAIL" \
        -passin env:ENC
    openssl req -in $MEMBER_UID.csr -noout -verify
}

source ./member_config
prompt_member
req_member

