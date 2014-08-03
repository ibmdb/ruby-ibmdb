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
      conn = IBM_DB::connect db,username,password

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
   10  Sanders       20 Mgr         7      0.183575E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   30  Marenghi      38 Mgr         5     0.1750675E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   50  Hanes         15 Mgr        10      0.206598E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   80  James         20 Clerk       0      0.135046E5   0.1282E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  100  Plotz         42 Mgr         7      0.183528E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  140  Fraye         51 Mgr         6        0.2115E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  150  Williams      51 Sales       6      0.194565E5  0.63765E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  160  Molinare      10 Mgr         7      0.229592E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  210  Lu            10 Mgr        10        0.2001E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  220  Smith         51 Sales       7      0.176545E5   0.9928E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  240  Daniels       10 Mgr         5     0.1926025E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  260  Jones         10 Mgr        12       0.21234E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  270  Lea           66 Mgr         9      0.185555E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  290  Quill         84 Mgr        10       0.19818E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  300  Davis         84 Sales       5      0.154545E5   0.8061E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  310  Graham        66 Sales      13          0.21E5   0.2003E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  330  Burke         66 Clerk       1       0.10988E5    0.555E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3 
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
   10  Sanders       20 Mgr         7      0.183575E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   30  Marenghi      38 Mgr         5     0.1750675E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   50  Hanes         15 Mgr        10      0.206598E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   80  James         20 Clerk       0      0.135046E5   0.1282E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  100  Plotz         42 Mgr         7      0.183528E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  140  Fraye         51 Mgr         6        0.2115E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  150  Williams      51 Sales       6      0.194565E5  0.63765E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  160  Molinare      10 Mgr         7      0.229592E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  210  Lu            10 Mgr        10        0.2001E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  220  Smith         51 Sales       7      0.176545E5   0.9928E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  240  Daniels       10 Mgr         5     0.1926025E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  260  Jones         10 Mgr        12       0.21234E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  270  Lea           66 Mgr         9      0.185555E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  290  Quill         84 Mgr        10       0.19818E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  300  Davis         84 Sales       5      0.154545E5   0.8061E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  310  Graham        66 Sales      13          0.21E5   0.2003E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  330  Burke         66 Clerk       1       0.10988E5    0.555E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3 
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
   10  Sanders       20 Mgr         7      0.183575E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   30  Marenghi      38 Mgr         5     0.1750675E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   50  Hanes         15 Mgr        10      0.206598E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   80  James         20 Clerk       0      0.135046E5   0.1282E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  100  Plotz         42 Mgr         7      0.183528E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  140  Fraye         51 Mgr         6        0.2115E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  150  Williams      51 Sales       6      0.194565E5  0.63765E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  160  Molinare      10 Mgr         7      0.229592E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  210  Lu            10 Mgr        10        0.2001E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  220  Smith         51 Sales       7      0.176545E5   0.9928E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  240  Daniels       10 Mgr         5     0.1926025E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  260  Jones         10 Mgr        12       0.21234E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  270  Lea           66 Mgr         9      0.185555E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  290  Quill         84 Mgr        10       0.19818E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  300  Davis         84 Sales       5      0.154545E5   0.8061E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  310  Graham        66 Sales      13          0.21E5   0.2003E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  330  Burke         66 Clerk       1       0.10988E5    0.555E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3 
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
   10  Sanders       20 Mgr         7      0.183575E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   30  Marenghi      38 Mgr         5     0.1750675E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   50  Hanes         15 Mgr        10      0.206598E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   80  James         20 Clerk       0      0.135046E5   0.1282E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  100  Plotz         42 Mgr         7      0.183528E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  140  Fraye         51 Mgr         6        0.2115E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  150  Williams      51 Sales       6      0.194565E5  0.63765E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  160  Molinare      10 Mgr         7      0.229592E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  210  Lu            10 Mgr        10        0.2001E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  220  Smith         51 Sales       7      0.176545E5   0.9928E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  240  Daniels       10 Mgr         5     0.1926025E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  260  Jones         10 Mgr        12       0.21234E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  270  Lea           66 Mgr         9      0.185555E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  290  Quill         84 Mgr        10       0.19818E5            
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  300  Davis         84 Sales       5      0.154545E5   0.8061E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  310  Graham        66 Sales      13          0.21E5   0.2003E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  330  Burke         66 Clerk       1       0.10988E5    0.555E2 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3 
		A00  SPIFFY COMPUTER SERVICE DIV. 000010 A00                 
		B01                      PLANNING 000020 A00                 
		C01            INFORMATION CENTER 000030 A00                 
		D01            DEVELOPMENT CENTER        A00                 
		D11         MANUFACTURING SYSTEMS 000060 D01                 
		D21        ADMINISTRATION SYSTEMS 000070 D01                 
		E01              SUPPORT SERVICES 000050 A00                 
		E11                    OPERATIONS 000090 E01                 
		E21              SOFTWARE SUPPORT 000100 E01                 

