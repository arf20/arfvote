#!/bin/bash
set -e

usage() {
    echo "usage: $0 <verify|register> <uid>"
}

verify_req() {
    MEMBER_UID=$1
    echo "== Verify Member Certificate Request"
    openssl req -in $RA_DIR/requests/$MEMBER_UID.csr -text -verify

    echo ""
    read -p "Approve request (y/n)?: " approval
    case "$approval" in
        y|Y|yes ) mv $RA_DIR/requests/$MEMBER_UID.csr $RA_DIR/approved;;
        * ) mv $RA_DIR/requests/$MEMBER_UID.csr $RA_DIR/rejected;;
    esac
}

register() {
    MEMBER_UID=$1
    CRT_UID=$(openssl x509 -in $RA_DIR/signed/$MEMBER_UID.pem -noout -subject -nameopt RFC2253 | tr ',' '\n' | grep '^UID=' | sed 's/UID=//')
    if [ "$CRT_UID" != "$CRT_UID" ]; then
        echo "UID does not match"
        exit 1
    fi

    MEMBER_EMAIL=$(openssl x509 -in ra/signed/$MEMBER_UID.pem -noout -ext subjectAltName | grep 'email:' | sed 's/ *email://')
    echo "email: $MEMBER_EMAIL"
    read -p "Member Common Name []: " MEMBER_CN
    read -p "Member Surname []: " MEMBER_SN

    CRT_BASE64=$(openssl x509 -in ra/signed/$MEMBER_UID.pem -outform der | base64 -w 0)

    cat << EOF | ldapadd -H "$LDAP_HOST" -D "$LDAP_ADMIN_DN" -W
dn: uid=$MEMBER_UID,$LDAP_MEMBER_BASE_DN
objectClass: inetOrgPerson
uid: $MEMBER_UID
cn: $MEMBER_CN
sn: $MEMBER_SN
mail: $MEMBER_EMAIL
userCertificate;binary:: $CRT_BASE64

EOF

}


echo "arfvote registration authority"

source ./config

if [ $# -lt 2 ]; then
    usage
fi

if [ "$1" == "verify" ]; then
    verify_req $2
elif [ "$1" == "register" ]; then
    register $2
else
    usage
fi

