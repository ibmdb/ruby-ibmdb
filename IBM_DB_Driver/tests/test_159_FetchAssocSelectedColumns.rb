# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_159_FetchAssocSelectedColumns
    assert_expect do
      conn = IBM_DB::connect db,user,password

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
        IBM_DB::set_option conn, op, 0
      end

      result = IBM_DB::exec conn, "select name,job from staff"
      i=1
      while (row = IBM_DB::fetch_assoc(result))
        printf("%3d %10s %10s\n",i, row['NAME'], row['JOB'])
        i+=1
      end
    end
  end

end

__END__
__LUW_EXPECTED__
  1    Sanders      Mgr  
  2     Pernal      Sales
  3   Marenghi      Mgr  
  4     OBrien      Sales
  5      Hanes      Mgr  
  6    Quigley      Sales
  7    Rothman      Sales
  8      James      Clerk
  9    Koonitz      Sales
 10      Plotz      Mgr  
 11       Ngan      Clerk
 12   Naughton      Clerk
 13  Yamaguchi      Clerk
 14      Fraye      Mgr  
 15   Williams      Sales
 16   Molinare      Mgr  
 17   Kermisch      Clerk
 18   Abrahams      Clerk
 19    Sneider      Clerk
 20   Scoutten      Clerk
 21         Lu      Mgr  
 22      Smith      Sales
 23  Lundquist      Clerk
 24    Daniels      Mgr  
 25    Wheeler      Clerk
 26      Jones      Mgr  
 27        Lea      Mgr  
 28     Wilson      Sales
 29      Quill      Mgr  
 30      Davis      Sales
 31     Graham      Sales
 32   Gonzales      Sales
 33      Burke      Clerk
 34    Edwards      Sales
 35     Gafney      Clerk
__ZOS_EXPECTED__
  1    Sanders      Mgr  
  2     Pernal      Sales
  3   Marenghi      Mgr  
  4     OBrien      Sales
  5      Hanes      Mgr  
  6    Quigley      Sales
  7    Rothman      Sales
  8      James      Clerk
  9    Koonitz      Sales
 10      Plotz      Mgr  
 11       Ngan      Clerk
 12   Naughton      Clerk
 13  Yamaguchi      Clerk
 14      Fraye      Mgr  
 15   Williams      Sales
 16   Molinare      Mgr  
 17   Kermisch      Clerk
 18   Abrahams      Clerk
 19    Sneider      Clerk
 20   Scoutten      Clerk
 21         Lu      Mgr  
 22      Smith      Sales
 23  Lundquist      Clerk
 24    Daniels      Mgr  
 25    Wheeler      Clerk
 26      Jones      Mgr  
 27        Lea      Mgr  
 28     Wilson      Sales
 29      Quill      Mgr  
 30      Davis      Sales
 31     Graham      Sales
 32   Gonzales      Sales
 33      Burke      Clerk
 34    Edwards      Sales
 35     Gafney      Clerk
__SYSTEMI_EXPECTED__
  1    Sanders      Mgr  
  2     Pernal      Sales
  3   Marenghi      Mgr  
  4     OBrien      Sales
  5      Hanes      Mgr  
  6    Quigley      Sales
  7    Rothman      Sales
  8      James      Clerk
  9    Koonitz      Sales
 10      Plotz      Mgr  
 11       Ngan      Clerk
 12   Naughton      Clerk
 13  Yamaguchi      Clerk
 14      Fraye      Mgr  
 15   Williams      Sales
 16   Molinare      Mgr  
 17   Kermisch      Clerk
 18   Abrahams      Clerk
 19    Sneider      Clerk
 20   Scoutten      Clerk
 21         Lu      Mgr  
 22      Smith      Sales
 23  Lundquist      Clerk
 24    Daniels      Mgr  
 25    Wheeler      Clerk
 26      Jones      Mgr  
 27        Lea      Mgr  
 28     Wilson      Sales
 29      Quill      Mgr  
 30      Davis      Sales
 31     Graham      Sales
 32   Gonzales      Sales
 33      Burke      Clerk
 34    Edwards      Sales
 35     Gafney      Clerk
__IDS_EXPECTED__
  1    Sanders      Mgr  
  2     Pernal      Sales
  3   Marenghi      Mgr  
  4     OBrien      Sales
  5      Hanes      Mgr  
  6    Quigley      Sales
  7    Rothman      Sales
  8      James      Clerk
  9    Koonitz      Sales
 10      Plotz      Mgr  
 11       Ngan      Clerk
 12   Naughton      Clerk
 13  Yamaguchi      Clerk
 14      Fraye      Mgr  
 15   Williams      Sales
 16   Molinare      Mgr  
 17   Kermisch      Clerk
 18   Abrahams      Clerk
 19    Sneider      Clerk
 20   Scoutten      Clerk
 21         Lu      Mgr  
 22      Smith      Sales
 23  Lundquist      Clerk
 24    Daniels      Mgr  
 25    Wheeler      Clerk
 26      Jones      Mgr  
 27        Lea      Mgr  
 28     Wilson      Sales
 29      Quill      Mgr  
 30      Davis      Sales
 31     Graham      Sales
 32   Gonzales      Sales
 33      Burke      Clerk
 34    Edwards      Sales
 35     Gafney      Clerk
