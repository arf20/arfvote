#!/bin/bash
set -e

DEF_UID="arf20"

prompt_req() {
    read -p "Requester Member User Identifier [$DEF_UID]: " MEMBER_UID
    MEMBER_UID=${MEMBER_UID:-"$DEF_UID"}
}

verify_req() {
    echo "== Verify Member Certificate Request"
    openssl req -in $RA_DIR/requests/$MEMBER_UID.csr -text -verify

    echo ""
    read -p "Approve request (y/n)?: " approval
    case "$approval" in
        y|Y|yes ) mv $RA_DIR/requests/$MEMBER_UID.csr $RA_DIR/approved;;
        * ) mv $RA_DIR/requests/$MEMBER_UID.csr $RA_DIR/rejected;;
    esac
}

source ./config
prompt_req
verify_req

