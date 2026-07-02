ruby-ibmdb (Linux)
==================

Rails adapter and Ruby driver for IBM data servers on **Linux x86** (DB2 LUW, remote DB2 on z/OS and IBM i, Informix IDS).

```
ibm_db gem version 5.5.1

Supported host OS:
  Linux x86_64 (linuxx64_odbc_cli.tar.gz)

Requirements:
  Ruby >= 2.5, <= 3.2
  Rails / ActiveRecord 7.0 - 7.1 (gem declares 7.0 - 7.1)
  Build tools: gcc, make, ruby-dev headers
```

The fork ships IBM CLI driver archives under `odbc_cli/`. During `gem install` or `bundle install` from a local path, `extconf.rb` unpacks the matching archive into `lib/clidriver/`, builds `ibm_db.so`, and removes the temporary archive file.

Installing from this repository
=================================

```bash
gem install /path/to/ruby-ibmdb/IBM_DB_Adapter/ibm_db
```

Or in a Rails `Gemfile`:

```ruby
gem 'ibm_db', path: "/path/to/ruby-ibmdb/IBM_DB_Adapter/ibm_db"
```

```bash
bundle install
```

Manual build (without gem install):

```bash
cd /path/to/ruby-ibmdb/IBM_DB_Adapter/ibm_db/ext
ruby extconf.rb
make
```

`lib/ibm_db.so` is a symlink to `ext/ibm_db.so` for local development.

Optional environment variables
==============================

| Variable | Purpose |
|----------|---------|
| `IBM_DB_HOME` | Use an existing DB2 / CLI installation instead of bundled `odbc_cli` |
| `IBM_DB_ODBC_CLI_DIR` | Directory with `linuxx64_odbc_cli.tar.gz` / `linuxia32_odbc_cli.tar.gz` |
| `IBM_DB_FORCE_BUILD` | `1` - always compile the native extension on install |
| `IBM_DB_ODBC_CLI_REPO` / `IBM_DB_ODBC_CLI_BRANCH` | GitHub source when a local archive is missing |

Contacts
========

Issues: https://github.com/etspring/ruby-ibmdb/issues
