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
DEF_CN_TV="SistemaTelevoto"
DEF_SAN_RA="ra.linux.inf.um.es"
DEF_SAN_VA="va.linux.inf.um.es"
DEF_SAN_TV="tv.linux.inf.um.es"
DEF_DAYS=3650
# ====================================================================

CNF_PATH="./"

prompt_subjects() {
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
}

make_ca() {
    echo "-- Creating Self-Signed Root CA certificate and key"
    openssl genpkey -algorithm EC -out ca-root.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -noenc \
        -sha3-512 \
        -x509 \
        -key ca-root.key \
        -out ca-root.crt \
        -config $CNF_PATH/ca-root.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_ROOT" \
        -extensions v3_req \
        -days $DAYS
}

make_int() {
    echo "-- Creating Intermediate CA certificate and key"
    openssl genpkey -algorithm EC -out ca-int.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -nodes \
        -sha3-512 \
        -key ca-int.key \
        -out ca-int.csr \
        -config $CNF_PATH/ca-int.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_INT" \
        -extensions v3_req \
        -batch
    openssl req -in ca-int.csr -noout -verify
    openssl x509 \
        -req \
        -CA ca-root.crt \
        -CAkey ca-root.key \
        -CAcreateserial \
        -in ca-int.csr \
        -out ca-int.crt \
        -extfile $CNF_PATH/ca-int.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile ca-root.crt ca-int.crt
    echo "Creating CA chain"
    cat ca-int.crt ca-root.crt > ca-chain.pem
}

make_ra() {
    echo "-- Creating registration authority certificate and key"
    openssl genpkey -algorithm EC -out ra.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -nodes \
        -key ra.key \
        -out ra.csr \
        -config $CNF_PATH/ra.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_RA" \
        -addext "subjectAltName = DNS:$SAN_RA"
    openssl req -in ra.csr -noout -verify
    openssl x509 \
        -req \
        -CA ca-int.crt \
        -CAkey ca-int.key \
        -CAcreateserial \
        -in ra.csr \
        -out ra.crt \
        -extfile $CNF_PATH/ra.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile ca-chain.pem ra.crt
}

make_va() {
    echo "-- Creating verification authority certificate and key"
    openssl genpkey -algorithm EC -out va.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -nodes \
        -key va.key \
        -out va.csr \
        -config $CNF_PATH/va.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_VA" \
        -addext "subjectAltName = DNS:$SAN_VA"
    openssl req -in va.csr -noout -verify
    openssl x509 \
        -req \
        -CA ca-int.crt \
        -CAkey ca-int.key \
        -CAcreateserial \
        -in va.csr \
        -out va.crt \
        -extfile $CNF_PATH/va.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile ca-chain.pem va.crt
}

make_tv() {
    echo "-- Creating televoting system certificate and key"
    openssl genpkey -algorithm EC -out tv.key \
       -pkeyopt ec_paramgen_curve:P-384 \
       -pkeyopt ec_param_enc:named_curve
    openssl req \
        -new \
        -nodes \
        -key tv.key \
        -out tv.csr \
        -config $CNF_PATH/tv.cnf \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN_VA" \
        -addext "subjectAltName = DNS:$SAN_TV"
    openssl req -in tv.csr -noout -verify
    openssl x509 \
        -req \
        -CA ca-int.crt \
        -CAkey ca-int.key \
        -CAcreateserial \
        -in tv.csr \
        -out tv.crt \
        -extfile $CNF_PATH/tv.cnf \
        -extensions v3_req \
        -days $DAYS
    openssl verify -CAfile ca-chain.pem tv.crt
}

write_config() {
    rm -f subj_config
    echo "C=$C" >> subj_config
    echo "ST=$ST" >> subj_config
    echo "L=$L" >> subj_config
    echo "O=$O" >> subj_config
    echo "MEMBER_OU=$MEMBER_OU" >> subj_config
}

sign_member() {
    echo "-- Signing member certificate request"
    openssl req -in "$1" -noout -verify
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
    openssl verify -CAfile ca-chain.pem member.crt
}

usage() {
    echo "usage: ca <arguments>"
    echo "    init:         initialize ca"
    echo "    sign <csr>:   sign csr"
    exit 1
}


# MAIN
if [ $# -eq 2 ]; then
    if [ "$1" == "init" ]; then
        echo "arfvote certification authority - initialization"
        CNF_PATH=$2
        prompt_subjects
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
        sign_member $2
    else
        usage
    fi
else
    usage
fi

