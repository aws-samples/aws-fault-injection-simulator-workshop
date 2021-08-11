#!/bin/bash -xe
# Run system updates
yum update -y
yum update -y aws-cfn-bootstrap
yum update -y aws-cli
yum install -y jq
/opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource LaunchConfig --region ${AWS::Region}

# Install NGINX 1.12
amazon-linux-extras install nginx1.12
# Install PHP 7.2
amazon-linux-extras install php7.2
# Update php-fpm config
mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.orig
cat >/etc/php-fpm.d/www.conf <<"EOF"
[www]
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
listen.acl_users = apache,nginx
listen.allowed_clients = 127.0.0.1
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
slowlog = /var/log/php-fpm/www-slow.log
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
EOF
# Update nginx config
# mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
mv /etc/nginx/conf.d/php-fpm.conf /etc/nginx/conf.d/php-fpm.conf.orig
mv /etc/nginx/default.d/php.conf /etc/nginx/default.d/php.conf.orig
# cat >/etc/nginx/nginx.conf <<"EOT"
# user nginx;
# worker_processes auto;
# error_log /var/log/nginx/error.log;
# pid /run/nginx.pid;
# include /usr/share/nginx/modules/*.conf;

# events {
#     worker_connections 1024;
# }

# http {
#     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
#                         '$status $body_bytes_sent "$http_referer" '
#                         '"$http_user_agent" "$http_x_forwarded_for"';

#     log_format json_combined escape=json
#         '{'
#         '"time_local":"$time_local",'
#         '"remote_addr":"$remote_addr",'
#         '"remote_user":"$remote_user",'
#         '"request":"$request",'
#         '"status": "$status",'
#         '"body_bytes_sent":$body_bytes_sent,'
#         '"request_time":$request_time,'
#         '"http_referrer":"$http_referer",'
#         '"http_user_agent":"$http_user_agent"'
#         '}';

#     access_log  /var/log/nginx/access.log  json_combined;

#     sendfile            on;
#     tcp_nopush          on;
#     tcp_nodelay         on;
#     keepalive_timeout   65;
#     types_hash_max_size 2048;

#     include             /etc/nginx/mime.types;
#     default_type        application/octet-stream;
#     include             /etc/nginx/conf.d/*.conf;

#     server {
#         listen       80 default_server;
#         listen       [::]:80 default_server;
#         # server_name  34.218.235.51;
#         server_name  _;
#         root         /usr/share/nginx/html;
#         index        index.php index.html index.htm;

#         include /etc/nginx/default.d/*.conf;

#         location / {
#             # This is cool because no php is touched for static content.
#             # include the "?" part so non-default permalinks doesn't break when using query string
#             # try_files \$uri \$uri/ /index.php?\$args;
#             # try_files \$uri \$uri/ =404;
#         }

#         location ~ \.php$ {
#                 # try_files $uri /index.php =404;
#                 fastcgi_pass unix:/run/php-fpm/www.sock;
#                 fastcgi_index index.php;
#                 fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#                 include fastcgi_params;
#         }

#         error_page 404 /404.html;
#             location = /40x.html {
#         }

#         error_page 500 502 503 504 /50x.html;
#             location = /50x.html {
#         }
#     }
# }
# EOT
# Install components needed for RDS tests
yum install -y mysql telnet
pip3 install mysql-connector-python pymysql boto3
# Start services and set to start on boot
systemctl start nginx
systemctl enable nginx
systemctl start php-fpm
systemctl enable php-fpm
# install CW unified agent
yum install -y amazon-cloudwatch-agent
amazon-linux-extras install -y collectd 
# rely on /opt/aws/amazon-cloudwatch-agent/bin/config.json
systemctl start collectd
systemctl enable collectd
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
systemctl start amazon-cloudwatch-agent
#
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource WebServerGroup --region ${AWS::Region}
