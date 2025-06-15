+++
title = "Comment section over SSH"
date = 2024-10-22
updated = 2024-10-22
description = "How to host a small comment section over ssh."
authors = ["Behemoth"]
+++

A while ago I saw a blog that had a comment section where you could send messages over ssh. It noted that you should use your own username but sadly it was broken by the time I found it.

I wanted to implement something like this for a while and finally got to do it.

You can try it now by ssh-ing into this server with the user "comment".
Username entry comes afterwards.

It's backed by a simple sqlite file and the script is self-contained and only needs libc and libsqlite3 to work.

You can find the [full script here](/blog/ssh_comment/comment.c).

To get this to work you have to create a user with password login enabled. The actual password is optional and can be left empty. Up to you.

* Compile the scriptlet e.g. like such: `gcc -O2 -static comment.c -o comment -lsqlite3`
* Create a proxy command that invokes the above created `command` with a path to the sqlite file
* Create the user that has write permissions to the DB folder
* Set his shell to use the proxy command
* Enable password login in your sshd server config (`PasswordAuthentication yes`, `PermitEmptyPasswords yes`)

The resulting user should look something like this
`comment:x:9000:9001:comments:/var/lib/comment:/usr/bin/comment.sh`

The proxy command could look like this:
```sh
#!/bin/sh

comment /var/lib/comment/comments.sqlite
```

If you need assistance, just leave me a comment :)
