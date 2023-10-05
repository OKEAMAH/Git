#!/bin/bash

tmp1=$(mktemp)
tmp2=$(mktemp)
bad=0

while read l ; do
    ./target/debug/codec $l | tee $tmp1
    ../../octez-codec $l | tee $tmp2
    (diff $tmp1 $tmp2 && echo "OK") || (echo "KO" ; $((bad++)))
done <<EOF
decode 005-PsBabyM1.contract from 00000000000000000000000000000000000000000000
decode 005-PsBabyM1.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 006-PsCARTHA.contract from 00000000000000000000000000000000000000000000
decode 006-PsCARTHA.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 007-PsDELPH1.contract from 00000000000000000000000000000000000000000000
decode 007-PsDELPH1.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 008-PtEdo2Zk.contract from 00000000000000000000000000000000000000000000
decode 008-PtEdo2Zk.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 009-PsFLoren.contract from 00000000000000000000000000000000000000000000
decode 009-PsFLoren.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 010-PtGRANAD.contract from 00000000000000000000000000000000000000000000
decode 010-PtGRANAD.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 011-PtHangz2.contract from 00000000000000000000000000000000000000000000
decode 011-PtHangz2.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 012-Psithaca.contract from 00000000000000000000000000000000000000000000
decode 012-Psithaca.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 013-PtJakart.contract from 00000000000000000000000000000000000000000000
decode 013-PtJakart.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 014-PtKathma.contract from 00000000000000000000000000000000000000000000
decode 014-PtKathma.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 015-PtLimaPt.contract from 00000000000000000000000000000000000000000000
decode 015-PtLimaPt.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 016-PtMumbai.contract from 00000000000000000000000000000000000000000000
decode 016-PtMumbai.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 016-PtMumbai.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode 017-PtNairob.contract from 00000000000000000000000000000000000000000000
decode 017-PtNairob.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
decode alpha.contract from 00000000000000000000000000000000000000000000
decode alpha.contract from 0000281aea86d1cf8b0c74f1be3eeb67c516cdcc2abf
encode 005-PsBabyM1.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 005-PsBabyM1.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 006-PsCARTHA.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 006-PsCARTHA.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 007-PsDELPH1.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 007-PsDELPH1.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 008-PtEdo2Zk.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 008-PtEdo2Zk.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 009-PsFLoren.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 009-PsFLoren.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 010-PtGRANAD.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 010-PtGRANAD.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 011-PtHangz2.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 011-PtHangz2.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 012-Psithaca.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 012-Psithaca.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 013-PtJakart.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 013-PtJakart.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 014-PtKathma.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 014-PtKathma.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 015-PtLimaPt.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 015-PtLimaPt.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 016-PtMumbai.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 016-PtMumbai.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode 017-PtNairob.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode 017-PtNairob.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
encode alpha.contract from "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"
encode alpha.contract from "tz1PJ5xxUFDAwgKHLMUPe5SL3eJkVehfiDL6"
EOF

if (( bad > 0 )) ; then
    echo "FAIL: some differences were detected."
    exit 1
else
    echo "No differences were detected."
    exit 0
fi
