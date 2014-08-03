# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_043_FetchArrayMany_02
    assert_expect do
      conn = IBM_DB::connect db,username,password
      
      result = IBM_DB::exec conn, "select * from staff"
      
      while (row = IBM_DB::fetch_array(result))
      printf("%5d  ",row[0])
      printf("%-10s ",row[1])
      printf("%5d ",row[2])
      printf("%-7s ",row[3])
      if(row[4])
        printf("%5d ", row[4])
      else
        printf("%5d ", 0)
      end
      printf("%15s ", row[5])
      printf("%10s ", row[6])
      puts ""
      end
    end
  end

end

__END__
__LUW_EXPECTED__
   10  Sanders       20 Mgr         7      0.183575E5            
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3 
   30  Marenghi      38 Mgr         5     0.1750675E5            
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3 
   50  Hanes         15 Mgr        10      0.206598E5            
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3 
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4 
   80  James         20 Clerk       0      0.135046E5   0.1282E3 
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4 
  100  Plotz         42 Mgr         7      0.183528E5            
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3 
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3 
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2 
  140  Fraye         51 Mgr         6        0.2115E5            
  150  Williams      51 Sales       6      0.194565E5  0.63765E3 
  160  Molinare      10 Mgr         7      0.229592E5            
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3 
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3 
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3 
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2 
  210  Lu            10 Mgr        10        0.2001E5            
  220  Smith         51 Sales       7      0.176545E5   0.9928E3 
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3 
  240  Daniels       10 Mgr         5     0.1926025E5            
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3 
  260  Jones         10 Mgr        12       0.21234E5            
  270  Lea           66 Mgr         9      0.185555E5            
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3 
  290  Quill         84 Mgr        10       0.19818E5            
  300  Davis         84 Sales       5      0.154545E5   0.8061E3 
  310  Graham        66 Sales      13          0.21E5   0.2003E3 
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3 
  330  Burke         66 Clerk       1       0.10988E5    0.555E2 
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4 
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3
__ZOS_EXPECTED__
   10  Sanders       20 Mgr         7      0.183575E5
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3
   30  Marenghi      38 Mgr         5     0.1750675E5
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3
   50  Hanes         15 Mgr        10      0.206598E5
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4
   80  James         20 Clerk       0      0.135046E5   0.1282E3
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4
  100  Plotz         42 Mgr         7      0.183528E5
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2
  140  Fraye         51 Mgr         6        0.2115E5
  150  Williams      51 Sales       6      0.194565E5  0.63765E3
  160  Molinare      10 Mgr         7      0.229592E5
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2
  210  Lu            10 Mgr        10        0.2001E5
  220  Smith         51 Sales       7      0.176545E5   0.9928E3
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3
  240  Daniels       10 Mgr         5     0.1926025E5
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3
  260  Jones         10 Mgr        12       0.21234E5
  270  Lea           66 Mgr         9      0.185555E5
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3
  290  Quill         84 Mgr        10       0.19818E5
  300  Davis         84 Sales       5      0.154545E5   0.8061E3
  310  Graham        66 Sales      13          0.21E5   0.2003E3
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3
  330  Burke         66 Clerk       1       0.10988E5    0.555E2
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3
__SYSTEMI_EXPECTED__
   10  Sanders       20 Mgr         7      0.183575E5            
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3 
   30  Marenghi      38 Mgr         5     0.1750675E5            
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3 
   50  Hanes         15 Mgr        10      0.206598E5            
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3 
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4 
   80  James         20 Clerk       0      0.135046E5   0.1282E3 
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4 
  100  Plotz         42 Mgr         7      0.183528E5            
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3 
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3 
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2 
  140  Fraye         51 Mgr         6        0.2115E5            
  150  Williams      51 Sales       6      0.194565E5  0.63765E3 
  160  Molinare      10 Mgr         7      0.229592E5            
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3 
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3 
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3 
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2 
  210  Lu            10 Mgr        10        0.2001E5            
  220  Smith         51 Sales       7      0.176545E5   0.9928E3 
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3 
  240  Daniels       10 Mgr         5     0.1926025E5            
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3 
  260  Jones         10 Mgr        12       0.21234E5            
  270  Lea           66 Mgr         9      0.185555E5            
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3 
  290  Quill         84 Mgr        10       0.19818E5            
  300  Davis         84 Sales       5      0.154545E5   0.8061E3 
  310  Graham        66 Sales      13          0.21E5   0.2003E3 
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3 
  330  Burke         66 Clerk       1       0.10988E5    0.555E2 
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4 
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3
__IDS_EXPECTED__
   10  Sanders       20 Mgr         7      0.183575E5            
   20  Pernal        20 Sales       8     0.1817125E5  0.61245E3 
   30  Marenghi      38 Mgr         5     0.1750675E5            
   40  OBrien        38 Sales       6       0.18006E5  0.84655E3 
   50  Hanes         15 Mgr        10      0.206598E5            
   60  Quigley       38 Sales       0      0.168083E5  0.65025E3 
   70  Rothman       15 Sales       7     0.1650283E5   0.1152E4 
   80  James         20 Clerk       0      0.135046E5   0.1282E3 
   90  Koonitz       42 Sales       6     0.1800175E5  0.13867E4 
  100  Plotz         42 Mgr         7      0.183528E5            
  110  Ngan          15 Clerk       5      0.125082E5   0.2066E3 
  120  Naughton      38 Clerk       0     0.1295475E5     0.18E3 
  130  Yamaguchi     42 Clerk       6      0.105059E5    0.756E2 
  140  Fraye         51 Mgr         6        0.2115E5            
  150  Williams      51 Sales       6      0.194565E5  0.63765E3 
  160  Molinare      10 Mgr         7      0.229592E5            
  170  Kermisch      15 Clerk       4      0.122585E5   0.1101E3 
  180  Abrahams      38 Clerk       3     0.1200975E5   0.2365E3 
  190  Sneider       20 Clerk       8     0.1425275E5   0.1265E3 
  200  Scoutten      42 Clerk       0      0.115086E5    0.842E2 
  210  Lu            10 Mgr        10        0.2001E5            
  220  Smith         51 Sales       7      0.176545E5   0.9928E3 
  230  Lundquist     51 Clerk       3      0.133698E5  0.18965E3 
  240  Daniels       10 Mgr         5     0.1926025E5            
  250  Wheeler       51 Clerk       6        0.1446E5   0.5133E3 
  260  Jones         10 Mgr        12       0.21234E5            
  270  Lea           66 Mgr         9      0.185555E5            
  280  Wilson        66 Sales       9      0.186745E5   0.8115E3 
  290  Quill         84 Mgr        10       0.19818E5            
  300  Davis         84 Sales       5      0.154545E5   0.8061E3 
  310  Graham        66 Sales      13          0.21E5   0.2003E3 
  320  Gonzales      66 Sales       4      0.168582E5    0.844E3 
  330  Burke         66 Clerk       1       0.10988E5    0.555E2 
  340  Edwards       84 Sales       7       0.17844E5   0.1285E4 
  350  Gafney        84 Clerk       5      0.130305E5    0.188E3
