#!/bin/bash
set -e

# ====================== defaults editable ==========================
DEF_C="ES"
DEF_ST="Murcia"
DEF_L="Campus de Espinardo"
DEF_O="LinuxUMU"
DEF_OU="Junta"
DEF_MEMBER_OU="Miembros"
DEF_CN_ROOT="AC-Raiz"
DEF_CN_INT="AC-Intermedio"
DEF_CN_RA="ARegistro"
DEF_CN_VA="AVerificacion"
DEF_CN_TV="Televoto"
DEF_SAN_RA="ra.linux.inf.um.es"
DEF_SAN_VA="va.linux.inf.um.es"
DEF_SAN_TV="tv.linux.inf.um.es"
DEF_DAYS=3650
DEF_ENC="test"
DEF_LDAP_HOST="ldap://localhost"
DEF_LDAP_ADMIN_DN="cn=admin,dc=linux,dc=inf,dc=um,dc=es"
DEF_LDAP_MEMBER_BASE_DN="dc=linux,dc=inf,dc=um,dc=es"
# ====================================================================

CNF_PATH="./"
CA_ROOT_DIR=ca-root
CA_INT_DIR=ca-int
RA_DIR=ra
VA_DIR=va
TV_DIR=tv

prompt() {
    read -p "Country [$DEF_C]: " C
    read -p "State/Province [$DEF_ST]: " ST
    read -p "Locality [$DEF_L]: " L
    read -p "Organization [$DEF_O]: " O
    read -p "Organizational Unit [$DEF_OU]: " OU
    read -p "Member Organizational Unit [$DEF_MEMBER_OU]: " MEMBER_OU
    read -p "Common Name for Root Certification Authority [$DEF_CN_ROOT]: " CN_ROOT
    read -p "Common Name for Intermediate Certification Authority [$DEF_CN_INT]: " CN_INT
    read -p "Common Name for Registration Authority [$DEF_CN_RA]: " CN_RA
    read -p "Common Name for Verification Authority [$DEF_CN_VA]: " CN_VA
    read -p "Common Name for Televoting System [$DEF_CN_TV]: " CN_TV
    read -p "DNS Subject Alternate Name for RA [$DEF_SAN_RA]: " SAN_RA
    read -p "DNS Subject Alternate Name for VA [$DEF_SAN_VA]: " SAN_VA
    read -p "DNS Subject Alternate Name for TV [$DEF_SAN_TV]: " SAN_TV
    read -p "Validity period in days [$DEF_DAYS]: " DAYS
    read -p "CA private key encryption key [$DEF_ENC]: " ENC
    read -p "LDAP Host URI [$DEF_LDAP_HOST]: " LDAP_HOST
    read -p "LDAP Admin DN [$DEF_LDAP_ADMIN_DN]: " LDAP_ADMIN_DN
    read -p "LDAP Member Base DN [$DEF_LDAP_MEMBER_BASE_DN]: " LDAP_MEMBER_BASE_DN
    C=${C:-"$DEF_C"}
    ST=${ST:-"$DEF_ST"}
    L=${L:-"$DEF_L"}
    O=${O:-"$DEF_O"}
    OU=${OU:-"$DEF_OU"}
    MEMBER_OU=${MEMBER_OU:-"$DEF_MEMBER_OU"}
    CN_ROOT=${CN_ROOT:-"$DEF_CN_ROOT"}
    CN_INT=${CN_INT:-"$DEF_CN_INT"}
    CN_RA=${CN_RA:-"$DEF_CN_RA"}
    CN_VA=${CN_VA:-"$DEF_CN_VA"}
    CN_TV=${CN_TV:-"$DEF_CN_TV"}
    SAN_RA=${SAN_RA:-"$DEF_SAN_RA"}
    SAN_VA=${SAN_VA:-"$DEF_SAN_VA"}
    SAN_TV=${SAN_TV:-"$DEF_SAN_TV"}
    DAYS=${DAYS:-"$DEF_DAYS"}
    ENC=${ENC:-"$DEF_ENC"}
    LDAP_HOST=${LDAP_URI:-"$DEF_LDAP_HOST"}
    LDAP_ADMIN_DN=${LDAP_ADMIN_DN:-"$DEF_LDAP_ADMIN_DN"}
    LDAP_MEMBER_BASE_DN=${LDAP_MEMBER_BASE_DN:-"$DEF_LDAP_MEMBER_BASE_DN"}

    if [ -z "$ENC" ]; then
        ENC_ARG=""
    else
        ENC_ARG="-pass env:ENC -aes-256-cbc"
    fi

    if [ -z "$ENC" ]; then
        DEENC_ARG=""
    else
        DEENC_ARG="-passin env:ENC"
    fi
}

make_ca() {
    echo "-- Creating Self-Signed Root CA certificate and key"
    mkdir $CA_ROOT_DIR
    mkdir $CA_ROOT_DIR/newcerts
    mkdir $CA_ROOT_DIR/private
    touch $CA_ROOT_DIR/index.txt
    touch $CA_ROOT_DIR/certs
    echo "01" > $CA_ROOT_DIR/serial
    echo "00" > $CA_ROOT_DIR/crlnumber
    env ENC=$ENC openssl genpkey -algorithm EC -out $CA_ROOT_DIR/private/cakey.pem \
        -pkeyopt ec_paramgen_curve:P-384 \
        -pkeyopt ec_param_enc:named_curve \
        $ENC_ARG
    chmod -R go-rwx $CA_ROOT_DIR/private/
    env ENC=$ENC openssl req \
        -new \
        -sha3-512 \
        -x509 \
        -key $CA_ROOT_DIR/private/cakey.pem \
        -out $CA_ROOT_DIR/cacert.pem \
        -config $CNF_PATH/ca-root.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_ROOT" \
        -extensions v3_req \
        -days $DAYS \
        $DEENC_ARG
}

make_int() {
    echo "-- Creating Intermediate CA certificate and key"
    mkdir $CA_INT_DIR
    mkdir $CA_INT_DIR/newcerts
    mkdir $CA_INT_DIR/private
    touch $CA_INT_DIR/index.txt
    touch $CA_INT_DIR/certs
    echo "01" > $CA_INT_DIR/serial
    echo "00" > $CA_INT_DIR/crlnumber
    env ENC=$ENC openssl genpkey -algorithm EC -out $CA_INT_DIR/private/cakey.pem \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve \
        $ENC_ARG
    chmod -R go-rwx $CA_INT_DIR/private/
    env ENC=$ENC openssl req \
        -new \
        -sha3-512 \
        -key $CA_INT_DIR/private/cakey.pem \
        -out $CA_INT_DIR/cacert.csr \
        -config $CNF_PATH/ca-int.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_INT" \
        -extensions v3_req \
        $DEENC_ARG
    openssl req -in $CA_INT_DIR/cacert.csr -noout -verify

    env ENC=$ENC openssl ca \
        -keyfile $CA_ROOT_DIR/private/cakey.pem \
        -in $CA_INT_DIR/cacert.csr \
        -out $CA_INT_DIR/cacert.pem \
        -config $CNF_PATH/ca-root.cnf \
        -extfile $CNF_PATH/ca-root.cnf \
        -extensions v3_req \
        -days $DAYS \
        $DEENC_ARG \
        -batch

    openssl verify -CAfile $CA_ROOT_DIR/cacert.pem $CA_INT_DIR/cacert.pem
    echo "-- Creating CA chain"
    cat $CA_INT_DIR/cacert.pem $CA_ROOT_DIR/cacert.pem > $CA_INT_DIR/cachain.pem
}

make_ra() {
    echo "-- Creating Registration Authority certificate and key"
    mkdir $RA_DIR
    mkdir $RA_DIR/private
    mkdir $RA_DIR/requests
    mkdir $RA_DIR/approved
    mkdir $RA_DIR/rejected
    mkdir $RA_DIR/signed
    openssl genpkey -algorithm EC -out $RA_DIR/private/rakey.pem \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    chmod -R go-rwx $RA_DIR/private/
    openssl req \
        -new \
        -key $RA_DIR/private/rakey.pem \
        -out $RA_DIR/racert.csr \
        -config $CNF_PATH/ra.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_RA" \
        -addext "subjectAltName = DNS:$SAN_RA"
    openssl req -in $RA_DIR/racert.csr -noout -verify

    env ENC=$ENC openssl ca \
        -keyfile $CA_INT_DIR/private/cakey.pem \
        -in $RA_DIR/racert.csr \
        -out $RA_DIR/racert.pem \
        -config $CNF_PATH/ca-int.cnf \
        -extfile $CNF_PATH/ca-int.cnf \
        -extensions v3_req \
        -days $DAYS \
        $DEENC_ARG \
        -batch
    openssl verify -CAfile $CA_INT_DIR/cachain.pem $RA_DIR/racert.pem
}

make_va() {
    echo "-- Creating Verification Authority certificate and key"
    mkdir $VA_DIR
    mkdir $VA_DIR/private
    openssl genpkey -algorithm EC -out $VA_DIR/private/vakey.pem \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    chmod -R go-rwx $VA_DIR/private/
    openssl req \
        -new \
        -key $VA_DIR/private/vakey.pem \
        -out $VA_DIR/vacert.csr \
        -config $CNF_PATH/va.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_VA" \
        -addext "subjectAltName = DNS:$SAN_VA"
    openssl req -in $VA_DIR/vacert.csr -noout -verify

    env ENC=$ENC openssl ca \
        -keyfile $CA_INT_DIR/private/cakey.pem \
        -in $VA_DIR/vacert.csr \
        -out $VA_DIR/vacert.pem \
        -config $CNF_PATH/ca-int.cnf \
        -extfile $CNF_PATH/ca-int.cnf \
        -extensions v3_req \
        -days $DAYS \
        $DEENC_ARG \
        -batch
    openssl verify -CAfile $CA_INT_DIR/cachain.pem $VA_DIR/vacert.pem
}

make_tv() {
    echo "-- Creating TeleVoting system certificate and key"
    mkdir $TV_DIR
    mkdir $TV_DIR/private
    openssl genpkey -algorithm EC -out $TV_DIR/private/tvkey.pem \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    chmod -R go-rwx $TV_DIR/private/
    openssl req \
        -new \
        -key $TV_DIR/private/tvkey.pem \
        -out $TV_DIR/tvcert.csr \
        -config $CNF_PATH/tv.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_TV" \
        -addext "subjectAltName = DNS:$SAN_TV"
    openssl req -in $TV_DIR/tvcert.csr -noout -verify

    env ENC=$ENC openssl ca \
        -keyfile $CA_INT_DIR/private/cakey.pem \
        -in $TV_DIR/tvcert.csr \
        -out $TV_DIR/tvcert.pem \
        -config $CNF_PATH/ca-int.cnf \
        -extfile $CNF_PATH/ca-int.cnf \
        -extensions v3_req \
        -days $DAYS \
        $DEENC_ARG \
        -batch
    openssl verify -CAfile $CA_INT_DIR/cachain.pem $TV_DIR/tvcert.pem
}

write_config() {
    rm -f config member_config
    echo "CNF_PATH=\"$CNF_PATH\"" >> config
    echo "C=\"$C\"" >> config
    echo "ST=\"$ST\"" >> config
    echo "L=\"$L\"" >> config
    echo "O=\"$O\"" >> config
    echo "MEMBER_OU=\"$MEMBER_OU\"" >> config
    echo "CA_ROOT_DIR=\"$CA_ROOT_DIR\"" >> config
    echo "CA_INT_DIR=\"$CA_INT_DIR\"" >> config
    echo "RA_DIR=\"$RA_DIR\"" >> config
    echo "VA_DIR=\"$VA_DIR\"" >> config
    echo "TV_DIR=\"$TV_DIR\"" >> config
    echo "DAYS=$DAYS" >> config
    if [ -z "$ENC" ]; then
        echo "DEENC_ARG=\"$DEENC_ARG\"" >> config
    fi
    echo "LDAP_HOST=\"$LDAP_HOST\"" >> config
    echo "LDAP_ADMIN_DN=\"$LDAP_ADMIN_DN\"" >> config
    echo "LDAP_MEMBER_BASE_DN=\"$LDAP_MEMBER_BASE_DN\"" >> config

    echo "C=\"$C\"" >> member_config
    echo "ST=\"$ST\"" >> member_config
    echo "L=\"$L\"" >> member_config
    echo "O=\"$O\"" >> member_config
    echo "MEMBER_OU=\"$MEMBER_OU\"" >> member_config

    cp $CNF_PATH/member.sh $CNF_PATH/member.cnf .
    tar cf member_req_dist.tar member.sh member.cnf member_config
    rm member.sh member.cnf member_config
}

sign_member() {
    echo "-- Signing member certificate request"
    openssl req -in $RA_DIR/approved/$1.csr -noout -verify
    openssl ca \
        -keyfile $CA_INT_DIR/private/cakey.pem \
        -in $RA_DIR/approved/$1.csr \
        -out $RA_DIR/signed/$1.pem \
        -config $CNF_PATH/ca-int.cnf \
        -policy policy_member \
        -extfile $CNF_PATH/ca-int.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile $CA_INT_DIR/cachain.pem $RA_DIR/signed/$1.pem
}

usage() {
    echo "usage: ca <arguments>"
    echo "    init:         initialize ca"
    echo "    sign <csr>:   sign csr"
    exit 1
}


# MAIN
echo "arfvote certification authority"

if [ $# -eq 2 ]; then
    if [ "$1" == "init" ]; then
        echo "authority initialization"
        CNF_PATH=$(realpath $2)
        prompt
        echo ""
        make_ca
        echo ""
        make_int
        echo ""
        make_ra
        echo ""
        make_va
        echo ""
        make_tv
        echo ""
        write_config
    elif [ "$1" == "sign" ]; then
        source ./config
        sign_member $2
    else
        usage
    fi
else
    usage
fi

