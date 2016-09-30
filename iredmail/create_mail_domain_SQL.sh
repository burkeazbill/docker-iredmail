#!/usr/bin/env bash

# Author:   Burke Azbill
# Purpose:  Import domains to MySQL database from plain text file.

# -------------------------------------------------------------------
# Usage:
#   * Run this script to generate SQL files used to import to MySQL
#     database later.
#
#       # bash create_mail_domain_SQL.sh domain [domain1 domain2 domain3 ...]
#
#     It will generate file 'domains.sql' in current directory, open
#     it and confirm all records are correct.
#
#   * Import domains.sql into MySQL database.
#
#       # mysql -uroot -p<PASSWORD> vmail < /path/to/domains.sql
#
#   That's all.
# -------------------------------------------------------------------

# ChangeLog:
#   - 2016.09.29 Initial version.
# Path to SQL template file.
SQL="domains.sql"
echo '' > ${SQL}

generate_sql()
{
    # Get domain name.

    for i in $@; do
        DOMAIN="$i"

        cat >> ${SQL} <<EOF
INSERT INTO domain (domain, created, modified)
             VALUES ('${DOMAIN}', NOW(), NOW());
EOF
    done
}

if [ $# -lt 2 ]; then
    echo "Usage: $0 domain [domain2 domain3 domain4 ...]"
else
    # Generate SQL template.
    generate_sql $@ && \
    cat <<EOF

SQL template file was generated successfully, Please import it
*MANUALLY* after verify the records:

    - ${SQL}

Steps to import these users looks like below:

    # mysql -uroot -p<PASSWORD> vmail < $(SQL);

EOF
fi
