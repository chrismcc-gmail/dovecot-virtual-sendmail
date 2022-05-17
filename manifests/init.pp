
include etchost
include qol
include sendmail
# include roundcubemail
include epel9
if $facts['os']['selinux']['enabled'] {
 include updateselinux
}
include firewalldrules
include roundcubemail


class etchost {
   notice('check fqdn')
  if $facts[networking][hostname] == $facts[networking][fqdn] {
   $myfqdn = "${facts[networking][hostname]}.example.com"
   notice("using local as dommainname $myfqdn")
  } else {
   $myfqdn = "${facts[networking][fqdn]}"
   notice("using domainname $myfqdn")
  }
 host { 'localhost4':
  name => 'localhost',
  ip => '127.0.0.1',
  host_aliases => "localhost4",
 }
 host { 'localhost6':
  name => 'localhost6',
  ip => '::1',
 }
 host { 'local4':
  name => $facts[networking][hostname],
  ip => $facts[networking][ip],
  host_aliases => [ "${myfqdn}", "local4" ],
 }
}

class qol {
 Package { ensure => 'installed' }
 $packages = ['man','tar','mlocate','telnet','net-tools','netcat','mutt','make','bash-completion','rsync']
 package { $packages: }
}

class sendmail {
 file { 'clamddir':
  ensure => directory,
  path => '/etc/clamd.d',
 }
 file { 'scan.conf':
  ensure => file,
  path => '/etc/clamd.d/scan.conf',
  content => file('files/etc/clamd.d/scan.conf'),
 }
 file { 'maildir':
  ensure => directory,
  path => '/etc/mail/',
 }
 file { 'sendmail.mc':
  ensure => file,
  path => '/etc/mail/sendmail.mc',
  content => file('files/etc/mail/sendmail.mc'),
 }
 file { 'sendmail.cf':
  ensure => file,
  path => '/etc/mail/sendmail.cf',
  content => file('files/etc/mail/sendmail.cf'),
 }
 file { 'local-host-names':
  ensure => file,
  replace => false,   # don't overwrite changes
  path => '/etc/mail/local-host-names',
  content => file('files/etc/mail/local-host-names'),
 }
 file { 'greylist.conf':
  ensure => file,
  path => '/etc/mail/greylist.conf',
  content => file('files/etc/mail/greylist.conf'),
 }
 file { 'spamassassindir':
  ensure => directory,
  path => '/etc/mail/spamassassin/',
 }
 file { 'spamassassin-local.cf':
  ensure => file,
  path => '/etc/mail/spamassassin/local.cf',
  content => file('files/etc/mail/spamassassin/local.cf'),
 }
 file { 'clamav-milter.conf':
  ensure => file,
  path => '/etc/mail/clamav-milter.conf',
  content => file('files/etc/mail/clamav-milter.conf'),
 }
 file { 'dovecotdir':
  ensure => directory,
  path => '/etc/dovecot/',
 }
 file { 'dovecot-local.conf':
  ensure => file,
  path => '/etc/dovecot/local.conf',
  content => file('files/etc/dovecot/local.conf'),
 }
 file { 'dovecotconfdir':
  ensure => directory,
  path => '/etc/dovecot/conf.d/',
 }
 file { 'dovecot-auth':
  ensure => file,
  path => '/etc/dovecot/conf.d/10-auth.conf',
  content => file('files/etc/dovecot/conf.d/10-auth.conf'),
 }
 file { '90-sieve':
  ensure => file,
  path => '/etc/dovecot/conf.d/90-sieve.conf',
  content => file('files/etc/dovecot/conf.d/90-sieve.conf'),
 }
 exec { 'nsswitch.conf':
  command => "/usr/bin/sed -i-orig 's@^passwd:.*files@& db @' /etc/nsswitch.conf",
  creates => '/etc/nsswitch.conf-orig',
 }
 file { 'spamass-milter':
  ensure => file,
  path => '/etc/sysconfig/spamass-milter',
  content => file('files/etc/sysconfig/spamass-milter'),
 }
 file { 'saslauthd':
  ensure => file,
  path => '/etc/sysconfig/saslauthd',
  content => file('files/etc/sysconfig/saslauthd'),
 }
 file { 'opendkimdir':
  ensure => directory,
  path => '/etc/opendkim/',
 }
 file { 'opendkimconf':
  ensure => file,
  path => '/etc/opendkim.conf',
  content => file('files/etc/opendkim.conf'),
 }

 Package { ensure => 'installed' }
 $packages = [ # 'epel-release',
        'sendmail', 'sendmail-cf' , 'sendmail-milter',
        'clamd' , 'clamav-update', 'clamav-milter', 'clamav-unofficial-sigs',
        'spamassassin', 'spamass-milter',
        'dovecot','dovecot-pigeonhole',
        'cyrus-sasl','cyrus-sasl-plain','certbot',
        'milter-greylist','opendkim','opendkim-tools']
 package { $packages: }

 service { sendmail: enable => true }
 service { clamav-freshclam: enable => true }
 service { clamav-milter: enable => true }
 service { "clamd@scan": enable => true }
 service { milter-greylist: enable => true }
 service { spamassassin: enable => true }
 service { "sa-update.timer": enable => true }
 service { spamass-milter: enable => true }
 service { dovecot: enable => true }
 service { saslauthd: enable => true }
 service { opendkim: enable => true }
 service { "certbot-renew.timer": enable => true }

 file { 'dovecot-users':
  ensure => file,
  replace => false,   # don't overwrite new users
  owner => 'root',
  group => 'dovecot',
  mode => '0640',
  path => '/etc/dovecot/usersfile',
  content => file('files/etc/dovecot/usersfile'),
 }
 package { "nss_db": }
 file { 'db-Makefile':
  ensure => file,
  path => '/var/db/Makefile',
  content => file('files/var/db/Makefile'),
 }
 exec { 'nss-chattr-i':
  command => "/bin/chattr +i /var/db/Makefile",
  subscribe => File['/var/db/Makefile'],
  refreshonly => true,
 }
 file { 'db-Makefile-copy':
  ensure => file,
  path => '/var/db/Makefile-puppet',
  content => file('files/var/db/Makefile'),
 }
 exec { 'nss-passwddb':
  command => "/usr/bin/make -C /var/db",
  creates => '/var/db/passwd.db',
 }
 exec { 'dkim-default':
  command => "/usr/sbin/opendkim-genkey -D /etc/opendkim/keys/ && chown -v root:opendkim /etc/opendkim/keys/default.private && chmod 0640 /etc/opendkim/keys/default.private",
  creates => '/etc/opendkim/keys/default.private',
 }
 exec { 'dkim-keytable':
  command => "/usr/bin/sed -i-orig 's|^#default|default|' /etc/opendkim/KeyTable",
  creates => '/etc/opendkim/KeyTable-orig',
 }
 exec { 'dkim-signingtable':
  command => "/usr/bin/sed -i-orig 's|^#\*@example|*@example|' /etc/opendkim/SigningTable",
  creates => '/etc/opendkim/SigningTable-orig',
 }
 group { 'vmail':
  name => 'vmail',
  ensure => 'present',
  system => 'true',
 }
 user { 'vmail':
  name => 'vmail',
  ensure => 'present',
  comment => 'dovecot virtual mailbox user',
  gid => 'vmail',
  home => '/home/vmail',
  managehome => 'true',
  shell => '/sbin/nologin',
  system => 'true',
 }
 file { 'sieved':
  ensure => directory,
  path => '/home/vmail/Sieve.d',
  owner => 'vmail',
  group => 'vmail',
 }
 file { 'default.sieve':
  ensure => file,
  path => '/home/vmail/Sieve.d/default.sieve',
  owner => 'vmail',
  group => 'vmail',
  content => file('files/home/vmail/Sieve.d/default.sieve'),
 }
}

class epel9 {
 file { 'epel9.repo':
  ensure => file,
  path => '/etc/yum.repos.d/epel9.repo',
  content => file('files/etc/yum.repos.d/epel9.repo'),
 }
}

class updateselinux {
 file { 'selinux-puppetdir':
  ensure => directory,
  path => '/etc/selinux/from-puppet/',
 }
 file { 'mail-server-pp':
  ensure => file,
  path => '/etc/selinux/from-puppet/mail-server.pp',
  content => file('files/etc/selinux/from-puppet/mail-server.pp'),
 }
 file { 'mail-server-te':
  ensure => file,
  path => '/etc/selinux/from-puppet/mail-server.te',
  content => file('files/etc/selinux/from-puppet/mail-server.te'),
 }
 exec { 'semodule':
  command => "/usr/sbin/semodule -vi /etc/selinux/from-puppet/mail-server.pp",
  subscribe => File['/etc/selinux/from-puppet/mail-server.pp'],
  refreshonly => true,
 }
}

class firewalldrules {
 exec { 'firewall-cmd-add-service':
  command => "/usr/bin/firewall-cmd --zone=public --add-service=smtp  --add-service=smtps --add-service=smtp-submission  --add-service=imap --add-service=imaps --add-service=http --add-service=https",
  onlyif => '/usr/bin/test -f /usr/bin/firewall-cmd',
#  creates => 'some.file',
 }
 exec { 'firewall-cmd-permanent':
  command => "/usr/bin/firewall-cmd --runtime-to-permanent",
  onlyif => '/usr/bin/test -f /usr/bin/firewall-cmd',
#  creates => 'some.file',
 }
}

class roundcubemail {
 file { 'roundconfigdir':
  ensure => directory,
  path => '/etc/roundcubemail/',
 }
 file { 'config.inc.php':
  ensure => file,
  path => '/etc/roundcubemail/config.inc.php',
  content => file('files/etc/roundcubemail/config.inc.php'),
 }

 file { 'httpddir':
  ensure => directory,
  path => '/etc/httpd/',
 }
 file { 'httpdconfdir':
  ensure => directory,
  path => '/etc/httpd/conf.d/',
 }
 file { 'roundcubemail.conf':
  ensure => file,
  path => '/etc/httpd/conf.d/roundcubemail.conf',
  content => file('files/etc/httpd/conf.d/roundcubemail.conf'),
 }

 Package { ensure => 'installed' }
 $packages = [ 'httpd', 'php-fpm', 'roundcubemail', 'mod_ssl' ]
 package { $packages: }
 service { httpd: enable => true }

}
