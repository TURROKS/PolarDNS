#!/bin/bash

target_ip="127.0.0.1"
target_port=53
timeout=1

nofail=0

##################
domain=""

# get the domain name from the config file
config="polardns.toml"
if [ -f "${config}" ]; then
  domain="`grep -v '^#' ${config} | grep -m1 "domain = " | awk '{print $3}' | cut -f2 -d"'"`"
else
  config="../polardns.toml"
  if [ -f "${config}" ]; then
    domain="`grep -v '^#' ${config} | grep -m1 "domain = " | awk '{print $3}' | cut -f2 -d"'"`"
  fi
fi
if [ "${domain}" == "" ]; then
  echo "ERROR: cannot load domain name"
  exit 1
fi

##################

rundig() {
  d="$1"
  #tmpfile="/tmp/output.${d//[ +]/}.${target_ip}.$$${RANDOM}"
  #tmpfile="/tmp/output.${d//[ +]/}.${target_ip}"
  dig ${d} @${target_ip} +tries=1 +timeout=${timeout} -p ${target_port} \
  | grep -v '^; <<>> DiG \| WHEN: \| Query time: ' \
  | sed -e 's/, id: .*/, id: <ID>/;s/expected ID .*, got .*/expected ID <ID>, got <DIF>/' \
  | sed -e 's/\x09\s*/ /g;s/\\000/<NUL>/g;s/\([^0-9]\)[0-9]\{6\}\([^0-9]\)/\1<RANDOM>\2/' \
  | sed -e 's/rcvd: .*/rcvd: <SIZE>/;s/has [0-9]* extra bytes/has <NUM> extra bytes/g' \
  | sed -e "s/${domain//\./\\.}/<OURDOM>/g;s/${domain%.*}/<OURDOM-NOTLD>/g" \
  | sed -e "s/#${target_port}/#53/g" \
  | sed -e "s/${target_ip}/127\.0\.0\.1/g" \
  | sed -e "/IN A/s/127\.0\.0\.1$/44\.196\.212\.212/g" \
  | md5sum | awk '{print $1}'
  #> "${tmpfile}"
  #echo hello | md5sum | awk '{print $1}'
}

runddig() {
  d="$1"
  tmpfile="/tmp/output.${d//[ +]/}.${target_ip}.$$${RANDOM}"
  echo "---------------------------------------------"
  echo "# dig ${d} @${target_ip} +tries=1 +timeout=${timeout} -p ${target_port} "
  echo
  dig ${d} @${target_ip} +tries=1 +timeout=${timeout} -p ${target_port} \
  | grep -v '^; <<>> DiG \| WHEN: \| Query time: ' \
  | sed -e 's/, id: .*/, id: <ID>/;s/expected ID .*, got .*/expected ID <ID>, got <DIF>/' \
  | sed -e 's/\x09\s*/ /g;s/\\000/<NUL>/g;s/\([^0-9]\)[0-9]\{6\}\([^0-9]\)/\1<RANDOM>\2/' \
  | sed -e 's/rcvd: .*/rcvd: <SIZE>/;s/has [0-9]* extra bytes/has <NUM> extra bytes/g' \
  | sed -e "s/${domain//\./\\.}/<OURDOM>/g;s/${domain%.*}/<OURDOM-NOTLD>/g" \
  | sed -e "s/#${target_port}/#53/g" \
  | sed -e "s/${target_ip}/127\.0\.0\.1/g" \
  | sed -e "/IN A/s/127\.0\.0\.1$/44\.196\.212\.212/g" \
  > "${tmpfile}"
  sum="`md5sum "${tmpfile}" | awk '{print $1}'`"
  cat "${tmpfile}"
  echo "CHECKSUM: ${sum}"
  echo "  OUTPUT: ${tmpfile}"
  #rm -f -- "${tmpfile}"
}

##################

failcount=0
passcount=0
testcount=0

runtest() {
  dom="$1"
  exp="$2"

  if [ $((debug)) -eq 1 ]; then runddig "${dom}"; return; fi
  out="`rundig "${dom}"`"
  ((testcount++))
  fail=0

  cmd="dig ${dom} @${target_ip} +tries=1 +timeout=${timeout} -p ${target_port} "
  if [ "${out}" != "${exp}" ]; then
    echo "FAIL    ${cmd}"
    ((failcount++))
    echo " \\          expected $exp"
    echo "  \\_______  got      $out"
    echo "runtest \"${dom}\" \"${out}\""
    if [ $((nofail)) -eq 1 ]; then exit 1; fi
  else
    echo "PASSED  ${cmd}"
    ((passcount++))
  fi
}

#######################################
# main

debug=0
if [ ! -z "${1}" ]; then
  debug=1
  if [ "${1}" == "dig" ]; then
    shift
    arg="${*}"
    arg="${arg//@${target_ip} +tries=1 +timeout=${timeout}/}"
    runddig "${arg}"
    exit 0
  fi
fi

#################################################################

#exit 0

#runtest "always123.anrr0.tc.${domain}" "911aebd69bf9ecd9e7b844b99869f9e6"
#runtest "inj13.qurr0.noq.tc.${domain}" "25d5500cd0da47c90636553b46a1a9b9"
#runtest "always123.anrr0.tc.${domain}" "911aebd69bf9ecd9e7b844b99869f9e6"
#runtest "always123.anrr0.tc.${domain}" "911aebd69bf9ecd9e7b844b99869f9e6"
#exit 0

runtest "cgena.1.${domain}" "8bee2a94ebe12cee620a8bfa18169b1d"
runtest "cgena.2.${domain}" "dc2bd1660fcad388dfabfca711546326"
runtest "cgena.3.${domain}" "c06177958752766ada88471b59477913"
runtest "cgena.4.${domain}" "dc7b01f4ff69a4d468d9e51bee94f369"
runtest "cgena.5.${domain}" "7edd717c934c28016e2b9fb1cfb70a06"
runtest "cgena.6.${domain}" "5fcbec1dbae6f22cd70f68eb79d52410"
runtest "cgena.1.46.2.${domain}" "1e2f7de3fdb71ce62268636d2f40d8b0"
runtest "cgena.2.46.2.${domain}" "faba11d7a4d8e10e6f66a09e68438bd2"
runtest "cgena.3.46.2.${domain}" "dbc80a3417981636741eb33c576ab61a"
runtest "cgena.4.46.2.${domain}" "a97a11a0094d417662f7e1a6fd3329a8"
runtest "cgena.5.46.2.${domain}" "a008fd76b9bc4385cef87af509095e08"
runtest "cgena.6.46.2.${domain}" "419d8e1bee7b8b1545fafb2450097ed8"
runtest "cgena.1.46.20.${domain}" "6966353072721a154b6a336760c3dcb7"
runtest "cgena.2.46.20.${domain}" "549bb5c2c32d4da2717d3a7861b1976d"
runtest "cgena.3.46.20.${domain}" "bd90291403be67234ad525372e1898d9"
runtest "cgena.4.46.20.${domain}" "d64e7f0ad0c5f46e383e53202370a826"
runtest "cgena.5.46.20.${domain}" "7a305889413bf1f16daa61cdf6af000d"
runtest "cgena.6.46.20.${domain}" "07723e17f4bef86122f3e4b1172458e4"
runtest "cgenb.1.${domain}" "d33691407563319077fe854dcb7c5380"
runtest "cgenb.2.${domain}" "c403ef763389d4523800cd6556e070e0"
runtest "cgenb.3.${domain}" "68ed4999b0bc232ef4493eadc1ed7d7c"
runtest "cgenb.4.${domain}" "c3746d505e1bebab7783e1cdec501bd4"
runtest "cgenb.5.${domain}" "e103aed14e560434bce735a035fa0787"
runtest "cgenb.6.${domain}" "fd749f8179889bef55954141658c944a"
runtest "cgenb.1.46.2.${domain}" "14f86f2a9a589d40e1178dac8e9ea719"
runtest "cgenb.2.46.2.${domain}" "2a41a7af59b2a28327d6ce3daa805d11"
runtest "cgenb.3.46.2.${domain}" "ae1010ea935f6915272159ca2d167a15"
runtest "cgenb.4.46.2.${domain}" "5af88e06e170d1254449e37a3859d5d6"
runtest "cgenb.5.46.2.${domain}" "01e892d555f4f6a603004e348a5276f1"
runtest "cgenb.6.46.2.${domain}" "9e403c1ffd5c91172b1f061d01b7ed9c"
runtest "cgenb.1.46.20.${domain}" "1224080487e889161c8c3123b7cf313e"
runtest "cgenb.2.46.20.${domain}" "5392e8cd7985998e0fd03819313c54ee"
runtest "cgenb.3.46.20.${domain}" "e0d66f55922ec4ee2ae9910816ac8ee9"
runtest "cgenb.4.46.20.${domain}" "64b6b56361dc344b676511a6eaf9dfbe"
runtest "cgenb.5.46.20.${domain}" "5a64122cb786894391c5afc661cd0d40"
runtest "cgenb.6.46.20.${domain}" "691b89b5ac86c74f1c24c20aa7698304"
runtest "cgenb.1.255.10.${domain}" "3faa158f0e9f756a4be7536fcfab823b"
runtest "cgenb.2.255.10.${domain}" "bad96729883a69c44698b868e8c5c800"
runtest "cgenb.3.39.10.${domain}" "dbcce138d6f37ad0fcca8527cc13bf8a"
runtest "cgenb.4.255.10.${domain}" "9bcbfdb1099faba485bf36e4c88824bb"
runtest "cgenb.5.255.10.${domain}" "e20acba70cda235ebb02948252caee24"
runtest "cgenb.6.255.10.${domain}" "22f064bf942d1be8d19b76f48dabf50f"
runtest "cgenb.1.0.10.${domain}" "2432c4649caf245158da098dcf1d53a1"
runtest "cgenb.2.0.10.${domain}" "f7ddba1cdcb31b8e7bd3bc47c7a7320a"
runtest "cgenb.3.0.10.${domain}" "1a17ebca4e04c811391c47f5777b46eb"
runtest "cgenb.4.0.10.${domain}" "ff0569bef6bce144b0e6eaf044abcb6c"
runtest "cgenb.5.0.10.${domain}" "868344c49c0fec71e23543ce8bff525d"
runtest "cgenb.6.0.10.${domain}" "426eb01e136a6043d29a13179c89ff1c"

runtest "dotcname.1.${domain}" "415588ba7f57e67844096cbd5f77dc01"
runtest "dotcname.2.${domain}" "74d57e24e1028707cfafd9ddfd387950"
runtest "dotcname.3.${domain}" "8ec4d2f00da8f2ca4831395228a0af0d"
runtest "dotcname.4.${domain}" "1489362d89a5fd66f25223ccd9f00853"
runtest "dotcname.5.${domain}" "b7c01afd0cf18fafb93aac9e33b5e15f"
runtest "dotcname.6.${domain}" "a76b671e913c603f576e8e57a11ec94e"
runtest "dotcname.7.${domain}" "f33f043ab0862a1a80a97fcbb589b9a2"

runtest "nonexistent.${domain}" "6b9a09d1428a3a0f31d7d2243aeb41ac"
runtest "nonexistent.noq.${domain}" "5b5bfcc4874cd03fcd806217b18f5333"
runtest "nonexistent.noq.qurr0.${domain}" "be9cbc836414b9820eb1c7b5455cdd5b"
runtest "nonexistent.qurr0.${domain}" "440aad2f6231f7c144449ce5582c5553"
runtest "nonexistent.com" "873136eebe43fe499d0ac597f9f6afaf"
runtest "something.nonexistent.com" "aef72e7e71144e5c66dbd660bc1a4663"
runtest "something.noq.nonexistent.com" "e992a0fa32144a8b38d457e3ffbe4492"
runtest "something.noq.qurr0.nonexistent.com" "6d7e9c8bf5eb60aaf18e1bf51f5659f2"
runtest "something.qurr0.nonexistent.com" "2e1622d2d559ee4020988e612dcd9d91"
runtest "nonexistent.tc.${domain}" "c36cb7d1dc4a7f1a3352dec9c2398fba"
runtest "nonexistent.tc.noq.${domain}" "f2228f4dd94f2e6070b733da940201fe"
runtest "nonexistent.tc.noq.qurr0.${domain}" "b9c0695408e887120940d3fdf2172df4"
runtest "nonexistent.tc.qurr0.${domain}" "92b126a4f178946faf9c6bc48d444c52"
runtest "tc.nonexistent.com" "cd9881a489746aca8829c50976269db1"
runtest "something.tc.nonexistent.com" "259ee95ee222deccb4643734a7e0230d"
runtest "something.tc.noq.nonexistent.com" "558743f631d6834a864015f5c7d7002a"
runtest "something.tc.noq.qurr0.nonexistent.com" "b54f4e322e03f79d1595c081a0ffdb14"
runtest "something.tc.qurr0.nonexistent.com" "0973b883bd75099e86e598fa601ef005"
runtest "+tcp nonexistent.${domain}" "f5be0cada23ae2170808356223f4b226"
runtest "+tcp nonexistent.noq.${domain}" "8834102893afa8a5b0ab3431a606cd12"
runtest "+tcp nonexistent.noq.qurr0.${domain}" "5bb4f2fec5890cdf6de4e5e7c07c787a"
runtest "+tcp nonexistent.qurr0.${domain}" "63dd59decc8e9e7c9440be7ac43bf4d4"
runtest "+tcp nonexistent.com" "45af965c0073060106200fa64662e254"
runtest "+tcp something.nonexistent.com" "717816fe14a5abce4a37d037d1fc1882"
runtest "+tcp something.noq.nonexistent.com" "dcbbcec4f3ea2ca8d47916d2acc7c1a0"
runtest "+tcp something.noq.qurr0.nonexistent.com" "38138c379c1e65acf15de9f73b2b7e57"
runtest "+tcp something.qurr0.nonexistent.com" "c7b7a3369ad2778ff3029553fb39a516"

runtest "always123.tc.${domain}" "0bd1f149a63b6c7ebaa90fe954c5836d"
runtest "chain123.tc.${domain}" "424a09be2aeeba10ea29abf25572d1e8"
runtest "dchain123.tc.${domain}" "a735591a7eae1563be166762f330994a"

runtest "cutabuf.${domain}" "602a68d207177ada35f896859aef5e64"
runtest "cutabuf.0.${domain}" "9815dd4cd51e7181224bc37992e127e8"
runtest "cutabuf.10.${domain}" "468857c2eef56aff5530f74700ceef66"
runtest "cutabuf.tc.${domain}" "1972d796dfa5adae20da9aadb7b719c5"
runtest "cutabuf.0.tc.${domain}" "a69c6c08a3f731fcef9214018ab40d90"
runtest "cutabuf.10.tc.${domain}" "1a57f4350cd9f474b73f69e8ac2747da"
runtest "+tcp cutabuf.${domain}" "c773439c853638658dd75b0e7e56b444"
runtest "+tcp cutabuf.0.${domain}" "5fe6274c00f5459bf8e0605fdf0359eb"
runtest "+tcp cutabuf.10.${domain}" "4b48cbdf251de563f97af298ba5bfbc8"
runtest "cutcnamebuf.${domain}" "3bef678b24bd67731842ccab71b5a27e"
runtest "cutcnamebuf.0.${domain}" "609202315fa845c6fc39b0d5be4d14df"
runtest "cutcnamebuf.10.${domain}" "91a16b19a56466d5039cd5173394d4aa"
runtest "cutcnamebuf.tc.${domain}" "d9eb9cc6447968028be361893632bcb6"
runtest "cutcnamebuf.0.tc.${domain}" "50ed6bfe8e671de9ff4213c24de14e55"
runtest "cutcnamebuf.10.tc.${domain}" "1a57f4350cd9f474b73f69e8ac2747da"
runtest "+tcp cutcnamebuf.${domain}" "3391c415e63a1b364e01168cf9bcd888"
runtest "+tcp cutcnamebuf.0.${domain}" "d97834bade1cb9417c8937627159b1d2"
runtest "+tcp cutcnamebuf.10.${domain}" "4b48cbdf251de563f97af298ba5bfbc8"

runtest "inj01.tc.${domain}" "a29cc934856dcc568da68bb883451fbc"
runtest "inj02.tc.${domain}" "8dded217217ecd74d9c8afed1a9a1037"
runtest "inj03.tc.${domain}" "e2577aada658eb27a78cfc2875302f53"
runtest "inj04.tc.${domain}" "d1225cde7f6da25f62f24e75f94d9141"
runtest "inj05.tc.${domain}" "4972a12cc352d72ddab7782319ee734b"
runtest "inj06.tc.${domain}" "6fe5cd7c001fe4ad7d476d46231eb528"
runtest "inj07.tc.${domain}" "cd26c8b2e522ffa265f3e65e37b3cdff"
runtest "inj08.tc.${domain}" "a708720000607b1779a01326d94280b9"
runtest "inj09.tc.${domain}" "83a13c5b012e7566acc5f4684d0cc52a"
runtest "inj10.tc.${domain}" "f4d6828e61030f24cb84dab74513012c"
runtest "inj11.tc.${domain}" "fe831b447e26724774dce7132e735172"
runtest "inj12.tc.${domain}" "492b7c051602d9e7b7e444f2ab5858b6"
runtest "inj13.tc.${domain}" "708b774d94fde6210cbd4f429dff2143"
runtest "inj01.3rdparty.tc.${domain}" "697daacc2873c88bb2f6243a349d6ad2"
runtest "inj02.3rdparty.tc.${domain}" "5256792da15694e8610c74680678b78d"
runtest "inj03.3rdparty.tc.${domain}" "88806b2eea9f925307a8a0fd5bd94658"
runtest "inj04.3rdparty.tc.${domain}" "cfe649f5c9282f8b9db8998a4661c3d3"
runtest "inj05.3rdparty.tc.${domain}" "72d961216732a635cd15432bbc931913"
runtest "inj06.3rdparty.tc.${domain}" "d8093896c9ceef4b31b3ee929cbc3889"
runtest "inj07.3rdparty.tc.${domain}" "525fbb53306eb568a07898165e93cff3"
runtest "inj08.3rdparty.tc.${domain}" "460be1c422e591233dcaea1565d8c428"
runtest "inj09.3rdparty.tc.${domain}" "bafaeb541786f414188ec2555305e1a1"
runtest "inj10.3rdparty.tc.${domain}" "a30cd95fb11e08a97cfb76940f644253"
runtest "inj11.3rdparty.tc.${domain}" "afd550b0aa2d771b83569a94334a5896"
runtest "inj12.3rdparty.tc.${domain}" "1aa53c657c1fe63da39035f63e06f1ea"
runtest "inj13.3rdparty.tc.${domain}" "7e4b8d67f4750fb58c15de21c5fd2f3e"
runtest "inj01.qurr0.noq.tc.${domain}" "d9c8a1a3ccee8f0c92b0581ddf24a02d"
runtest "inj02.qurr0.noq.tc.${domain}" "451eb6317f3d7d2d351ea0c0c2c0ba52"
runtest "inj03.qurr0.noq.tc.${domain}" "e030f7107df780ea06e136b8e048eb4a"
runtest "inj04.qurr0.noq.tc.${domain}" "06e19d90474a9eabbbe48e45732071ce"
runtest "inj05.qurr0.noq.tc.${domain}" "aa9a58181537b32e5473e4838cbfd3f9"
runtest "inj06.qurr0.noq.tc.${domain}" "e78f2dbd75da24341baa2ad00e521b04"
runtest "inj07.qurr0.noq.tc.${domain}" "0a3aaa2f9c95b9e3f44e04b03f5f66e1"
runtest "inj08.qurr0.noq.tc.${domain}" "f309caf7c79a05b8df3b467f91657b34"
runtest "inj09.qurr0.noq.tc.${domain}" "f390d384f3d765e3ec2760464cd7a28d"
runtest "inj11.qurr0.noq.tc.${domain}" "68b51f68a1e51921876f1691812d5d83"
runtest "inj12.qurr0.noq.tc.${domain}" "7543c4de6703c3ef1a9d6f205c57ab7e"
runtest "inj13.qurr0.noq.tc.${domain}" "182f17c8d51d9d0b5c6a659a02042283"
runtest "always123.anrr0.tc.${domain}" "c1c7e444332837238ff7d2d3db344529"
runtest "always123.aurr0.tc.${domain}" "7e97fb63c9bd088434bd47fc3aac36f3"
runtest "always123.adrr0.tc.${domain}" "dc23653983824427f7df9f5652e30bed"
runtest "always123.anrr3.tc.${domain}" "ee0f9d62c83b20423d5fbd451add17a7"
runtest "always123.aurr3.tc.${domain}" "b707af4f7b99e34300d749f597a8ebb4"
runtest "always123.adrr3.tc.${domain}" "99212d7b97eab8c72655497118ad90cf"
runtest "always123.ttl12345.tc.${domain}" "4107a0d099cae52754b44943bfd00aa4"
runtest "always123.ttl9999999.tc.${domain}" "8b1e49e99419aeecf05774d113da3820"
runtest "always123.tc.tc.${domain}" "060fa3509cdc905d3fa9b9871040432c"
runtest "always123.noq.tc.${domain}" "256994002e33d16b131b6fa00e507058"
runtest "always123.qurr0.tc.${domain}" "2356e3488a2471e1a09fa0078d6a03fa"
runtest "always123.qurr0.noq.tc.${domain}" "26c96aed349acc5817b5b009a79cc221"
runtest "always123.qurr3.tc.${domain}" "96eab67b98b8088d1988d500c9d6cc08"
runtest "+tcp ${domain} NS" "224e91e1e6dc0c8e3e23d2cd29213431"
runtest "+tcp ${domain} TXT" "f643f5aa8fdfa6ba99ad580a982f07c5"
runtest "+tcp ${domain} MX" "f7fc21fbda8cf09a05f6f96e8de2f73d"
runtest "+tcp always123.${domain}" "9af36d22f33e36a67ee53b68b1e3665b"
runtest "+tcp chain123.${domain}" "b712083dd40f0f3cf947f5af71672987"
runtest "+tcp dchain123.${domain}" "e0a7147c442f72ec5154b3bcb5da5878"
runtest "+tcp inj01.${domain}" "aa11b982cf8e317dbe3c86cac1d09c04"
runtest "+tcp inj02.${domain}" "f08a6dd7b6191e380f36ebc52c7626ed"
runtest "+tcp inj03.${domain}" "8593b6ba5683c1632c603a6898692911"
runtest "+tcp inj04.${domain}" "e04f3d0b855e9f01c14c3e5f440b7bfd"
runtest "+tcp inj05.${domain}" "2e89b8183839be6357bb50bfac4f4538"
runtest "+tcp inj06.${domain}" "02c29f7abf560668209d562fb8e15a77"
runtest "+tcp inj07.${domain}" "633dcdf41d5be84dbe381841b3456eb0"
runtest "+tcp inj08.${domain}" "1ebf80d57baa239d32ab5429ecd6a031"
runtest "+tcp inj09.${domain}" "234d6b89d5fccd661f5af45bfdf83b89"
runtest "+tcp inj10.${domain}" "904b6eb48249a5340a8cc9275e1f16f7"
runtest "+tcp inj11.${domain}" "f397a89e6e8c236c8f2bbe5b42f58c0b"
runtest "+tcp inj12.${domain}" "e1c723795ba64ed1fd6c5d1688c5327f"
runtest "+tcp inj13.${domain}" "f67783a5324d6c7af8e0c6d270e33576"
runtest "+tcp inj01.3rdparty.${domain}" "5e28bfef4eb00da279d3788d17431c5c"
runtest "+tcp inj02.3rdparty.${domain}" "33b97805a1277d142a3411007e26fbe2"
runtest "+tcp inj03.3rdparty.${domain}" "464235c1be0ef80fc9f39c5668b839f1"
runtest "+tcp inj04.3rdparty.${domain}" "54404aa7387c2b29c251b67a1f6b8ed2"
runtest "+tcp inj05.3rdparty.${domain}" "3101de61984b6e87badf2f84fdce1bdf"
runtest "+tcp inj06.3rdparty.${domain}" "dab7d62c2b7fc7f1d5e1366f8b9ab583"
runtest "+tcp inj07.3rdparty.${domain}" "102e5fbb2e1dd58fa02237cf58d049ea"
runtest "+tcp inj08.3rdparty.${domain}" "73b580c4bac4393c70c41c72c7369508"
runtest "+tcp inj09.3rdparty.${domain}" "30b6868ffe564a020548488ed3fb444e"
runtest "+tcp inj10.3rdparty.${domain}" "9ffc43875c1293780e5e1fcd7679e6bf"
runtest "+tcp inj11.3rdparty.${domain}" "3b059768ca1d5076fdea49717911a604"
runtest "+tcp inj12.3rdparty.${domain}" "9357e61223feea33c04b5115f7c6b1ac"
runtest "+tcp inj13.3rdparty.${domain}" "4f7f756c04d6fd2cb1bb586ec9a9b79b"
runtest "+tcp inj01.qurr0.noq.${domain}" "8debe9566621d0eac9f300e9913430b5"
runtest "+tcp inj02.qurr0.noq.${domain}" "815468012a7fdcbf6e76da619e2f4412"
runtest "+tcp inj03.qurr0.noq.${domain}" "b9adbaa61550c8cab8f63f40b3af693b"
runtest "+tcp inj04.qurr0.noq.${domain}" "ef7f08bc2d79d5783916f80b6d15f7bc"
runtest "+tcp inj05.qurr0.noq.${domain}" "92e64499a2bd10d8ea1fb02abfd58469"
runtest "+tcp inj06.qurr0.noq.${domain}" "0cc3812119c1b593bb479b9593ebadb1"
runtest "+tcp inj07.qurr0.noq.${domain}" "98e6bbeb073c26a341a15defa6bde1cd"
runtest "+tcp inj08.qurr0.noq.${domain}" "5f85588fe30fdb6176f25fe650d6c91b"
runtest "+tcp inj09.qurr0.noq.${domain}" "871ceb93b0c67fb363f79db0101d43f4"
runtest "+tcp inj11.qurr0.noq.${domain}" "2f3a05bae72e9c9962cd9cfe819a74b0"
runtest "+tcp inj12.qurr0.noq.${domain}" "6d40ea20a5736944f7c8e9c516bcc2a3"
runtest "+tcp inj13.qurr0.noq.${domain}" "840c8c86531fdc29831b056b0f05e8dd"
runtest "+tcp always123.anrr0.${domain}" "915929e8021b1c7149df6a1155f0172c"
runtest "+tcp always123.aurr0.${domain}" "2ee5ab659d501038f3e6350cc1e63672"
runtest "+tcp always123.adrr0.${domain}" "c3aa0007485f8ad7b3590f16f1158dbe"
runtest "+tcp always123.anrr3.${domain}" "ff1894af38df4df6380f7b7925fc323c"
runtest "+tcp always123.aurr3.${domain}" "10cdea2a30cc056053773d47ace03e5c"
runtest "+tcp always123.adrr3.${domain}" "d28b88f1e8655a0373676dd5e4d487ea"
runtest "+tcp always123.ttl12345.${domain}" "f628e256fee2ca5d6d9b7df9ce61fe29"
runtest "+tcp always123.ttl9999999.${domain}" "c394c71bd97e37cdb1f015534880984f"
runtest "+tcp always123.tc.${domain}" "63458d2a1a0eae1ec1d5e9a1868899fa"
runtest "+tcp always123.noq.${domain}" "93f308e0452d91bb1d6f244b6ab5af41"
runtest "+tcp always123.qurr0.${domain}" "9b38b6e234a9c00111931ac2ca9dc9c6"
runtest "+tcp always123.qurr0.noq.${domain}" "0ae017c36585fc19e56b3d6ce2ac55b7"
runtest "+tcp always123.qurr3.${domain}" "9266464bba77416ee71a9827733cc2ec"
runtest "${domain} NS" "cbde4fca020a9345459731a0149cc5b1"
runtest "${domain} TXT" "816d9b4b8d039df11b0d9b3414effff6"
runtest "${domain} MX" "508918c4fb499d55abe8d6f9e3b73900"
runtest "always123.${domain}" "38da4075b11e62b0473782ea144459be"
runtest "chain123.${domain}" "af14c76738cb2fea1cab8e07e01df018"
runtest "dchain123.${domain}" "188b343589d514d0400462214c95b0c8"
runtest "inj01.${domain}" "0c2071983b97bcc2d837a31b80116f83"
runtest "inj02.${domain}" "619439d41f0ea32f2da0c9389dacc576"
runtest "inj03.${domain}" "c64099d8fe54b82d8cc9a81a41eac048"
runtest "inj04.${domain}" "9aa697e9ace2bdbafeff9ae77df7ba91"
runtest "inj05.${domain}" "e0a97d49177594f62ce37b65209ff10e"
runtest "inj06.${domain}" "b72093f06bec5bd1a69d1346269ebb1e"
runtest "inj07.${domain}" "24943245224b2911c27aee3cd051ff3d"
runtest "inj08.${domain}" "2b5790eb8c5d1856e9fbdf69f36802e2"
runtest "inj09.${domain}" "360cb74690553936f1c6453ec4e29221"
runtest "inj10.${domain}" "3ec916216b0b4287324ae67323694241"
runtest "inj11.${domain}" "93cfb91bbbfed71f1a58687411d76095"
runtest "inj12.${domain}" "e6f7123ef462e6f83d47650448f2bb0a"
runtest "inj13.${domain}" "9c9e65fa4ea9e0a192a738046966d31d"
runtest "inj01.3rdparty.${domain}" "0233a706929d686ed806ce31c988467a"
runtest "inj02.3rdparty.${domain}" "6628f92ce74d43f4c0e041c395bf83b8"
runtest "inj03.3rdparty.${domain}" "575fc08d03bc2d7b67c5d70d888249d6"
runtest "inj04.3rdparty.${domain}" "c48c1a850f6eb1e53fbd80d1a849fba7"
runtest "inj05.3rdparty.${domain}" "9462d340d4e93b5e1fc79bc87c0ebfd9"
runtest "inj06.3rdparty.${domain}" "18295ae98885e2e3ee08c74337443ae8"
runtest "inj07.3rdparty.${domain}" "8ee9b70f53cb6367176e17999a6189db"
runtest "inj08.3rdparty.${domain}" "54aae87719b84d6b6ba6c7e2f107df7f"
runtest "inj09.3rdparty.${domain}" "b520e793d809ffb3d0ccafa0a0a5e672"
runtest "inj10.3rdparty.${domain}" "5159b59e8ea7f1fedf94bf5dac734af6"
runtest "inj11.3rdparty.${domain}" "89f99c358bd7d93dfbaa63ccc9a13898"
runtest "inj12.3rdparty.${domain}" "ca92f3fc59c0a219dea7ec8631aa2fb7"
runtest "inj13.3rdparty.${domain}" "5c715cafd5e6eb94241a671035cd08dd"
runtest "inj01.qurr0.noq.${domain}" "320a2e69ff5f589b96f1f8c9e69ff4e4"
runtest "inj02.qurr0.noq.${domain}" "b56ba3b199c2b0fe2d270b813421e3b2"
runtest "inj03.qurr0.noq.${domain}" "f8e347dd6d51b19f957ea37ca325187b"
runtest "inj04.qurr0.noq.${domain}" "cbefe876f734fc84f400634ee8ccfe39"
runtest "inj05.qurr0.noq.${domain}" "3f1ffb6c5d890e05afa207b88f6eedb2"
runtest "inj06.qurr0.noq.${domain}" "8a0ded4baae6d29ed342a3bfbbf8815d"
runtest "inj07.qurr0.noq.${domain}" "d3027e9f2ca8cd3930e652d9271587e9"
runtest "inj08.qurr0.noq.${domain}" "5ef5c48bedfb8d3c391acf87414af6c6"
runtest "inj09.qurr0.noq.${domain}" "4e1128767bb94dfae344ed91c95ce106"
runtest "inj11.qurr0.noq.${domain}" "b669a1f0d9dcdaf0e3233c29dd925032"
runtest "inj12.qurr0.noq.${domain}" "2c4a75d0041e84148403273ebba2e34c"
runtest "inj13.qurr0.noq.${domain}" "4f095cd38a21f82bbaecc126181b00d5"
runtest "always123.anrr0.${domain}" "6470758a399e59687d3e5039f00e10f8"
runtest "always123.aurr0.${domain}" "6a6998d796be2261b69e822718151b90"
runtest "always123.adrr0.${domain}" "bef379722872594dafb295a876a3faea"
runtest "always123.anrr3.${domain}" "d7d00b6e80d4a23c8549287ed4610364"
runtest "always123.aurr3.${domain}" "bb78cd21a6a7eada8a7dc6cb68e9b9a5"
runtest "always123.adrr3.${domain}" "b9604796e48567d0b66374512b207c52"
runtest "always123.ttl12345.${domain}" "04496562e6fe0159d7a9af961736b8f5"
runtest "always123.ttl9999999.${domain}" "f0d35809e65755f7c78091a8f8b59786"
runtest "always123.tc.${domain}" "0bd1f149a63b6c7ebaa90fe954c5836d"
runtest "always123.noq.${domain}" "0218131c8635ba393a74ebec112d9f8c"
runtest "always123.qurr0.${domain}" "fd496813bed57eeee013bc859b6f32d8"
runtest "always123.qurr0.noq.${domain}" "9f1491ebd4dbdda8cc0c6d71b679bc3b"
runtest "always123.qurr3.${domain}" "16477486e5f45f4db023d40f742206ea"
runtest "always123.newid.${domain}" "fb41ffb8a1d54f86d65748bc0df1e135"
runtest "inj01.addq.${domain}" "ad1c5ade6c80c4cd70afdc4ba58be6d2"
runtest "inj02.addq.${domain}" "1299a66b4da9c55590edc86c02accdc8"
runtest "inj03.addq.${domain}" "d4cf578332cdc78c2c70a6c7b49de5ec"
runtest "inj04.addq.${domain}" "9a1444c88cc704b5fcb0f85ca95bf31a"
runtest "inj05.addq.${domain}" "09377ca32be565aa392842e98b975ade"
runtest "inj06.addq.${domain}" "c8b6743ce322339980f01e81dccb0d58"
runtest "inj07.addq.${domain}" "d911d2432d7e8bbc10c4a4c81c66b929"
runtest "inj08.addq.${domain}" "239b140df2a42bbdb4250b1e46475a3a"
runtest "inj09.addq.${domain}" "833b3354ad67c6306e6e0145e67b0d03"
runtest "inj10.addq.${domain}" "45fecb93cf976d2e71942d0c379ef7ca"
runtest "inj11.addq.${domain}" "4a1b179b292a61ab4d45328255977a2c"
runtest "inj12.addq.${domain}" "45fecb93cf976d2e71942d0c379ef7ca"
runtest "inj13.addq.${domain}" "4a1b179b292a61ab4d45328255977a2c"
runtest "inj01.replq.${domain}" "33db40ddafa4be3c79db7cd6dee37549"
runtest "inj02.replq.${domain}" "90d6af9e4822e55f96f391bc23b2934e"
runtest "inj03.replq.${domain}" "09a6f94a841bdc2ecdb19c905856e547"
runtest "inj04.replq.${domain}" "c96263e35a9a022d37d70bb4f3e30c06"
runtest "inj05.replq.${domain}" "cba4895c38836e2022a3dabbe4f9e787"
runtest "inj06.replq.${domain}" "47c21677848cb71b9c1c3b164e49e48e"
runtest "inj07.replq.${domain}" "74e4563e21868bee8894873f70e56056"
runtest "inj08.replq.${domain}" "fb2d49b9e184c0767515e3a86117c572"
runtest "inj09.replq.${domain}" "c6c05bdc45cdb9b639ea43b107b045c0"
runtest "inj10.replq.${domain}" "da2f80983531ae73d76f37f3ca5b8cc9"
runtest "inj11.replq.${domain}" "e29435ba118b222973421d89e064a82e"
runtest "inj12.replq.${domain}" "da2f80983531ae73d76f37f3ca5b8cc9"
runtest "inj13.replq.${domain}" "e29435ba118b222973421d89e064a82e"
runtest "close.${domain}" "7fa9178ec0e6fd5c809bb2a00fbe6e81"
runtest "empty1.${domain}" "bcb6a2f9baa932bbaab2cdcc1d76a2d5"
runtest "empty2.${domain}" "bcb6a2f9baa932bbaab2cdcc1d76a2d5"
runtest "empty2.65500.${domain}" "69690434fcdc96e4083c718fe0027d22"
runtest "empty3.${domain}" "bcb6a2f9baa932bbaab2cdcc1d76a2d5"
runtest "empty3.65500.${domain}" "69690434fcdc96e4083c718fe0027d22"
runtest "empty4.${domain}" "bcb6a2f9baa932bbaab2cdcc1d76a2d5"
runtest "empty4.65500.${domain}" "6c14c2a4ebf796dfdae915d5c96f8a19"
runtest "close.tc.${domain}" "1a57f4350cd9f474b73f69e8ac2747da"
runtest "empty1.tc.${domain}" "1a57f4350cd9f474b73f69e8ac2747da"
runtest "empty2.tc.${domain}" "1a57f4350cd9f474b73f69e8ac2747da"
runtest "empty2.65500.tc.${domain}" "4f3a3422ddb6fcaafa1f8afaf48032f5"
runtest "empty3.tc.${domain}" "4f3a3422ddb6fcaafa1f8afaf48032f5"
runtest "empty3.65500.tc.${domain}" "f50693934eac610c16cb0fe0231fa363"
runtest "empty4.tc.${domain}" "4f3a3422ddb6fcaafa1f8afaf48032f5"
runtest "empty4.65500.tc.${domain}" "6f5ce2ff130d19a481b0bf2e8220aabb"
runtest "+tcp close.${domain}" "4b48cbdf251de563f97af298ba5bfbc8"
runtest "+tcp empty1.${domain}" "4b48cbdf251de563f97af298ba5bfbc8"
runtest "+tcp empty2.${domain}" "4b48cbdf251de563f97af298ba5bfbc8"
runtest "+tcp empty2.65500.${domain}" "725e3a59a45d67ed5dae46c7b76ce842"
runtest "+tcp empty3.${domain}" "725e3a59a45d67ed5dae46c7b76ce842"
runtest "+tcp empty3.65500.${domain}" "30ce19487e5e9e588a18ecef9b142ec8"
runtest "+tcp empty4.${domain}" "725e3a59a45d67ed5dae46c7b76ce842"
runtest "+tcp empty4.65500.${domain}" "d6b8bc731f7d8b9ef2f34b94f330b720"
runtest "+tcp empty2.10.len50.${domain}" "725e3a59a45d67ed5dae46c7b76ce842"
runtest "+tcp empty2.50.len50.${domain}" "725e3a59a45d67ed5dae46c7b76ce842"
runtest "+tcp empty2.50.len5.${domain}" "725e3a59a45d67ed5dae46c7b76ce842"
runtest "empty4.0.len200.tc.${domain}" "1a57f4350cd9f474b73f69e8ac2747da"
runtest "empty4.10.len200.tc.${domain}" "1a57f4350cd9f474b73f69e8ac2747da"
runtest "empty4.1000.len200.tc.${domain}" "6f5ce2ff130d19a481b0bf2e8220aabb"
runtest "empty5.${domain}" "662021c5f44742f3f4bba3b4ceb64df0"
runtest "empty5.0.${domain}" "afad2d4f3a29e8c4b3f8d2bc0c5f93c2"
runtest "empty5.10.${domain}" "ba9e8265f80bdb05878c8fa41ffa1ad9"
runtest "empty6.${domain}" "19b5f56687b167e29c5056f89cfd7cb9"
runtest "chunkedcnames.20.slp10.${domain}" "790d58da7fc632d5dfe0144e83e6c10a"

echo
echo "TESTS: ${testcount}"
echo " PASS: ${passcount}"
echo " FAIL: ${failcount}"
