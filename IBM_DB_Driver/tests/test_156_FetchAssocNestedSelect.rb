# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

# This test will use a lot of the heap size allocated
# for DB2.  If is is failing on your system, please 
# increase the application heap size.

class TestIbmDb < Test::Unit::TestCase

  def test_156_FetchAssocNestedSelect
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
        if( row['YEARS'] )
          printf("%5d ", row['YEARS'])
        else
          printf("%5d ", 0)
        end
        printf("%15s ", row['SALARY'])
        printf("%10s ", row['COMM'])
        puts ""
        result2 = IBM_DB::exec conn,"select * from department where substr(deptno,1,1) in ('A','B','C','D','E')"
        while (row2 = IBM_DB::fetch_assoc(result2))
         printf("\t\t%3s %29s %6s %3s %-16s\n",
         row2['DEPTNO'], row2['DEPTNAME'], row2['MGRNO'],
         row2['ADMRDEPT'], row2['LOCATION']);    
         result3 = IBM_DB::exec conn,"select count(*) from sales"
        end
      end
    end
  end

end

__END__
__LUW_EXPECTED__
   10  Sanders       20 Mgr         7      0.183575e5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   30  Marenghi      38 Mgr         5     0.1750675e5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   40  OBrien        38 Sales       6           18006  0.84655e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   50  Hanes         15 Mgr        10      0.206598e5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   70  Rothman       15 Sales       7     0.1650283e5       1152 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   80  James         20 Clerk       0      0.135046e5   0.1282e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  100  Plotz         42 Mgr         7      0.183528e5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  120  Naughton      38 Clerk       0     0.1295475e5        180 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  140  Fraye         51 Mgr         6           21150            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  150  Williams      51 Sales       6      0.194565e5  0.63765e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  160  Molinare      10 Mgr         7      0.229592e5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  210  Lu            10 Mgr        10           20010            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  220  Smith         51 Sales       7      0.176545e5   0.9928e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  240  Daniels       10 Mgr         5     0.1926025e5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  250  Wheeler       51 Clerk       6           14460   0.5133e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  260  Jones         10 Mgr        12           21234            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  270  Lea           66 Mgr         9      0.185555e5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  290  Quill         84 Mgr        10           19818            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  300  Davis         84 Sales       5      0.154545e5   0.8061e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  310  Graham        66 Sales      13           21000   0.2003e3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  320  Gonzales      66 Sales       4      0.168582e5        844 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  330  Burke         66 Clerk       1           10988    0.555e2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  340  Edwards       84 Sales       7           17844       1285 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  350  Gafney        84 Clerk       5      0.130305e5        188 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01
__ZOS_EXPECTED__
10  Sanders       20 Mgr         7      0.183575e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
30  Marenghi      38 Mgr         5     0.1750675e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
40  OBrien        38 Sales       6           18006  0.84655e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
50  Hanes         15 Mgr        10      0.206598e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
70  Rothman       15 Sales       7     0.1650283e5       1152 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
80  James         20 Clerk       0      0.135046e5   0.1282e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
100  Plotz         42 Mgr         7      0.183528e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
120  Naughton      38 Clerk       0     0.1295475e5        180 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
140  Fraye         51 Mgr         6           21150            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
150  Williams      51 Sales       6      0.194565e5  0.63765e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
160  Molinare      10 Mgr         7      0.229592e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
210  Lu            10 Mgr        10           20010            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
220  Smith         51 Sales       7      0.176545e5   0.9928e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
240  Daniels       10 Mgr         5     0.1926025e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
250  Wheeler       51 Clerk       6           14460   0.5133e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
260  Jones         10 Mgr        12           21234            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
270  Lea           66 Mgr         9      0.185555e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
290  Quill         84 Mgr        10           19818            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
300  Davis         84 Sales       5      0.154545e5   0.8061e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
310  Graham        66 Sales      13           21000   0.2003e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
320  Gonzales      66 Sales       4      0.168582e5        844 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
330  Burke         66 Clerk       1           10988    0.555e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
340  Edwards       84 Sales       7           17844       1285 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
350  Gafney        84 Clerk       5      0.130305e5        188 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01

__SYSTEMI_EXPECTED__
10  Sanders       20 Mgr         7      0.183575e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
30  Marenghi      38 Mgr         5     0.1750675e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
40  OBrien        38 Sales       6           18006  0.84655e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
50  Hanes         15 Mgr        10      0.206598e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
70  Rothman       15 Sales       7     0.1650283e5       1152 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
80  James         20 Clerk       0      0.135046e5   0.1282e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
100  Plotz         42 Mgr         7      0.183528e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
120  Naughton      38 Clerk       0     0.1295475e5        180 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
140  Fraye         51 Mgr         6           21150            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
150  Williams      51 Sales       6      0.194565e5  0.63765e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
160  Molinare      10 Mgr         7      0.229592e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
210  Lu            10 Mgr        10           20010            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
220  Smith         51 Sales       7      0.176545e5   0.9928e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
240  Daniels       10 Mgr         5     0.1926025e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
250  Wheeler       51 Clerk       6           14460   0.5133e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
260  Jones         10 Mgr        12           21234            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
270  Lea           66 Mgr         9      0.185555e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
290  Quill         84 Mgr        10           19818            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
300  Davis         84 Sales       5      0.154545e5   0.8061e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
310  Graham        66 Sales      13           21000   0.2003e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
320  Gonzales      66 Sales       4      0.168582e5        844 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
330  Burke         66 Clerk       1           10988    0.555e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
340  Edwards       84 Sales       7           17844       1285 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
350  Gafney        84 Clerk       5      0.130305e5        188 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01

__IDS_EXPECTED__
10  Sanders       20 Mgr         7      0.183575e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
20  Pernal        20 Sales       8     0.1817125e5  0.61245e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
30  Marenghi      38 Mgr         5     0.1750675e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
40  OBrien        38 Sales       6           18006  0.84655e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
50  Hanes         15 Mgr        10      0.206598e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
60  Quigley       38 Sales       0      0.168083e5  0.65025e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
70  Rothman       15 Sales       7     0.1650283e5       1152 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
80  James         20 Clerk       0      0.135046e5   0.1282e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
90  Koonitz       42 Sales       6     0.1800175e5  0.13867e4 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
100  Plotz         42 Mgr         7      0.183528e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
110  Ngan          15 Clerk       5      0.125082e5   0.2066e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
120  Naughton      38 Clerk       0     0.1295475e5        180 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
130  Yamaguchi     42 Clerk       6      0.105059e5    0.756e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
140  Fraye         51 Mgr         6           21150            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
150  Williams      51 Sales       6      0.194565e5  0.63765e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
160  Molinare      10 Mgr         7      0.229592e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
170  Kermisch      15 Clerk       4      0.122585e5   0.1101e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
180  Abrahams      38 Clerk       3     0.1200975e5   0.2365e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
190  Sneider       20 Clerk       8     0.1425275e5   0.1265e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
200  Scoutten      42 Clerk       0      0.115086e5    0.842e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
210  Lu            10 Mgr        10           20010            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
220  Smith         51 Sales       7      0.176545e5   0.9928e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
230  Lundquist     51 Clerk       3      0.133698e5  0.18965e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
240  Daniels       10 Mgr         5     0.1926025e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
250  Wheeler       51 Clerk       6           14460   0.5133e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
260  Jones         10 Mgr        12           21234            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
270  Lea           66 Mgr         9      0.185555e5            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
280  Wilson        66 Sales       9      0.186745e5   0.8115e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
290  Quill         84 Mgr        10           19818            
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
300  Davis         84 Sales       5      0.154545e5   0.8061e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
310  Graham        66 Sales      13           21000   0.2003e3 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
320  Gonzales      66 Sales       4      0.168582e5        844 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
330  Burke         66 Clerk       1           10988    0.555e2 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
340  Edwards       84 Sales       7           17844       1285 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01                 
350  Gafney        84 Clerk       5      0.130305e5        188 
A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
B01                      PLANNING 000020 A00                 
C01            INFORMATION CENTER 000030 A00                 
D01            DEVELOPMENT CENTER        A00                 
D11         MANUFACTURING SYSTEMS 000060 D01                 
D21        ADMINISTRATION SYSTEMS 000070 D01                 
E01              SUPPORT SERVICES 000050 A00                 
E11                    OPERATIONS 000090 E01                 
E21              SOFTWARE SUPPORT 000100 E01
