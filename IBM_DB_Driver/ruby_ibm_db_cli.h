/*
  +----------------------------------------------------------------------+
  |  Licensed Materials - Property of IBM                                |
  |                                                                      |
  | (C) Copyright IBM Corporation 2009 - 2015                            |
  +----------------------------------------------------------------------+
  | Authors: Praveen Devarao, Arvind Gupta                               |
  +----------------------------------------------------------------------+
*/

#ifndef RUBY_IBM_DB_CLI_H
#define RUBY_IBM_DB_CLI_H

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#ifdef _WIN32
#define DLOPEN LoadLibrary
#define DLSYM GetProcAddress
#define DLCLOSE FreeLibrary
#define LIBDB2 "db2cli.dll"
#elif _AIX
#define DLOPEN dlopen
#define DLSYM dlsym
#define DLCLOSE dlclose
#ifdef __64BIT__
/*64-bit library in the archive libdb2.a*/
#define LIBDB2 "libdb2.a(shr_64.o)"
#else
/*32-bit library in the archive libdb2.a*/
#define LIBDB2 "libdb2.a(shr.o)"
#endif
#elif __APPLE__
#define DLOPEN dlopen
#define DLSYM dlsym
#define DLCLOSE dlclose
#define LIBDB2 "libdb2.dylib"
#else
#define DLOPEN dlopen
#define DLSYM dlsym
#define DLCLOSE dlclose
#define LIBDB2 "libdb2.so.1"
#endif

#include <ruby.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>

/* Defines a linked list structure for caching param data */
typedef struct _param_cache_node {
  SQLSMALLINT data_type;          /* Datatype */
  SQLUINTEGER param_size;         /* param size */
  SQLSMALLINT nullable;           /* is Nullable */
  SQLSMALLINT scale;              /* Decimal scale */
  SQLUINTEGER file_options;       /* File options if PARAM_FILE */
  SQLINTEGER  bind_indicator;     /* indicator variable for SQLBindParameter */
  int         param_num;              /* param number in stmt */
  int         param_type;             /* Type of param - INP/OUT/INP-OUT/FILE */
  int         size;                   /* Size of param */
  char        *varname;               /* bound variable name */
  SQLBIGINT   ivalue;                 /* Temp storage value */
  SQLDOUBLE   fvalue;                 /* Temp storage value */
  SQLPOINTER  svalue;                /* Temp storage value */
  struct _param_cache_node *next; /* Pointer to next node */
} param_node;

typedef struct _conn_handle_struct {
  SQLHANDLE    henv;
  SQLHANDLE    hdbc;
  long         auto_commit;
  long         c_bin_mode;
  long         c_case_mode;
  long         c_cursor_type;
  int          handle_active;
  int          transaction_active;
  SQLSMALLINT  error_recno_tracker;
  SQLSMALLINT  errormsg_recno_tracker;
  int          flag_pconnect; /* Indicates that this connection is persistent */

  int  errorType;    /*Indicates Whether the error logged in ruby_error_msg is a statement error or connection error*/

  SQLPOINTER   ruby_error_msg;
  SQLPOINTER   ruby_error_state;
  SQLSMALLINT  ruby_error_msg_len;

  SQLINTEGER   sqlcode;
} conn_handle;

typedef union {
  SQLINTEGER   i_val;
  SQLDOUBLE    d_val;
  SQLFLOAT     f_val;
  SQLSMALLINT  s_val;
  SQLPOINTER   str_val;
} ibm_db_row_data_type;

typedef struct {
  SQLINTEGER            out_length;
  ibm_db_row_data_type  data;
} ibm_db_row_type;

typedef struct _ibm_db_result_set_info_struct {
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR     *name;
  long         name_length;
#else
  SQLCHAR      *name;
#endif
  SQLSMALLINT  type;
  SQLUINTEGER  size;
  SQLSMALLINT  scale;
  SQLSMALLINT  nullable;
  SQLINTEGER   lob_loc;
  SQLINTEGER   loc_ind;
  SQLSMALLINT  loc_type;
} ibm_db_result_set_info;

typedef struct _row_hash_struct {
  VALUE hash;
} row_hash_struct;

typedef struct _stmt_handle_struct {
  SQLHANDLE    hdbc;
  SQLHANDLE    hstmt;
  long         s_bin_mode;
  long         cursor_type;
  long         s_case_mode;
  SQLSMALLINT  error_recno_tracker;
  SQLSMALLINT  errormsg_recno_tracker;

  /* Parameter Caching variables */
  param_node   *head_cache_list;
  param_node   *current_node;

  int          num_params;       /* Number of Params */
  int          file_param;       /* if option passed in is FILE_PARAM */
  int          num_columns;
  int          is_executing;
  int          is_freed;        /* Indicates if the SQLFreeHandle is been called on the handle or not.*/

  ibm_db_result_set_info  *column_info;
  ibm_db_row_type         *row_data;

  SQLPOINTER   ruby_stmt_err_msg;
  SQLPOINTER   ruby_stmt_err_state;
  SQLSMALLINT  ruby_stmt_err_msg_len;
  SQLINTEGER   sqlcode;
  int		   rc;
} stmt_handle;

/* 
    Structure holding the data to be passed to SQLConnect or SQLDriverConnect CLI call 
*/
typedef struct _ibm_db_connect_args_struct {
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR          *database;
  SQLWCHAR          *uid;
  SQLWCHAR          *password;
#else
  SQLCHAR          *database;
  SQLCHAR          *uid;
  SQLCHAR          *password;
#endif
  SQLSMALLINT       database_len;
  SQLSMALLINT       uid_len;
  SQLSMALLINT       password_len;
  int           ctlg_conn;        /*Indicates if the connection is a cataloged connection or not*/
  SQLHANDLE     *hdbc;
} connect_args;

/* 
    Structure holding the necessary info to be passed to SQLEndTran CLI call
*/
typedef struct _ibm_db_end_tran_args_struct {
  SQLHANDLE      *hdbc;
  SQLSMALLINT    handleType;
  SQLSMALLINT    completionType;
  int 			 rc;
} end_tran_args;

/* 
    Structure holding the necessary info to be passed to SQLDescribeparam CLI call
*/
typedef struct _ibm_db_describeparam_args_struct {
  stmt_handle   *stmt_res;
  SQLUSMALLINT  param_no;
  SQLSMALLINT   sql_data_type;
  SQLUINTEGER   sql_precision;
  SQLSMALLINT   sql_scale;
  SQLSMALLINT   sql_nullable;
  int 			rc;
} describeparam_args;

/* 
    Structure holding the necessary info to be passed to SQLDescribeCol CLI call
*/
typedef struct _ibm_db_describecol_args_struct {
  stmt_handle   *stmt_res;
  SQLUSMALLINT  col_no;
  SQLSMALLINT   name_length;
  SQLSMALLINT   buff_length;
} describecol_args;
/*
    Structure holding the necessary info to be passed to CLI calls like SQLColumns
    SQLForeignKeys etc. The same structure is used to get the SP parameters, with table_name as proc_name
*/
typedef struct _ibm_db_metadata_args_struct {
  stmt_handle   *stmt_res;
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR      *qualifier;
  SQLWCHAR      *owner;
  SQLWCHAR      *table_name;
  SQLWCHAR      *proc_name;  /*Used for call SQLProcedureColumns*/
  SQLWCHAR      *column_name;
  SQLWCHAR      *table_type;
#else
  SQLCHAR       *qualifier;
  SQLCHAR       *owner;
  SQLCHAR       *table_name;
  SQLCHAR       *proc_name;  /*Used for call SQLProcedureColumns*/
  SQLCHAR       *column_name;
  SQLCHAR       *table_type;
#endif
  SQLSMALLINT   qualifier_len;
  SQLSMALLINT   owner_len;
  SQLSMALLINT   table_name_len;
  SQLSMALLINT   proc_name_len;  /*Used for call SQLProcedureColumns*/
  SQLSMALLINT   column_name_len;
  SQLSMALLINT   table_type_len;
  int           scope;       /*Used in SQLSpecialColumns To determine the scope of the unique row identifier*/
  int           unique;      /*Used in SQLStatistics to determine if only unique indexes are to be fetched or all*/
  int 			rc;

} metadata_args;

/* 
    Structure holding the necessary info to be passed to SQLPrepare and SQLExecDirect CLI call
*/
typedef struct _ibm_db_exec_direct_args_struct {
  stmt_handle   *stmt_res;
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR      *stmt_string;
#else
  SQLCHAR       *stmt_string;
#endif
  long          stmt_string_len;
  int 			rc;
} exec_cum_prepare_args;

/* 
    Structure holding the necessary info to be passed to SQLCreateDB and SQLDropDB CLI call
*/
typedef struct _ibm_db_create_drop_db_args_struct {
  conn_handle   *conn_res;
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR      *dbName;
  SQLWCHAR      *codeSet;
  SQLWCHAR      *mode;
#else
  SQLCHAR       *dbName;
  SQLCHAR       *codeSet;
  SQLCHAR       *mode;
#endif
  long          dbName_string_len;
  long          codeSet_string_len;
  long          mode_string_len;
  int 			rc;
} create_drop_db_args;

/* 
    Structure holding the necessary info to be passed to SQLParamData and SQLPutData CLI call
*/
typedef struct _ibm_db_param_and_put_data_struct {
  stmt_handle   *stmt_res;
  SQLPOINTER    valuePtr;
} param_cum_put_data_args;

/* 
    Structure holding the necessary info to be passed to SQLNextResult CLI call
*/
typedef struct _ibm_db_next_result_args_struct {
  SQLHSTMT      *new_hstmt;
  stmt_handle   *stmt_res;
  int 			rc;
} next_result_args;

/* 
    Structure holding the necessary info to be passed to calls SQLNumResultCols/SQLNumParams
*/
typedef struct _ibm_db_row_col_count_struct {
  stmt_handle    *stmt_res;
  SQLSMALLINT    count;
  int 			 rc;
} row_col_count_args;

/* 
    Structure holding the necessary info to be passed to call SQLRowcount
*/
typedef struct _ibm_db_row_count_struct {
  stmt_handle    *stmt_res;
  SQLINTEGER     count;
  int 			 rc;
} sql_row_count_args;

/* 
    Structure holding the necessary info to be passed to call SQLColAttributes
*/
typedef struct _ibm_db_col_attr_struct {
  stmt_handle    *stmt_res;
  SQLSMALLINT    col_num;
  SQLSMALLINT    FieldIdentifier;
  SQLINTEGER     num_attr;
  int 			 rc;
} col_attr_args;

/* 
    Structure holding the necessary info to be passed to call SQLBindCol
*/
typedef struct _ibm_db_bind_col_struct {
  stmt_handle    *stmt_res;
  SQLUSMALLINT   col_num;
  SQLSMALLINT    TargetType;
  SQLPOINTER     TargetValuePtr;
  SQLLEN         buff_length;
  SQLLEN         *out_length;
} bind_col_args;

/* 
    Structure holding the necessary info to be passed to call SQLGetData
*/
typedef struct _ibm_db_get_data_args_struct {
  stmt_handle    *stmt_res;
  SQLSMALLINT    col_num;
  SQLSMALLINT    targetType;
  SQLPOINTER     buff;
  SQLLEN         buff_length;
  SQLLEN         *out_length;
} get_data_args;

/* 
    Structure holding the necessary info to be passed to call SQLGetLength
*/
typedef struct _ibm_db_get_data_length_struct {
  SQLHSTMT       *new_hstmt;
  SQLSMALLINT    col_num;
  stmt_handle    *stmt_res;
  SQLINTEGER     *sLength;

} get_length_args;

/* 
    Structure holding the necessary info to be passed to call SQLGetSubString
*/
typedef struct _ibm_db_get_data_subString_struct {
  SQLHSTMT       *new_hstmt;
  SQLSMALLINT    col_num;
  stmt_handle    *stmt_res;
  SQLUINTEGER    forLength;
  SQLSMALLINT    targetCType;
  SQLPOINTER     buffer;
  SQLLEN         buff_length;
  SQLINTEGER     *out_length;

} get_subString_args;

/* 
    Structure holding the necessary info to be passed to call SQLFetchScroll and SQLFetch
*/
typedef struct _ibm_db_fetch_data_struct {
  stmt_handle    *stmt_res;
  SQLSMALLINT    fetchOrientation;
  SQLLEN         fetchOffset;
} fetch_data_args;

/* 
    Structure holding the necessary info to be passed to calls SQLSetStmtAttr/SQLSetConnectAttr/SQLEnvAttr
*/
typedef struct _ibm_db_set_handle_attr_struct {
  SQLHANDLE    *handle;
  SQLINTEGER   attribute;
  SQLPOINTER   valuePtr;
  SQLINTEGER   strLength;

} set_handle_attr_args;

/* 
    Structure holding the necessary info to be passed to call SQLGetStmtAttr and SQLGetConnectAttr
*/
typedef struct _ibm_db_get_handle_attr_struct {
  SQLHANDLE    *handle;
  SQLINTEGER   attribute;
  SQLPOINTER   valuePtr;
  SQLINTEGER   buff_length;
  SQLINTEGER   *out_length;
} get_handle_attr_args;

/* 
    Structure holding the necessary info to be passed to call SQLBindParameter
*/
typedef struct _ibm_db_bind_parameter_struct {
  stmt_handle    *stmt_res;
  SQLSMALLINT    param_num;
  SQLSMALLINT    IOType;
  SQLSMALLINT    valueType;
  SQLSMALLINT    paramType;
  SQLULEN        colSize;
  SQLSMALLINT    decimalDigits;
  SQLPOINTER     paramValPtr;
  SQLLEN         buff_length;
  SQLLEN         *out_length;
} bind_parameter_args;

/* 
    Structure holding the necessary info to be passed to call SQLGetInfo
*/
typedef struct _ibm_db_get_info_struct {
  conn_handle   *conn_res;
  SQLUSMALLINT  infoType;
  SQLPOINTER    infoValue;
  SQLSMALLINT   buff_length;
  SQLSMALLINT   *out_length;
  VALUE 		return_value;
} get_info_args;

/* 
    Structure holding the necessary info to be passed to call SQLGetDiagRec
*/
typedef struct _ibm_db_get_diagRec_struct {
  SQLSMALLINT       hType;
  SQLHANDLE         handle;
  SQLSMALLINT       recNum;
  SQLPOINTER        SQLState;
  SQLPOINTER        msgText;
  SQLINTEGER        *NativeErrorPtr;
  SQLSMALLINT       buff_length;
  SQLSMALLINT       *text_length_ptr;
  int  				return_code;
} get_diagRec_args;

/* 
    Structure holding the necessary info to be passed to call SQLFreestmt
*/
typedef struct _ibm_db_free_stmt_struct {
  stmt_handle   *stmt_res;
  SQLUSMALLINT  option;
  int			rc;
} free_stmt_args;

int _ruby_ibm_db_SQLConnect_helper(connect_args *data);
int _ruby_ibm_db_SQLDisconnect_helper(SQLHANDLE *hdbc);
void _ruby_ibm_db_Connection_level_UBF(void *data);
int _ruby_ibm_db_SQLEndTran(end_tran_args *endtran_args);
int _ruby_ibm_db_SQLDescribeParam_helper(describeparam_args *data);
int _ruby_ibm_db_SQLDescribeCol_helper(describecol_args *data);
int _ruby_ibm_db_SQLBindCol_helper(bind_col_args *data);
int _ruby_ibm_db_SQLColumnPrivileges_helper(metadata_args *data);
int _ruby_ibm_db_SQLColumns_helper(metadata_args *data);
int _ruby_ibm_db_SQLPrimaryKeys_helper(metadata_args *data);
int _ruby_ibm_db_SQLForeignKeys_helper(metadata_args *data);
int _ruby_ibm_db_SQLProcedureColumns_helper(metadata_args *data);
int _ruby_ibm_db_SQLProcedures_helper(metadata_args *data);
int _ruby_ibm_db_SQLSpecialColumns_helper(metadata_args *data);
int _ruby_ibm_db_SQLStatistics_helper(metadata_args *data);
int _ruby_ibm_db_SQLTablePrivileges_helper(metadata_args *data);
int _ruby_ibm_db_SQLTables_helper(metadata_args *data);
int _ruby_ibm_db_SQLExecDirect_helper(exec_cum_prepare_args *data);
int _ruby_ibm_db_SQLPrepare_helper(exec_cum_prepare_args *data);
int _ruby_ibm_db_SQLFreeStmt_helper(free_stmt_args *data);
int _ruby_ibm_db_SQLExecute_helper(stmt_handle *stmt_res);
int _ruby_ibm_db_SQLParamData_helper(param_cum_put_data_args *data);
int _ruby_ibm_db_SQLColAttributes_helper(col_attr_args *data);
int _ruby_ibm_db_SQLPutData_helper(param_cum_put_data_args *data);
int _ruby_ibm_db_SQLGetData_helper(get_data_args *data);
int _ruby_ibm_db_SQLGetLength_helper(get_length_args *data);
int _ruby_ibm_db_SQLGetSubString_helper(get_subString_args *data);
int _ruby_ibm_db_SQLNextResult_helper(next_result_args *data);
int _ruby_ibm_db_SQLFetchScroll_helper(fetch_data_args *data);
int _ruby_ibm_db_SQLFetch_helper(fetch_data_args *data);
int _ruby_ibm_db_SQLNumResultCols_helper(row_col_count_args *data);
int _ruby_ibm_db_SQLNumParams_helper(row_col_count_args *data);
int _ruby_ibm_db_SQLRowCount_helper(sql_row_count_args *data);
int _ruby_ibm_db_SQLGetInfo_helper(get_info_args *data);
int _ruby_ibm_db_SQLGetDiagRec_helper(get_diagRec_args *data);
int _ruby_ibm_db_SQLSetStmtAttr_helper(set_handle_attr_args *data);
int _ruby_ibm_db_SQLSetConnectAttr_helper(set_handle_attr_args *data);
int _ruby_ibm_db_SQLSetEnvAttr_helper(set_handle_attr_args *data);
int _ruby_ibm_db_SQLGetStmtAttr_helper(get_handle_attr_args *data);
int _ruby_ibm_db_SQLGetConnectAttr_helper(get_handle_attr_args *data);
int _ruby_ibm_db_SQLBindFileToParam_helper(stmt_handle *stmt_res, param_node *curr);
int _ruby_ibm_db_SQLBindParameter_helper(bind_parameter_args *data);
void _ruby_ibm_db_Statement_level_UBF(stmt_handle *stmt_res);
int _ruby_ibm_db_SQLCreateDB_helper(create_drop_db_args *data);
int _ruby_ibm_db_SQLDropDB_helper(create_drop_db_args *data);

#endif  /* RUBY_IBM_DB_CLI_H */
