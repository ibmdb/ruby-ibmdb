#
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_053_SetClientAttributes
    assert_expect do

      puts "Client attributes passed through conection string:"

      options1 = {IBM_DB::SQL_ATTR_INFO_USERID => 'db2inst1'}
      conn1 = IBM_DB::connect database, user, password, options1
      val = IBM_DB::get_option conn1, IBM_DB::SQL_ATTR_INFO_USERID, 1
      puts val

      options2 = {IBM_DB::SQL_ATTR_INFO_ACCTSTR => 'account'}
      conn2 = IBM_DB::connect database, user, password, options2
      val = IBM_DB::get_option conn2, IBM_DB::SQL_ATTR_INFO_ACCTSTR, 1
      puts val

      options3 = {IBM_DB::SQL_ATTR_INFO_APPLNAME => 'myapp'}
      conn3 = IBM_DB::connect database, user, password, options3
      val = IBM_DB::get_option conn3, IBM_DB::SQL_ATTR_INFO_APPLNAME, 1
      puts val

      options4 = {IBM_DB::SQL_ATTR_INFO_WRKSTNNAME => 'workstation'}
      conn4 = IBM_DB::connect database, user, password, options4
      val = IBM_DB::get_option conn4, IBM_DB::SQL_ATTR_INFO_WRKSTNNAME, 1
      puts val

      options5 = {IBM_DB::SQL_ATTR_INFO_USERID => 'kfb',
                  IBM_DB::SQL_ATTR_INFO_WRKSTNNAME => 'kfbwork',
                  IBM_DB::SQL_ATTR_INFO_ACCTSTR => 'kfbacc',
                  IBM_DB::SQL_ATTR_INFO_APPLNAME => 'kfbapp'}
      conn5 = IBM_DB::connect database, user, password, options5
      val = IBM_DB::get_option conn5, IBM_DB::SQL_ATTR_INFO_USERID, 1
      puts val
      val = IBM_DB::get_option conn5, IBM_DB::SQL_ATTR_INFO_ACCTSTR, 1
      puts val
      val = IBM_DB::get_option conn5, IBM_DB::SQL_ATTR_INFO_APPLNAME, 1
      puts val
      val = IBM_DB::get_option conn5, IBM_DB::SQL_ATTR_INFO_WRKSTNNAME, 1
      puts val

      puts "Client attributes passed post-conection:"

      options5 = {IBM_DB::SQL_ATTR_INFO_USERID => 'db2inst1'}
      conn5 = IBM_DB::connect database, user, password
      rc = IBM_DB::set_option conn5, options5, 1
      val = IBM_DB::get_option conn5, IBM_DB::SQL_ATTR_INFO_USERID, 1
      puts val

      options6 = {IBM_DB::SQL_ATTR_INFO_ACCTSTR => 'account'}
      conn6 = IBM_DB::connect database, user, password
      rc = IBM_DB::set_option conn6, options6, 1
      val = IBM_DB::get_option conn6, IBM_DB::SQL_ATTR_INFO_ACCTSTR, 1
      puts val

      options7 = {IBM_DB::SQL_ATTR_INFO_APPLNAME => 'myapp'}
      conn7 = IBM_DB::connect database, user, password
      rc = IBM_DB::set_option conn7, options7, 1
      val = IBM_DB::get_option conn7, IBM_DB::SQL_ATTR_INFO_APPLNAME, 1
      puts val

      options8 = {IBM_DB::SQL_ATTR_INFO_WRKSTNNAME => 'workstation'}
      conn8 = IBM_DB::connect database, user, password
      rc = IBM_DB::set_option conn8, options8, 1
      val = IBM_DB::get_option conn8, IBM_DB::SQL_ATTR_INFO_WRKSTNNAME, 1
      puts val
    end
  end

end

__END__
__LUW_EXPECTED__
Client attributes passed through conection string:
db2inst1
account
myapp
workstation
kfb
kfbacc
kfbapp
kfbwork
Client attributes passed post-conection:
db2inst1
account
myapp
workstation
__ZOS_EXPECTED__
Client attributes passed through conection string:
db2inst1
account
myapp
workstation
kfb
kfbacc
kfbapp
kfbwork
Client attributes passed post-conection:
db2inst1
account
myapp
workstation
__SYSTEMI_EXPECTED__
Client attributes passed through conection string:
db2inst1
account
myapp
workstation
kfb
kfbacc
kfbapp
kfbwork
Client attributes passed post-conection:
db2inst1
account
myapp
workstation
__IDS_EXPECTED__
Client attributes passed through conection string:
db2inst1
account
myapp
workstation
kfb
kfbacc
kfbapp
kfbwork
Client attributes passed post-conection:
db2inst1
account
myapp
workstation
