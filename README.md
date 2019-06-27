ruby-ibmdb
==========
Rails Adapter/Ruby Driver for IBM Data Servers: {DB2 on Linux/Unix/Windows, DB2 on zOS, DB2 on IBMi, IBM Informix (IDS)}

```
ibm_db gem version 4.0.0

Requirements:
 Ruby : 2.2.6
 Rails : 5.0.7 
```

 
Installing the IBM_DB adapter and driver
========================================

Issue the following command to install the ibm_db gem

```
gem install ibm_db
```

Contacts
========

For any issues or help: https://github.com/ibmdb/ruby-ibmdb/issues

Local Development
=================

To easily test changes to the ibm_db gem locally without building 
a gem package, add to your Rails Gemfile:

```
gem 'ibm_db', path: "/path/to/ruby-ibmdb/IBM_DB_Adapter/ibm_db"
```

Then build the ibm_db.so library:

```bash
$ cd /path/to/ruby-ibmdb/IBM_DB_Adapter/ibm_db/ext"
$ ruby extconf.rb
$ make
```

Then bundle install in your rails app:

```
$ bundle install
...
Using ibm_db 4.0.0 from source at `ruby-ibmdb/IBM_DB_Adapter/ibm_db`
```

License
=======
Copyright (c) 2006 - 2017 IBM Corporation

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



Contributing
=======
See [CONTRIBUTING](https://github.com/ibmdb/ruby-ibmdb/blob/master/contributing/CONTRIBUTING.md)

```
The developer sign-off should include the reference to the DCO in remarks(example below):
DCO 1.1 Signed-off-by: Random J Developer <random@developer.org>
```
