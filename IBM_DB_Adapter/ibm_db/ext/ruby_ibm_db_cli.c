/*
  +----------------------------------------------------------------------+
  |  Licensed Materials - Property of IBM                                |
  |                                                                      |
  | (C) Copyright IBM Corporation 2009 - 2015                            |
  +----------------------------------------------------------------------+
  | Authors: Praveen Devarao, Arvind Gupta                               |
  +----------------------------------------------------------------------+
*/


/*
    This C file contains functions that perform DB operations, which can take long time to complete.
    For Eg: - Like SQLConnect, SQLFetch etc.

    This file in general will contain functions that make CLI calls and 
    depending on whether the call will be transferred to server or not the functions are termed long time comsuming or not.

    The functions which will contact the server and hence can be time consuming will be called by ruby's (1.9 onwards)
    rb_thread_blocking_region method, which inturn will release the GVL while these operations are being performed. 
    With this the executing thread will become unblocking allowing concurrent threads perform operations simultaneously.
*/

#include "ruby.h"

#include "ruby_ibm_db_cli.h"

/*
    This function connects to the database using either SQLConnect or SQLDriverConnect CLI API
    depending on whether it is a cataloged or an uncataloged connection.
*/
int _ruby_ibm_db_SQLConnect_helper(connect_args *data) {
  if(data->ctlg_conn == 1) {
#ifndef UNICODE_SUPPORT_VERSION
    return SQLConnect( (SQLHDBC)*(data->hdbc), (SQLCHAR *)data->database,
            (SQLSMALLINT)data->database_len, (SQLCHAR *)data->uid, (SQLSMALLINT)data->uid_len,
            (SQLCHAR *)data->password, (SQLSMALLINT)data->password_len );
#else
    return SQLConnectW( (SQLHDBC)*(data->hdbc), data->database,
            data->database_len, data->uid, data->uid_len,
            data->password, data->password_len );
#endif
  } else {
#ifndef UNICODE_SUPPORT_VERSION
    return SQLDriverConnect( (SQLHDBC) *(data->hdbc), (SQLHWND)NULL,
            (SQLCHAR*)data->database, SQL_NTS, NULL, 0, NULL, SQL_DRIVER_NOPROMPT );
#else
    return SQLDriverConnectW( (SQLHDBC) *(data->hdbc), (SQLHWND)NULL,
            data->database, SQL_NTS, NULL, 0, NULL, SQL_DRIVER_NOPROMPT );
#endif
  }
}

/*
    This function issues SQLDisconnect to disconnect from the Dataserver
*/
int _ruby_ibm_db_SQLDisconnect_helper(SQLHANDLE *hdbc) {
  return SQLDisconnect( (SQLHDBC) *hdbc );  
}

/*
   Connection level Unblock function. This function is called when a thread interruput is issued while executing a
   connection level SQL call
*/
void _ruby_ibm_db_Connection_level_UBF(void *data) {	
    return;
}

/*
    This function will commit and end the inprogress transaction by issuing a SQLCommit
*/
int _ruby_ibm_db_SQLEndTran(end_tran_args *endtran_args) {
  int rc = 0;
  rc = SQLEndTran( endtran_args->handleType, *(endtran_args->hdbc), endtran_args->completionType );  
  endtran_args->rc = rc;
  return rc;
}

/*
   This function call the SQLDescribeParam cli call to get the description of the parameter in the sql specified
*/
int _ruby_ibm_db_SQLDescribeParam_helper(describeparam_args *data) {
  int rc = 0;
  data->stmt_res->is_executing = 1;

  rc = SQLDescribeParam( (SQLHSTMT) data->stmt_res->hstmt, (SQLUSMALLINT)data->param_no, &(data->sql_data_type),
                &(data->sql_precision), &(data->sql_scale), &(data->sql_nullable) );

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function call the SQLDescribeCol cli call to get the description of the parameter in the sql specified
*/
int _ruby_ibm_db_SQLDescribeCol_helper(describecol_args *data) {
  int i  = data->col_no - 1;
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifdef UNICODE_SUPPORT_VERSION
  rc = SQLDescribeColW( (SQLHSTMT)data->stmt_res->hstmt, (SQLSMALLINT)(data->col_no),
      data->stmt_res->column_info[i].name, data->buff_length, &(data->name_length),
      &(data->stmt_res->column_info[i].type), &(data->stmt_res->column_info[i].size),
      &(data->stmt_res->column_info[i].scale), &(data->stmt_res->column_info[i].nullable) );
#else
  rc = SQLDescribeCol( (SQLHSTMT)data->stmt_res->hstmt, (SQLSMALLINT)(data->col_no),
      data->stmt_res->column_info[i].name, data->buff_length, &(data->name_length), 
      &(data->stmt_res->column_info[i].type), &(data->stmt_res->column_info[i].size), 
      &(data->stmt_res->column_info[i].scale), &(data->stmt_res->column_info[i].nullable) );
#endif

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function call the SQLBindCol cli call to get the description of the parameter in the sql specified
*/
int _ruby_ibm_db_SQLBindCol_helper(bind_col_args *data) {
  int rc = 0;
  data->stmt_res->is_executing = 1;

  rc = SQLBindCol( (SQLHSTMT) data->stmt_res->hstmt, (SQLUSMALLINT)(data->col_num),
          data->TargetType, data->TargetValuePtr, data->buff_length,
          data->out_length );

  data->stmt_res->is_executing = 0;
  return rc;
}

/*
   This function calls SQLColumnPrivileges cli call to get the list of columns and the associated privileges
*/
int _ruby_ibm_db_SQLColumnPrivileges_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLColumnPrivileges( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
            data->owner, data->owner_len, data->table_name, data->table_name_len, 
            data->column_name, data->column_name_len );
#else
  rc = SQLColumnPrivilegesW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
            data->owner, data->owner_len, data->table_name, data->table_name_len,
            data->column_name, data->column_name_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc=rc;
  return rc;

}

/*
   This function calls SQLColumns cli call to get the list of columns and the associated metadata of the table
*/
int _ruby_ibm_db_SQLColumns_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLColumns( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
            data->owner, data->owner_len, data->table_name, data->table_name_len,
            data->column_name, data->column_name_len );
#else
  rc = SQLColumnsW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
            data->owner, data->owner_len, data->table_name, data->table_name_len,
            data->column_name, data->column_name_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLPrimaryKeys cli call to get the list of primay key columns and the associated metadata
*/
int _ruby_ibm_db_SQLPrimaryKeys_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLPrimaryKeys( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, data->table_name, data->table_name_len );
#else
  rc = SQLPrimaryKeysW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, data->table_name, data->table_name_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLForeignKeys cli call to get the list of foreign key columns and the associated metadata
*/
int _ruby_ibm_db_SQLForeignKeys_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  if(!NIL_P(data->table_type))
  {
#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLForeignKeys( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, NULL , SQL_NTS, NULL, SQL_NTS,
                NULL, SQL_NTS, data->table_name, data->table_name_len );
#else
  rc = SQLForeignKeysW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, NULL , SQL_NTS, NULL, SQL_NTS,
                NULL, SQL_NTS, data->table_name, data->table_name_len );
#endif
  }
  else
  {
#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLForeignKeys( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, data->table_name , data->table_name_len, NULL, SQL_NTS,
                NULL, SQL_NTS, NULL, SQL_NTS );
#else
  rc = SQLForeignKeysW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, data->table_name , data->table_name_len, NULL, SQL_NTS,
                NULL, SQL_NTS, NULL, SQL_NTS );
#endif
	}

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLProcedureColumns cli call to get the list of parameters 
   and associated metadata of the stored procedure
*/
int _ruby_ibm_db_SQLProcedureColumns_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLProcedureColumns( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->proc_name, data->proc_name_len, data->column_name, data->column_name_len );
#else
  rc = SQLProcedureColumnsW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->proc_name, data->proc_name_len, data->column_name, data->column_name_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLProcedures cli call to get the list of stored procedures 
   and associated metadata of the stored procedure
*/
int _ruby_ibm_db_SQLProcedures_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLProcedures( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->proc_name, data->proc_name_len );
#else
  rc = SQLProceduresW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->proc_name, data->proc_name_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLSpecialColumns cli call to get the metadata related to the special columns 
   (Unique index or primary key column) and associated metadata
*/
int _ruby_ibm_db_SQLSpecialColumns_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLSpecialColumns( (SQLHSTMT) data->stmt_res->hstmt, SQL_BEST_ROWID, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, data->table_name, data->table_name_len,
                (SQLUSMALLINT)data->scope, SQL_NULLABLE );
#else
  rc = SQLSpecialColumnsW( (SQLHSTMT) data->stmt_res->hstmt, SQL_BEST_ROWID, data->qualifier, data->qualifier_len,
                data->owner, data->owner_len, data->table_name, data->table_name_len,
                (SQLUSMALLINT)data->scope, SQL_NULLABLE );
#endif

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLStatistics cli call to get the index information for a given table. 
*/
int _ruby_ibm_db_SQLStatistics_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLStatistics( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->table_name, data->table_name_len, (SQLUSMALLINT)data->unique, SQL_QUICK );
#else
  rc = SQLStatisticsW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->table_name, data->table_name_len, (SQLUSMALLINT)data->unique, SQL_QUICK );
#endif

  data->stmt_res->is_executing = 0;
  data->rc= rc;
  return rc;
}

/*
   This function calls SQLTablePrivileges cli call to retrieve list of tables and 
   the asscociated privileges for each table. 
*/
int _ruby_ibm_db_SQLTablePrivileges_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLTablePrivileges( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
            data->owner, data->owner_len, data->table_name, data->table_name_len );
#else
  rc = SQLTablePrivilegesW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len,
            data->owner, data->owner_len, data->table_name, data->table_name_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLTables cli call to retrieve list of tables in the specified schema and 
   the asscociated metadata for each table. 
*/
int _ruby_ibm_db_SQLTables_helper(metadata_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLTables( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->table_name, data->table_name_len, data->table_type, data->table_type_len );
#else
  rc = SQLTablesW( (SQLHSTMT) data->stmt_res->hstmt, data->qualifier, data->qualifier_len, data->owner,
          data->owner_len, data->table_name, data->table_name_len, data->table_type, data->table_type_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLExecDirect cli call to execute a statement directly
*/
int _ruby_ibm_db_SQLExecDirect_helper(exec_cum_prepare_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLExecDirect( (SQLHSTMT) data->stmt_res->hstmt, data->stmt_string, (SQLINTEGER)data->stmt_string_len );  
#else
  rc = SQLExecDirectW( (SQLHSTMT) data->stmt_res->hstmt, data->stmt_string, (SQLINTEGER)data->stmt_string_len );
#endif

  data->stmt_res->is_executing = 0;
  data->rc=rc;
  return rc;
}

/*
   This function calls SQLCreateDb cli call
*/
int _ruby_ibm_db_SQLCreateDB_helper(create_drop_db_args *data) {
  int rc = 0;
#ifndef UNICODE_SUPPORT_VERSION
  #ifdef _WIN32
    HINSTANCE cliLib = NULL;
    FARPROC sqlcreatedb;
    cliLib = DLOPEN( LIBDB2 );
    sqlcreatedb =  DLSYM( cliLib, "SQLCreateDb" );
  #elif _AIX
    void *cliLib = NULL;
    typedef int (*sqlcreatedbType)( SQLHDBC, SQLCHAR *, SQLINTEGER, SQLCHAR *, SQLINTEGER, SQLCHAR *, SQLINTEGER );
    sqlcreatedbType sqlcreatedb;
  /* On AIX CLI library is in archive. Hence we will need to specify flags in DLOPEN to load a member of the archive*/
    cliLib = DLOPEN( LIBDB2, RTLD_MEMBER | RTLD_LAZY );
    sqlcreatedb = (sqlcreatedbType) DLSYM( cliLib, "SQLCreateDb" );
  #else
    void *cliLib = NULL;
    typedef int (*sqlcreatedbType)( SQLHDBC, SQLCHAR *, SQLINTEGER, SQLCHAR *, SQLINTEGER, SQLCHAR *, SQLINTEGER );
    sqlcreatedbType sqlcreatedb;
    cliLib = DLOPEN( LIBDB2, RTLD_LAZY );
    sqlcreatedb = (sqlcreatedbType) DLSYM( cliLib, "SQLCreateDb" );
  #endif
#else
  #ifdef _WIN32
    HINSTANCE cliLib = NULL;
    FARPROC sqlcreatedb;
    cliLib = DLOPEN( LIBDB2 );
    sqlcreatedb =  DLSYM( cliLib, "SQLCreateDbW" );
  #elif _AIX
    void *cliLib = NULL;
    typedef int (*sqlcreatedbType)( SQLHDBC, SQLWCHAR *, SQLINTEGER, SQLWCHAR *, SQLINTEGER, SQLWCHAR *, SQLINTEGER );
    sqlcreatedbType sqlcreatedb;
  /* On AIX CLI library is in archive. Hence we will need to specify flags in DLOPEN to load a member of the archive*/
    cliLib = DLOPEN( LIBDB2, RTLD_MEMBER | RTLD_LAZY );
    sqlcreatedb = (sqlcreatedbType) DLSYM( cliLib, "SQLCreateDbW" );
  #else
    void *cliLib = NULL;
    typedef int (*sqlcreatedbType)( SQLHDBC, SQLWCHAR *, SQLINTEGER, SQLWCHAR *, SQLINTEGER, SQLWCHAR *, SQLINTEGER );
    sqlcreatedbType sqlcreatedb;
    cliLib = DLOPEN( LIBDB2, RTLD_LAZY );
    sqlcreatedb = (sqlcreatedbType) DLSYM( cliLib, "SQLCreateDbW" );
  #endif
#endif

  rc = (*sqlcreatedb)( (SQLHSTMT) data->conn_res->hdbc, data->dbName, (SQLINTEGER)data->dbName_string_len, 
                            data->codeSet, (SQLINTEGER)data->codeSet_string_len,
							data->mode, (SQLINTEGER)data->mode_string_len );
  data->rc =rc;							
  DLCLOSE( cliLib );  
  return rc;
}

/*
   This function calls SQLDropDb cli call
*/
int _ruby_ibm_db_SQLDropDB_helper(create_drop_db_args *data) {
  int rc = 0;
#ifndef UNICODE_SUPPORT_VERSION
  #ifdef _WIN32
    HINSTANCE cliLib = NULL;
    FARPROC sqldropdb;
    cliLib = DLOPEN( LIBDB2 );
    sqldropdb =  DLSYM( cliLib, "SQLDropDb" );
  #elif _AIX
    void *cliLib = NULL;
    typedef int (*sqldropdbType)( SQLHDBC, SQLCHAR *, SQLINTEGER);
    sqldropdbType sqldropdb;
  /* On AIX CLI library is in archive. Hence we will need to specify flags in DLOPEN to load a member of the archive*/
    cliLib = DLOPEN( LIBDB2, RTLD_MEMBER | RTLD_LAZY );
    sqldropdb = (sqldropdbType) DLSYM( cliLib, "SQLDropDb" );
  #else
    void *cliLib = NULL;
    typedef int (*sqldropdbType)( SQLHDBC, SQLCHAR *, SQLINTEGER);
    sqldropdbType sqldropdb;
    cliLib = DLOPEN( LIBDB2, RTLD_LAZY );
    sqldropdb = (sqldropdbType) DLSYM( cliLib, "SQLDropDb" );
  #endif
#else
  #ifdef _WIN32
    HINSTANCE cliLib = NULL;
    FARPROC sqldropdb;
    cliLib = DLOPEN( LIBDB2 );
    sqldropdb =  DLSYM( cliLib, "SQLDropDbW" );
  #elif _AIX
    void *cliLib = NULL;
    typedef int (*sqldropdbType)( SQLHDBC, SQLWCHAR *, SQLINTEGER);
    sqldropdbType sqldropdb;
  /* On AIX CLI library is in archive. Hence we will need to specify flags in DLOPEN to load a member of the archive*/
    cliLib = DLOPEN( LIBDB2, RTLD_MEMBER | RTLD_LAZY );
    sqldropdb = (sqldropdbType) DLSYM( cliLib, "SQLDropDbW" );
  #else
    void *cliLib = NULL;
    typedef int (*sqldropdbType)( SQLHDBC, SQLWCHAR *, SQLINTEGER);
    sqldropdbType sqldropdb;
    cliLib = DLOPEN( LIBDB2, RTLD_LAZY );
    sqldropdb = (sqldropdbType) DLSYM( cliLib, "SQLDropDbW" );
  #endif
#endif

  rc = (*sqldropdb)( (SQLHSTMT) data->conn_res->hdbc, data->dbName, (SQLINTEGER)data->dbName_string_len );

  DLCLOSE( cliLib );
  return rc;
}

/*
   This function calls SQLPrepare cli call to prepare the given statement
*/
int _ruby_ibm_db_SQLPrepare_helper(exec_cum_prepare_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

#ifndef UNICODE_SUPPORT_VERSION
  rc = SQLPrepare( (SQLHSTMT) data->stmt_res->hstmt, data->stmt_string, (SQLINTEGER)data->stmt_string_len );
#else
  rc = SQLPrepareW( (SQLHSTMT) data->stmt_res->hstmt, data->stmt_string, (SQLINTEGER)data->stmt_string_len );
#endif

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLFreeStmt to end processing on the statement referenced by statement handle
*/
int _ruby_ibm_db_SQLFreeStmt_helper(free_stmt_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLFreeStmt((SQLHSTMT)data->stmt_res->hstmt, data->option );

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLExecute cli call to execute the prepared
*/
int _ruby_ibm_db_SQLExecute_helper(stmt_handle *stmt_res) {
  int  rc =  0;

  stmt_res->is_executing = 1;

  rc = SQLExecute( (SQLHSTMT) stmt_res->hstmt );

  stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLParamData cli call to read if there is still data to be sent
*/
int _ruby_ibm_db_SQLParamData_helper(param_cum_put_data_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLParamData( (SQLHSTMT) data->stmt_res->hstmt, (SQLPOINTER *) &(data->valuePtr) );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLColAttributes cli call to get the specified attribute of the column in result set
*/
int _ruby_ibm_db_SQLColAttributes_helper(col_attr_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLColAttributes( (SQLHSTMT) data->stmt_res->hstmt, data->col_num,
                     data->FieldIdentifier, NULL, 0, NULL, &(data->num_attr) );

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLPutData cli call to supply parameter data value
*/
int _ruby_ibm_db_SQLPutData_helper(param_cum_put_data_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLPutData( (SQLHSTMT) data->stmt_res->hstmt, (SQLPOINTER)(((param_node*)(data->valuePtr))->svalue), 
           ((param_node*)(data->valuePtr))->ivalue );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLGetData cli call to retrieve data for a single column
*/
int _ruby_ibm_db_SQLGetData_helper(get_data_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLGetData( (SQLHSTMT) data->stmt_res->hstmt, data->col_num, data->targetType, data->buff, 
            data->buff_length, data->out_length);

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLGetLength cli call to retrieve the length of the lob value
*/
int _ruby_ibm_db_SQLGetLength_helper(get_length_args *data) {
  int col_num = data->col_num;
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLGetLength( (SQLHSTMT) *( data->new_hstmt ), data->stmt_res->column_info[col_num-1].loc_type,
            data->stmt_res->column_info[col_num-1].lob_loc, data->sLength,
            &(data->stmt_res->column_info[col_num-1].loc_ind) );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLGetSubString cli call to retrieve portion of the lob value
*/
int _ruby_ibm_db_SQLGetSubString_helper(get_subString_args *data) {
  int col_num = data->col_num;
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLGetSubString( (SQLHSTMT) *( data->new_hstmt ), data->stmt_res->column_info[col_num-1].loc_type,
            data->stmt_res->column_info[col_num-1].lob_loc, 1, data->forLength, data->targetCType,
            data->buffer, data->buff_length, data->out_length, 
            &(data->stmt_res->column_info[col_num-1].loc_ind) );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLNextResult cli call to fetch the multiple result sets that might be returned by a stored Proc
*/
int _ruby_ibm_db_SQLNextResult_helper(next_result_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLNextResult( (SQLHSTMT) data->stmt_res->hstmt, (SQLHSTMT) *(data->new_hstmt) );

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLFetchScroll cli call to fetch the specified rowset of data from result
*/
int _ruby_ibm_db_SQLFetchScroll_helper(fetch_data_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLFetchScroll( (SQLHSTMT) data->stmt_res->hstmt, data->fetchOrientation, data->fetchOffset);

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLFetch cli call to advance the cursor to 
   the next row of the result set, and retrieves any bound columns
*/
int _ruby_ibm_db_SQLFetch_helper(fetch_data_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLFetch( (SQLHSTMT) data->stmt_res->hstmt );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLNumResultCols cli call to fetch the number of fields contained in a result set
*/
int _ruby_ibm_db_SQLNumResultCols_helper(row_col_count_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLNumResultCols( (SQLHSTMT) data->stmt_res->hstmt, (SQLSMALLINT*) &(data->count) );

  data->stmt_res->is_executing = 0;
  data->rc = rc;
  return rc;
}

/*
   This function calls SQLNumParams cli call to fetch the number of parameter markers in an SQL statement
*/
int _ruby_ibm_db_SQLNumParams_helper(row_col_count_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLNumParams( (SQLHSTMT) data->stmt_res->hstmt, (SQLSMALLINT*) &(data->count) );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLRowCount cli call to fetch the number of rows affected by the SQL statement
*/
int _ruby_ibm_db_SQLRowCount_helper(sql_row_count_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLRowCount( (SQLHSTMT) data->stmt_res->hstmt, (SQLLEN*) &(data->count) );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLGetInfo cli call to get general information about DBMS, which the app is connected to
*/
int _ruby_ibm_db_SQLGetInfo_helper(get_info_args *data) {
#ifndef UNICODE_SUPPORT_VERSION
  return SQLGetInfo( data->conn_res->hdbc, data->infoType, data->infoValue, data->buff_length, data->out_length);
#else
  return SQLGetInfoW( data->conn_res->hdbc, data->infoType, data->infoValue, data->buff_length, data->out_length);
#endif
}

/*
   This function calls SQLGetDiagRec cli call to get the current values of a diagnostic record that contains error
*/
int _ruby_ibm_db_SQLGetDiagRec_helper(get_diagRec_args *data) {
#ifdef UNICODE_SUPPORT_VERSION
  int rc= SQLGetDiagRecW( data->hType, data->handle, data->recNum, data->SQLState, data->NativeErrorPtr,
                              data->msgText, data->buff_length, data->text_length_ptr );
  data->return_code=rc;
  return rc;  
#else
  return SQLGetDiagRec(data->hType, data->handle, data->recNum, data->SQLState, data->NativeErrorPtr,
                              data->msgText, data->buff_length, data->text_length_ptr );
#endif
}

/*
   This function calls SQLSetStmtAttr cli call to set attributes related to a statement
*/
int _ruby_ibm_db_SQLSetStmtAttr_helper(set_handle_attr_args *data) {
#ifndef UNICODE_SUPPORT_VERSION
  return SQLSetStmtAttr( (SQLHSTMT) *(data->handle), data->attribute, data->valuePtr, data->strLength );
#else
  return SQLSetStmtAttrW( (SQLHSTMT) *(data->handle), data->attribute, data->valuePtr, data->strLength );
#endif
}

/*
   This function calls SQLSetConnectAttr cli call to set attributes that govern aspects of connections
*/
int _ruby_ibm_db_SQLSetConnectAttr_helper(set_handle_attr_args *data) {
#ifndef UNICODE_SUPPORT_VERSION
  return SQLSetConnectAttr( (SQLHDBC) *(data->handle), data->attribute, data->valuePtr, data->strLength );
#else
  return SQLSetConnectAttrW( (SQLHDBC) *(data->handle), data->attribute, data->valuePtr, data->strLength );
#endif
}

/*
   This function calls SQLSetEnvAttr cli call to set an environment attribute
*/
int _ruby_ibm_db_SQLSetEnvAttr_helper(set_handle_attr_args *data) {
  return SQLSetEnvAttr( (SQLHENV) *(data->handle), data->attribute, data->valuePtr, data->strLength);
}

/*
   This function calls SQLGetStmtAttr cli call to set an environment attribute

   The unicode equivalent of SQLGetStmtAttr is not used because the attributes being retrieved currently are not of type char or binary (SQL_IS_INTEGER). If support for retrieving a string type is provided then use the SQLGetStmtAttrW function accordingly
   In get_last_serial_id although we are retrieving a char type, it is converted back to an integer (atoi). The char to integer conversion function in unicode equivalent will be more complicated and is unnecessary for this case.

*/
int _ruby_ibm_db_SQLGetStmtAttr_helper(get_handle_attr_args *data) {
  return SQLGetStmtAttr( (SQLHSTMT) *(data->handle), data->attribute, data->valuePtr, 
            data->buff_length, data->out_length);
}

/*
   This function calls SQLGetConnectAttr cli call to set an environment attribute
*/
int _ruby_ibm_db_SQLGetConnectAttr_helper(get_handle_attr_args *data) {
#ifndef UNICODE_SUPPORT_VERSION
  return SQLGetConnectAttr( (SQLHDBC) *(data->handle), data->attribute, data->valuePtr, 
            data->buff_length, data->out_length);
#else
  return SQLGetConnectAttrW( (SQLHDBC) *(data->handle), data->attribute, data->valuePtr,
            data->buff_length, data->out_length);
#endif
}

/*
   This function calls SQLBindFileToParam cli call
*/
int _ruby_ibm_db_SQLBindFileToParam_helper(stmt_handle *stmt_res, param_node *curr) {
  int rc = 0;

  stmt_res->is_executing = 1;

  rc = SQLBindFileToParam( (SQLHSTMT)stmt_res->hstmt, curr->param_num,
           curr->data_type, (SQLCHAR*)curr->svalue,
           (SQLSMALLINT*)&(curr->ivalue), &(curr->file_options), 
           curr->ivalue, &(curr->bind_indicator) );

  stmt_res->is_executing = 0;

  return rc;
}

/*
   This function calls SQLBindParameter cli call
*/
int _ruby_ibm_db_SQLBindParameter_helper(bind_parameter_args *data) {
  int rc = 0;

  data->stmt_res->is_executing = 1;

  rc = SQLBindParameter( (SQLHSTMT) data->stmt_res->hstmt, data->param_num, data->IOType, data->valueType,
           data->paramType, data->colSize, data->decimalDigits, data->paramValPtr, data->buff_length,
           data->out_length );

  data->stmt_res->is_executing = 0;

  return rc;
}

/*
    Statement level thread unblock function. This fuction cancels a statement level SQL call issued when requested for,
    allowing for a safe interrupt of the thread.
*/
void _ruby_ibm_db_Statement_level_UBF(stmt_handle *stmt_res) {
  int rc = 0;
  if( stmt_res->is_executing == 1 ) {
    rc = SQLCancel( (SQLHSTMT) stmt_res->hstmt );
  }
  return;
}
