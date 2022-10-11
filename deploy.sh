server=root@boxcat.site
folder=/var/www/boxcat.site/htdocs/

zola build
ssh $server rm -r $folder
scp -rp public/* $server:$folder
ssh $server chown -R nginx:nginx $folder
