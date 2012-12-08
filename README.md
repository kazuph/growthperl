## PerlPad
### install app
```
$ sudo yum groupinstall "Development Tools"
$ curl -L http://cpanmin.us | perl - --sudo App::cpanminus
$ ./install_cpan.sh
```

### install supervisor
```
# yum install python-setuptools
# easy_install pip
# pip install supervisor

# mkdir /var/log/supervisor
# mkdir /etc/supervisord.d

# cp -p /home/homepage/PerlPad/etc/supervisord.conf /etc/supervisord.conf
# mkdir /var/log/PerlPad
```
### start supervisor
```
# vi /etc/init/supervisord.conf

description "supervisord"

start on runlevel [2345]
stop on runlevel [!2345]

respawn
exec /usr/bin/supervisord -n

# initctl start supervisord
```

