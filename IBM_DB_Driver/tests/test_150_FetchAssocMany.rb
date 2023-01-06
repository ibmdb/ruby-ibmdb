# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_150_FetchAssocMany
    assert_expect do
      conn = IBM_DB.connect("DATABASE=#{database};HOSTNAME=#{hostname};PORT=#{port};UID=#{user};PWD=#{password}",'','')

      server = IBM_DB::server_info( conn )
      if (server.DBMS_NAME[0,3] == 'IDS')
        op = {IBM_DB::ATTR_CASE => IBM_DB::CASE_UPPER}
        IBM_DB::set_option conn, op, 0
      end
      
      result = IBM_DB::exec conn, "select * from staff"
      
      while (row = IBM_DB::fetch_assoc(result))
      printf("%5d  ",row['ID'])
      printf("%-10s ",row['NAME'])
      printf("%5d ",row['DEPT'])
      printf("%-7s ",row['JOB'])
      if(row['YEARS'])
        printf("%5d ", row['YEARS'])
      else
        printf("%5d ", 0)
      end
      printf("%15s ", row['SALARY'])
      printf("%10s ", row['COMM'])
      puts ""
      end
    end
  end

end

__END__
__LUW_EXPECTED__
10  Sanders       20 Mgr         7      0.183575e5            
   20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
   30  Marenghi      38 Mgr         5     0.1750675e5            
   40  OBrien        38 Sales       6           18006  0.84655e3 
   50  Hanes         15 Mgr        10      0.206598e5            
   60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
   70  Rothman       15 Sales       7     0.1650283e5       1152 
   80  James         20 Clerk       0      0.135046e5   0.1282e3 
   90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
  100  Plotz         42 Mgr         7      0.183528e5            
  110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
  120  Naughton      38 Clerk       0     0.1295475e5        180 
  130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
  140  Fraye         51 Mgr         6           21150            
  150  Williams      51 Sales       6      0.194565e5  0.63765e3 
  160  Molinare      10 Mgr         7      0.229592e5            
  170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
  180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
  190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
  200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
  210  Lu            10 Mgr        10           20010            
  220  Smith         51 Sales       7      0.176545e5   0.9928e3 
  230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
  240  Daniels       10 Mgr         5     0.1926025e5            
  250  Wheeler       51 Clerk       6           14460   0.5133e3 
  260  Jones         10 Mgr        12           21234            
  270  Lea           66 Mgr         9      0.185555e5            
  280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
  290  Quill         84 Mgr        10           19818            
  300  Davis         84 Sales       5      0.154545e5   0.8061e3 
  310  Graham        66 Sales      13           21000   0.2003e3 
  320  Gonzales      66 Sales       4      0.168582e5        844 
  330  Burke         66 Clerk       1           10988    0.555e2 
  340  Edwards       84 Sales       7           17844       1285 
  350  Gafney        84 Clerk       5      0.130305e5        188
__ZOS_EXPECTED__
10  Sanders       20 Mgr         7      0.183575e5            
   20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
   30  Marenghi      38 Mgr         5     0.1750675e5            
   40  OBrien        38 Sales       6           18006  0.84655e3 
   50  Hanes         15 Mgr        10      0.206598e5            
   60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
   70  Rothman       15 Sales       7     0.1650283e5       1152 
   80  James         20 Clerk       0      0.135046e5   0.1282e3 
   90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
  100  Plotz         42 Mgr         7      0.183528e5            
  110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
  120  Naughton      38 Clerk       0     0.1295475e5        180 
  130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
  140  Fraye         51 Mgr         6           21150            
  150  Williams      51 Sales       6      0.194565e5  0.63765e3 
  160  Molinare      10 Mgr         7      0.229592e5            
  170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
  180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
  190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
  200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
  210  Lu            10 Mgr        10           20010            
  220  Smith         51 Sales       7      0.176545e5   0.9928e3 
  230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
  240  Daniels       10 Mgr         5     0.1926025e5            
  250  Wheeler       51 Clerk       6           14460   0.5133e3 
  260  Jones         10 Mgr        12           21234            
  270  Lea           66 Mgr         9      0.185555e5            
  280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
  290  Quill         84 Mgr        10           19818            
  300  Davis         84 Sales       5      0.154545e5   0.8061e3 
  310  Graham        66 Sales      13           21000   0.2003e3 
  320  Gonzales      66 Sales       4      0.168582e5        844 
  330  Burke         66 Clerk       1           10988    0.555e2 
  340  Edwards       84 Sales       7           17844       1285 
  350  Gafney        84 Clerk       5      0.130305e5        188
__SYSTEMI_EXPECTED__
10  Sanders       20 Mgr         7      0.183575e5            
   20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
   30  Marenghi      38 Mgr         5     0.1750675e5            
   40  OBrien        38 Sales       6           18006  0.84655e3 
   50  Hanes         15 Mgr        10      0.206598e5            
   60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
   70  Rothman       15 Sales       7     0.1650283e5       1152 
   80  James         20 Clerk       0      0.135046e5   0.1282e3 
   90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
  100  Plotz         42 Mgr         7      0.183528e5            
  110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
  120  Naughton      38 Clerk       0     0.1295475e5        180 
  130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
  140  Fraye         51 Mgr         6           21150            
  150  Williams      51 Sales       6      0.194565e5  0.63765e3 
  160  Molinare      10 Mgr         7      0.229592e5            
  170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
  180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
  190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
  200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
  210  Lu            10 Mgr        10           20010            
  220  Smith         51 Sales       7      0.176545e5   0.9928e3 
  230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
  240  Daniels       10 Mgr         5     0.1926025e5            
  250  Wheeler       51 Clerk       6           14460   0.5133e3 
  260  Jones         10 Mgr        12           21234            
  270  Lea           66 Mgr         9      0.185555e5            
  280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
  290  Quill         84 Mgr        10           19818            
  300  Davis         84 Sales       5      0.154545e5   0.8061e3 
  310  Graham        66 Sales      13           21000   0.2003e3 
  320  Gonzales      66 Sales       4      0.168582e5        844 
  330  Burke         66 Clerk       1           10988    0.555e2 
  340  Edwards       84 Sales       7           17844       1285 
  350  Gafney        84 Clerk       5      0.130305e5        188
__IDS_EXPECTED__
10  Sanders       20 Mgr         7      0.183575e5            
   20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
   30  Marenghi      38 Mgr         5     0.1750675e5            
   40  OBrien        38 Sales       6           18006  0.84655e3 
   50  Hanes         15 Mgr        10      0.206598e5            
   60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
   70  Rothman       15 Sales       7     0.1650283e5       1152 
   80  James         20 Clerk       0      0.135046e5   0.1282e3 
   90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
  100  Plotz         42 Mgr         7      0.183528e5            
  110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
  120  Naughton      38 Clerk       0     0.1295475e5        180 
  130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
  140  Fraye         51 Mgr         6           21150            
  150  Williams      51 Sales       6      0.194565e5  0.63765e3 
  160  Molinare      10 Mgr         7      0.229592e5            
  170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
  180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
  190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
  200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
  210  Lu            10 Mgr        10           20010            
  220  Smith         51 Sales       7      0.176545e5   0.9928e3 
  230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
  240  Daniels       10 Mgr         5     0.1926025e5            
  250  Wheeler       51 Clerk       6           14460   0.5133e3 
  260  Jones         10 Mgr        12           21234            
  270  Lea           66 Mgr         9      0.185555e5            
  280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
  290  Quill         84 Mgr        10           19818            
  300  Davis         84 Sales       5      0.154545e5   0.8061e3 
  310  Graham        66 Sales      13           21000   0.2003e3 
  320  Gonzales      66 Sales       4      0.168582e5        844 
  330  Burke         66 Clerk       1           10988    0.555e2 
  340  Edwards       84 Sales       7           17844       1285 
  350  Gafney        84 Clerk       5      0.130305e5        188
