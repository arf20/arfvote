#!/bin/bash
set -e

DEF_UID="arf20"
DEF_CN="Angel"
DEF_SN="Ruiz Fernandez"
DEF_MAIL="arf20@arf20.com"

prompt_member() {
    read -p "Member User Identifier [$DEF_UID]: " MEMBER_UID
    read -p "Member Common Name [$DEF_CN]: " MEMBER_CN
    read -p "Member Surname [$DEF_SN]: " MEMBER_SN
    read -p "Member e-mail [$DEF_MAIL]: " MEMBER_MAIL
    MEMBER_UID=${MEMBER_UID:-"$DEF_UID"}
    MEMBER_CN=${MEMBER_CN:-"$DEF_CN"}
    MEMBER_SN=${MEMBER_SN:-"$DEF_SN"}
    MEMBER_MAIL=${MEMBER_MAIL:-"$DEF_MAIL"}
}

req_member() {
    echo "-- Creating member request and key"
    mkdir private
    openssl genpkey -algorithm EC -out private/${MEMBER_UID}_key.pem \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    chmod -R go-rwx private

    openssl req \
        -new \
        -nodes \
        -key private/${MEMBER_UID}_key.pem \
        -out $MEMBER_UID.csr \
        -config member.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$MEMBER_OU/UID=$MEMBER_UID+$MEMBER_CN" \
        -addext "subjectAltName=email:$MEMBER_MAIL"
    openssl req -in $MEMBER_UID.csr -noout -verify
}

source ./member_config
prompt_member
req_member

