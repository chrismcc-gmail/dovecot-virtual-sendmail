# modified from nss_db Makefile

VAR_DB = /var/db

AWK = awk
MAKEDB = makedb 

all: $(VAR_DB)/passwd.db


$(VAR_DB)/passwd.db: /etc/dovecot/usersfile
	@printf %s "$(patsubst %.db,%,$(@F))... "
	@$(AWK) 'BEGIN { FS=":"; OFS=":" } \
		 /^[ \t]*$$/ { next } \
		 /^[ \t]*#/ { next } \
		 /^root/ { next } \
		 /^[^#]/ { printf ".%s ", $$1; \
		printf "%s:x:65534:65534:%s:/home/vmail/%s:/sbin/nologin\n", $$1, $$1, $$1; \
			                             }' $^ | \
	$(MAKEDB) -o $@ -
	@echo "done."

