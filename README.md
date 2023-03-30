# 简介

更多的介绍，请先参看原库的“简介”。原库用 Github Actions，每天定时自动执行，生成 geosite.dat。

此 Fork 库，介绍如何在本地的 Ubuntu/MacOS 等系统里，用 Bash 脚本，自定义生成 geosite.dat。

## Shell 脚本

### 1. gen_community_data.sh

功能：生成数据文件到 ./community/data/ 目录。

说明：

(1) ./custom-txt/ 目录: 6个文件名的作用，请看原库简介里的 “可添加自定义直连、代理和广告域名”、“可移除自定义直连、代理和广告域名”。

    比如，sensorsdata.cn 不想被当成广告网站，就可以增加 sensorsdata.cn 到
     ./custom-txt/reject-need-to-remove.txt，就不会被加到：geosite:category-ads-all

    又比如，假如你的 DNS forwarder 会根据 geosite.dat 来进行国内国际分流解析，
    某网站不想被当成 cn 的网站来用国内普通 DNS 的解析(因为可能会被DNS 污染)，
    而想进行国际加密 DNS 的解析。那么可把该网站增加到 ./custom-txt/direct-need-to-remove.txt，
    就不会被加到：geosite:cn

(2) Ubuntu 和 MacOS 的 sort 的结果不一样。第 0 步（Prepare），会把 ./custom-txt/ 里的文件，都用当前 OS 里的 sort 进行排序，然后输出到 ./ 目录，供后续步骤使用。

(3) 每个步骤，都会 pause，以便查看结果是否有异常（比如，网络异常，导致下载失败之类的问题），按回车键可继续。 

(4) 若在外，网络顺畅，可在 pause 函数体的第一行，最前面增加 # 这个符号，注释掉。

(5) 若在内，在执行脚本之前，先要解决顺畅上网的问题。比如，类似这样：export https_proxy=http://localhost:7890

(6) ./gfwlist2dnsmasq/gfwlist2dnsmasq.sh: 

    该脚本在 Ubuntu 下运行正常，但在 MacOS 下有点小问题。

    若在 MacOS 下运行，第 6 步执行完后 pause，需修改 gfwlist2dnsmasq.sh 中的一行，增加一个小于号：
    $BASE64_DECODE $BASE64_FILE 改为：$BASE64_DECODE < $BASE64_FILE
    再按回车键执行第 7 步。


### 2. build_geosite_dat.sh

功能：生成 geosite.dat 文件

说明：

(1) 可参考 https://www.runoob.com/go/go-environment.html 下载、解压、设置环境变量。只需三步，安装好 Go 语言编译环境。

(2) 运行它，会根据以上的 ./community/data/ 目录的数据文件，生成 geosite.dat 文件，位于 ./custom/publish/ 目录下，约 5 MB

(3) 可根据需要，裁减 ./community/data/ 下的数据文件。

    比如，若仅需 geosite:category-ads-all, geosite:cn, geosite:geolocation-!cn，
    那么 ./community/data/ 目录下，只需保留 category-ads-all, cn, geolocation-!cn，
    其他文件可删除 (建议将 data 目录所有文件，先备份一下，再删)，
    再执行脚本，生成的 geosite.dat 约 3 MB。 

    注意：若裁减不当，可能造成 go 程序一直占用大量 CPU、内存，无法正常生成 geosite.dat，
    可将备份的 data 目录恢复回来，再尝试裁减。

(4) 在云端小内存的 Ubuntu（比如 1 GB）下运行，若 data 目录下的数据文件多，在 go 程序运行过程中，可关注内存是否耗尽。

    若内存不足，可减少数据文件，或者适当增加内存，或者用 scp 把云端 ubuntu 的
    ./community/data/ 下载到本地 MacOS 、在本地执行 build_geosite_dat.sh

