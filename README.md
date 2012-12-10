# PerlPad

## install app
```
$ sudo yum groupinstall "Development Tools"
$ curl -L http://cpanmin.us | perl - --sudo App::cpanminus
$ ./install_cpan.sh
$ ./postinstall
# run
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
# mkdir /var/log/PerlPad
```

### set config
```
# cp -p /home/homepage/PerlPad/etc/supervisord.conf /etc/supervisord.conf
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
# cp /home/homepage/PerlPad/config/nginx/nginx.conf nginx.conf
# cp /home/homepage/PerlPad/config/nginx/perlpad.conf conf.d/
```

## make directory
```
mkdir /var/log/PerlPad/nginx
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

## TODO
* add user_name to db.
* make only one page in user page.
