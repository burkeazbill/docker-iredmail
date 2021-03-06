#!/usr/bin/env bash

# Author:   Zhang Huangbin (zhb _at_ iredmail.org)
# Purpose:  Import users to MySQL database from plain text file.
# Project:  iRedMail (http://www.iredmail.org/)

# -------------------------------------------------------------------
# Usage:
#   * Edit these variables:
#       STORAGE_BASE_DIRECTORY
#       DEFAULT_PASSWD=VMware1!
#       USE_DEFAULT_PASSWD='YES'
#       DEFAULT_QUOTA='100'   # 100 -> 100M
#
#   * Run this script to generate SQL files used to import to MySQL
#     database later.
#
#       # bash create_mail_user_MySQL.sh domain.ltd user [user1 user2 user3 ...]
#
#     It will generate file 'output.sql' in current directory, open
#     it and confirm all records are correct.
#
#   * Import output.sql into MySQL database.
#
#       # mysql -uroot -p
#       mysql> USE vmail;
#       mysql> SOURCE /path/to/output.sql;
#
#   That's all.
# -------------------------------------------------------------------

# ChangeLog:
#   - 2018.03.21 (Burke Azbill) Updated lines 125 and 126 to match iRedMail 0.9.7 script
#     so that this older script version may be used for bulk user import
#   - 2009.05.07 Add hashed maildir style support.
#   - Improve file detect.
#   - Drop output message of 'which dos2unix'.

# --------- CHANGE THESE VALUES ----------
# Storage base directory used to store users' mail.
STORAGE_BASE_DIRECTORY="/var/vmail/vmail1"

###########
# Password
#
# Password scheme. Available schemes: BCRYPT, SSHA512, SSHA, MD5, NTLM, PLAIN.
# Check file Available
PASSWORD_SCHEME='SSHA512'

DEFAULT_PASSWD=VMware1!
USE_DEFAULT_PASSWD='YES'

# Default mail quota.
DEFAULT_QUOTA='1024'   # 1024 = 1024M

#
# Maildir settings
#
# Maildir style: hashed, normal.
# Hashed maildir style, so that there won't be many large directories
# in your mail storage file system. Better performance in large scale
# deployment.
# Format: e.g. username@domain.td
#   hashed  -> domain.ltd/u/us/use/username/
#   normal  -> domain.ltd/username/
# Default hash level is 3.
MAILDIR_STYLE='hashed'      # hashed, normal.

# Time stamp, will be appended in maildir.
DATE="$(date +%Y.%m.%d.%H.%M.%S)"

STORAGE_BASE="$(dirname ${STORAGE_BASE_DIRECTORY})"
STORAGE_NODE="$(basename ${STORAGE_BASE_DIRECTORY})"

# Path to SQL template file.
SQL="output.sql"
echo '' > ${SQL}

# Cyrpt default password.
export CRYPT_PASSWD="$(python ./generate_password_hash.py ${PASSWORD_SCHEME} ${DEFAULT_PASSWD})"

generate_sql()
{
    # Get domain name.
    DOMAIN="$1"
    shift 1

    for i in $@; do
        username="$i"
        mail="${username}@${DOMAIN}"

        if [ X"${USE_DEFAULT_PASSWD}" != X'YES' ]; then
            export CRYPT_PASSWD="$(python ./generate_password_hash.py ${PASSWORD_SCHEME} ${username})"
        fi

        # Different maildir style: hashed, normal.
        if [ X"${MAILDIR_STYLE}" == X"hashed" ]; then
            length="$(echo ${username} | wc -L)"
            str1="$(echo ${username} | cut -c1)"
            str2="$(echo ${username} | cut -c2)"
            str3="$(echo ${username} | cut -c3)"

            if [ X"${length}" == X"1" ]; then
                str2="${str1}"
                str3="${str1}"
            elif [ X"${length}" == X"2" ]; then
                str3="${str2}"
            else
                :
            fi

            # Use mbox, will be changed later.
            maildir="${DOMAIN}/${str1}/${str2}/${str3}/${username}-${DATE}/"
        else
            # Use mbox, will be changed later.
            maildir="${DOMAIN}/${username}-${DATE}/"
        fi

        cat >> ${SQL} <<EOF
INSERT INTO mailbox (username, password, name,
                     storagebasedirectory,storagenode, maildir,
                     quota, domain, active, local_part, created)
             VALUES ('${mail}', '${CRYPT_PASSWD}', '${username}',
                     '${STORAGE_BASE}','${STORAGE_NODE}', '${maildir}',
                     '${DEFAULT_QUOTA}', '${DOMAIN}', '1','${username}', NOW());
INSERT INTO forwardings (address, forwarding, domain, dest_domain, is_forwarding)
                 VALUES ('${mail}', '${mail}','${domain}', '${domain}', 1);
EOF
    done
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 domain_name username [user2 user3 user4 ...]"
else
    # Generate SQL template.
    generate_sql $@ && \
    cat <<EOF

SQL template file was generated successfully, Please import it
*MANUALLY* after verify the records:

    - ${SQL}

Steps to import these users looks like below:

    # mysql -uroot -p
    mysql> USE vmail;
    mysql> SOURCE ${SQL};

Or, PostgreSQL:

    # su - postgres
    $ psql -d vmail
    sql> \i ${SQL};

EOF
fi
