#!/usr/bin/env bash

export CHINA_DOMAINS_URL=https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
export GOOGLE_DOMAINS_URL=https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf
export APPLE_DOMAINS_URL=https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf
export GREATFIRE_DOMAINS_URL=https://raw.githubusercontent.com/Loyalsoldier/cn-blocked-domain/release/domains.txt
export EASYLISTCHINA_EASYLIST_REJECT_URL=https://easylist-downloads.adblockplus.org/easylistchina+easylist.txt
export PETERLOWE_REJECT_URL="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext"
export ADGUARD_DNS_REJECT_URL=https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
export DANPOLLOCK_REJECT_URL=https://someonewhocares.org/hosts/hosts
export CUSTOM_DIRECT=https://raw.githubusercontent.com/Loyalsoldier/domain-list-custom/release/cn.txt
export CUSTOM_PROXY="https://raw.githubusercontent.com/Loyalsoldier/domain-list-custom/release/geolocation-!cn.txt"
export WIN_SPY=https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
export WIN_UPDATE=https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/update.txt
export WIN_EXTRA=https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/extra.txt

function pause(){
    read -s -n 1 -p "Press any key to continue . . ."
    echo ""
}

echo 0. Prepare

rm -f apple-cn.txt google-cn.txt gfw.txt greatfire.txt direct-list* proxy-list* reject-list* *-tld-list.txt temp-*.txt win-*.txt *-reserve.txt *-need-to-remove.txt proxy.txt direct.txt reject.txt
rm -f geoip.dat
rm -rf custom community gfwlist2dnsmasq

cd custom-txt
ls -1 | xargs -I {} bash -c 'sort {} > ../{}'
cd ..

echo 1. Checkout the "hidden" branch of this repo
#git checkout hidden

echo 2. Checkout Loyalsoldier/domain-list-custom
git clone https://github.com/Loyalsoldier/domain-list-custom custom

echo 3. Checkout v2fly/domain-list-community
git clone https://github.com/v2fly/domain-list-community community

echo 4. Checkout cokebar/gfwlist2dnsmasq
git clone https://github.com/cokebar/gfwlist2dnsmasq gfwlist2dnsmasq

echo 5. Setup Go
echo ...
go version

echo 6. Get geoip.dat relative files
wget https://github.com/Loyalsoldier/geoip/raw/release/geoip.dat

echo 7. Generate GFWList domains
pause
cd gfwlist2dnsmasq || exit 1
chmod +x ./gfwlist2dnsmasq.sh
./gfwlist2dnsmasq.sh -l -o ./temp-gfwlist.txt
cd ..

echo 8. Get and add direct domains into temp-direct.txt file
pause
curl -sSL "$CHINA_DOMAINS_URL" | perl -ne '/^server=\/([^\/]+)\// && print "$1\n"' > temp-direct.txt
curl -sSL "$CUSTOM_DIRECT" | perl -ne '/^(domain):([^:]+)(\n$|:@.+)/ && print "$2\n"' >> temp-direct.txt

echo 9. Get and add proxy domains into temp-proxy.txt file
pause
cat ./gfwlist2dnsmasq/temp-gfwlist.txt | perl -ne '/^((?=^.{3,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})+)/ && print "$1\n"' > temp-proxy.txt
curl -sSL "$GREATFIRE_DOMAINS_URL" | perl -ne '/^((?=^.{3,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})+)/ && print "$1\n"' >> temp-proxy.txt
curl -sSL "$GOOGLE_DOMAINS_URL" | perl -ne '/^server=\/([^\/]+)\// && print "$1\n"' >> temp-proxy.txt
curl -sSL "$APPLE_DOMAINS_URL" | perl -ne '/^server=\/([^\/]+)\// && print "$1\n"' >> temp-proxy.txt
curl -sSL "$CUSTOM_PROXY" | grep -Ev ":@cn" | perl -ne '/^(domain):([^:]+)(\n$|:@.+)/ && print "$2\n"' >> temp-proxy.txt

echo 10. Get and add reject domains into temp-reject.txt file
pause
curl -sSL $EASYLISTCHINA_EASYLIST_REJECT_URL | perl -ne '/^\|\|([-_0-9a-zA-Z]+(\.[-_0-9a-zA-Z]+){1,64})\^$/ && print "$1\n"' | perl -ne 'print if not /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/' > temp-reject.txt
curl -sSL $ADGUARD_DNS_REJECT_URL | perl -ne '/^\|\|([-_0-9a-zA-Z]+(\.[-_0-9a-zA-Z]+){1,64})\^$/ && print "$1\n"' | perl -ne 'print if not /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/' >> temp-reject.txt
curl -sSL $PETERLOWE_REJECT_URL | perl -ne '/^127\.0\.0\.1\s([-_0-9a-zA-Z]+(\.[-_0-9a-zA-Z]+){1,64})$/ && print "$1\n"' >> temp-reject.txt
curl -sSL $DANPOLLOCK_REJECT_URL | perl -ne '/^127\.0\.0\.1\s([-_0-9a-zA-Z]+(\.[-_0-9a-zA-Z]+){1,64})/ && print "$1\n"' | sed '1d' >> temp-reject.txt

echo 11. Reserve full, regexp and keyword type of rules from custom lists to "reserve" files
pause
curl -sSL $CUSTOM_DIRECT | perl -ne '/^((full|regexp|keyword):[^:]+)(\n$|:@.+)/ && print "$1\n"' | sort --ignore-case -u > direct-reserve.txt
curl -sSL $CUSTOM_PROXY | grep -Ev ":@cn" | perl -ne '/^((full|regexp|keyword):[^:]+)(\n$|:@.+)/ && print "$1\n"' | sort --ignore-case -u > proxy-reserve.txt

echo 12. Add proxy, direct and reject domains from "hidden" branch to appropriate temp files
pause
cat proxy.txt >> temp-proxy.txt
cat direct.txt >> temp-direct.txt
cat reject.txt >> temp-reject.txt

echo 13. Sort and generate redundant lists
pause
cat temp-proxy.txt | sort --ignore-case -u > proxy-list-with-redundant
cat temp-direct.txt | sort --ignore-case -u > direct-list-with-redundant
cat temp-reject.txt | sort --ignore-case -u > reject-list-with-redundant

echo 14. Remove redundant domains
pause
chmod +x findRedundantDomain.py
./findRedundantDomain.py ./direct-list-with-redundant ./direct-list-deleted-unsort
./findRedundantDomain.py ./proxy-list-with-redundant ./proxy-list-deleted-unsort
./findRedundantDomain.py ./reject-list-with-redundant ./reject-list-deleted-unsort
[ ! -f "direct-list-deleted-unsort" ] && touch direct-list-deleted-unsort
[ ! -f "proxy-list-deleted-unsort" ] && touch proxy-list-deleted-unsort
[ ! -f "reject-list-deleted-unsort" ] && touch reject-list-deleted-unsort
sort ./direct-list-deleted-unsort > ./direct-list-deleted-sort
sort ./proxy-list-deleted-unsort > ./proxy-list-deleted-sort
sort ./reject-list-deleted-unsort > ./reject-list-deleted-sort

# comm -1 -3 b.txt a.txt > new_a.txt  的作用是： 在a文件中，删除b文件里的相同的行（前提是 a.txt 和 b.txt 都是 sort 过的）
comm -1 -3 ./direct-list-deleted-sort ./direct-list-with-redundant > ./direct-list-without-redundant
comm -1 -3 ./proxy-list-deleted-sort ./proxy-list-with-redundant > ./proxy-list-without-redundant
comm -1 -3 ./reject-list-deleted-sort ./reject-list-with-redundant > ./reject-list-without-redundant

echo 15. Remove domains from "need-to-remove" lists in "hidden" branch
pause
comm -1 -3 ./direct-need-to-remove.txt ./direct-list-without-redundant > temp-cn.txt
comm -1 -3 ./proxy-need-to-remove.txt ./proxy-list-without-redundant  > temp-geolocation-\!cn.txt
comm -1 -3 ./reject-need-to-remove.txt ./reject-list-without-redundant > temp-category-ads-all.txt

echo 16. Remove domains end with ".cn" in "temp-geolocation-!cn.txt" and write lists to data directory
pause
cat temp-cn.txt | sort --ignore-case -u | perl -ne '/^((?=^.{1,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})*)/ && print "$1\n"' > ./community/data/cn
cat temp-cn.txt | sort --ignore-case -u | perl -ne 'print if not /^((?=^.{3,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})+)/' > direct-tld-list.txt
cat temp-geolocation-\!cn.txt | sort --ignore-case -u | perl -ne '/^((?=^.{1,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})*)/ && print "$1\n"' | perl -ne 'print if not /\.cn$/' > ./community/data/geolocation-\!cn
cat temp-geolocation-\!cn.txt | sort --ignore-case -u | perl -ne 'print if not /^((?=^.{3,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})+)/' > proxy-tld-list.txt
cat temp-category-ads-all.txt | sort --ignore-case -u | perl -ne '/^((?=^.{1,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})*)/ && print "$1\n"' > ./community/data/category-ads-all
cat temp-category-ads-all.txt | sort --ignore-case -u | perl -ne 'print if not /^((?=^.{3,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})+)/' > reject-tld-list.txt

echo 17. Add full, regexp and keyword type of rules back into "cn", "geolocation-!cn" and "category-ads-all" list
pause
[ -f "direct-reserve.txt" ] && cat direct-reserve.txt >> ./community/data/cn
[ -f "proxy-reserve.txt" ] && cat proxy-reserve.txt >> ./community/data/geolocation-\!cn
[ -f "reject-reserve.txt" ] && cat reject-reserve.txt >> ./community/data/category-ads-all

#cp ./community/data/cn direct-list.txt
#cp ./community/data/geolocation-\!cn proxy-list.txt
#cp ./community/data/category-ads-all reject-list.txt

echo 18. Create google-cn、apple-cn、gfw、greatfire lists
pause
curl -sSL $GOOGLE_DOMAINS_URL | perl -ne '/^server=\/([^\/]+)\// && print "full:$1\n"' > ./community/data/google-cn
curl -sSL $APPLE_DOMAINS_URL | perl -ne '/^server=\/([^\/]+)\// && print "full:$1\n"' > ./community/data/apple-cn
cat ./gfwlist2dnsmasq/temp-gfwlist.txt | perl -ne '/^((?=^.{3,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})+)/ && print "$1\n"' >> ./community/data/gfw
curl -sSL $GREATFIRE_DOMAINS_URL | perl -ne '/^((?=^.{3,255})[a-zA-Z0-9][-_a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-_a-zA-Z0-9]{0,62})+)/ && print "$1\n"' >> ./community/data/greatfire
curl -sSL $WIN_SPY | grep "0.0.0.0" | awk '{print $2}' > ./community/data/win-spy
curl -sSL $WIN_UPDATE | grep "0.0.0.0" | awk '{print $2}' > ./community/data/win-update
curl -sSL $WIN_EXTRA | grep "0.0.0.0" | awk '{print $2}' > ./community/data/win-extra

#cp ./community/data/google-cn google-cn.txt
#cp ./community/data/apple-cn apple-cn.txt
#cat ./community/data/gfw | sort --ignore-case -u > gfw.txt
#cat ./community/data/greatfire | sort --ignore-case -u > greatfire.txt
#cp ./community/data/win-spy win-spy.txt
#cp ./community/data/win-update  win-update.txt
#cp ./community/data/win-extra win-extra.txt

