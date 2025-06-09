ruby-ibmdb
==========
Rails Adapter/Ruby Driver for IBM Data Servers: {DB2 on Linux/Unix/Windows, DB2 on zOS, DB2 on IBMi, IBM Informix (IDS)}

```
ibm_db gem version 5.6.1

Requirements:
 Ruby should be installed(Ruby version should be >=2.5.x and <= 3.3.x)
 For developing rails appications Rails should be 7.2.x

 Note: x86 version of ruby can be downloaded from https://rubyinstaller.org/downloads/archives/
       ibm_db@5.5.1 onwards supports native installation on MacOS ARM64(M* Chip/Apple Silicon Chip) system using clidriver/dsdriver version 12.1.0.
```

 
Installing the IBM_DB adapter and driver
========================================

Issue the following command to install the ibm_db gem

```
gem install ibm_db

```

For Windows please set the below variable:-

```
set RUBY_DLL_PATH=path\to\clidriver\bin
```

Important Note on Requiring the Library
=======================================
  require 'ibm_db'  —  Loads only the low-level native driver.

  require 'IBM_DB'  —  Loads both the Rails adapter and native driver.

  Use require 'IBM_DB' if you want full ActiveRecord adapter functionality (e.g., when integrating with Rails).


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
