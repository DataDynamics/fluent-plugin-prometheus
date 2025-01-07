# fluent-plugin-prometheus

이 플러그인은 fluentd의 out 플러그인으로써 Prometheus의 Push Gateway에 Metric을 전송하는 플러그인입니다.

## Requirement

개발시 macOS 또는 Linux를 권장합니다. 윈도 환경에서는 빌드 환경을 구성하는데 많은 어려움이 있습니다.

* Ruby 3.2.6
* Fluent 1.16.6

Fluent 5.0.5 버전은 Ruby 3.2.6 버전이 내장되어 있습니다.

## Fluent Installation

이 플러그인을 테스트하기 위해서는 Fluent가 필요하므로 OS에 맞는 버전을 설치하도록 합니다.

### Linux

Fluentd를 Linux 환경에서 구성하기 위해서는 설치전 커널 파라미터 등의 변경이 필요합니다. 자세한 사항은 [Fluentd > Before Installation](https://docs.fluentd.org/installation/before-install)을 참고하십시오.

`/etc/security/limits.conf` 파일을 다음과 같이 수정하도록 합니다.

```
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
```

CentOS/RHEL 환경에서 `systemd`로 실행하는 경우 `LimitNOFILE=65536` 환경변수로 설정할 수도 있습니다. 기본값으로 65536으로 설정되어 있으며 `systemd` 설정 파일은 `/usr/lib/systemd/system/fluentd.service` 파일에서 확인할 수 있습니다.

또한 `/etc/sysctl.conf` 파일을 수정하여 네트워크 관련 커널 파라미터를 조정하도록 합니다. 즉시 적용은 `sysctl -p` 커맨드를 실행하도록 합니다.

```
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535
# If forward uses port 24224, reserve that port number for use as an ephemeral port.
# If another port, e.g., monitor_agent uses port 24220, add a comma-separated list of port numbers.
# net.ipv4.ip_local_reserved_ports = 24220,24224
net.ipv4.ip_local_reserved_ports = 24224
```

Fluent가 5.0.4 버전 이후로는 RHEL 7/CentOS 7을 더이상 지원하지 않습니다. 따라서 신규 설치는 RHEL 8 이상 버전을 사용하도록 합니다.

Fluent를 설치하려면 https://www.fluentd.org/download/fluent_package 경로에서 OS에 맞는 버전을 다운로드하여 설치할 수 있으며 이 플러그인을 개발하는 시점에서는 [Fluent 5.0.5 버전](https://s3.amazonaws.com/packages.treasuredata.com/lts/5/redhat/8/x86_64/fluent-package-5.0.5-1.el8.x86_64.rpm)을 사용하였습니다.

## Fluent Plugin 개발 환경 구성

Fluent Plugin을 개발하기 위해서는 다음의 조건을 충족시켜야 하며, Ruby의 경우 `rbenv`를 통해 수동 빌드하여 버전을 설치할 수 있습니다.

* Ruby 3.2.6
* Fluent 1.16.6

### macOS & Linux

macOS에서는 Ruby 설치를 위해서 다음의 커맨드를 실행할 수 있습니다.

```
# brew install rbenv ruby-build
# eval "$(rbenv init -)"
# rbenv install 3.2.6
# rbenv global 3.2.6
# ruby --version
# gem install fluentd -v '1.16.6'
# gem install rufus-scheduler
# gem update --system 3.6.2
# gem --version
```

RHEL 등의 환경에서는 다음의 커맨드를 실행할 수 있습니다.

```
# brew install rbenv ruby-build
# eval "$(rbenv init -)"
# rbenv install 3.2.6
# rbenv global 3.2.6
# ruby --version
# gem install fluentd -v '1.16.6'
# gem install rufus-scheduler
# gem update --system 3.6.2
# gem --version
```

### Windows

윈도의 경우 설치가 매우 까다롭고 Fluent Plugin 개발시 단위 테스트를 하는데 있어서 개발 환경을 구성하기가 어려우므로 될 수 있으면 macOS, Linux 환경에서 개발을 권장합니다.

```
# MSYS2 and MINGW development toolchain 선택
ridk install
ridk enable
```

## Fluent Plugin Installation

```bash
$ cd <PLUGIN_HOME>
$ /opt/fluent/bin/gem build fluent-plugin-prometheus.gemspec
$ /opt/fluent/bin/gem install fluent-plugin-prometheus-0.1.0.gem
$ ls -lsa /opt/fluent/lib/ruby/gems/3.2.0/gems
```