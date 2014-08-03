# 
#  Licensed Materials - Property of IBM
#
#  (c) Copyright IBM Corp. 2007,2008,2009
#

class TestIbmDb < Test::Unit::TestCase

  def test_103_numfields_FetchArrayMany
    assert_expect do
      conn = IBM_DB::connect db, username, password
      
      if conn
        result = IBM_DB::exec conn, "select * from org, project order by org.location, project.projname"
        cols = IBM_DB::num_fields result
        j=0
        while (row = IBM_DB::fetch_array(result))
         print "#{j}) "
         for i in (0 ... cols)
           if row[i] == '      '
             row[i] = ''
           end
           print "#{row[i]}\t|\t"
         end
         print "\n";    
         j+=1
        end
        IBM_DB::close conn
      else
        print IBM_DB::conn_errormsg()
      end
    end
  end

end

__END__
__LUW_EXPECTED__
0) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
1) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
2) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
3) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
4) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
5) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
6) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
7) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
8) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
9) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
10) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
11) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
12) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
13) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
14) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
15) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
16) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
17) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
18) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
19) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
20) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
21) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
22) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
23) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
24) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
25) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
26) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
27) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
28) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
29) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
30) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
31) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
32) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
33) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
34) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
35) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
36) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
37) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
38) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
39) 15	|	New England	|	50	|	Eastern	|	Boston	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
40) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
41) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
42) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
43) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
44) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
45) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
46) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
47) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
48) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
49) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
50) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
51) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
52) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
53) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
54) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
55) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
56) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
57) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
58) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
59) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
60) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
61) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
62) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
63) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
64) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
65) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
66) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
67) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
68) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
69) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
70) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
71) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
72) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
73) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
74) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
75) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
76) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
77) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
78) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
79) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
80) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
81) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
82) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
83) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
84) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
85) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
86) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
87) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
88) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
89) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
90) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
91) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
92) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
93) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
94) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
95) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
96) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
97) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
98) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
99) 84	|	Mountain	|	290	|	Western	|	Denver	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
100) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
101) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
102) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
103) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
104) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
105) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
106) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
107) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
108) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
109) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
110) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
111) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
112) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
113) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
114) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
115) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
116) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
117) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
118) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
119) 10	|	Head Office	|	160	|	Corporate	|	New York	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
120) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
121) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
122) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
123) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
124) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
125) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
126) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
127) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
128) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
129) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
130) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
131) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
132) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
133) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
134) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
135) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
136) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
137) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
138) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
139) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
140) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
141) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
142) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
143) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
144) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
145) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
146) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
147) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
148) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
149) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
150) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
151) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
152) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
153) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
154) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
155) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
156) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
157) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
158) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
159) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|
__ZOS_EXPECTED__
0) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
1) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
2) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
3) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
4) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
5) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
6) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
7) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
8) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
9) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
10) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
11) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
12) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
13) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
14) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
15) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
16) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
17) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
18) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
19) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
20) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
21) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
22) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
23) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
24) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
25) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
26) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
27) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
28) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
29) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
30) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
31) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
32) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
33) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
34) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
35) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
36) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
37) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
38) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
39) 15	|	New England	|	50	|	Eastern	|	Boston	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
40) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
41) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
42) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
43) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
44) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
45) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
46) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
47) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
48) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
49) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
50) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
51) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
52) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
53) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
54) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
55) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
56) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
57) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
58) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
59) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
60) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
61) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
62) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
63) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
64) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
65) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
66) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
67) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
68) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
69) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
70) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
71) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
72) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
73) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
74) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
75) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
76) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
77) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
78) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
79) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
80) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
81) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
82) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
83) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
84) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
85) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
86) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
87) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
88) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
89) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
90) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
91) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
92) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
93) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
94) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
95) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
96) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
97) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
98) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
99) 84	|	Mountain	|	290	|	Western	|	Denver	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
100) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
101) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
102) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
103) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
104) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
105) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
106) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
107) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
108) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
109) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
110) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
111) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
112) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
113) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
114) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
115) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
116) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
117) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
118) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
119) 10	|	Head Office	|	160	|	Corporate	|	New York	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
120) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
121) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
122) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
123) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
124) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
125) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
126) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
127) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
128) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
129) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
130) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
131) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
132) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
133) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
134) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
135) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
136) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
137) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
138) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
139) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
140) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
141) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
142) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
143) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
144) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
145) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
146) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
147) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
148) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
149) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
150) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
151) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
152) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
153) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
154) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
155) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
156) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
157) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
158) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
159) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|
__SYSTEMI_EXPECTED__
0) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
1) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
2) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
3) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
4) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
5) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
6) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
7) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
8) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
9) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
10) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
11) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
12) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
13) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
14) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
15) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
16) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
17) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
18) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
19) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
20) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
21) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
22) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
23) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
24) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
25) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
26) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
27) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
28) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
29) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
30) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
31) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
32) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
33) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
34) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
35) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
36) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
37) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
38) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
39) 15	|	New England	|	50	|	Eastern	|	Boston	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
40) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
41) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
42) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
43) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
44) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
45) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
46) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
47) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
48) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
49) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
50) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
51) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
52) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
53) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
54) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
55) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
56) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
57) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
58) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
59) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
60) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
61) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
62) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
63) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
64) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
65) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
66) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
67) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
68) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
69) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
70) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
71) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
72) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
73) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
74) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
75) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
76) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
77) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
78) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
79) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
80) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
81) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
82) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
83) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
84) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
85) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
86) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
87) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
88) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
89) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
90) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
91) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
92) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
93) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
94) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
95) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
96) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
97) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
98) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
99) 84	|	Mountain	|	290	|	Western	|	Denver	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
100) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
101) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
102) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
103) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
104) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
105) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
106) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
107) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
108) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
109) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
110) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
111) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
112) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
113) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
114) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
115) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
116) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
117) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
118) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
119) 10	|	Head Office	|	160	|	Corporate	|	New York	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
120) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
121) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
122) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
123) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
124) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
125) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
126) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
127) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
128) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
129) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
130) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
131) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
132) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
133) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
134) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
135) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
136) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
137) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
138) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
139) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
140) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
141) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
142) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
143) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
144) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
145) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
146) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
147) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
148) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
149) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
150) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
151) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
152) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
153) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
154) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
155) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
156) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
157) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
158) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
159) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|
__IDS_EXPECTED__
0) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
1) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
2) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
3) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
4) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
5) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
6) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
7) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
8) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
9) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
10) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
11) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
12) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
13) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
14) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
15) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
16) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
17) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
18) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
19) 38	|	South Atlantic	|	30	|	Eastern	|	Atlanta	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
20) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
21) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
22) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
23) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
24) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
25) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
26) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
27) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
28) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
29) 15	|	New England	|	50	|	Eastern	|	Boston	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
30) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
31) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
32) 15	|	New England	|	50	|	Eastern	|	Boston	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
33) 15	|	New England	|	50	|	Eastern	|	Boston	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
34) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
35) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
36) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
37) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
38) 15	|	New England	|	50	|	Eastern	|	Boston	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
39) 15	|	New England	|	50	|	Eastern	|	Boston	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
40) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
41) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
42) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
43) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
44) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
45) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
46) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
47) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
48) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
49) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
50) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
51) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
52) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
53) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
54) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
55) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
56) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
57) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
58) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
59) 42	|	Great Lakes	|	100	|	Midwest	|	Chicago	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
60) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
61) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
62) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
63) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
64) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
65) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
66) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
67) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
68) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
69) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
70) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
71) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
72) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
73) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
74) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
75) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
76) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
77) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
78) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
79) 51	|	Plains	|	140	|	Midwest	|	Dallas	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
80) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
81) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
82) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
83) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
84) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
85) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
86) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
87) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
88) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
89) 84	|	Mountain	|	290	|	Western	|	Denver	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
90) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
91) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
92) 84	|	Mountain	|	290	|	Western	|	Denver	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
93) 84	|	Mountain	|	290	|	Western	|	Denver	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
94) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
95) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
96) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
97) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
98) 84	|	Mountain	|	290	|	Western	|	Denver	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
99) 84	|	Mountain	|	290	|	Western	|	Denver	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
100) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
101) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
102) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
103) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
104) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
105) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
106) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
107) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
108) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
109) 10	|	Head Office	|	160	|	Corporate	|	New York	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
110) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
111) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
112) 10	|	Head Office	|	160	|	Corporate	|	New York	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
113) 10	|	Head Office	|	160	|	Corporate	|	New York	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
114) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
115) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
116) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
117) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
118) 10	|	Head Office	|	160	|	Corporate	|	New York	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
119) 10	|	Head Office	|	160	|	Corporate	|	New York	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
120) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
121) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
122) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
123) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
124) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
125) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
126) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
127) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
128) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
129) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
130) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
131) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
132) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
133) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
134) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
135) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
136) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
137) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
138) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
139) 66	|	Pacific	|	270	|	Western	|	San Francisco	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|	
140) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3113	|	ACCOUNT PROGRAMMING	|	D21	|	000270	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
141) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3100	|	ADMIN SERVICES	|	D01	|	000010	|	0.65E1	|	1982-01-01	|	1983-02-01	|		|	
142) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2012	|	APPLICATIONS SUPPORT	|	E21	|	000330	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
143) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2013	|	DB/DC SUPPORT	|	E21	|	000340	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
144) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2000	|	GEN SYSTEMS SERVICES	|	E01	|	000050	|	0.5E1	|	1982-01-01	|	1983-02-01	|		|	
145) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3110	|	GENERAL ADMIN SYSTEMS	|	D21	|	000070	|	0.6E1	|	1982-01-01	|	1983-02-01	|	AD3100	|	
146) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1010	|	OPERATION	|	E11	|	000090	|	0.5E1	|	1982-01-01	|	1983-02-01	|	OP1000	|	
147) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP1000	|	OPERATION SUPPORT	|	E01	|	000050	|	0.6E1	|	1982-01-01	|	1983-02-01	|		|	
148) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3111	|	PAYROLL PROGRAMMING	|	D21	|	000230	|	0.2E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
149) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	AD3112	|	PERSONNEL PROGRAMMING	|	D21	|	000250	|	0.1E1	|	1982-01-01	|	1983-02-01	|	AD3110	|	
150) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF1000	|	QUERY SERVICES	|	C01	|	000030	|	0.2E1	|	1982-01-01	|	1983-02-01	|		|	
151) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2011	|	SCP SYSTEMS SUPPORT	|	E21	|	000320	|	0.1E1	|	1982-01-01	|	1983-02-01	|	OP2010	|	
152) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	OP2010	|	SYSTEMS SUPPORT	|	E21	|	000100	|	0.4E1	|	1982-01-01	|	1983-02-01	|	OP2000	|	
153) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	IF2000	|	USER EDUCATION	|	C01	|	000030	|	0.1E1	|	1982-01-01	|	1983-02-01	|		|	
154) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2113	|	W L PROD CONT PROGS	|	D11	|	000160	|	0.3E1	|	1982-02-15	|	1982-12-01	|	MA2110	|	
155) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2111	|	W L PROGRAM DESIGN	|	D11	|	000220	|	0.2E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
156) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2110	|	W L PROGRAMMING	|	D11	|	000060	|	0.9E1	|	1982-01-01	|	1983-02-01	|	MA2100	|	
157) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2112	|	W L ROBOT DESIGN	|	D11	|	000150	|	0.3E1	|	1982-01-01	|	1982-12-01	|	MA2110	|	
158) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	MA2100	|	WELD LINE AUTOMATION	|	D01	|	000010	|	0.12E2	|	1982-01-01	|	1983-02-01	|		|	
159) 20	|	Mid Atlantic	|	10	|	Eastern	|	Washington	|	PL2100	|	WELD LINE PLANNING	|	B01	|	000020	|	0.1E1	|	1982-01-01	|	1982-09-15	|	MA2100	|
