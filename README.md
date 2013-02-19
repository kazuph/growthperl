# GrowthPerl
## install app
```
$ git clone https://github.com/kazuph/GrowthPerl.git
$ cd GrowthPerl
$ sudo yum groupinstall "Development Tools"
$ curl -L http://cpanmin.us | perl - --sudo App::cpanminus
$ ./bin/install_cpan.sh
$ ./bin/postinstall
```
## run application
### for development
```
$ perl -Mlib=extlib/lib/perl5 extlib/bin/plackup -s Starman app.psgi
or
$ ./bin/run_server_for_development.sh
```

### for development
```
$ perl -Mlib=extlib/lib/perl5 extlib/bin/plackup -s Starman -E deployment --preload-app --disable-keepalive --workers 10 app.psgi
```

## supervisor
### install
```
# yum install python-setuptools
# easy_install pip
# pip install supervisor
```

### make directory
```
# mkdir /var/log/supervisor
# mkdir /etc/supervisord.d
# mkdir /var/log/GrowthPerl
```

### set config
```
# cp -p /home/homepage/GrowthPerl/etc/supervisord.conf /etc/supervisord.conf
```

### set initctl
```
# vi /etc/init/supervisord.conf
# cat /etc/init/supervisord.conf
description "supervisord"

start on runlevel [2345]
stop on runlevel [!2345]

respawn
exec /usr/bin/supervisord -n
```

### start supervisor
```
# initctl start supervisord
```

## nginx
### install
```
# rpm -ivh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
# yum install nginx
```

### set config
```
# cd /etc/nginx
# cp nginx.conf nginx.conf.org
# cp /home/homepage/GrowthPerl/config/nginx/nginx.conf nginx.conf
# cp /home/homepage/GrowthPerl/config/nginx/perlpad.conf conf.d/
```

## make directory
```
mkdir /var/log/GrowthPerl/nginx
```

### start nginx
```
# chkconfig nginx on
# service nginx start
```

## set problem text
```
cd config/problems/
ln -s problem_sample.yml problem.yml
```
