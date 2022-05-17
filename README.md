# puppet init.pp to setup a RedHat8/CentOS8 server with sendmail and dovecot using virtual users

## This will setup a new RedHat 8 or CentOS 8 server with the following:

### sendmail for email transport
 Clamav anti virus with clamav-milter
 Spamassassin spam check with spamass-milter
 grey listing with milter-greylist
 dkim sighning with opendkim

### dovcot for local delivery and imap for email clients
 a default sieve rule to deliver messages marked as spam by spamassassin
 directly to the users Junk folder

### roundcubemail for web based email with a few plugings added
 uses apache with mod_ssl

### Updates the firewalld rules to allow access to all the above

### Adds a few selinux policies to allow all the above to work together

See manifests/init.pp for all the details.  The config files installed are in
the files directory.


# To use:
Install a new redhat/centos server, virtual machines work either libvirt or lxc
 run ./init-puppet.sh ; this adds epel, the puppet binaries, and any updates
 run puppet apply --modulepath=`pwd` --verbose  manifests/init.pp 
 reboot to start all the daemons

# TODO:
add more documentation on what configs are used and why
most config files are added before the rpm packages. You can see the differences
with diff, like diff -u /etc/mail/sendmail.mc.rpmnew /etc/mail/sendmail.mc



