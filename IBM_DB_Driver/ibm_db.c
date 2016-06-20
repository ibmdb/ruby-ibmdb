/*
  +----------------------------------------------------------------------+
  |  Licensed Materials - Property of IBM                                |
  |                                                                      |
  | (C) Copyright IBM Corporation 2006 - 2016                            |
  +----------------------------------------------------------------------+
  | Authors: Sushant Koduru, Lynh Nguyen, Kanchana Padmanabhan,          |
  |          Dan Scott, Helmut Tessarek, Sam Ruby, Kellen Bombardier,    |
  |          Tony Cairns, Manas Dadarkar, Swetha Patel, Salvador Ledezma |
  |          Mario Ds Briggs, Praveen Devarao, Ambrish Bhargava,         |
  |          Tarun Pasrija, Arvind Gupta                                 |
  +----------------------------------------------------------------------+
*/

#define MODULE_RELEASE "3.0.3"

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "ruby.h"

#ifdef UNICODE_SUPPORT_VERSION
  #include "ruby/encoding.h"
#endif

#include "ruby_ibm_db_cli.h"
#include "ruby_ibm_db.h"
#include <ctype.h>

#ifdef RUBY_THREAD_H
	#include <ruby/thread.h>
#endif

#include <ruby/version.h>

/* True global resources - no need for thread safety here */
static VALUE   le_conn_struct, le_stmt_struct, le_pconn_struct, le_row_struct;
static VALUE   le_client_info, le_server_info;
static struct  _ibm_db_globals *ibm_db_globals;

static void _ruby_ibm_db_check_sql_errors( void *conn_or_stmt, int resourceType, SQLHANDLE handle, SQLSMALLINT hType,
                                           int rc, int cpy_to_global, SQLPOINTER ret_str, SQLSMALLINT *ret_str_len, int API,
                                           SQLSMALLINT recno, int release_gil );
static VALUE _ruby_ibm_db_assign_options( void* handle, int type, long opt_key, VALUE data, VALUE *error );
static void _ruby_ibm_db_clear_conn_err_cache();
static void _ruby_ibm_db_clear_stmt_err_cache();
static int  _ruby_ibm_db_set_decfloat_rounding_mode_client(SQLHANDLE hdbc);
static char *_ruby_ibm_db_instance_name;
static int  is_systemi, is_informix;        /* 1 == TRUE; 0 == FALSE; */
static int  createDbSupported, dropDbSupported; /*1 == TRUE; 0 == FALSE*/

/* Strucure holding the necessary data to be passed to bind the list of elements passed to the execute function*/
typedef struct _stmt_bind_data_array {
  VALUE         *parameters_array;
  stmt_handle   *stmt_res;
  SQLSMALLINT   num;
  int           bind_params;
  VALUE         *error;
  VALUE         return_value;
}stmt_bind_array;

/*
  Structure to hold the data necessary for the connect helper function. Contains details like 
  is persistent, the credentials and the connection options required
*/
typedef struct _ibm_db_connect_helper_args_struct {
  connect_args  *conn_args;
  int           isPersistent;
  VALUE         *options;
  VALUE         *error;
  int           literal_replacement;
  VALUE         hKey;  
  conn_handle *conn_res;
  VALUE         entry;
} connect_helper_args;

/*
   Structure to hold the data necessary for the function ibm_db_result to retrieve the corresponding data
*/
typedef struct _ibm_db_result_args_struct {
  stmt_handle  *stmt_res;
  VALUE        column;
  VALUE        *error;
  VALUE 	   return_value;
} ibm_db_result_args;

/*
   Structure to hold the data necessary for the function fetch_row_helper
*/
typedef struct _ibm_db_fetch_helper_struct {
  stmt_handle  *stmt_res;
  VALUE        row_number;
  int          arg_count;
  int          funcType;
  VALUE        *error;
  VALUE 	   return_value;
} ibm_db_fetch_helper_args;

void ruby_init_ibm_db();

/* equivalent functions on different platforms */
#ifdef _WIN32
#define STRCASECMP stricmp
#else
#define STRCASECMP strcasecmp
#endif

static VALUE mDB;
static VALUE id_new;
static VALUE id_keys;
static VALUE id_id2name;

#define RUBY_FE(function) \
  rb_define_singleton_method(mDB, #function, ibm_db_##function, -1);
#define RUBY_FALIAS(alias, function) \
  rb_define_singleton_method(mDB, #alias, ibm_db_##function, -1);


 

#ifdef UNICODE_SUPPORT_VERSION
  const int _check_i = 1;
  #define arch_is_bigendian() ( (*(char*)&_check_i) == 0 ) /* returns 0 if the machine is of little endian architecture, 1 if the machine is of bigendian architecture*/

  static VALUE _ruby_ibm_db_export_str_to_utf16(VALUE string){
    rb_encoding *utf16_enc;
    if ( arch_is_bigendian() ){
      utf16_enc = rb_enc_find("UTF-16BE");
    } else {
      utf16_enc = rb_enc_find("UTF-16LE");
    }
    return rb_str_export_to_enc(string,utf16_enc);
  }

  static VALUE _ruby_ibm_db_export_str_to_ascii(VALUE string){
    rb_encoding *ascii_enc = rb_enc_find("ASCII-8BIT");
    return rb_str_export_to_enc(string,ascii_enc);
  }

  static VALUE _ruby_ibm_db_export_str_to_utf8(VALUE string){
    rb_encoding *utf8_enc = rb_enc_find("UTF-8");
    return rb_str_export_to_enc(string,utf8_enc);
  }

  static VALUE _ruby_ibm_db_export_char_to_utf16_rstr(const char *str){
    VALUE rbString;
    rb_encoding *utf16_enc;

    if ( arch_is_bigendian() ){
      utf16_enc = rb_enc_find("UTF-16BE");
    } else {
      utf16_enc = rb_enc_find("UTF-16LE");
    }

    rbString  =  rb_external_str_new(str, strlen(str));

    return rb_str_export_to_enc(rbString, utf16_enc);
  }

  static VALUE _ruby_ibm_db_export_char_to_utf8_rstr(const char *str){
    VALUE rbString;
    rb_encoding *utf8_enc;

    utf8_enc  =  rb_enc_find("UTF-8");
    rbString  =  rb_external_str_new(str, strlen(str));
    return rb_str_export_to_enc(rbString, utf8_enc);
  }

  static VALUE _ruby_ibm_db_export_sqlwchar_to_utf16_rstr(SQLWCHAR *str, long len) {
    rb_encoding *utf16_enc;

    if ( arch_is_bigendian() ){
      utf16_enc = rb_enc_find("UTF-16BE");
    } else {
      utf16_enc = rb_enc_find("UTF-16LE");
    }
    return rb_external_str_new_with_enc((char *)str, len, utf16_enc);
  }

  static VALUE _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(SQLWCHAR *str, long len){
    VALUE rbString;

    rbString = _ruby_ibm_db_export_sqlwchar_to_utf16_rstr( str, len ); /*Construct the Ruby string from SQLWCHAR(which is in utf16)*/
	
    return _ruby_ibm_db_export_str_to_utf8(rbString); /*Convert the string to utf8 encoding*/
  }

  static VALUE _ruby_ibm_db_export_sqlchar_to_utf8_rstr(SQLCHAR *str, long len) {
    rb_encoding *utf8_enc;

    utf8_enc  =  rb_enc_find("UTF-8");
	
    return rb_external_str_new_with_enc((char *)str, len, utf8_enc);
  }
#endif

/*  Every user visible function must have an entry in Init_ibm_db
*/
void Init_ibm_db(void) {
	
  mDB = rb_define_module("IBM_DB");

  rb_define_module_function(mDB, "connect", ibm_db_connect, -1);
  rb_define_module_function(mDB, "createDB", ibm_db_createDB, -1);
  rb_define_module_function(mDB, "dropDB", ibm_db_dropDB, -1);
  rb_define_module_function(mDB, "createDBNX", ibm_db_createDBNX, -1);
  rb_define_module_function(mDB, "commit", ibm_db_commit, -1);
  rb_define_module_function(mDB, "pconnect", ibm_db_pconnect, -1);
  rb_define_module_function(mDB, "autocommit", ibm_db_autocommit, -1);
  rb_define_module_function(mDB, "bind_param", ibm_db_bind_param, -1);
  rb_define_module_function(mDB, "close", ibm_db_close, -1);
  rb_define_module_function(mDB, "column_privileges", ibm_db_column_privileges, -1);
  rb_define_module_function(mDB, "columnprivileges", ibm_db_column_privileges, -1);
  rb_define_module_function(mDB, "columns", ibm_db_columns, -1);
  rb_define_module_function(mDB, "foreign_keys", ibm_db_foreign_keys, -1);
  rb_define_module_function(mDB, "foreignkeys", ibm_db_foreign_keys, -1);
  rb_define_module_function(mDB, "primary_keys", ibm_db_primary_keys, -1);
  rb_define_module_function(mDB, "primarykeys", ibm_db_primary_keys, -1);
  rb_define_module_function(mDB, "procedure_columns", ibm_db_procedure_columns, -1);
  rb_define_module_function(mDB, "procedurecolumns", ibm_db_procedure_columns, -1);
  rb_define_module_function(mDB, "procedures", ibm_db_procedures, -1);
  rb_define_module_function(mDB, "special_columns", ibm_db_special_columns, -1);
  rb_define_module_function(mDB, "specialcolumns", ibm_db_special_columns, -1);
  rb_define_module_function(mDB, "statistics", ibm_db_statistics, -1);
  rb_define_module_function(mDB, "table_privileges", ibm_db_table_privileges, -1);
  rb_define_module_function(mDB, "tableprivileges", ibm_db_table_privileges, -1);
  rb_define_module_function(mDB, "tables", ibm_db_tables, -1);
  rb_define_module_function(mDB, "exec", ibm_db_exec, -1);
  rb_define_module_function(mDB, "prepare", ibm_db_prepare, -1);
  rb_define_module_function(mDB, "execute", ibm_db_execute, -1);
  rb_define_module_function(mDB, "stmt_errormsg", ibm_db_stmt_errormsg, -1);
  rb_define_module_function(mDB, "conn_errormsg", ibm_db_conn_errormsg, -1);
  rb_define_module_function(mDB, "conn_error", ibm_db_conn_error, -1);
  rb_define_module_function(mDB, "stmt_error", ibm_db_stmt_error, -1);
  rb_define_module_function(mDB, "getErrormsg", ibm_db_getErrormsg, -1);
  rb_define_module_function(mDB, "getErrorstate", ibm_db_getErrorstate, -1);
  rb_define_module_function(mDB, "next_result", ibm_db_next_result, -1);
  rb_define_module_function(mDB, "num_fields", ibm_db_num_fields, -1);
  rb_define_module_function(mDB, "num_rows", ibm_db_num_rows, -1);
  rb_define_module_function(mDB, "resultCols", ibm_db_result_cols, -1);
  rb_define_module_function(mDB, "field_name", ibm_db_field_name, -1);
  rb_define_module_function(mDB, "field_display_size", ibm_db_field_display_size, -1);
  rb_define_module_function(mDB, "field_num", ibm_db_field_num, -1);
  rb_define_module_function(mDB, "field_precision", ibm_db_field_precision, -1);
  rb_define_module_function(mDB, "field_scale", ibm_db_field_scale, -1);
  rb_define_module_function(mDB, "field_type", ibm_db_field_type, -1);
  rb_define_module_function(mDB, "field_width", ibm_db_field_width, -1);
  rb_define_module_function(mDB, "cursor_type", ibm_db_cursor_type, -1);
  rb_define_module_function(mDB, "rollback", ibm_db_rollback, -1);
  rb_define_module_function(mDB, "free_stmt", ibm_db_free_stmt, -1);
  rb_define_module_function(mDB, "result", ibm_db_result, -1);
  rb_define_module_function(mDB, "fetch_row", ibm_db_fetch_row, -1);
  rb_define_module_function(mDB, "fetch_assoc", ibm_db_fetch_assoc, -1);
  rb_define_module_function(mDB, "fetch_array", ibm_db_fetch_array, -1);
  rb_define_module_function(mDB, "fetch_both", ibm_db_fetch_both, -1);
  rb_define_module_function(mDB, "free_result", ibm_db_free_result, -1);
  rb_define_module_function(mDB, "set_option", ibm_db_set_option, -1);
  rb_define_module_function(mDB, "setoption", ibm_db_set_option, -1);
  rb_define_module_function(mDB, "get_option", ibm_db_get_option, -1);
  rb_define_module_function(mDB, "getoption", ibm_db_get_option, -1);
  rb_define_module_function(mDB, "get_last_serial_value", ibm_db_get_last_serial_value, -1);
  rb_define_module_function(mDB, "fetch_object", ibm_db_fetch_object, -1);
  rb_define_module_function(mDB, "server_info", ibm_db_server_info, -1);
  rb_define_module_function(mDB, "client_info", ibm_db_client_info, -1);
  rb_define_module_function(mDB, "active", ibm_db_active, -1);
  
  RUBY_FE(connect)
  RUBY_FE(commit)
  RUBY_FE(pconnect)
  RUBY_FE(autocommit)
  RUBY_FE(bind_param)
  RUBY_FE(close)
  RUBY_FE(column_privileges)
  RUBY_FALIAS(columnprivileges, column_privileges)
  RUBY_FE(columns)
  RUBY_FE(foreign_keys)
  RUBY_FALIAS(foreignkeys, foreign_keys)
  RUBY_FE(primary_keys)
  RUBY_FALIAS(primarykeys, primary_keys)
  RUBY_FE(procedure_columns)
  RUBY_FALIAS(procedurecolumns, procedure_columns)
  RUBY_FE(procedures)
  RUBY_FE(special_columns)
  RUBY_FALIAS(specialcolumns, special_columns)
  RUBY_FE(statistics)
  RUBY_FE(table_privileges)
  RUBY_FALIAS(tableprivileges, table_privileges)
  RUBY_FE(tables)
  RUBY_FE(exec)
  RUBY_FE(prepare)
  RUBY_FE(execute)
  RUBY_FE(stmt_errormsg)
  RUBY_FE(conn_errormsg)
  RUBY_FE(conn_error)
  RUBY_FE(stmt_error)
  RUBY_FE(getErrormsg)
  RUBY_FE(getErrorstate)
  RUBY_FE(next_result)
  RUBY_FE(num_fields)
  RUBY_FE(num_rows)
  RUBY_FE(field_name)
  RUBY_FE(field_display_size)
  RUBY_FE(field_num)
  RUBY_FE(field_precision)
  RUBY_FE(field_scale)
  RUBY_FE(field_type)
  RUBY_FE(field_width)
  RUBY_FE(cursor_type)
  RUBY_FE(rollback)
  RUBY_FE(free_stmt)
  RUBY_FE(result)
  RUBY_FE(fetch_row)
  RUBY_FE(fetch_assoc)
  RUBY_FE(fetch_array)
  RUBY_FE(fetch_both)
  RUBY_FE(free_result)
  RUBY_FE(set_option)
  RUBY_FALIAS(setoption, set_option)
  RUBY_FE(get_option)
  RUBY_FALIAS(getoption, get_option)
  RUBY_FE(get_last_serial_value)
  RUBY_FE(fetch_object)
  RUBY_FE(server_info)
  RUBY_FE(client_info)
  RUBY_FE(active)

  ruby_init_ibm_db();

  id_keys     =  rb_intern("keys");
  id_new      =  rb_intern("new");
  id_id2name  =  rb_intern("id2name");
  
};
/*  */

/* {{{ RUBY_INI
*/
#define INI_STR(name) NULL
/* }}} */

/*Load necessary libraries*/
static void ruby_ibm_db_load_necessary_libs() {
  rb_eval_string("require \'bigdecimal\'");
}

#ifdef _WIN32
static void ruby_ibm_db_check_sqlcreatedb(HINSTANCE cliLib) {	
   FARPROC sqlcreatedb;
   sqlcreatedb =  DLSYM( cliLib, "SQLCreateDbW" );
#else
static void ruby_ibm_db_check_sqlcreatedb(void *cliLib) {
   typedef int (*sqlcreatedbType)( SQLHDBC, SQLWCHAR *, SQLINTEGER, SQLWCHAR *, SQLINTEGER, SQLWCHAR *, SQLINTEGER );
   sqlcreatedbType sqlcreatedb;
   sqlcreatedb = (sqlcreatedbType) DLSYM( cliLib, "SQLCreateDbW" );
#endif
     if ( sqlcreatedb == NULL )  {
        createDbSupported = 0;
        dropDbSupported   = 0;
	 } else {
        createDbSupported = 1;
        dropDbSupported   = 1;
	 }
}
/*Check if specific functions are supported or not based on CLI being used
 * For Eg: SQLCreateDB and SQLDropDB is supported only from V97fp3 onwards. In this function we open the CLI library 
 * using DLOpen and check if the function is defined. If yes then we allow the user to use the function, 
 * else throw a warning saying this is not supported 
 */
static void ruby_ibm_db_check_if_cli_func_supported() {
#ifdef _WIN32
   HINSTANCE cliLib = NULL;
#else
   void *cliLib = NULL;
#endif

#ifdef _WIN32
    cliLib = DLOPEN( LIBDB2 );
#elif _AIX
/* On AIX CLI library is in archive. Hence we will need to specify flags in DLOPEN to load a member of the archive*/
    cliLib = DLOPEN( LIBDB2, RTLD_MEMBER | RTLD_LAZY );
#else
    cliLib = DLOPEN( LIBDB2, RTLD_LAZY );
#endif
  if ( !cliLib ) {
    rb_warn("Could not load CLI library to check functionality support");
    createDbSupported = 0;
    dropDbSupported   = 0;
    return;
  }
  ruby_ibm_db_check_sqlcreatedb(cliLib);
  DLCLOSE( cliLib );
}

static void ruby_ibm_db_init_globals(struct _ibm_db_globals *ibm_db_globals)
{
  /* env handle */
  ibm_db_globals->bin_mode = 1;

  memset(ibm_db_globals->__ruby_conn_err_msg, '\0', DB2_MAX_ERR_MSG_LEN);
  memset(ibm_db_globals->__ruby_stmt_err_msg, '\0', DB2_MAX_ERR_MSG_LEN);
  memset(ibm_db_globals->__ruby_conn_err_state, '\0', SQL_SQLSTATE_SIZE + 1);
  memset(ibm_db_globals->__ruby_stmt_err_state, '\0', SQL_SQLSTATE_SIZE + 1);
  
}
/*  */

static VALUE persistent_list;

char *estrdup(char *data) {
  int len    =  strlen(data);
  char *dup  =  ALLOC_N(char, len+1);
  strcpy(dup, data);
  return dup;
}

#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR *esqlwchardup(SQLWCHAR *data, int len) {
    SQLWCHAR *dup  =  ALLOC_N(SQLWCHAR, len + 1 );
    memset(dup, '\0', (len * sizeof(SQLWCHAR)) + 2 );
    memcpy((char *)dup, (char *)data, len * sizeof(SQLWCHAR) );
    return dup;
  }
#endif

char *estrndup(char *data, int max) {
  int len = strlen(data);
  char *dup;
  if (len > max) {
    len = max;
  }
  dup = ALLOC_N(char, len+1);
  strcpy(dup, data);
  return dup;
}

void strtolower(char *data, int max) {
#ifdef UNICODE_SUPPORT_VERSION
  rb_encoding *enc;
    
  if ( arch_is_bigendian() ){
    enc = rb_enc_find("UTF-16BE");
  } else {
    enc = rb_enc_find("UTF-16LE");
  }
#endif

  if( max > 0 ) {
    while (max--) {
#ifdef UNICODE_SUPPORT_VERSION
      data[max] = rb_enc_tolower((int)data[max], enc);
#else
      data[max] = tolower(data[max]);
#endif
    }
  }
}

void strtoupper(char *data, int max) {
#ifdef UNICODE_SUPPORT_VERSION
  rb_encoding *enc;

  if ( arch_is_bigendian() ){
    enc = rb_enc_find("UTF-16BE");
  } else {
    enc = rb_enc_find("UTF-16LE");
  }
#endif
  if( max > 0 ) {
    while (max--) {
#ifdef UNICODE_SUPPORT_VERSION
      data[max] = rb_enc_toupper((int)data[max], enc);
#else
      data[max] = toupper(data[max]);
#endif
    }
  }
}

/*  static void _ruby_ibm_db_mark_conn_struct */
static void _ruby_ibm_db_mark_conn_struct(conn_handle *handle)
{
}
/*  */

/*  static void _ruby_ibm_db_free_conn_struct */
static void _ruby_ibm_db_free_conn_struct(conn_handle *handle)
{
  	
  int rc;
  end_tran_args *end_X_args;

  if ( handle != NULL ) {
    //Disconnect from DB. If stmt is allocated, it is freed automatically
    if ( handle->handle_active ) {
      if( handle->transaction_active == 1 && handle->auto_commit == 0 ) {
        handle->transaction_active = 0;
        end_X_args = ALLOC( end_tran_args );
        memset(end_X_args,'\0',sizeof(struct _ibm_db_end_tran_args_struct));

        end_X_args->hdbc            =  &(handle->hdbc);
        end_X_args->handleType      =  SQL_HANDLE_DBC;
        end_X_args->completionType  =  SQL_ROLLBACK; //Note we are rolling back the transaction

        _ruby_ibm_db_SQLEndTran( end_X_args );

        ruby_xfree( end_X_args );

      }
	  rc = _ruby_ibm_db_SQLDisconnect_helper( &(handle->hdbc) );
      rc = SQLFreeHandle(SQL_HANDLE_DBC, handle->hdbc );
      rc = SQLFreeHandle(SQL_HANDLE_ENV, handle->henv );
    }

    if ( handle->ruby_error_msg != NULL ) {
      ruby_xfree( handle->ruby_error_msg );
      handle->ruby_error_msg  =  NULL;
    }

    if ( handle->ruby_error_state != NULL ) {
      ruby_xfree( handle->ruby_error_state );
      handle->ruby_error_state  =  NULL;
    }

    //if ( handle->flag_pconnect ) {
    //    ruby_xfree( handle );
    //} else {
    //  ruby_xfree( handle );
    //}
    ruby_xfree( handle );
    handle = NULL;
  }
  
}
/*  */

/*  static void _ruby_ibm_db_mark_pconn_struct */
static void _ruby_ibm_db_mark_pconn_struct(conn_handle *handle)
{
}
/*  */

/*  static void _ruby_ibm_db_free_pconn_struct */
static void _ruby_ibm_db_free_pconn_struct(conn_handle *handle)
{
  _ruby_ibm_db_free_conn_struct( handle );
}
/*  */

/*  static void _ruby_ibm_db_mark_row_struct */
static void _ruby_ibm_db_mark_row_struct(row_hash_struct *handle)
{
  rb_gc_mark( handle->hash );
}
/*  */

/*  static void _ruby_ibm_db_free_row_struct */
static void _ruby_ibm_db_free_row_struct(row_hash_struct *handle)
{
  if ( handle != NULL ) {
    ruby_xfree( handle );
    handle = NULL;
  }
}
/*  */

/*  static void _ruby_ibm_db_free_result_struct(stmt_handle* handle)
  */
static void _ruby_ibm_db_free_result_struct(stmt_handle* handle)
{
  int i;
  param_node *curr_ptr = NULL, *prev_ptr = NULL;
  

  if ( handle != NULL ) {
    /* Free param cache list */
    curr_ptr = handle->head_cache_list;
    prev_ptr = handle->head_cache_list;
    while ( curr_ptr != NULL ) {
      curr_ptr = curr_ptr->next;
      if ( prev_ptr->varname != NULL ) {
        ruby_xfree( prev_ptr->varname );
        prev_ptr->varname = NULL;
      }
      if ( prev_ptr->svalue != NULL ) {
        ruby_xfree( prev_ptr->svalue );
        prev_ptr->svalue = NULL;
      }
      ruby_xfree( prev_ptr );

      prev_ptr = curr_ptr;
    }
    handle->head_cache_list = NULL;
    handle->num_params      = 0;
    handle->current_node    = NULL;
    /* free row data cache */
    if ( handle->row_data ) {
      for (i=0; i<handle->num_columns;i++) {
        switch (handle->column_info[i].type) {
          case SQL_CHAR:
          case SQL_WCHAR:
          case SQL_VARCHAR:
          case SQL_WVARCHAR:
          case SQL_GRAPHIC:
          case SQL_VARGRAPHIC:
#ifndef PASE /* i5/OS SQL_LONGVARCHAR is SQL_VARCHAR */
          case SQL_LONGVARCHAR:
          case SQL_WLONGVARCHAR:
#endif /* PASE */
          case SQL_TYPE_DATE:
          case SQL_TYPE_TIME:
          case SQL_TYPE_TIMESTAMP:
          case SQL_BIGINT:
          case SQL_DECIMAL:
          case SQL_NUMERIC:
          case SQL_XML:
          case SQL_DECFLOAT:
            if ( handle->row_data[i].data.str_val != NULL ) {
              ruby_xfree( handle->row_data[i].data.str_val );
              handle->row_data[i].data.str_val = NULL;
            }
        }
      }
      ruby_xfree( handle->row_data );
      handle->row_data = NULL;
    }
    /* free column info cache */
    if ( handle->column_info ) {
      for (i=0; i<handle->num_columns; i++) {
        if ( handle->column_info[i].name != NULL ) {
          ruby_xfree( handle->column_info[i].name );
          handle->column_info[i].name = NULL;
        }
      }
      ruby_xfree( handle->column_info );
      handle->column_info = NULL;
      handle->num_columns = 0;
    }
  }
}
/*  */

/*  static stmt_handle *_ibm_db_new_stmt_struct(conn_handle* conn_res)
  */
static stmt_handle *_ibm_db_new_stmt_struct(conn_handle* conn_res)
{
  stmt_handle *stmt_res;

  stmt_res = ALLOC( stmt_handle );
  memset( stmt_res, '\0', sizeof(stmt_handle) );

  /* Initialize stmt resource so parsing assigns updated options if needed */
  stmt_res->hdbc         =  conn_res->hdbc;
  stmt_res->s_bin_mode   =  conn_res->c_bin_mode;
  stmt_res->cursor_type  =  conn_res->c_cursor_type;
  stmt_res->s_case_mode  =  conn_res->c_case_mode;

  stmt_res->head_cache_list = NULL;
  stmt_res->current_node    = NULL;

  stmt_res->num_params = 0;
  stmt_res->file_param = 0;

  stmt_res->column_info = NULL;
  stmt_res->num_columns = 0;

  stmt_res->error_recno_tracker    = 1;
  stmt_res->errormsg_recno_tracker = 1;

  stmt_res->row_data = NULL;

  stmt_res->is_executing    = 0;
  stmt_res->is_freed        = 0;

  stmt_res->ruby_stmt_err_msg    =  NULL;
  stmt_res->ruby_stmt_err_state  =  NULL;

  return stmt_res;
}
/*  */

/*  static _ruby_ibm_db_mark_stmt_struct */
static void _ruby_ibm_db_mark_stmt_struct(stmt_handle *handle)
{
}


VALUE ibm_Ruby_Thread_Call(rb_blocking_function_t *func, void *data1, rb_unblock_function_t *ubf, void *data2)
{
	#ifdef RUBY_API_VERSION_MAJOR 
		if( RUBY_API_VERSION_MAJOR >=2 && RUBY_API_VERSION_MINOR >=2) 
		{
			
			#ifdef _WIN32
				void *(*f)(void*) = (void *(*)(void*))func;
				return (VALUE)rb_thread_call_without_gvl(f, data1, ubf, data2);
			#elif __APPLE__
				return rb_thread_call_without_gvl(func, data1, ubf, data2);                	   
			#else
				rb_thread_call_without_gvl(func, data1, ubf, data2);
	#endif	
		}		
		else	
		{
			rb_thread_call_without_gvl(func, data1, ubf, data2);
		}
	#else
		rb_thread_call_without_gvl(func, data1, ubf, data2);
	#endif	
  }
  

/*  */

/*  static _ruby_ibm_db_free_stmt_handle_and_resources */
static void _ruby_ibm_db_free_stmt_handle_and_resources(stmt_handle *handle)
{
  int rc;
  if ( handle != NULL ) {
    if( !handle->is_freed ) {
      rc = SQLFreeHandle( SQL_HANDLE_STMT, handle->hstmt );

      _ruby_ibm_db_free_result_struct( handle );

      if( handle->ruby_stmt_err_msg != NULL ) {
        ruby_xfree( handle->ruby_stmt_err_msg );
        handle->ruby_stmt_err_msg = NULL;
      }
      if( handle->ruby_stmt_err_state != NULL ) {
        ruby_xfree( handle->ruby_stmt_err_state );
        handle->ruby_stmt_err_state = NULL;
      }
      handle->is_freed = 1; /* Indicates that the handle is freed */
    }
  }
}

/*  */

/*  static _ruby_ibm_db_free_stmt_struct */
static void _ruby_ibm_db_free_stmt_struct(stmt_handle *handle)
{		
  if ( handle != NULL ) {
    _ruby_ibm_db_free_stmt_handle_and_resources( handle );
    ruby_xfree( handle );
    handle = NULL;	
  }  
}

/*  */

/* allow direct access to hash object as object attributes */
VALUE ibm_db_row_object(int argc, VALUE *argv, VALUE self)
{
  row_hash_struct *row_res;
  VALUE symbol;
  VALUE rest;
  VALUE index;

  Data_Get_Struct(self, row_hash_struct, row_res );

  rb_scan_args(argc, argv, "1*", &symbol, &rest );

  if ( symbol == ID2SYM(id_keys) ) {
      return rb_funcall( row_res->hash, id_keys, 0 );
  } else {
      index = rb_funcall( symbol, id_id2name, 0 );
      return rb_hash_aref( row_res->hash, index );
  }
}

/*  Module initialization
*/
void ruby_init_ibm_db()
{
	
#ifndef _WIN32
  /* Declare variables for DB2 instance settings */
  char * tmp_name      =  NULL;
  char * instance_name =  NULL;
#endif

  ibm_db_globals = ALLOC(struct _ibm_db_globals);
  memset(ibm_db_globals, '\0', sizeof(struct _ibm_db_globals));
	
  ruby_ibm_db_init_globals(ibm_db_globals);
  
  /* Specifies that binary data shall be converted to a hexadecimal encoding and returned as an ASCII string */
  rb_define_const(mDB, "BINARY", INT2NUM(1));
  /* Specifies that binary data shall be converted to a hexadecimal encoding and returned as an ASCII string */
  rb_define_const(mDB, "CONVERT", INT2NUM(2));
  /* Specifies that binary data shall be converted to a NULL value */
  rb_define_const(mDB, "PASSTHRU", INT2NUM(3));
  /* Specifies that the column should be bound directly to a file for input */
  rb_define_const(mDB, "PARAM_FILE", INT2NUM(11));
  /* Specifies the column names case attribute <b>ATTENTION</b> this number is not currently in CLI but used for ibm_db purpose only */
  rb_define_const(mDB, "ATTR_CASE", INT2NUM(ATTR_CASE));
  /* Specifies that column names will be returned in their natural case */
  rb_define_const(mDB, "CASE_NATURAL", INT2NUM(0));
  /* Specifies that column names will be returned in lower case */
  rb_define_const(mDB, "CASE_LOWER", INT2NUM(1));
  /* Specifies that column names will be returned in upper case */
  rb_define_const(mDB, "CASE_UPPER", INT2NUM(2));
  /* Specifies the cursor type */
  rb_define_const(mDB, "SQL_ATTR_CURSOR_TYPE", INT2NUM(SQL_ATTR_CURSOR_TYPE));
  /* Cursor type that detects all changes to the result set <b>ATTENTION</b> Only supported when using DB2 for z/OS Version 8.1 and later. */
  rb_define_const(mDB, "SQL_CURSOR_DYNAMIC", INT2NUM(SQL_CURSOR_DYNAMIC));
  /* Cursor type that only scrolls forward. This is the default */
  rb_define_const(mDB, "SQL_CURSOR_FORWARD_ONLY", INT2NUM(SQL_CURSOR_FORWARD_ONLY));
  /* Cursor type is a pure keyset cursor */
  rb_define_const(mDB, "SQL_CURSOR_KEYSET_DRIVEN", INT2NUM(SQL_CURSOR_KEYSET_DRIVEN));
  /* Cursor type that only scrolls forward */
  rb_define_const(mDB, "SQL_SCROLL_FORWARD_ONLY", INT2NUM(SQL_SCROLL_FORWARD_ONLY));
  /* Cursor type in which the data in the result set is static */
  rb_define_const(mDB, "SQL_CURSOR_STATIC", INT2NUM(SQL_CURSOR_STATIC));
  /* Parmater binding type of input  */
  rb_define_const(mDB, "SQL_PARAM_INPUT", INT2NUM(SQL_PARAM_INPUT));
  /* Parmater binding type of output  */
  rb_define_const(mDB, "SQL_PARAM_OUTPUT", INT2NUM(SQL_PARAM_OUTPUT));
  /* Parmater binding type of input/output  */
  rb_define_const(mDB, "SQL_PARAM_INPUT_OUTPUT", INT2NUM(SQL_PARAM_INPUT_OUTPUT));
  /* Data type used to specify binary data  */
  rb_define_const(mDB, "SQL_BINARY", INT2NUM(SQL_BINARY));
  /* Data type used to specify bigint data */
  rb_define_const(mDB, "SQL_BIGINT", INT2NUM(SQL_BIGINT));
  /* Data type used to specify long data */
  rb_define_const(mDB, "SQL_LONG", INT2NUM(SQL_INTEGER));
  /* Data type used to specify double data */
  rb_define_const(mDB, "SQL_DOUBLE", INT2NUM(SQL_DOUBLE));
  /* Data type used to specify char data */
  rb_define_const(mDB, "SQL_CHAR", INT2NUM(SQL_CHAR));
  rb_define_const(mDB, "SQL_WCHAR", INT2NUM(SQL_WCHAR));
  /* Data type used to specify XML data */
  rb_define_const(mDB, "SQL_XML", INT2NUM(SQL_XML));
  /* Data type used to specify VARCHAR data */
  rb_define_const(mDB, "SQL_VARCHAR", INT2NUM(SQL_VARCHAR));
  rb_define_const(mDB, "SQL_WVARCHAR", INT2NUM(SQL_WVARCHAR));
  /* Operates in auto-commit mode off. The application must manually commit or rollback transactions */
  rb_define_const(mDB, "SQL_AUTOCOMMIT_OFF", INT2NUM(SQL_AUTOCOMMIT_OFF));
  /* Operates in auto-commit mode on. This is the default */
  rb_define_const(mDB, "SQL_AUTOCOMMIT_ON", INT2NUM(SQL_AUTOCOMMIT_ON));
  /* Specifies whether to use auto-commit or manual commit mode */
  rb_define_const(mDB, "SQL_ATTR_AUTOCOMMIT", INT2NUM(SQL_ATTR_AUTOCOMMIT));
  /* Specifies whether to enable trusted context mode */
  rb_define_const(mDB, "SQL_TRUE", INT2NUM(SQL_TRUE));
  /* Specifies whether to enable trusted context mode */
  rb_define_const(mDB, "SQL_ATTR_USE_TRUSTED_CONTEXT", INT2NUM(SQL_ATTR_USE_TRUSTED_CONTEXT));
  /* Specifies whether to siwtch trusted user */
  rb_define_const(mDB, "SQL_ATTR_TRUSTED_CONTEXT_USERID", INT2NUM(SQL_ATTR_TRUSTED_CONTEXT_USERID));
  /* Specifies when trusted user is specified */
  rb_define_const(mDB, "SQL_ATTR_TRUSTED_CONTEXT_PASSWORD", INT2NUM(SQL_ATTR_TRUSTED_CONTEXT_PASSWORD));
  /* String used to identify the client user ID sent to the host database */
  rb_define_const(mDB, "SQL_ATTR_INFO_USERID", INT2NUM(SQL_ATTR_INFO_USERID));
  /* String used to identify the client workstation name sent to the host database */
  rb_define_const(mDB, "SQL_ATTR_INFO_WRKSTNNAME", INT2NUM(SQL_ATTR_INFO_WRKSTNNAME));
  /* String used to identify the client application name sent to the host database */
  rb_define_const(mDB, "SQL_ATTR_INFO_APPLNAME", INT2NUM(SQL_ATTR_INFO_APPLNAME));
  /* String used to identify the client accounting string sent to the host database */
  rb_define_const(mDB, "SQL_ATTR_INFO_ACCTSTR", INT2NUM(SQL_ATTR_INFO_ACCTSTR));
  /* Enabling Prefetching of Rowcount - Available from V95FP3 onwards */
  rb_define_const(mDB, "SQL_ATTR_ROWCOUNT_PREFETCH", INT2NUM(SQL_ATTR_ROWCOUNT_PREFETCH));
  rb_define_const(mDB, "SQL_ROWCOUNT_PREFETCH_ON", INT2NUM(SQL_ROWCOUNT_PREFETCH_ON));
  rb_define_const(mDB, "SQL_ROWCOUNT_PREFETCH_OFF", INT2NUM(SQL_ROWCOUNT_PREFETCH_OFF));
  /*Specifies resource Type passed is Connection Handle, for retrieving error message*/
  rb_define_const(mDB, "DB_CONN", INT2NUM(DB_CONN));
  /*Specifies resource Type passed is Statement Handle, for retrieving error message*/
  rb_define_const(mDB, "DB_STMT", INT2NUM(DB_STMT));
  /*Specifies Quoted Literal replacement connection attribute is to be set*/
  rb_define_const(mDB, "QUOTED_LITERAL_REPLACEMENT_ON", INT2NUM(SET_QUOTED_LITERAL_REPLACEMENT_ON));
  /*Specifies Quoted Literal replacement connection attribute should not be set*/
  rb_define_const(mDB, "QUOTED_LITERAL_REPLACEMENT_OFF", INT2NUM(SET_QUOTED_LITERAL_REPLACEMENT_OFF));
  /*Specfies the version of the driver*/
  rb_define_const(mDB, "VERSION",rb_str_new2(MODULE_RELEASE));

  rb_global_variable(&persistent_list);

  /* REGISTER_INI_ENTRIES(); */

#ifndef _WIN32
  /* Tell DB2 where to find its libraries */
  tmp_name = INI_STR("ibm_db.instance_name");
  if ( NULL != tmp_name ) {
    instance_name = (char *)malloc(strlen(DB2_VAR_INSTANCE) + strlen(tmp_name) + 1);
    strcpy(instance_name, DB2_VAR_INSTANCE);
    strcat(instance_name, tmp_name);
    putenv(instance_name);
    _ruby_ibm_db_instance_name = instance_name;
  }
#endif

#ifdef _AIX
  /* atexit() handler in the DB2/AIX library segfaults in Ruby CLI */
  /* DB2NOEXITLIST env variable prevents DB2 from invoking atexit() */
  putenv("DB2NOEXITLIST=TRUE");
#endif

  persistent_list = rb_hash_new();
  
  le_conn_struct   =  rb_define_class_under(mDB, "Connection", rb_cObject);
  le_pconn_struct  =  rb_define_class_under(mDB, "PConnection", rb_cObject);
  le_stmt_struct   =  rb_define_class_under(mDB, "Statement", rb_cObject);
  le_row_struct    =  rb_define_class_under(mDB, "RowObject", rb_cObject);
  le_client_info   =  rb_define_class_under(mDB, "ClientInfo", rb_cObject);
  le_server_info   =  rb_define_class_under(mDB, "ServerInfo", rb_cObject);

  rb_define_method(le_row_struct, "method_missing", ibm_db_row_object, -1);

  rb_attr(le_client_info, rb_intern("DRIVER_NAME"), 1, 0, 0);
  rb_attr(le_client_info, rb_intern("DRIVER_VER"), 1, 0, 0);
  rb_attr(le_client_info, rb_intern("DATA_SOURCE_NAME"), 1, 0, 0);
  rb_attr(le_client_info, rb_intern("DRIVER_ODBC_VER"), 1, 0, 0);
  rb_attr(le_client_info, rb_intern("ODBC_VER"), 1, 0, 0);
  rb_attr(le_client_info, rb_intern("ODBC_SQL_CONFORMANCE"), 1, 0, 0);
  rb_attr(le_client_info, rb_intern("APPL_CODEPAGE"), 1, 0, 0);
  rb_attr(le_client_info, rb_intern("CONN_CODEPAGE"), 1, 0, 0);

  rb_attr(le_server_info, rb_intern("DBMS_NAME"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("DBMS_VER"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("DB_CODEPAGE"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("DB_NAME"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("INST_NAME"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("SPECIAL_CHARS"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("KEYWORDS"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("DFT_ISOLATION"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("ISOLATION_OPTION"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("SQL_CONFORMANCE"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("PROCEDURES"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("IDENTIFIER_QUOTE_CHAR"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("LIKE_ESCAPE_CLAUSE"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_COL_NAME_LEN"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_ROW_SIZE"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_IDENTIFIER_LEN"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_INDEX_SIZE"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_PROC_NAME_LEN"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_SCHEMA_NAME_LEN"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_STATEMENT_LEN"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("MAX_TABLE_NAME_LEN"), 1, 0, 0);
  rb_attr(le_server_info, rb_intern("NON_NULLABLE_COLUMNS"), 1, 0, 0);

  ruby_ibm_db_load_necessary_libs();

  ruby_ibm_db_check_if_cli_func_supported();
  
}
/*  */

/*  static void _ruby_ibm_db_init_error_info(stmt_handle *stmt_res)
*/
static void _ruby_ibm_db_init_error_info(stmt_handle *stmt_res)
{
  stmt_res->error_recno_tracker     =  1;
  stmt_res->errormsg_recno_tracker  =  1;
}
/*  */

/*  static void _ruby_ibm_db_check_sql_errors( void *conn_or_stmt, int resourceType, SQLSMALLINT hType, int rc, 
                                               int cpy_to_global, SQLPOINTER ret_str, SQLSMALLINT *ret_str_len , int API,
                                               SQLSMALLINT recno, int release_gil )
*/
static void _ruby_ibm_db_check_sql_errors( void *conn_or_stmt, int resourceType, SQLHANDLE handle, SQLSMALLINT hType,
                                           int rc, int cpy_to_global,  SQLPOINTER ret_str, SQLSMALLINT *ret_str_len, 
                                           int API, SQLSMALLINT recno, int release_gil )
{
  SQLPOINTER        msg                =  NULL;
  SQLPOINTER        errMsg             =  NULL;
  SQLPOINTER        sqlstate           =  NULL;

  SQLINTEGER        sqlcode;
  SQLSMALLINT       length;
  SQLSMALLINT       to_decrement       =  0;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE             print_str          =  Qnil;
#else
  char*             print_str          =  NULL;
#endif

  stmt_handle       *stmt_res          =  NULL;
  conn_handle       *conn_res          =  NULL;
  get_diagRec_args  *get_DiagRec_args  =  NULL;

  char *p;
  int  return_code;

  if( resourceType == DB_CONN ){
    conn_res  =  (conn_handle *) conn_or_stmt;
  } else if ( resourceType == DB_STMT ) {
    stmt_res  =  (stmt_handle *) conn_or_stmt;
  }

#ifdef UNICODE_SUPPORT_VERSION
  errMsg    =  ALLOC_N( SQLWCHAR, DB2_MAX_ERR_MSG_LEN );
  memset(errMsg, '\0', DB2_MAX_ERR_MSG_LEN * sizeof(SQLWCHAR) );

  msg       =  ALLOC_N( SQLWCHAR, SQL_MAX_MESSAGE_LENGTH + 1 );
  memset(msg, '\0', (SQL_MAX_MESSAGE_LENGTH + 1) * sizeof(SQLWCHAR) );

  sqlstate  =  ALLOC_N( SQLWCHAR, SQL_SQLSTATE_SIZE + 1 );
  memset(sqlstate, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
#else
  errMsg    =  ALLOC_N( SQLCHAR, DB2_MAX_ERR_MSG_LEN );
  memset(errMsg, '\0', DB2_MAX_ERR_MSG_LEN);

  msg       =  ALLOC_N( SQLCHAR, SQL_MAX_MESSAGE_LENGTH + 1 );
  memset(msg, '\0', SQL_MAX_MESSAGE_LENGTH + 1);

  sqlstate  =  ALLOC_N( SQLCHAR, SQL_SQLSTATE_SIZE + 1 );
  memset(sqlstate, '\0', SQL_SQLSTATE_SIZE + 1);

  print_str  =  ALLOC_N( SQLCHAR, SQL_SQLSTATE_SIZE + 1 + 10);
  memset(print_str, '\0', SQL_SQLSTATE_SIZE + 1 + 10);
#endif

  get_DiagRec_args  =  ALLOC( get_diagRec_args );
  memset(get_DiagRec_args,'\0',sizeof( struct _ibm_db_get_diagRec_struct ) );

  get_DiagRec_args->hType            =   hType;
  get_DiagRec_args->handle           =   handle;
  get_DiagRec_args->recNum           =   recno;
  get_DiagRec_args->SQLState         =   sqlstate;
  get_DiagRec_args->NativeErrorPtr   =   &sqlcode;
  get_DiagRec_args->msgText          =   msg;
  get_DiagRec_args->buff_length      =   SQL_MAX_MESSAGE_LENGTH + 1;
  get_DiagRec_args->text_length_ptr  =   &length;

  if( release_gil == 1 ){

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLGetDiagRec_helper, get_DiagRec_args,
                                (void *)_ruby_ibm_db_Connection_level_UBF, NULL);
	  return_code  =get_DiagRec_args->return_code; 						
    #else
      return_code  =  _ruby_ibm_db_SQLGetDiagRec_helper( get_DiagRec_args );
    #endif

  } else {
    return_code  =  _ruby_ibm_db_SQLGetDiagRec_helper( get_DiagRec_args );
  }

  /*Free Memory Allocated*/
  if( get_DiagRec_args != NULL ) {
    ruby_xfree( get_DiagRec_args );
    get_DiagRec_args  =  NULL;
  }

  if ( return_code == SQL_SUCCESS) {

#ifdef UNICODE_SUPPORT_VERSION
    while ((p = memchr( (char *)msg, '\n', length * sizeof(SQLWCHAR) ))) {
      to_decrement  =  1;
      *p            = '\0';
    }

    if( 1 == to_decrement ) {
      length = length - 1;
    }

    length = length * sizeof(SQLWCHAR);
    memcpy( errMsg, msg, length );
    print_str = _ruby_ibm_db_export_str_to_utf16( rb_sprintf( " SQLCODE=%d", (int)sqlcode ) );
    memcpy( (char *)errMsg + length, (void *)RSTRING_PTR( print_str ), RSTRING_LEN( print_str ) );
    length = length + RSTRING_LEN( print_str );
#else
    while ((p = memchr( (char *)msg, '\n', length ))) {
      to_decrement  =  1;
      *p            = '\0';
    }

    if( 1 == to_decrement ) {
      length = length - 1;
    }

    memcpy( errMsg, msg, length );
    sprintf(print_str, " SQLCODE=%d", (int)sqlcode);
    memcpy( (char *)errMsg + length, print_str, strlen( print_str ) );
    length = length + strlen( print_str );
#endif

    switch ( rc ) {
      case SQL_ERROR:
        /* Need to copy the error msg and sqlstate into the symbol Table to cache these results */
        if ( cpy_to_global ) {
          switch (hType) {
            case SQL_HANDLE_ENV:
            case SQL_HANDLE_DBC:
              /*
                This copying into global should be removed once the deprecated methods 
                conn_errormsg and conn_error are removed
              */
#ifdef UNICODE_SUPPORT_VERSION
              memset(IBM_DB_G( __ruby_conn_err_msg), '\0', DB2_MAX_ERR_MSG_LEN * sizeof(SQLWCHAR) );
              memset(IBM_DB_G( __ruby_conn_err_state), '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );

              memcpy(IBM_DB_G( __ruby_conn_err_msg), errMsg, length );
              memcpy(IBM_DB_G( __ruby_conn_err_state), sqlstate, (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
#else
              memset(IBM_DB_G( __ruby_conn_err_msg), '\0', DB2_MAX_ERR_MSG_LEN );
              memset(IBM_DB_G( __ruby_conn_err_state), '\0', SQL_SQLSTATE_SIZE + 1 );

              memcpy(IBM_DB_G( __ruby_conn_err_msg), errMsg, length );
              memcpy(IBM_DB_G( __ruby_conn_err_state), sqlstate, SQL_SQLSTATE_SIZE + 1 );
#endif

              if(conn_res == NULL ) {
                break;
              }
              conn_res->errorType  =  1;

              if( conn_res->ruby_error_state == NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
                conn_res->ruby_error_state = ALLOC_N( SQLWCHAR, SQL_SQLSTATE_SIZE + 1 );
#else
                conn_res->ruby_error_state = ALLOC_N( char, SQL_SQLSTATE_SIZE + 1 );
#endif
              }

              if( conn_res->ruby_error_msg == NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
                conn_res->ruby_error_msg = ALLOC_N( SQLWCHAR, DB2_MAX_ERR_MSG_LEN + 1 );
#else
                conn_res->ruby_error_msg = ALLOC_N( char, DB2_MAX_ERR_MSG_LEN + 1 );
#endif
              }

#ifdef UNICODE_SUPPORT_VERSION
              memset( conn_res->ruby_error_state, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
              memset( conn_res->ruby_error_msg, '\0', (DB2_MAX_ERR_MSG_LEN + 1) * sizeof(SQLWCHAR) );

              memcpy( conn_res->ruby_error_state, sqlstate, (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
              memcpy( conn_res->ruby_error_msg, errMsg, length );
#else
              memset( conn_res->ruby_error_state, '\0', SQL_SQLSTATE_SIZE + 1 );
              memset( conn_res->ruby_error_msg, '\0', DB2_MAX_ERR_MSG_LEN + 1 );

              strncpy(conn_res->ruby_error_state, (char*)sqlstate, SQL_SQLSTATE_SIZE + 1 );
              strncpy(conn_res->ruby_error_msg, (char*)errMsg, length );
#endif
              conn_res->ruby_error_msg_len  =  length;
              conn_res->sqlcode             =  sqlcode;
              break;

            case SQL_HANDLE_STMT:
              switch( resourceType ) {
                case DB_CONN:
                  if(conn_res == NULL ) {
                    break;
                  }
                  conn_res->errorType  =  0;

                  if( conn_res->ruby_error_state == NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
                    conn_res->ruby_error_state = ALLOC_N( SQLWCHAR, SQL_SQLSTATE_SIZE + 1 );
#else
                    conn_res->ruby_error_state = ALLOC_N(char, SQL_SQLSTATE_SIZE + 1 );
#endif
                  }

                  if( conn_res->ruby_error_msg == NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
                    conn_res->ruby_error_msg = ALLOC_N( SQLWCHAR, DB2_MAX_ERR_MSG_LEN + 1 );
#else
                    conn_res->ruby_error_msg = ALLOC_N( char, DB2_MAX_ERR_MSG_LEN + 1 );
#endif
                  }

#ifdef UNICODE_SUPPORT_VERSION
                  memset( conn_res->ruby_error_state, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
                  memset( conn_res->ruby_error_msg, '\0', (DB2_MAX_ERR_MSG_LEN + 1) * sizeof(SQLWCHAR) );

                  memcpy(conn_res->ruby_error_state, sqlstate, (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
                  memcpy(conn_res->ruby_error_msg, errMsg, length  );
#else
                  memset( conn_res->ruby_error_state, '\0', SQL_SQLSTATE_SIZE + 1 );
                  memset( conn_res->ruby_error_msg, '\0', DB2_MAX_ERR_MSG_LEN + 1 );

                  strncpy(conn_res->ruby_error_state, (char*)sqlstate, SQL_SQLSTATE_SIZE + 1 );
                  strncpy(conn_res->ruby_error_msg, (char*)errMsg, length );
#endif
                  conn_res->ruby_error_msg_len  =  length;
                  conn_res->sqlcode             =  sqlcode;
                  break;

                case DB_STMT:
                  if(stmt_res == NULL ) {
                    break;
                  }

                  if( stmt_res->ruby_stmt_err_state == NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
                    stmt_res->ruby_stmt_err_state = ALLOC_N( SQLWCHAR, SQL_SQLSTATE_SIZE + 1 );
#else
                    stmt_res->ruby_stmt_err_state = ALLOC_N( char, SQL_SQLSTATE_SIZE + 1 );
#endif
                  }

                  if( stmt_res->ruby_stmt_err_msg == NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
                    stmt_res->ruby_stmt_err_msg = ALLOC_N( SQLWCHAR, DB2_MAX_ERR_MSG_LEN + 1 );
#else
                    stmt_res->ruby_stmt_err_msg = ALLOC_N( char, DB2_MAX_ERR_MSG_LEN + 1 );
#endif
                  }

#ifdef UNICODE_SUPPORT_VERSION
                  memset( stmt_res->ruby_stmt_err_state, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
                  memset( stmt_res->ruby_stmt_err_msg, '\0', (DB2_MAX_ERR_MSG_LEN + 1) * sizeof(SQLWCHAR) );

                  memcpy(stmt_res->ruby_stmt_err_state, sqlstate, (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
                  memcpy(stmt_res->ruby_stmt_err_msg, errMsg, length );
#else
                  memset( stmt_res->ruby_stmt_err_state, '\0', SQL_SQLSTATE_SIZE + 1 );
                  memset( stmt_res->ruby_stmt_err_msg, '\0', DB2_MAX_ERR_MSG_LEN + 1 );

                  strncpy(stmt_res->ruby_stmt_err_state, (char*)sqlstate, SQL_SQLSTATE_SIZE + 1 );
                  strncpy(stmt_res->ruby_stmt_err_msg, (char*)errMsg, length );
#endif
                  stmt_res->ruby_stmt_err_msg_len  =  length;
                  stmt_res->sqlcode                =  sqlcode;
                  break; 

              }  /*End of switch( resourceType )*/

              /*
                This copying into global should be removed once the deprecated methods 
                conn_errormsg and conn_error are removed
              */
#ifdef UNICODE_SUPPORT_VERSION
              memset( IBM_DB_G(__ruby_stmt_err_state), '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
              memset( IBM_DB_G(__ruby_stmt_err_msg), '\0', (DB2_MAX_ERR_MSG_LEN + 1) * sizeof(SQLWCHAR) );

              memcpy( IBM_DB_G(__ruby_stmt_err_state), sqlstate, (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
              memcpy( IBM_DB_G(__ruby_stmt_err_msg), errMsg, length );
#else
              memset( IBM_DB_G(__ruby_stmt_err_state), '\0', SQL_SQLSTATE_SIZE + 1 );
              memset( IBM_DB_G(__ruby_stmt_err_msg), '\0', (DB2_MAX_ERR_MSG_LEN + 1) );

              strncpy(IBM_DB_G(__ruby_stmt_err_state), (char*)sqlstate, SQL_SQLSTATE_SIZE + 1 );
              strncpy(IBM_DB_G(__ruby_stmt_err_msg), (char*)errMsg, length );
#endif

              break;

          }  /*End of switch( hType )*/
        }

        /* This call was made from ibm_db_errmsg or ibm_db_error */
        /* Check for error and return */
        switch (API) {
          case DB_ERR_STATE:
            if ( ret_str != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
              memcpy( ret_str, sqlstate, (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
              if( ret_str_len != NULL ) {
                *ret_str_len = (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR);
              }
#else
              memcpy( ret_str, sqlstate, (SQL_SQLSTATE_SIZE + 1) );
              if( ret_str_len != NULL ) {
                *ret_str_len = SQL_SQLSTATE_SIZE + 1;
              }
#endif
            }
            break;
          case DB_ERRMSG:
            if ( ret_str != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
              memcpy( ret_str, msg, length );
#else
              memcpy( ret_str, msg, length );
#endif
              if( ret_str_len != NULL ) {
                *ret_str_len = length;
              }
            }
            break;
          default:
            break;
        }

        break;

      default:
        break;
    }
  }

  /*Free memory Allocated*/
  if( msg != NULL ) {
    ruby_xfree( msg );
  }

  if( errMsg != NULL ) {
    ruby_xfree( errMsg );
  }

  if( sqlstate != NULL ) {
    ruby_xfree( sqlstate );
  }
  
}
/*  */

/*  
   static void _ruby_ibm_db_assign_options( void *handle, int type, long opt_key, VALUE data, VALUE *error )
*/
static VALUE _ruby_ibm_db_assign_options( void *handle, int type, long opt_key, VALUE data, VALUE *error )
{
  int    rc            =  0;
  long   option_num    =  0;
  char   *option_str   =  NULL;

  set_handle_attr_args *handleAttr_args = NULL;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE data_utf16 = Qnil;
#endif

  /* First check to see if it is a non-cli attribut */
  if (opt_key == ATTR_CASE) {
    option_num = NUM2LONG(data);
    if (type == SQL_HANDLE_STMT) {
      switch (option_num) {
        case CASE_LOWER:
          ((stmt_handle*)handle)->s_case_mode = CASE_LOWER;
          break;
        case CASE_UPPER:
          ((stmt_handle*)handle)->s_case_mode = CASE_UPPER;
          break;
        case CASE_NATURAL:
          ((stmt_handle*)handle)->s_case_mode = CASE_NATURAL;
          break;
        default:
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("ATTR_CASE attribute must be one of CASE_LOWER, CASE_UPPER, or CASE_NATURAL");
#else
          *error = rb_str_new2("ATTR_CASE attribute must be one of CASE_LOWER, CASE_UPPER, or CASE_NATURAL");
#endif
          return Qfalse;
      }
    } else if (type == SQL_HANDLE_DBC) {
      switch (option_num) {
        case CASE_LOWER:
          ((conn_handle*)handle)->c_case_mode = CASE_LOWER;
          break;
        case CASE_UPPER:
          ((conn_handle*)handle)->c_case_mode = CASE_UPPER;
          break;
        case CASE_NATURAL:
          ((conn_handle*)handle)->c_case_mode = CASE_NATURAL;
          break;
        default:
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("ATTR_CASE attribute must be one of CASE_LOWER, CASE_UPPER, or CASE_NATURAL");
#else
          *error = rb_str_new2("ATTR_CASE attribute must be one of CASE_LOWER, CASE_UPPER, or CASE_NATURAL");
#endif
          return Qfalse;
      }
    } else {
#ifdef UNICODE_SUPPORT_VERSION
      *error = _ruby_ibm_db_export_char_to_utf8_rstr("Connection or statement handle must be passed in");
#else
      *error = rb_str_new2("Connection or statement handle must be passed in");
#endif
      return Qfalse;
    }
  } else if (type == SQL_HANDLE_STMT) {
    handleAttr_args = ALLOC( set_handle_attr_args );
    memset(handleAttr_args,'\0',sizeof(struct _ibm_db_set_handle_attr_struct));

    handleAttr_args->handle      =  &((stmt_handle *)handle)->hstmt;
    handleAttr_args->attribute   =  opt_key;

    if (TYPE(data) == T_STRING) {

#ifndef UNICODE_SUPPORT_VERSION
      option_str  =  RSTRING_PTR(data);
#else
      data_utf16  =  _ruby_ibm_db_export_str_to_utf16(data);
      option_str  =  RSTRING_PTR(data_utf16);
#endif

#ifdef PASE
      handleAttr_args->valuePtr = (SQLPOINTER)&option_str;
#else
      handleAttr_args->valuePtr = (SQLPOINTER)option_str;
#endif

      handleAttr_args->strLength   =  SQL_NTS;

      rc  =  _ruby_ibm_db_SQLSetStmtAttr_helper( handleAttr_args );

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( handle, DB_STMT, (SQLHSTMT)((stmt_handle *)handle)->hstmt, 
                  SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        if( handle != NULL && ((stmt_handle *)handle)->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Setting of statement attribute failed: "), 
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(((stmt_handle *)handle)->ruby_stmt_err_msg, 
                               ((stmt_handle *)handle)->ruby_stmt_err_msg_len) 
                   );
#else
          *error = rb_str_cat2(rb_str_new2("Setting of statement attribute failed: "), ((stmt_handle *)handle)->ruby_stmt_err_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Setting of statement attribute failed: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Setting of statement attribute failed: <error message could not be retrieved>");
#endif
        }
        return Qfalse;
      }
    } else {
      option_num = NUM2LONG(data);

      handleAttr_args->strLength   =  SQL_IS_INTEGER;

      if (opt_key == SQL_ATTR_AUTOCOMMIT && option_num == SQL_AUTOCOMMIT_OFF) {
        ((conn_handle*)handle)->auto_commit = 0;
      } else if (opt_key == SQL_ATTR_AUTOCOMMIT && option_num == SQL_AUTOCOMMIT_ON) {
        ((conn_handle*)handle)->auto_commit = 1;
      }

#ifdef PASE
      handleAttr_args->valuePtr = (SQLPOINTER)&option_num;
#else
      handleAttr_args->valuePtr = (SQLPOINTER)option_num;
#endif

      rc = _ruby_ibm_db_SQLSetStmtAttr_helper( handleAttr_args );

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( handle, DB_STMT, (SQLHSTMT)((stmt_handle *)handle)->hstmt, 
                  SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        if( handle != NULL && ((stmt_handle *)handle)->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Setting of statement attribute failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(((stmt_handle *)handle)->ruby_stmt_err_msg,
                               ((stmt_handle *)handle)->ruby_stmt_err_msg_len)
                   );
#else
          *error = rb_str_cat2(rb_str_new2("Setting of statement attribute failed: "), ((stmt_handle *)handle)->ruby_stmt_err_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Setting of statement attribute failed: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Setting of statement attribute failed: <error message could not be retrieved>");
#endif
        }
        return Qfalse;
      }
    }
  } else if (type == SQL_HANDLE_DBC) {
    handleAttr_args = ALLOC( set_handle_attr_args );
    memset(handleAttr_args,'\0',sizeof(struct _ibm_db_set_handle_attr_struct));

    handleAttr_args->handle      =  &((conn_handle*)handle)->hdbc;
    handleAttr_args->strLength   =  SQL_NTS;
    handleAttr_args->attribute   =  opt_key;

    if (TYPE(data) == T_STRING) {
#ifndef UNICODE_SUPPORT_VERSION
      option_str                   =  RSTRING_PTR(data);
      handleAttr_args->strLength   =  RSTRING_LEN(data);
#else
      data_utf16                   =  _ruby_ibm_db_export_str_to_utf16(data);
      option_str                   =  RSTRING_PTR(data_utf16);
      handleAttr_args->strLength   =  RSTRING_LEN(data_utf16);
#endif

#ifdef PASE
      handleAttr_args->valuePtr = (SQLPOINTER)&option_str;
#else
      handleAttr_args->valuePtr = (SQLPOINTER)option_str;
#endif

      rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( handle, DB_CONN, (SQLHDBC)((conn_handle *)handle)->hdbc, 
                  SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        if( handle != NULL && ((conn_handle *)handle)->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Setting of connection attribute failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(((conn_handle *)handle)->ruby_error_msg,
                               ((conn_handle *)handle)->ruby_error_msg_len)
                   );
#else
          *error = rb_str_cat2(rb_str_new2("Setting of connection attribute failed: "), ((conn_handle *)handle)->ruby_error_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Setting of connection attribute failed: <error message could not be retrieved>");
#else
          *error =  rb_str_new2("Setting of connection attribute failed: <error message could not be retrieved>");
#endif
        }
        return Qfalse;
      }
    } else {
      option_num = NUM2LONG(data);
#ifdef PASE
      handleAttr_args->valuePtr = (SQLPOINTER)&option_num;
#else
      handleAttr_args->valuePtr = (SQLPOINTER)option_num;
#endif

      rc =  _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( handle, DB_CONN, (SQLHDBC)((conn_handle *)handle)->hdbc, 
                  SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0);
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        if( handle != NULL && ((conn_handle *)handle)->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Setting of connection attribute failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( ((stmt_handle *)handle)->ruby_stmt_err_msg,
                               ((stmt_handle *)handle)->ruby_stmt_err_msg_len)
                   );
#else
          *error = rb_str_cat2(rb_str_new2("Setting of connection attribute failed: "), ((conn_handle *)handle)->ruby_error_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Setting of connection attribute failed: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Setting of connection attribute failed: <error message could not be retrieved>");
#endif
        }
        return Qfalse;
      } else {
        if (opt_key == SQL_ATTR_AUTOCOMMIT && option_num == SQL_AUTOCOMMIT_OFF) {
          ((conn_handle*)handle)->auto_commit = 0;
        } else if (opt_key == SQL_ATTR_AUTOCOMMIT && option_num == SQL_AUTOCOMMIT_ON) {
          ((conn_handle*)handle)->auto_commit        = 1;
          ((conn_handle*)handle)->transaction_active = 0; /* Setting Autocommit to ON commits any open transaction*/
        }
      }
    }
  } else {
#ifdef UNICODE_SUPPORT_VERSION
      *error = _ruby_ibm_db_export_char_to_utf8_rstr("Connection or statement handle must be passed in");
#else
      *error = rb_str_new2("Connection or statement handle must be passed in");
#endif
      return Qfalse;
  }

  /*Free Any Memory allocated*/
  if( handleAttr_args != NULL ) {
    ruby_xfree( handleAttr_args );
    handleAttr_args = NULL;
  }

  return Qtrue;
}
/*  */

/*  static int _ruby_ibm_db_parse_options( VALUE options, int type, void *handle, VALUE *error)
*/
static int _ruby_ibm_db_parse_options ( VALUE options, int type, void *handle, VALUE *error )
{
  int   numOpts = 0, i = 0;
  VALUE keys;
  VALUE key; /* Holds the Option Index Key */
  VALUE data;
  VALUE tc_pass = Qnil;
  VALUE ret_val = Qtrue;

  if ( !NIL_P(options) ) {
    keys     =  rb_funcall(options, id_keys, 0);
    numOpts  =  RARRAY_LEN(keys);

    for ( i = 0; i < numOpts; i++) {
      key  =  rb_ary_entry(keys,i);
      data =  rb_hash_aref(options,key);

      if (NUM2LONG(key) == SQL_ATTR_TRUSTED_CONTEXT_PASSWORD) {
        tc_pass = data;
      } else {
        /* Assign options to handle. */
        /* Sets the options in the handle with CLI/ODBC calls */
        ret_val  =  _ruby_ibm_db_assign_options( handle, type, NUM2LONG(key), data, error );
      }
    }
    if ( !NIL_P(tc_pass) ) {
      ret_val  =  _ruby_ibm_db_assign_options( handle, type, SQL_ATTR_TRUSTED_CONTEXT_PASSWORD, tc_pass, error );
    }
  }

  if( ret_val == Qfalse ){
    return SQL_ERROR;
  }
  
  return SQL_SUCCESS;
}
/*  */

/* 
    static int _ruby_ibm_db_get_result_set_info(stmt_handle *stmt_res)
    initialize the result set information of each column. This must be done once
*/
static int _ruby_ibm_db_get_result_set_info(stmt_handle *stmt_res)
{
  int rc = -1, i;
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR  tmp_name[BUFSIZ];
#else
  SQLCHAR   tmp_name[BUFSIZ];
#endif

  row_col_count_args *result_cols_args = NULL;
  describecol_args   *describecolargs  = NULL;

  result_cols_args = ALLOC( row_col_count_args );
  memset(result_cols_args,'\0',sizeof(struct _ibm_db_row_col_count_struct));

  result_cols_args->stmt_res =  stmt_res;
  result_cols_args->count    =  0;

  rc = _ruby_ibm_db_SQLNumResultCols_helper( result_cols_args );

  if ( rc == SQL_ERROR || result_cols_args->count == 0) {
    _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
    ruby_xfree( result_cols_args );
    result_cols_args = NULL;
	stmt_res->rc = -1;
    return -1;
  }
  stmt_res->num_columns = result_cols_args->count;

  stmt_res->column_info = ALLOC_N(ibm_db_result_set_info, result_cols_args->count);
  memset(stmt_res->column_info, 0, sizeof(ibm_db_result_set_info)*(result_cols_args->count));

  describecolargs = ALLOC( describecol_args );
  memset(describecolargs,'\0',sizeof(struct _ibm_db_describecol_args_struct));

  describecolargs->stmt_res     =  stmt_res;

  /* return a set of attributes for a column */
  for (i = 0 ; i < result_cols_args->count; i++) {
    stmt_res->column_info[i].lob_loc  = 0;
    stmt_res->column_info[i].loc_ind  = 0;
    stmt_res->column_info[i].loc_type = 0;

    stmt_res->column_info[i].name = tmp_name;
#ifdef UNICODE_SUPPORT_VERSION
    memset(stmt_res->column_info[i].name, '\0', BUFSIZ * sizeof(SQLWCHAR));
#else
    memset(stmt_res->column_info[i].name, '\0', BUFSIZ);
#endif

    describecolargs->col_no       =  i + 1;
    describecolargs->name_length  =  0;
    describecolargs->buff_length  =  BUFSIZ;

    rc = _ruby_ibm_db_SQLDescribeCol_helper( describecolargs );

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT, 
                  rc, 1, NULL, NULL, -1, 1, 0 );
      ruby_xfree( result_cols_args );
      ruby_xfree( describecolargs );
      ruby_xfree( stmt_res->column_info );
      result_cols_args       =  NULL;
      describecolargs        =  NULL;
      stmt_res->column_info  =  NULL;
	  stmt_res->rc = -1;
      return -1;
    }
    if ( describecolargs->name_length <= 0 ) {
#ifdef UNICODE_SUPPORT_VERSION
      stmt_res->column_info[i].name        = esqlwchardup((SQLWCHAR*)"", 0);
      stmt_res->column_info[i].name_length = 0;
#else
      stmt_res->column_info[i].name = (SQLCHAR *)estrdup("");
#endif
    } else if ( describecolargs->name_length >= BUFSIZ ) {
      /* column name is longer than BUFSIZ, free the previously allocate memory and reallocate new*/

#ifdef UNICODE_SUPPORT_VERSION
      stmt_res->column_info[i].name         =  (SQLWCHAR*)ALLOC_N(SQLWCHAR, describecolargs->name_length+1);
      stmt_res->column_info[i].name_length  =  describecolargs->name_length ;
#else
      stmt_res->column_info[i].name = (SQLCHAR*)ALLOC_N(char, describecolargs->name_length+1);
#endif

      describecolargs->buff_length  =  describecolargs->name_length + 1;

      rc = _ruby_ibm_db_SQLDescribeCol_helper( describecolargs );

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                  rc, 1, NULL, NULL, -1, 1, 0 );
        ruby_xfree( describecolargs );
        ruby_xfree( result_cols_args );
        ruby_xfree( stmt_res->column_info );
        result_cols_args       =  NULL;
        describecolargs        =  NULL;
        stmt_res->column_info  =  NULL;
		stmt_res->rc = -1;
        return -1;
      }
    } else {
#ifdef UNICODE_SUPPORT_VERSION
      stmt_res->column_info[i].name         =  (SQLWCHAR*) esqlwchardup( tmp_name, describecolargs->name_length );
      stmt_res->column_info[i].name_length  =  describecolargs->name_length;
#else
      stmt_res->column_info[i].name = (SQLCHAR*) estrdup( (char *)tmp_name );
#endif
    }
  }

  /*Free Memory Allocated*/
  if ( describecolargs != NULL ) {
    ruby_xfree( describecolargs );
    describecolargs = NULL;
  }

  if ( result_cols_args != NULL ) {
    ruby_xfree( result_cols_args );
    result_cols_args = NULL;
  }
  stmt_res->rc = 0;
  return 0;
}
/*  */

/*  static int _ruby_ibm_db_bind_column_helper(stmt_handle *stmt_res)
  bind columns to data, this must be done once
*/
static int _ruby_ibm_db_bind_column_helper(stmt_handle *stmt_res)
{
  SQLSMALLINT column_type;
  ibm_db_row_data_type *row_data;

  int i, rc = SQL_SUCCESS;
  bind_col_args *bindCol_args = NULL;

  stmt_res->row_data = ALLOC_N(ibm_db_row_type, stmt_res->num_columns);
  memset(stmt_res->row_data,'\0',sizeof(ibm_db_row_type)*stmt_res->num_columns);

  bindCol_args = ALLOC( bind_col_args );
  memset(bindCol_args,'\0',sizeof(struct _ibm_db_bind_col_struct));

  bindCol_args->stmt_res  =  stmt_res;
  
  for (i=0; i<stmt_res->num_columns; i++) {
    column_type =  stmt_res->column_info[i].type;
    row_data    =  &stmt_res->row_data[i].data;

    bindCol_args->col_num         =  (SQLUSMALLINT) i+1;

    switch(column_type) {
      case SQL_CHAR:
      case SQL_WCHAR:
      case SQL_VARCHAR:
      case SQL_WVARCHAR:
      case SQL_GRAPHIC:
      case SQL_VARGRAPHIC:
#ifndef PASE /* i5/OS EBCIDIC<->ASCII related - we do getdata call instead */
      case SQL_LONGVARCHAR:
      case SQL_WLONGVARCHAR:

#ifdef UNICODE_SUPPORT_VERSION
        bindCol_args->TargetType      =  SQL_C_WCHAR;
        bindCol_args->buff_length     =  (stmt_res->column_info[i].size+1) * sizeof(SQLWCHAR);
        row_data->str_val             =  ALLOC_N(char, bindCol_args->buff_length);
        /*Note: buff_length already is multiplied by sizeof SQLWCHAR, hence allocating mem for type char (1 byte)*/
#else
        bindCol_args->TargetType      =  SQL_C_CHAR;
        bindCol_args->buff_length     =  stmt_res->column_info[i].size+1;
        if( column_type == SQL_GRAPHIC || column_type == SQL_VARGRAPHIC ){
          /* Graphic string is 2 byte character string.
           * Size multiply by 2 is required only for non-unicode support version because the W equivalent functions return 
           * SQLType as wchar or wvarchar, respectively. Hence is handled properly.        
           */
          bindCol_args->buff_length     =  bindCol_args->buff_length * 2;
        }
		
        if( column_type == SQL_CHAR || column_type == SQL_VARCHAR ) {
          /* Multiply the size by 4 to handle cases where client and server code pages are different.
           * 4 bytes should be able to cover any codeset character known*/
          bindCol_args->buff_length     =  bindCol_args->buff_length * 4;
        }
		
        row_data->str_val             =  ALLOC_N(char, bindCol_args->buff_length);
#endif
        bindCol_args->TargetValuePtr  =  row_data->str_val;
        bindCol_args->out_length      =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );
        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
#else
        stmt_res->row_data[i].out_length = 0;
#endif
        break;

      case SQL_BINARY:
#ifndef PASE /* i5/OS SQL_LONGVARBINARY is SQL_VARBINARY */
      case SQL_LONGVARBINARY:
#endif /* PASE */
      case SQL_VARBINARY:
        bindCol_args->out_length        =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        if ( stmt_res->s_bin_mode == CONVERT ) {
          bindCol_args->TargetType      =  SQL_C_CHAR;
          bindCol_args->buff_length     =  2*(stmt_res->column_info[i].size)+1;
          row_data->str_val             =  ALLOC_N(char, bindCol_args->buff_length);
          bindCol_args->TargetValuePtr  =  row_data->str_val;

          rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

          if ( rc == SQL_ERROR ) {
            _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                      rc, 1, NULL, NULL, -1, 1, 0 );
          }
        } else {
          bindCol_args->TargetType      =  SQL_C_DEFAULT;
          bindCol_args->buff_length     =  stmt_res->column_info[i].size+1;
          row_data->str_val             =  ALLOC_N(char, bindCol_args->buff_length);
          bindCol_args->TargetValuePtr  =  row_data->str_val;

          rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

          if ( rc == SQL_ERROR ) {
            _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                      rc, 1, NULL, NULL, -1, 1, 0);
          }
        }
        break;

      case SQL_TYPE_DATE:
      case SQL_TYPE_TIME:
      case SQL_TYPE_TIMESTAMP:
      case SQL_BIGINT:
      case SQL_DECFLOAT:
        bindCol_args->TargetType      =  SQL_C_CHAR;
        bindCol_args->buff_length     =  stmt_res->column_info[i].size+1;
        row_data->str_val             =  ALLOC_N(char, bindCol_args->buff_length);
        bindCol_args->TargetValuePtr  =  row_data->str_val;
        bindCol_args->out_length      =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;

      case SQL_SMALLINT:
        bindCol_args->TargetType      =  SQL_C_DEFAULT;
        bindCol_args->buff_length     =  sizeof(row_data->s_val);
        bindCol_args->TargetValuePtr  =  &row_data->s_val;
        bindCol_args->out_length      =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;

      case SQL_INTEGER:
        bindCol_args->TargetType      =  SQL_C_DEFAULT;
        bindCol_args->buff_length     =  sizeof(row_data->i_val);
        bindCol_args->TargetValuePtr  =  &row_data->i_val;
        bindCol_args->out_length      =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;

      case SQL_REAL:
      case SQL_FLOAT:
        bindCol_args->TargetType      =  SQL_C_DEFAULT;
        bindCol_args->buff_length     =  sizeof(row_data->f_val);
        bindCol_args->TargetValuePtr  =  &row_data->f_val;
        bindCol_args->out_length      =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;

      case SQL_DOUBLE:
        bindCol_args->TargetType      =  SQL_C_DEFAULT;
        bindCol_args->buff_length     =  sizeof(row_data->d_val);
        bindCol_args->TargetValuePtr  =  &row_data->d_val;
        bindCol_args->out_length      =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;

      case SQL_DECIMAL:
      case SQL_NUMERIC:
        bindCol_args->TargetType      =  SQL_C_CHAR;
        bindCol_args->buff_length     =  stmt_res->column_info[i].size +
                                           stmt_res->column_info[i].scale + 2 + 1;
        row_data->str_val             =  ALLOC_N(char, bindCol_args->buff_length);
        bindCol_args->TargetValuePtr  =  row_data->str_val;
        bindCol_args->out_length      =  (SQLLEN *) (&stmt_res->row_data[i].out_length);

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;

      case SQL_CLOB:
        stmt_res->row_data[i].out_length  =  0;
        stmt_res->column_info[i].loc_type =  SQL_CLOB_LOCATOR;

        bindCol_args->TargetType      =  stmt_res->column_info[i].loc_type;
        bindCol_args->buff_length     =  4;
        bindCol_args->TargetValuePtr  =  &stmt_res->column_info[i].lob_loc;
        bindCol_args->out_length      =  &stmt_res->column_info[i].loc_ind;

        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;
      case SQL_BLOB:
        stmt_res->row_data[i].out_length  =  0;
        stmt_res->column_info[i].loc_type =  SQL_BLOB_LOCATOR;

        bindCol_args->TargetType      =  stmt_res->column_info[i].loc_type;
        bindCol_args->buff_length     =  4;
        bindCol_args->TargetValuePtr  =  &stmt_res->column_info[i].lob_loc;
        bindCol_args->out_length      =  &stmt_res->column_info[i].loc_ind;
	
        rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT,
                    rc, 1, NULL, NULL, -1, 1, 0 );
        }
        break;
      case SQL_XML:
        stmt_res->row_data[i].out_length = 0;
        break;

      default:
        break;
    }
    /*Reset all the data in bindCol_args for next iteration*/
    bindCol_args->col_num         =  0;
    bindCol_args->TargetType      =  SQL_C_DEFAULT;
    bindCol_args->buff_length     =  0;
    bindCol_args->TargetValuePtr  =  NULL;
    bindCol_args->out_length      =  NULL;
  }
  /*Free Any Memory Allocated*/
  if ( bindCol_args != NULL ) {
    ruby_xfree( bindCol_args );
    bindCol_args = NULL;
  }
  
  return rc;
}
/*  */

/*  static void _ruby_ibm_db_clear_stmt_err_cache ()
*/
static void _ruby_ibm_db_clear_stmt_err_cache()
{
  memset(IBM_DB_G(__ruby_stmt_err_msg), '\0', DB2_MAX_ERR_MSG_LEN);
  memset(IBM_DB_G(__ruby_stmt_err_state), '\0', SQL_SQLSTATE_SIZE + 1);
}

/*  static VALUE _ruby_ibm_db_connect_helper2( connect_helper_args *data )
*/
static VALUE _ruby_ibm_db_connect_helper2( connect_helper_args *data ) {

  SQLINTEGER conn_alive;
  SQLINTEGER enable_numeric_literals = 1; /* Enable CLI numeric literals */

  conn_handle *conn_res = NULL;

  connect_args *conn_args    =  data->conn_args;
  VALUE        *options      =  data->options;
  int          isPersistent  =  data->isPersistent;
  VALUE        *error        =  data->error;

  int           rc           =  0;
  int           reused       =  0;
  SQLSMALLINT   out_length   =  0;
  VALUE         entry        =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR *server      =  NULL;
  VALUE    iserver      =  Qnil;
  VALUE    idsserver    =  Qnil;
  VALUE    server_utf16 =  Qnil;
#else
  SQLCHAR  *server  =  NULL;
#endif

  get_info_args          *getInfo_args        =  NULL;
  set_handle_attr_args   *handleAttr_args     =  NULL;
  get_handle_attr_args   *get_handleAttr_args =  NULL;

  conn_alive = 1;
  

  handleAttr_args = ALLOC( set_handle_attr_args );
  memset(handleAttr_args,'\0',sizeof(struct _ibm_db_set_handle_attr_struct));

  do {
    /* Check if we already have a connection for this userID & database combination */
    if ( isPersistent ) {
      if ( !NIL_P(entry = rb_hash_aref(persistent_list, data->hKey)) ) {		  
        Data_Get_Struct(entry, conn_handle, conn_res);
#ifndef PASE /* i5/OS server mode is persistant */
        /* Need to reinitialize connection? */
        get_handleAttr_args = ALLOC( get_handle_attr_args );
        memset(get_handleAttr_args,'\0',sizeof(struct _ibm_db_get_handle_attr_struct));

        get_handleAttr_args->handle       =  &( conn_res->hdbc );
        get_handleAttr_args->attribute    =  SQL_ATTR_PING_DB;
        get_handleAttr_args->valuePtr     =  (SQLPOINTER)&conn_alive;
        get_handleAttr_args->buff_length  =  0;
        get_handleAttr_args->out_length   =  NULL;
		
        rc = _ruby_ibm_db_SQLGetConnectAttr_helper( get_handleAttr_args );
		
        ruby_xfree( get_handleAttr_args );
        get_handleAttr_args = NULL;

        if ( (rc == SQL_SUCCESS) && conn_alive ) {
          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
          reused = 1;
        } /* else will re-connect since connection is dead */
#endif /* PASE */
        reused = 1;
      }
    } else {
      /* Need to check for max pconnections? */
    }
    if ( conn_res == NULL ) {
      conn_res = ALLOC(conn_handle);
      memset(conn_res, '\0', sizeof(conn_handle));
    }
    /* handle not active as of yet */
    conn_res->handle_active = 0;

    /* We need to set this early, in case we get an error below,
      so we know how to free the connection */
    conn_res->flag_pconnect = isPersistent;
    /* Allocate ENV handles if not present */
    if ( !conn_res->henv ) {
#ifndef PASE /* i5/OS difference */
      rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &(conn_res->henv));
#else /* PASE */
      rc = SQLAllocEnv(&(conn_res->henv));
#endif /* PASE */
      if (rc != SQL_SUCCESS) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->henv, SQL_HANDLE_ENV, rc, 1, NULL, NULL, -1, 1, 0 );
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        if( conn_res != NULL && conn_res->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Allocation of environment handle failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(conn_res->ruby_error_msg, conn_res->ruby_error_msg_len )
                   );
#else
          *error = rb_str_cat2(rb_str_new2("Allocation of environment handle failed: "), conn_res->ruby_error_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Allocation of environment handle failed: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Allocation of environment handle failed: <error message could not be retrieved>");
#endif
        }
        return Qnil;
        break;
      }
      handleAttr_args->handle      =  &( conn_res->henv );
      handleAttr_args->strLength   =  0;
#ifndef PASE /* i5/OS server mode */
      handleAttr_args->attribute   =  SQL_ATTR_ODBC_VERSION;
      handleAttr_args->valuePtr    =  (void *) SQL_OV_ODBC3;
#else /* PASE */
      long attr = SQL_TRUE;
      handleAttr_args->attribute   =  SQL_ATTR_SERVER_MODE;
      handleAttr_args->valuePtr    =  &attr;
#endif /* PASE */
      rc = _ruby_ibm_db_SQLSetEnvAttr_helper( handleAttr_args );

      if (rc != SQL_SUCCESS) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->henv, SQL_HANDLE_ENV, rc, 1, NULL, NULL, -1, 1, 0 );
        if( conn_res != NULL && conn_res->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Setting of Environemnt Attribute during connection failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(conn_res->ruby_error_msg, conn_res->ruby_error_msg_len )
                   );
#else
          *error = rb_str_cat2(rb_str_new2("Setting of Environemnt Attribute during connection failed: "),conn_res->ruby_error_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Setting of Environemnt Attribute during connection failed: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Setting of Environemnt Attribute during connection failed: <error message could not be retrieved>");
#endif
        }
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        rc = SQLFreeHandle(SQL_HANDLE_ENV, conn_res->henv );
        _ruby_ibm_db_free_conn_struct( conn_res );
        return Qnil;
        break;
      }
    }
    if (! reused) {
      /* Alloc CONNECT Handle */
      rc = SQLAllocHandle( SQL_HANDLE_DBC, conn_res->henv, &(conn_res->hdbc) );
      if (rc != SQL_SUCCESS) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->henv, SQL_HANDLE_ENV, rc, 1, NULL, NULL, -1, 1, 0 );
        if( conn_res != NULL && conn_res->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Allocation of connection handle failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( conn_res->ruby_error_msg, conn_res->ruby_error_msg_len) );
#else
          *error = rb_str_cat2(rb_str_new2("Allocation of connection handle failed: "),conn_res->ruby_error_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Allocation of connection handle failed: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Allocation of connection handle failed: <error message could not be retrieved>");
#endif
        }
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        rc = SQLFreeHandle(SQL_HANDLE_ENV, conn_res->henv );
        _ruby_ibm_db_free_conn_struct( conn_res );
        return Qnil;
        break;
      }
    }
    handleAttr_args->handle      =  &(conn_res->hdbc);
    handleAttr_args->strLength   =  SQL_NTS;
    handleAttr_args->attribute   =  SQL_ATTR_AUTOCOMMIT;

    /* Set this after the connection handle has been allocated to avoid
    unnecessary network flows. Initialize the structure to default values */
#ifndef PASE
    conn_res->auto_commit     =  SQL_AUTOCOMMIT_ON;
    handleAttr_args->valuePtr =  (SQLPOINTER)(conn_res->auto_commit);

    rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
#else
    conn_res->auto_commit     =  SQL_AUTOCOMMIT_ON;
    handleAttr_args->valuePtr =  (SQLPOINTER)(&conn_res->auto_commit);

    rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
    if (!IBM_DB_G(i5_allow_commit)) {
      if (!rc) {
        SQLINTEGER nocommitpase      =  SQL_TXN_NO_COMMIT;

        handleAttr_args->valuePtr    =  (SQLPOINTER)&nocommitpase;
        handleAttr_args->strLength   =  SQL_NTS;
        handleAttr_args->attribute   =  SQL_ATTR_COMMIT;

        rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
      }
    }
#endif
    conn_res->c_bin_mode     =  IBM_DB_G(bin_mode);
    conn_res->c_case_mode    =  CASE_NATURAL;
    conn_res->c_cursor_type  =  SQL_SCROLL_FORWARD_ONLY;

    conn_res->error_recno_tracker    =  1;
    conn_res->errormsg_recno_tracker =  1;

    conn_res->ruby_error_msg         =  NULL;
    conn_res->ruby_error_state       =  NULL;

    conn_res->errorType              =  1;

    conn_res->transaction_active     =  0; /*No transaction is active*/
    /* Set Options */
    if ( !NIL_P(*options) ) {
      rc = _ruby_ibm_db_parse_options( *options, SQL_HANDLE_DBC, conn_res, error );
      if (rc != SQL_SUCCESS) {
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        rc = SQLFreeHandle(SQL_HANDLE_DBC, conn_res->hdbc );
        rc = SQLFreeHandle(SQL_HANDLE_ENV, conn_res->henv );
        _ruby_ibm_db_free_conn_struct( conn_res );
        return Qnil;
      }
    }
    if (! reused) {
      conn_args->hdbc = &(conn_res->hdbc);

      rc = _ruby_ibm_db_SQLConnect_helper( conn_args );
      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
        SQLFreeHandle( SQL_HANDLE_DBC, conn_res->hdbc );
        SQLFreeHandle( SQL_HANDLE_ENV, conn_res->henv );
        if( conn_res != NULL && conn_res->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Connection failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(conn_res->ruby_error_msg, conn_res->ruby_error_msg_len));
#else
          *error = rb_str_cat2(rb_str_new2("Connection failed: "),conn_res->ruby_error_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Connection failed: <error message could not be retrieved>");
#else	
          *error = rb_str_new2("Connection failed: <error message could not be retrieved>");
#endif
        }
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;		
        _ruby_ibm_db_free_conn_struct( conn_res );		
        return Qnil;
      }      
      /* Get the AUTOCOMMIT state from the CLI driver as cli driver could have changed autocommit status based on it's precedence  */
      get_handleAttr_args = ALLOC( get_handle_attr_args );
      memset(get_handleAttr_args,'\0',sizeof(struct _ibm_db_get_handle_attr_struct));
	  
      get_handleAttr_args->handle       =  &( conn_res->hdbc );
      get_handleAttr_args->attribute    =  SQL_ATTR_AUTOCOMMIT;
      get_handleAttr_args->valuePtr     =  (SQLPOINTER)(&conn_res->auto_commit);	  
      get_handleAttr_args->buff_length  =  0;
      get_handleAttr_args->out_length   =  NULL;	  
      rc = _ruby_ibm_db_SQLGetConnectAttr_helper( get_handleAttr_args );	  
      ruby_xfree( get_handleAttr_args );
      get_handleAttr_args = NULL;
      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
		rc = _ruby_ibm_db_SQLDisconnect_helper( &(conn_res->hdbc)  );        
        SQLFreeHandle( SQL_HANDLE_DBC, conn_res->hdbc );
        SQLFreeHandle( SQL_HANDLE_ENV, conn_res->henv );		
        if( conn_res != NULL && conn_res->ruby_error_msg != NULL ) {			
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Failed to retrieve autocommit status during connection: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(conn_res->ruby_error_msg, conn_res->ruby_error_msg_len));
#else
          *error = rb_str_cat2(rb_str_new2("Connection failed: "),conn_res->ruby_error_msg);
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Failed to retrieve autocommit status during connection: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Connection failed: <error message could not be retrieved>");
#endif
        }
        ruby_xfree( handleAttr_args );
        handleAttr_args = NULL;
        _ruby_ibm_db_free_conn_struct( conn_res );
        return Qnil;

      }
#ifdef CLI_DBC_SERVER_TYPE_DB2LUW
#ifdef SQL_ATTR_DECFLOAT_ROUNDING_MODE
                                                                                         
        /**
                    * Code for setting SQL_ATTR_DECFLOAT_ROUNDING_MODE
                    * for implementation of Decfloat Datatype
                    * */  
       _ruby_ibm_db_set_decfloat_rounding_mode_client( handleAttr_args, conn_res );

#endif
#endif
      /* Get the server name */
#ifdef UNICODE_SUPPORT_VERSION
      server = ALLOC_N(SQLWCHAR, 2048);
      memset(server, 0, sizeof(server));
      iserver   =  _ruby_ibm_db_export_char_to_utf16_rstr("AS");
      idsserver =  _ruby_ibm_db_export_char_to_utf16_rstr("IDS");
#else
      server = ALLOC_N(SQLCHAR, 2048);
      memset(server, 0, sizeof(server));
#endif
      getInfo_args = ALLOC( get_info_args );
      memset(getInfo_args,'\0',sizeof(struct _ibm_db_get_info_struct));
      getInfo_args->conn_res     =  conn_res;
      getInfo_args->out_length   =  &out_length;
      getInfo_args->infoType     =  SQL_DBMS_NAME;
      getInfo_args->infoValue    =  (SQLPOINTER)server;
	  
#ifdef UNICODE_SUPPORT_VERSION
      getInfo_args->buff_length  =  2048 * sizeof(SQLWCHAR);
#else
      getInfo_args->buff_length  =  2048;
#endif
      rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

#ifndef UNICODE_SUPPORT_VERSION
      if (!strcmp((char *)server, "AS")) {
        is_systemi = 1;
      }
      if (!strncmp((char *)server, "IDS", 3)) {
        is_informix = 1;
      }
#else
      server_utf16 = _ruby_ibm_db_export_sqlwchar_to_utf16_rstr(server, out_length);
      if (rb_str_equal(iserver, server_utf16)){
        is_systemi = 1;
      }
      if (rb_str_equal(rb_str_substr(server_utf16,0,3), idsserver)){
        is_informix = 1;
      }
#endif
      ruby_xfree( getInfo_args );
      ruby_xfree( server );
      getInfo_args = NULL;
      server       = NULL;
      rc = SQL_SUCCESS; /*Setting rc to SQL_SUCCESS, because the below block may or may not be executed*/

    /* Set SQL_ATTR_REPLACE_QUOTED_LITERALS connection attribute to
     * enable CLI numeric literal feature. This is equivalent to
     * PATCH2=71 in the db2cli.ini file
     * Note, for backward compatibility with older CLI drivers having a 
     * different value for SQL_ATTR_REPLACE_QUOTED_LITERALS, we call 
     * SQLSetConnectAttr() with both the old and new value
     */
#ifndef PASE
      /* Only enable this feature if we are not connected to an Informix data server */
      if (!is_informix && data->literal_replacement == SET_QUOTED_LITERAL_REPLACEMENT_ON ) {
        handleAttr_args->handle      =  &( conn_res->hdbc );
        handleAttr_args->strLength   =  SQL_IS_INTEGER;
        handleAttr_args->attribute   =  SQL_ATTR_REPLACE_QUOTED_LITERALS;
        handleAttr_args->valuePtr    =  (SQLPOINTER)(enable_numeric_literals);
        rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
        if (rc != SQL_SUCCESS) {
          handleAttr_args->attribute =  SQL_ATTR_REPLACE_QUOTED_LITERALS_OLDVALUE;
          rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
        }
      }
#else
      /* Only enable this feature if we are not connected to an Informix data server */
      if (!is_informix && data->literal_replacement == SET_QUOTED_LITERAL_REPLACEMENT_ON ) {
        handleAttr_args->handle      =  &( conn_res->hdbc );
        handleAttr_args->strLength   =  SQL_IS_INTEGER;
        handleAttr_args->attribute   =  SQL_ATTR_REPLACE_QUOTED_LITERALS;
        handleAttr_args->valuePtr    =  (SQLPOINTER)(&enable_numeric_literals);
        rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
        if (rc != SQL_SUCCESS) {
          handleAttr_args->attribute =  SQL_ATTR_REPLACE_QUOTED_LITERALS_OLDVALUE;
          rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
        }
      }
#endif
      if (rc != SQL_SUCCESS) {
          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
      }
    }
    conn_res->handle_active = 1;
  } while (0);
  if( handleAttr_args != NULL ) {
    ruby_xfree( handleAttr_args );
    handleAttr_args = NULL;
  }
  if (data->hKey != Qnil) 
  {
	  //data->conn_res = conn_res;	  
	if (! reused && rc == SQL_SUCCESS) 
	{
      /* If we created a new persistent connection, add it to the persistent_list */
      entry = Data_Wrap_Struct(le_pconn_struct,
                _ruby_ibm_db_mark_pconn_struct, _ruby_ibm_db_free_pconn_struct,				
                conn_res);
	  //data->entry = entry;
      rb_hash_aset(persistent_list, data->hKey, entry);
    }
	data->entry = entry;
  }
  if ( rc < SQL_SUCCESS ) {
    if (conn_res != NULL && conn_res->handle_active) {
      rc = SQLFreeHandle( SQL_HANDLE_DBC, conn_res->hdbc);
      rc = SQLFreeHandle(SQL_HANDLE_ENV, conn_res->henv );
    }
    /* free memory */
    if (conn_res != NULL) {
      conn_res->handle_active = 0;
      _ruby_ibm_db_free_conn_struct(conn_res);
    }
    return Qfalse;
  } else if (!NIL_P(entry)) {
	  //data->conn_res = conn_res; 
      return entry;	
  } else if (isPersistent) {
	  //data->conn_res = conn_res;
      entry = Data_Wrap_Struct(le_pconn_struct,
            _ruby_ibm_db_mark_pconn_struct, _ruby_ibm_db_free_pconn_struct,
            conn_res);
	   data->entry = entry;
  } else {
		data->conn_res = conn_res;		
		/* return Data_Wrap_Struct(le_conn_struct,
_ruby_ibm_db_mark_conn_struct, _ruby_ibm_db_free_conn_struct,
conn_res);
		*/
  }
  
}

/*  */

/*  static int _ruby_ibm_db_connect_helper( argc, argv, isPersistent )
*/
static VALUE _ruby_ibm_db_connect_helper( int argc, VALUE *argv, int isPersistent )
{
  connect_args        *conn_args    =  NULL;
  connect_helper_args *helper_args  =  NULL;
  conn_handle *conn_res = NULL;
  
  VALUE r_db, r_uid, r_passwd, options,return_value;
  VALUE r_literal_replacement = Qnil;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_db_utf16, r_uid_utf16, r_passwd_utf16, r_db_ascii;
#endif

  VALUE error = Qnil;
     
  
  rb_scan_args(argc, argv, "32", &r_db, &r_uid, &r_passwd, &options, &r_literal_replacement );

  /* Allocate the mwmory for necessary components */

  conn_args = ALLOC( connect_args );
  memset(conn_args,'\0',sizeof(struct _ibm_db_connect_args_struct));
  
#ifndef UNICODE_SUPPORT_VERSION
  conn_args->database      =  (SQLCHAR *)   RSTRING_PTR( r_db );
  conn_args->database_len  =  (SQLSMALLINT) RSTRING_LEN( r_db );

  conn_args->uid           =  (SQLCHAR *)   RSTRING_PTR( r_uid );
  conn_args->uid_len       =  (SQLSMALLINT) RSTRING_LEN( r_uid );
  
  conn_args->password      =  (SQLCHAR *)   RSTRING_PTR( r_passwd );
  conn_args->password_len  =  (SQLSMALLINT) RSTRING_LEN( r_passwd );
  
#else
  r_db_utf16               =  _ruby_ibm_db_export_str_to_utf16( r_db );
  r_db_ascii               =  _ruby_ibm_db_export_str_to_ascii( r_db );
  r_uid_utf16              =  _ruby_ibm_db_export_str_to_utf16( r_uid );
  r_passwd_utf16           =  _ruby_ibm_db_export_str_to_utf16( r_passwd );
  
  conn_args->database      =  (SQLWCHAR *)  RSTRING_PTR( r_db_utf16 );
  conn_args->database_len  =  (SQLSMALLINT) RSTRING_LEN( r_db_utf16 )/sizeof(SQLWCHAR);
  /*RSTRING returns the number of bytes, while CLI expects number of SQLWCHAR(2 bytes) elements, hence dividing the len by 2*/

  conn_args->uid           =  (SQLWCHAR *)  RSTRING_PTR( r_uid_utf16 );
  conn_args->uid_len       =  (SQLSMALLINT) RSTRING_LEN( r_uid_utf16 )/sizeof(SQLWCHAR);  
  conn_args->password      =  (SQLWCHAR *)  RSTRING_PTR( r_passwd_utf16 );
  conn_args->password_len  =  (SQLSMALLINT) RSTRING_LEN( r_passwd_utf16 )/sizeof(SQLWCHAR);
#endif

  /* If the string contains a =, set ctlg_conn = 0, to use SQLDriverConnect */
#ifndef UNICODE_SUPPORT_VERSION
  if ( strstr( (char *) conn_args->database, "=") != NULL ) {
#else
  if ( RARRAY_LEN(rb_str_split(r_db_ascii,"=")) > 1) { /*There is no direct API like strstr, hence split string with delimiter as '=' if the returned RARRAY has more than 1 element then set ctlg_conn = 0*/
#endif
    conn_args->ctlg_conn = 0;
  } else {
    conn_args->ctlg_conn = 1;
  }
  

  helper_args = ALLOC( connect_helper_args );  
  memset(helper_args,'\0',sizeof(struct _ibm_db_connect_helper_args_struct));
   

  helper_args->conn_args              =  conn_args;
  helper_args->isPersistent           =  isPersistent;
  helper_args->options                =  &options;
  helper_args->error                  =  &error;
  
  if( isPersistent ) { 
  /*If making a persistent connection calculate the hash key to cache the connection in persistence list*/
#ifndef UNICODE_SUPPORT_VERSION
    helper_args->hKey = rb_str_concat(rb_str_dup(r_uid), r_db); /*A duplicate of r_uid is made so that initial value is intact*/
    helper_args->hKey = rb_str_concat(helper_args->hKey, r_passwd);
    helper_args->hKey = rb_str_concat(rb_str_new2("__ibm_db_"),helper_args->hKey);
#else
    helper_args->hKey = rb_str_concat(rb_str_dup(r_uid_utf16), r_db_utf16);/*A duplicate of r_uid is made so that initial value is intact*/
    helper_args->hKey = rb_str_concat(helper_args->hKey, r_passwd_utf16);
    helper_args->hKey = rb_str_concat(_ruby_ibm_db_export_char_to_utf16_rstr("__ibm_db_"),helper_args->hKey);
#endif
  } else {
    helper_args->hKey = Qnil;
  }
  if( !NIL_P(r_literal_replacement) ) {
    helper_args->literal_replacement  =  NUM2INT(r_literal_replacement);
  } else {
    helper_args->literal_replacement  =  SET_QUOTED_LITERAL_REPLACEMENT_ON; /*QUOTED LITERAL replacemnt is ON by default*/
  }
  /* Call the function where the actual logic is being run*/
  #ifdef UNICODE_SUPPORT_VERSION
	
	ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_connect_helper2, helper_args, (void *)_ruby_ibm_db_Connection_level_UBF, NULL);	
	
				
    conn_res = helper_args->conn_res;
	
	if(helper_args->isPersistent)
	{
		if(helper_args-> entry == NULL)
		{
			return_value = Qnil;
		}
		else
		{
			return_value = helper_args->entry;
		}
	}
	else
	{
		if( conn_res == NULL )
		{
			return_value = Qnil;
		}
		else
		{
			return_value = Data_Wrap_Struct(le_conn_struct, _ruby_ibm_db_mark_conn_struct, _ruby_ibm_db_free_conn_struct, conn_res);
		}		
	}			 
  #else
    return_value = _ruby_ibm_db_connect_helper2( helper_args );
  #endif
  /* Free the memory allocated */
  if(conn_args != NULL) {
    /* Memory to structure elements of helper_args is not allocated explicitly hence it is automatically freed by Ruby.
       Dont try to explicitly free it, else a double free exception is thrown and the application will crash
       with memory dump.
    */
    helper_args->conn_args = NULL;	
    ruby_xfree( conn_args );	
    conn_args = NULL;		
  }
  if ( helper_args != NULL ) {
    ruby_xfree( helper_args );	
    helper_args = NULL;	
  }
  if( return_value == Qnil ){
    rb_throw( RSTRING_PTR(error), Qnil );	
  }  
  return return_value;
}




/*Check for feasibility of moving to other file*/
typedef struct _rounding_mode_struct {
  stmt_handle  *stmt_res;
  int          rounding_mode;
} _rounding_mode;
/*
   Helper Function for setting the decfloat rounding mode on client
*/
static int _ruby_ibm_db_set_decfloat_rounding_mode_client_helper(_rounding_mode *rnd_mode, conn_handle *conn_res ) {
  int rc = 0;
  SQLCHAR decflt_rounding[20];

  exec_cum_prepare_args *exec_direct_args  =  NULL;
  bind_col_args         *bindCol_args      =  NULL;
  fetch_data_args       *fetch_args        =  NULL;
#ifndef UNICODE_SUPPORT_VERSION
  SQLCHAR *stmt = (SQLCHAR *)"values current decfloat rounding mode";
#else
  VALUE stmt  =  Qnil;
        stmt  =  _ruby_ibm_db_export_char_to_utf16_rstr("values current decfloat rounding mode");
#endif

  exec_direct_args = ALLOC( exec_cum_prepare_args );
  memset(exec_direct_args,'\0',sizeof(struct _ibm_db_exec_direct_args_struct));

#ifdef UNICODE_SUPPORT_VERSION
  exec_direct_args->stmt_string       =  (SQLWCHAR *)RSTRING_PTR( stmt );
#else
  exec_direct_args->stmt_string       =  stmt;
#endif
  exec_direct_args->stmt_string_len   =  SQL_NTS;
  exec_direct_args->stmt_res          =  rnd_mode->stmt_res;

  rc = _ruby_ibm_db_SQLExecDirect_helper( exec_direct_args );

  if ( rc == SQL_ERROR ) {
    if( conn_res->ruby_error_msg == NULL){
      conn_res->ruby_error_msg = ALLOC_N( char, DB2_MAX_ERR_MSG_LEN+1 );
    }
    memset(conn_res->ruby_error_msg, '\0', DB2_MAX_ERR_MSG_LEN+1 );

    _ruby_ibm_db_check_sql_errors( conn_res , DB_CONN, (SQLHSTMT) rnd_mode->stmt_res->hstmt,
             SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
  } else {

    bindCol_args = ALLOC( bind_col_args );
    memset(bindCol_args,'\0',sizeof(struct _ibm_db_bind_col_struct));

    bindCol_args->stmt_res        =  rnd_mode->stmt_res;
    bindCol_args->col_num         =  1;
    bindCol_args->TargetType      =  SQL_C_DEFAULT;
    bindCol_args->buff_length     =  20;
    bindCol_args->TargetValuePtr  =  decflt_rounding;
    bindCol_args->out_length      =  NULL;

    rc = _ruby_ibm_db_SQLBindCol_helper( bindCol_args );

    if ( rc == SQL_ERROR ) {
      if( conn_res->ruby_error_msg == NULL){
        conn_res->ruby_error_msg = ALLOC_N( char, DB2_MAX_ERR_MSG_LEN+1 );
      }
      memset(conn_res->ruby_error_msg, '\0', DB2_MAX_ERR_MSG_LEN+1 );

      _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, (SQLHSTMT)rnd_mode->stmt_res->hstmt,
               SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0);

    } else {

      fetch_args = ALLOC( fetch_data_args );
      memset(fetch_args,'\0',sizeof(struct _ibm_db_fetch_data_struct));

      fetch_args->stmt_res = rnd_mode->stmt_res;

      rc  = _ruby_ibm_db_SQLFetch_helper( fetch_args );

      if ( rc == SQL_ERROR ) {
        if( conn_res->ruby_error_msg == NULL){
          conn_res->ruby_error_msg = ALLOC_N( char, DB2_MAX_ERR_MSG_LEN+1 );
        }
        memset(conn_res->ruby_error_msg, '\0', DB2_MAX_ERR_MSG_LEN+1 );

        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, (SQLHSTMT) rnd_mode->stmt_res->hstmt,
                  SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );

      } else {
        /* Now setting up the same rounding mode on the client*/
        if(strcmp((char *)decflt_rounding,"ROUND_HALF_EVEN")== 0)   rnd_mode->rounding_mode = ROUND_HALF_EVEN;
        if(strcmp((char *)decflt_rounding,"ROUND_HALF_UP")  == 0)   rnd_mode->rounding_mode = ROUND_HALF_UP;
        if(strcmp((char *)decflt_rounding,"ROUND_DOWN")     == 0)   rnd_mode->rounding_mode = ROUND_DOWN;
        if(strcmp((char *)decflt_rounding,"ROUND_CEILING")  == 0)   rnd_mode->rounding_mode = ROUND_CEILING;
        if(strcmp((char *)decflt_rounding,"ROUND_FLOOR")    == 0)   rnd_mode->rounding_mode = ROUND_FLOOR;
      }
    }
  }

  /*Free memory Allocated*/
  if ( exec_direct_args != NULL ) {
    ruby_xfree( exec_direct_args );
    exec_direct_args = NULL;
  }
  if ( bindCol_args != NULL ) {
    ruby_xfree( bindCol_args );
    bindCol_args = NULL;
  }
  if ( fetch_args != NULL ) {
    ruby_xfree( fetch_args );
    fetch_args = NULL;
  }
  return rc;
}
#ifdef CLI_DBC_SERVER_TYPE_DB2LUW
#ifdef SQL_ATTR_DECFLOAT_ROUNDING_MODE
/**
 * Function for implementation of DECFLOAT Datatype
 * 
 * Description :
 * This function retrieves the value of special register decflt_rounding
 * from the database server which signifies the current rounding mode set
 * on the server. For using decfloat, the rounding mode has to be in sync
 * on the client as well as server. Thus we set here on the client, the
 * same rounding mode as the server.
 * @return: success or failure
 * */
static int _ruby_ibm_db_set_decfloat_rounding_mode_client( set_handle_attr_args *data, conn_handle *conn_res )
{
    int rc = 0;
    _rounding_mode *rnd_mode;

    SQLHANDLE hdbc = *(data->handle);
    
    rnd_mode =  ALLOC( _rounding_mode );
    memset(rnd_mode,'\0',sizeof(struct _rounding_mode_struct));

    stmt_res = _ibm_db_new_stmt_struct(conn_res);

    /* Allocate a Statement Handle */
    rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &(stmt_res->hstmt));

    if (rc == SQL_ERROR) {
      _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, hdbc, SQL_HANDLE_DBC, rc, 1,
                NULL, NULL, -1, 1, 0 );
      ruby_xfree( rnd_mode );
      ruby_xfree( stmt_res );
      rnd_mode = NULL;
      stmt_res = NULL;
      return rc;
    }

    rnd_mode->stmt_res = stmt_res;

    _ruby_ibm_db_set_decfloat_rounding_mode_client_helper(rnd_mode, conn_res);
	
    _ruby_ibm_db_free_stmt_struct( rnd_mode->stmt_res );
    rnd_mode->stmt_res = NULL;
    stmt_res           = NULL;

    data->strLength   =  SQL_NTS;
    data->attribute   =  SQL_ATTR_DECFLOAT_ROUNDING_MODE;

#ifndef PASE
    data->valuePtr    =  (SQLPOINTER)rnd_mode->rounding_mode;
#else
    data->valuePtr    =  (SQLPOINTER)&(rnd_mode->rounding_mode);
#endif

    rc  =  _ruby_ibm_db_SQLSetConnectAttr_helper( data );

    ruby_xfree( rnd_mode );
    rnd_mode = NULL;

    return rc;
}
#endif
#endif

/*  */

/*  static void _ruby_ibm_db_clear_conn_err_cache ()
*/
static void _ruby_ibm_db_clear_conn_err_cache()
{
  /* Clear out the cached conn messages */
  memset(IBM_DB_G(__ruby_conn_err_msg), '\0', DB2_MAX_ERR_MSG_LEN);
  memset(IBM_DB_G(__ruby_conn_err_state), '\0', SQL_SQLSTATE_SIZE + 1);
}
/*  */

/* IBM_DB.connect --  Returns a connection to a database
 *
 * ===Description
 *
 * resource IBM_DB.connect ( string database, string username, string password [, array options, int set_replace_quoted_literal] )
 *
 * Creates a new connection to an IBM DB2 Universal Database, IBM Cloudscape, or Apache Derby database.
 * ==Parameters
 *
 * ====<em>database</em>
 *    For a cataloged connection to a database, database represents the database alias in the DB2 client catalog.
 *    For an uncataloged connection to a database, database represents a complete connection string in the following format:
 *    DRIVER={IBM DB2 ODBC DRIVER};DATABASE=database;HOSTNAME=hostname;PORT=port;PROTOCOL=TCPIP;UID=username;PWD=password;
 *    where the parameters represent the following values:
 *       hostname
 *          The hostname or IP address of the database server. 
 *       port
 *          The TCP/IP port on which the database is listening for requests. 
 *       username
 *          The username with which you are connecting to the database. 
 *       password
 *          The password with which you are connecting to the database. 
 *
 * ====<em>username</em>
 *    The username with which you are connecting to the database.
 *    For uncataloged connections, you must pass a NULL value or empty string. 
 * ====<em>password</em>
 *    The password with which you are connecting to the database.
 *    For uncataloged connections, you must pass a NULL value or empty string. 
 * ====<em>options</em>
 *    An associative array of connection options that affect the behavior of the connection,
 *    where valid array keys include:
 *       SQL_ATTR_AUTOCOMMIT
 *          Passing the SQL_AUTOCOMMIT_ON value turns autocommit on for this connection handle.
 *          Passing the SQL_AUTOCOMMIT_OFF value turns autocommit off for this connection handle. 
 *       ATTR_CASE
 *          Passing the CASE_NATURAL value specifies that column names are returned in natural case.
 *          Passing the CASE_LOWER value specifies that column names are returned in lower case.
 *          Passing the CASE_UPPER value specifies that column names are returned in upper case. 
 *       CURSOR
 *          Passing the SQL_SCROLL_FORWARD_ONLY value specifies a forward-only cursor for a statement resource.
 *          This is the default cursor type and is supported on all database servers.
 *          Passing the SQL_CURSOR_KEYSET_DRIVEN value specifies a scrollable cursor for a statement resource.
 *          This mode enables random access to rows in a result set, but currently is supported
 *          only by IBM DB2 Universal Database. 
 * ====<em>set_replace_quoted_literal</em>
 *    This variable indicates if the CLI Connection attribute SQL_ATTR_REPLACE_QUOTED_LITERAL is to be set or not
 *    To turn it ON pass  IBM_DB::QUOTED_LITERAL_REPLACEMENT_ON
 *    To turn it OFF pass IBM_DB::QUOTED_LITERAL_REPLACEMENT_OFF
 *
 *    Default Setting: - IBM_DB::SET_QUOTED_LITERAL_REPLACEMENT_ON
 *
 * ==Return Values
 * Returns a connection handle resource if the connection attempt is successful.
 * If the connection attempt fails an exception is thrown with the connection error message. 
 * 
 */
VALUE ibm_db_connect(int argc, VALUE *argv, VALUE self)
{
	
  _ruby_ibm_db_clear_conn_err_cache();

  return _ruby_ibm_db_connect_helper( argc, argv, 0 );
}
/*  */

/*
 * IBM_DB.pconnect --  Returns a persistent connection to a database
 * 
 * ===Description
 * resource IBM_DB.pconnect ( string database, string username, string password [, array options, int set_replace_quoted_literal] )
 * 
 * Returns a persistent connection to an IBM DB2 Universal Database, IBM Cloudscape,
 * or Apache Derby database.
 * 
 * Calling IBM_DB.close() on a persistent connection always returns TRUE, but the underlying DB2 client
 * connection remains open and waiting to serve the next matching IBM_DB.pconnect() request.
 * 
 * ===Parameters
 * 
 * database
 *     The database alias in the DB2 client catalog. 
 * 
 * username
 *     The username with which you are connecting to the database. 
 * 
 * password
 *     The password with which you are connecting to the database. 
 * 
 * options
 *     An associative array of connection options that affect the behavior of the connection,
 *     where valid array keys include:
 * 
 *     autocommit
 *         Passing the DB2_AUTOCOMMIT_ON value turns autocommit on for this connection handle.
 *         Passing the DB2_AUTOCOMMIT_OFF value turns autocommit off for this connection handle. 
 * 
 *     DB2_ATTR_CASE
 *         Passing the DB2_CASE_NATURAL value specifies that column names are returned in natural case.
 *         Passing the DB2_CASE_LOWER value specifies that column names are returned in lower case.
 *         Passing the DB2_CASE_UPPER value specifies that column names are returned in upper case. 
 * 
 *     CURSOR
 *         Passing the SQL_SCROLL_FORWARD_ONLY value specifies a forward-only cursor for a statement resource.
 *         This is the default cursor type and is supported on all database servers.
 *         Passing the SQL_CURSOR_KEYSET_DRIVEN value specifies a scrollable cursor for a statement resource.
 *         This mode enables random access to rows in a result set, but currently is supported only
 *         by IBM DB2 Universal Database. 
 * ====<em>set_replace_quoted_literal</em>
 *    This variable indicates if the CLI Connection attribute SQL_ATTR_REPLACE_QUOTED_LITERAL is to be set or not
 *    To turn it ON pass  IBM_DB::SET_QUOTED_LITERAL_REPLACEMENT_ON
 *    To turn it OFF pass IBM_DB::SET_QUOTED_LITERAL_REPLACEMENT_OFF
 *
 *    Default Setting: - IBM_DB::SET_QUOTED_LITERAL_REPLACEMENT_ON
 * 
 * ===Return Values
 * 
 * Returns a connection handle resource if the connection attempt is successful. IBM_DB.pconnect()
 * tries to reuse an existing connection resource that exactly matches the database, username,
 * and password parameters. If the connection attempt fails, an exception is thrown with the connection error message. 
 */
VALUE ibm_db_pconnect(int argc, VALUE *argv, VALUE self)
{
  _ruby_ibm_db_clear_conn_err_cache();
  return _ruby_ibm_db_connect_helper( argc, argv, 1);
  
}
/*
 * CreateDB helper
 */
VALUE ruby_ibm_db_createDb_helper(VALUE connection, VALUE dbName, VALUE codeSet, VALUE mode, int createNX) {

  
  VALUE return_value    =  Qfalse;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE dbName_utf16    = Qnil;
  VALUE codeSet_utf16   = Qnil;
  VALUE mode_utf16      = Qnil;
#endif

  int rc;

  create_drop_db_args *create_db_args = NULL;
  conn_handle *conn_res;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);
		
	if( 0 == createDbSupported ) {
      rb_warn("Create Database not supported: This function is only supported from DB2 Client v97fp4 version and onwards");
	  return Qfalse;
    }
	
    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }

	if (!NIL_P(dbName)) {
      create_db_args = ALLOC( create_drop_db_args );
	  memset(create_db_args,'\0',sizeof(struct _ibm_db_create_drop_db_args_struct));

#ifdef UNICODE_SUPPORT_VERSION
      dbName_utf16               =  _ruby_ibm_db_export_str_to_utf16(dbName);

	  create_db_args->dbName     =  (SQLWCHAR*)RSTRING_PTR(dbName_utf16);
      create_db_args->dbName_string_len =  RSTRING_LEN(dbName_utf16)/sizeof(SQLWCHAR); /*RSTRING_LEN returns number of bytes*/

	  if(!NIL_P(codeSet)){
        codeSet_utf16            =  _ruby_ibm_db_export_str_to_utf16(codeSet); 
        create_db_args->codeSet  =  (SQLWCHAR*)RSTRING_PTR(codeSet_utf16);
        create_db_args->codeSet_string_len =  RSTRING_LEN(codeSet_utf16)/sizeof(SQLWCHAR); /*RSTRING_LEN returns number of bytes*/
	  } else {
        create_db_args->codeSet  =  NULL;
	  }

	  if(!NIL_P(mode)) {
	    mode_utf16               =  _ruby_ibm_db_export_str_to_utf16(mode);
		create_db_args->mode     =  (SQLWCHAR*)RSTRING_PTR(mode_utf16);
        create_db_args->mode_string_len =  RSTRING_LEN(mode_utf16)/sizeof(SQLWCHAR); /*RSTRING_LEN returns number of bytes*/
	  } else {
        create_db_args->mode     =  NULL;
	  }
#else
      create_db_args->dbName     = (SQLCHAR*)rb_str2cstr(dbName, &(create_db_args->dbName_string_len));
	  if(!NIL_P(codeSet)){
        create_db_args->codeSet  = (SQLCHAR*)rb_str2cstr(codeSet, &(create_db_args->codeSet_string_len));
	  } else {
        create_db_args->codeSet  = NULL;
	  }
	  if(!NIL_P(mode)) {
        create_db_args->mode     = (SQLCHAR*)rb_str2cstr(mode, &(create_db_args->mode_string_len));
	  } else {
        create_db_args->mode     = NULL;
	  }
#endif
	} else {
		rb_warn("Invalid Parameter: Database Name cannot be nil");
		return Qfalse;
	}

	create_db_args->conn_res = conn_res;

	_ruby_ibm_db_clear_conn_err_cache();

#ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLCreateDB_helper, create_db_args,
                       (void *)_ruby_ibm_db_Connection_level_UBF, NULL );
		rc = create_db_args->rc;
#else
        rc = _ruby_ibm_db_SQLCreateDB_helper( create_db_args );
#endif

      if ( rc == SQL_ERROR ) {
        conn_res->error_recno_tracker    =  1;
        conn_res->errormsg_recno_tracker =  1;
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
		if(conn_res->sqlcode == -1005 && 1 == createNX) {
          return_value = Qtrue; /*Return true if database already exists and Create if not existing called*/
		  /*Clear the error messages*/
#ifdef UNICODE_SUPPORT_VERSION
          memset( conn_res->ruby_error_state, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
          memset( conn_res->ruby_error_msg, '\0', (DB2_MAX_ERR_MSG_LEN + 1) * sizeof(SQLWCHAR) );
#else
          memset( conn_res->ruby_error_state, '\0', SQL_SQLSTATE_SIZE + 1 );
          memset( conn_res->ruby_error_msg, '\0', DB2_MAX_ERR_MSG_LEN + 1 );
#endif
		} else {
          return_value = Qfalse;
		}
      } else {
        return_value = Qtrue;
      }
  }

  /*Free memory allocated*/
  if( create_db_args != NULL ) {
    ruby_xfree( create_db_args );
    create_db_args = NULL;
  }

  return return_value;  
}
/*  */
/*
 * IBM_DB.createDB -- Creates a Database
 *
 * ===Description
 * bool IBM_DB.createDB ( resource connection , string dbName [, String codeSet, String mode] )
 *
 * Creates a database with the specified name. Returns true if operation successful else false
 *
 * ===Parameters
 * 
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect() with parameter ATTACH=true specified.
 *     IBM_DB.connect('DRIVER={IBM DB2 ODBC DRIVER};ATTACH=true;HOSTNAME=myhost;PORT=1234;PROTOCOL=TCPIP;UID=user;PWD=secret;','','')
 *     Note: Database is not specified. In this case we connect to the instance only.
 *
 * dbName
 *     Name of the database that is to be created.
 *
 * codeSet
 *      Database code set information.
 *      Note: If the value of the codeSet argument is not specified, 
 *      the database is created in the Unicode code page for DB2 data servers and in the UTF-8 code page for IDS data servers
 *
 * mode
 *      Database logging mode.
 *      Note: This value is applicable only to IDS data servers
 *
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_createDB(int argc, VALUE *argv, VALUE self)
{
  VALUE connection   = Qnil;
  VALUE dbName       = Qnil;
  VALUE codeSet      = Qnil;
  VALUE mode         = Qnil;

  rb_scan_args(argc, argv, "22", &connection, &dbName, &codeSet, &mode);

  return ruby_ibm_db_createDb_helper(connection, dbName, codeSet, mode, 0);  
}
/*
 *  DropDb helper
 */
VALUE ruby_ibm_db_dropDb_helper(VALUE connection, VALUE dbName) {
#ifdef UNICODE_SUPPORT_VERSION
  VALUE dbName_utf16    = Qnil;
#endif

  VALUE return_value =  Qfalse;

  int rc;

  create_drop_db_args *drop_db_args = NULL;
  conn_handle         *conn_res     = NULL;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

	if( 0 == dropDbSupported ) {
      rb_warn("Drop Database not supported: This function is only supported from DB2 Client v97fp4 version and onwards");
	  return Qfalse;
    }
	
    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }

	if (!NIL_P(dbName)) {
      drop_db_args = ALLOC( create_drop_db_args );
	  memset(drop_db_args,'\0',sizeof(struct _ibm_db_create_drop_db_args_struct));

#ifdef UNICODE_SUPPORT_VERSION
      dbName_utf16             =  _ruby_ibm_db_export_str_to_utf16(dbName);

	  drop_db_args->dbName     =  (SQLWCHAR*)RSTRING_PTR(dbName_utf16);
      drop_db_args->dbName_string_len =  RSTRING_LEN(dbName_utf16)/sizeof(SQLWCHAR); /*RSTRING_LEN returns number of bytes*/
#else
      drop_db_args->dbName     =  (SQLCHAR*)rb_str2cstr(dbName, &(drop_db_args->dbName_string_len));
#endif
	} else {
		rb_warn("Invalid Parameter: Database Name cannot be nil");
		return Qfalse;
	}

	drop_db_args->conn_res = conn_res;

	_ruby_ibm_db_clear_conn_err_cache();

#ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLDropDB_helper, drop_db_args,
                       (void *)_ruby_ibm_db_Connection_level_UBF, NULL );
		rc = drop_db_args->rc;
#else
        rc = _ruby_ibm_db_SQLDropDB_helper( drop_db_args );
#endif

      if ( rc == SQL_ERROR ) {
        conn_res->error_recno_tracker    =  1;
        conn_res->errormsg_recno_tracker =  1;
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
        return_value = Qfalse;
      } else {
        return_value = Qtrue;
      }
  }

  /*Free memory allocated*/
  if( drop_db_args != NULL ) {
    ruby_xfree( drop_db_args );
    drop_db_args = NULL;
  }

  return return_value;  
}
/*  */
/*
 * IBM_DB.dropDB -- Drops the mentioned Database
 *
 * ===Description
 * bool IBM_DB.dropDB ( resource connection , string dbName [, String codeSet, String mode] )
 *
 * Drops a database with the specified name. Returns true if operation successful else false
 *
 * ===Parameters
 * 
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect() with parameter ATTACH=true specified.
 *     IBM_DB.connect('DRIVER={IBM DB2 ODBC DRIVER};ATTACH=true;HOSTNAME=myhost;PORT=1234;PROTOCOL=TCPIP;UID=user;PWD=secret;','','')
 *     Note: Database is not specified. In this case we connect to the instance only.
 * dbName
 *     Name of the database that is to be created.
 *
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_dropDB(int argc, VALUE *argv, VALUE self)
{
  VALUE connection      = Qnil;
  VALUE dbName          = Qnil;

  rb_scan_args(argc, argv, "2", &connection, &dbName);

  return ruby_ibm_db_dropDb_helper(connection, dbName);
}
/*  */
/*
 * IBM_DB.recreateDB -- Recreates an Existing database
 *
 * ===Description
 * bool IBM_DB.recreateDB ( resource connection , string dbName [, String codeSet, String mode] )
 *
 * Recreates a database with the specified name. This method will drop an existing database and then re-create it.
 * If database doesnot exist the method will return false.
 * Returns true if operation successful else false
 *
 * ===Parameters
 * 
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect() with parameter ATTACH=true specified.
 *     IBM_DB.connect('DRIVER={IBM DB2 ODBC DRIVER};ATTACH=true;HOSTNAME=myhost;PORT=1234;PROTOCOL=TCPIP;UID=user;PWD=secret;','','')
 *     Note: Database is not specified. In this case we connect to the instance only.
 *
 * dbName
 *     Name of the database that is to be created.
 *
 * codeSet
 *      Database code set information.
 *      Note: If the value of the codeSet argument is not specified, 
 *      the database is created in the Unicode code page for DB2 data servers and in the UTF-8 code page for IDS data servers
 *
 * mode
 *      Database logging mode.
 *      Note: This value is applicable only to IDS data servers
 *
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 */
/*VALUE ibm_db_recreateDB(int argc, VALUE *argv, VALUE self)
{
  VALUE connection   = Qnil;
  VALUE dbName       = Qnil;
  VALUE codeSet      = Qnil;
  VALUE mode         = Qnil;
  VALUE return_value = Qnil;

  rb_scan_args(argc, argv, "22", &connection, &dbName, &codeSet, &mode);

  return_value = ruby_ibm_db_dropDb_helper(connection, dbName);

  if(return_value == Qfalse) {
    return Qfalse;
  }

  return ruby_ibm_db_createDb_helper(connection, dbName, codeSet, mode);  
}*/
/*  */
/*
 * IBM_DB.createDBNX -- creates a database if it does not exist aleady
 *
 * ===Description
 * bool IBM_DB.createDBNX ( resource connection , string dbName [, String codeSet, String mode] )
 *
 * Creates a database with the specified name, if it does not exist already. This method will drop an existing database and then re-create it.
 * If database doesnot exist the method will return false.
 * Returns true if operation successful else false
 *
 * ===Parameters
 * 
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect() with parameter ATTACH=true specified.
 *     IBM_DB.connect('DRIVER={IBM DB2 ODBC DRIVER};ATTACH=true;HOSTNAME=myhost;PORT=1234;PROTOCOL=TCPIP;UID=user;PWD=secret;','','')
 *     Note: Database is not specified. In this case we connect to the instance only.
 *
 * dbName
 *     Name of the database that is to be created.
 *
 * codeSet
 *      Database code set information.
 *      Note: If the value of the codeSet argument is not specified, 
 *      the database is created in the Unicode code page for DB2 data servers and in the UTF-8 code page for IDS data servers
 *
 * mode
 *      Database logging mode.
 *      Note: This value is applicable only to IDS data servers
 *
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_createDBNX(int argc, VALUE *argv, VALUE self)
{
  VALUE connection   = Qnil;
  VALUE dbName       = Qnil;
  VALUE codeSet      = Qnil;
  VALUE mode         = Qnil;
  VALUE return_value = Qnil;

  rb_scan_args(argc, argv, "22", &connection, &dbName, &codeSet, &mode);

  return ruby_ibm_db_createDb_helper(connection, dbName, codeSet, mode, 1);  
}
/*  */

/*
 * IBM_DB.autocommit --  Returns or sets the AUTOCOMMIT state for a database connection
 *
 * ===Description
 * mixed IBM_DB.autocommit ( resource connection [, bool value] )
 *
 * Returns or sets the AUTOCOMMIT behavior of the specified connection resource.
 *
 * ===Parameters
 *
 * connection
 *   A valid database connection resource variable as returned from connect() or pconnect().
 *
 * value
 *   One of the following constants:
 *   SQL_AUTOCOMMIT_OFF
 *       Turns AUTOCOMMIT off. 
 *   SQL_AUTOCOMMIT_ON
 *       Turns AUTOCOMMIT on. 
 *
 * ===Return Values
 *
 * When IBM_DB.autocommit() receives only the connection parameter, it returns the current state
 * of AUTOCOMMIT for the requested connection as an integer value.
 * A value of 0 indicates that AUTOCOMMIT is off, while a value of 1 indicates that AUTOCOMMIT is on.
 *
 * When IBM_DB.autocommit() receives both the connection parameter and autocommit parameter, 
 * it attempts to set the AUTOCOMMIT state of the requested connection to the corresponding state.
 *
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_autocommit(int argc, VALUE *argv, VALUE self)
{
  VALUE value;
  VALUE connection = Qnil;
  VALUE ret_val    = Qnil;

  conn_handle *conn_res;
  int rc;

  SQLINTEGER autocommit;

  set_handle_attr_args *handleAttr_args = NULL;

  rb_scan_args(argc, argv, "11", &connection, &value);

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);
		
    if (!conn_res || !conn_res->handle_active) {		
      rb_warn("Connection is not active");
      return Qfalse;
    }
    /* If value in handle is different from value passed in */
    if (argc == 2) {
      autocommit = FIX2INT(value);
      if(autocommit != (conn_res->auto_commit)) {
        handleAttr_args = ALLOC( set_handle_attr_args );
        memset(handleAttr_args,'\0',sizeof(struct _ibm_db_set_handle_attr_struct));

        handleAttr_args->handle      =  &( conn_res->hdbc );
        handleAttr_args->strLength   =  SQL_IS_INTEGER;
        handleAttr_args->attribute   =  SQL_ATTR_AUTOCOMMIT;

#ifndef PASE
        handleAttr_args->valuePtr = (SQLPOINTER)autocommit;
#else
        handleAttr_args->valuePtr = (SQLPOINTER)&autocommit;
#endif
        rc = _ruby_ibm_db_SQLSetConnectAttr_helper( handleAttr_args );
        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        } else {
          conn_res->auto_commit = autocommit;

          /* If autocommit is requested to be turned ON and there is a transaction in progress, the trasaction is committed.
           * Hence set flag_transaction  to 0 indicating no transaction is in progress */ 
          if( autocommit == SQL_AUTOCOMMIT_ON ) {
            conn_res->transaction_active = 0;
          }
        }
      }
      ruby_xfree( handleAttr_args );
      handleAttr_args = NULL;
      ret_val = Qtrue;
    } else {
      ret_val = INT2NUM(conn_res->auto_commit);
    }
  }
  if ( handleAttr_args != NULL ) {
    ruby_xfree( handleAttr_args );
    handleAttr_args  =  NULL;
  }
  return ret_val;
}
/*  */

/*  static void _ruby_ibm_db_add_param_cache( stmt_handle *stmt_res, int param_no, char *varname, int param_type, int size, SQLSMALLINT data_type, SQLSMALLINT precision, SQLSMALLINT scale, SQLSMALLINT nullable )
*/
static void _ruby_ibm_db_add_param_cache( stmt_handle *stmt_res, int param_no, char *varname, int varname_len, int param_type, int size, SQLSMALLINT data_type, SQLUINTEGER precision, SQLSMALLINT scale, SQLSMALLINT nullable )
{
  param_node *tmp_curr  =  NULL;
  param_node *prev      =  stmt_res->head_cache_list;
  param_node *curr      =  stmt_res->head_cache_list;

  while ( (curr != NULL) && (curr->param_num < param_no) ) {
    prev = curr;
    curr = curr->next;
  }

  if ( curr == NULL || curr->param_num != param_no ) {
    /* Allocate memory and make new node to be added */
    tmp_curr = ALLOC(param_node);
    memset(tmp_curr, '\0', sizeof(param_node));

    /* assign values */
    tmp_curr->data_type     =  data_type;
    tmp_curr->param_size    =  precision;
    tmp_curr->nullable      =  nullable;
    tmp_curr->scale         =  scale;
    tmp_curr->param_num     =  param_no;
    tmp_curr->file_options  =  SQL_FILE_READ;
    tmp_curr->param_type    =  param_type;
    tmp_curr->size          =  size;
    tmp_curr->varname       =  NULL;
    tmp_curr->svalue        =  NULL;

    /* Set this flag in stmt_res if a FILE INPUT is present */
    if ( param_type == PARAM_FILE) {
      stmt_res->file_param = 1;
    }

    if ( varname != NULL) {
      tmp_curr->varname = estrndup(varname, varname_len);
    }

    /* link pointers for the list */
    if ( prev == NULL ) {
      stmt_res->head_cache_list = tmp_curr;
    } else {
      prev->next = tmp_curr;
    }
    tmp_curr->next = curr;

    /* Increment num params added */
    stmt_res->num_params++;
  } else {
    /* Both the nodes are for the same param no */
    /* Replace Information */
    curr->data_type     =  data_type;
    curr->param_size    =  precision;
    curr->nullable      =  nullable;
    curr->scale         =  scale;
    curr->param_num     =  param_no;
    curr->file_options  =  SQL_FILE_READ;
    curr->param_type    =  param_type;
    curr->size          =  size;

    if( curr->varname != NULL ) {
      ruby_xfree( curr->varname );
    }
    curr->varname = NULL;

    if( curr->svalue != NULL ) {
      ruby_xfree( curr->svalue );
    }
    curr->svalue = NULL;

    /* Set this flag in stmt_res if a FILE INPUT is present */
    if ( param_type == PARAM_FILE) {
      stmt_res->file_param = 1;
    }

    /* Free and assign the variable name again */
    /* Var lengths can be variable and different in both cases. */
    /* This shouldn't happen often anyway */
    if ( varname != NULL) {
      curr->varname = estrndup(varname, varname_len);
    }
  }
}

/*
  VALUE ibm_db_bind_param_helper(char * varname, long varname_len ,long param_type, long data_type, long precision, 
                                 long scale, long size, stmt_handle *stmt_res, describeparam_args *data)
*/
VALUE ibm_db_bind_param_helper(int argc, char * varname, long varname_len ,long param_type, long data_type, 
                            long precision, long scale, long size, stmt_handle *stmt_res, describeparam_args *data) {

  int   rc            =  0;
  VALUE return_value  =  Qtrue;
#ifdef UNICODE_SUPPORT_VERSION
  char  *err_str      =  NULL;
#endif

  /* Check for Param options */
  switch (argc) {
    /* if argc == 3, then the default value for param_type will be used */
    case 3:
      param_type = SQL_PARAM_INPUT;

      #ifdef UNICODE_SUPPORT_VERSION        
	  
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLDescribeParam_helper, data,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res);
		rc = data->rc;
      #else
        rc  =  _ruby_ibm_db_SQLDescribeParam_helper( data );
      #endif

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
        return_value = Qfalse;
        break;
      }

      /* Add to cache */
      _ruby_ibm_db_add_param_cache( stmt_res, data->param_no, varname, varname_len, param_type, size, 
                data->sql_data_type, data->sql_precision, data->sql_scale, data->sql_nullable );
      break;

    case 4:

      #ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLDescribeParam_helper, data,
                       (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res);
		rc = data->rc;
      #else
        rc = _ruby_ibm_db_SQLDescribeParam_helper( data );
      #endif

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
        return_value = Qfalse;
        break;
      }

      /* Add to cache */
      _ruby_ibm_db_add_param_cache( stmt_res, data->param_no, varname, varname_len, param_type, size, 
                data->sql_data_type, data->sql_precision, data->sql_scale, data->sql_nullable );
      break;

    case 5:

      #ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLDescribeParam_helper, data,
                       (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		rc = data->rc;
      #else
        rc = _ruby_ibm_db_SQLDescribeParam_helper( data );
      #endif

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
        return_value = Qfalse;
        break;
      }
      data->sql_data_type = (SQLSMALLINT)data_type;

      /* Add to cache */
      _ruby_ibm_db_add_param_cache( stmt_res, data->param_no, varname, varname_len, param_type, size, 
                data->sql_data_type, data->sql_precision, data->sql_scale, data->sql_nullable );
      break;

    case 6:

      #ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLDescribeParam_helper, data,
                       (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		rc = data->rc;
      #else
        rc = _ruby_ibm_db_SQLDescribeParam_helper( data );
      #endif

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
        return_value = Qfalse;
        break;
      }
      data->sql_data_type = (SQLSMALLINT)data_type;
      data->sql_precision = (SQLUINTEGER)precision;

      /* Add to cache */
      _ruby_ibm_db_add_param_cache( stmt_res, data->param_no, varname, varname_len, param_type, size, 
                data->sql_data_type, data->sql_precision, data->sql_scale, data->sql_nullable );
      break;

    case 7:
    case 8:
      /* Cache param data passed */
      /* I am using a linked list of nodes here because I dont know before hand how many params are being passed in/bound. */
      /* To determine this, a call to SQLNumParams is necessary. This is take away any advantages an array would have over linked list access */
      /* Data is being copied over to the correct types for subsequent CLI call because this might cause problems on other platforms such as AIX */
      data->sql_data_type = (SQLSMALLINT)data_type;
      data->sql_precision = (SQLUINTEGER)precision;
      data->sql_scale     = (SQLSMALLINT)scale;

      _ruby_ibm_db_add_param_cache( stmt_res, data->param_no, varname, varname_len, param_type, size, 
                data->sql_data_type, data->sql_precision, data->sql_scale, data->sql_nullable );
      break;

    default:
      /* WRONG_PARAM_COUNT; */
      return_value = Qfalse;
  }
  /* end Switch */

  if( rc == SQL_ERROR ) {
#ifdef UNICODE_SUPPORT_VERSION
        /*String in SQLWCHAR(utf16) format will contain '\0' due to which the err string will be printed wrong, 
         * hence convert it to utf8 format
         */
        err_str = RSTRING_PTR(
                    _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg, 
                       DB2_MAX_ERR_MSG_LEN * sizeof(SQLWCHAR) ) 
                  );
        rb_warn("Describe Param Failed: %s", err_str );
#else
        rb_warn("Describe Param Failed: %s", (char *) stmt_res->ruby_stmt_err_msg );
#endif
  }

  /* We bind data with DB2 CLI in IBM_DB.execute() */
  /* This will save network flow if we need to override params in it */

  return return_value;
}
/*  */

/*
 * IBM_DB.bind_param --  Binds a Ruby variable to an SQL statement parameter
 *
 * ===Description
 * bool IBM_DB.bind_param ( resource stmt, int parameter-number, string variable-name [, int parameter-type
 *                                         [, int data-type [, int precision [, int scale [, int size[]]]]]] )
 *
 * Binds a Ruby variable to an SQL statement parameter in a statement resource returned by IBM_DB.prepare().
 * This function gives you more control over the parameter type, data type, precision, and scale for
 * the parameter than simply passing the variable as part of the optional input array to IBM_DB.execute().
 *
 * ===Parameters
 *
 * stmt
 *   A prepared statement returned from IBM_DB.prepare(). 
 *
 * parameter-number
 *   Specifies the 1-indexed position of the parameter in the prepared statement. 
 *
 * variable-name
 *   A string specifying the name of the Ruby variable to bind to the parameter specified by parameter-number. 
 *
 * parameter-type
 *   A constant specifying whether the Ruby variable should be bound to the SQL parameter as an input parameter
 *   (SQL_PARAM_INPUT), an output parameter (SQL_PARAM_OUTPUT), or as a parameter that accepts input and returns output
 *   (SQL_PARAM_INPUT_OUTPUT). To avoid memory overhead, you can also specify PARAM_FILE to bind the Ruby variable
 *   to the name of a file that contains large object (BLOB, CLOB, or DBCLOB) data. 
 *
 * data-type
 *   A constant specifying the SQL data type that the Ruby variable should be bound as: one of SQL_BINARY,
 *   DB2_CHAR, DB2_DOUBLE, or DB2_LONG . 
 *
 * precision
 *   Specifies the precision that the variable should be bound to the database. 
 *
 * scale
 *    Specifies the scale that the variable should be bound to the database. 
 *
 * size
 *    Specifies the size that should be retreived from an INOUT/OUT parameter.
 *
 * ===Return Values
 *
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_bind_param(int argc, VALUE *argv, VALUE self)
{
  char *varname   = NULL;
  long varname_len;
  long param_type = SQL_PARAM_INPUT;
  /* LONG types used for data being passed in */
  long data_type  = 0;
  long precision  = 0;
  long scale      = 0;
  long size       = 0;
  describeparam_args *desc_param_args = NULL;

  VALUE stmt = Qnil;
  VALUE return_value;
  stmt_handle *stmt_res;

  VALUE r_param_no, r_varname, r_param_type=Qnil, r_size=Qnil;
  VALUE r_data_type=Qnil, r_precision=Qnil, r_scale=Qnil;

  rb_scan_args(argc, argv, "35", &stmt, &r_param_no, &r_varname, 
    &r_param_type, &r_data_type, &r_precision, &r_scale, &r_size);

#ifdef UNICODE_SUPPORT_VERSION
  varname     = RSTRING_PTR(r_varname);
  varname_len = RSTRING_LEN(r_varname);
#else
  varname = rb_str2cstr(r_varname, &varname_len);
#endif

  if (!NIL_P(r_param_type)) {
    param_type =  NUM2LONG(r_param_type);
  }
  if (!NIL_P(r_data_type)) {
    data_type  =  NUM2LONG(r_data_type);
  }
  if (!NIL_P(r_precision)) {
    precision  =  NUM2LONG(r_precision);
  }
  if (!NIL_P(r_scale)) {
    scale      =  NUM2LONG(r_scale);
  }
  if (!NIL_P(r_size)) {
    size       =  NUM2LONG(r_size);
  }

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

    desc_param_args = ALLOC( describeparam_args );
    memset(desc_param_args,'\0',sizeof(struct _ibm_db_describeparam_args_struct));

    desc_param_args->param_no          =  NUM2INT(r_param_no);

    desc_param_args->sql_data_type     =  0;
    desc_param_args->sql_precision     =  0;
    desc_param_args->sql_scale         =  0;
    desc_param_args->sql_nullable      =  SQL_NO_NULLS;
    desc_param_args->stmt_res          =  stmt_res;

    return_value = ibm_db_bind_param_helper(argc,varname,varname_len,param_type,data_type,precision,
                                              scale,size,stmt_res,desc_param_args);
  } else {
    rb_warn("Invalid Statement resource specified");
    return_value = Qfalse;
  }
 
  /*Free any memory used*/
  if(desc_param_args != NULL) {
    ruby_xfree( desc_param_args );
    desc_param_args = NULL;
  }
  
  return return_value;
}
/*  */

/*
 * IBM_DB.close --  Closes a database connection
 *
 * ===Description
 *
 * bool IBM_DB.close ( resource connection )
 *
 * This function closes a DB2 client connection created with IBM_DB.connect() and returns 
 * the corresponding resources to the database server.
 * 
 * If you attempt to close a persistent DB2 client connection created with IBM_DB.pconnect(), the close request
 * returns TRUE and the persistent DB2 client connection remains available for the next caller.
 * 
 * ===Parameters
 *
 * connection
 *   Specifies an active DB2 client connection. 
 *
 * ===Return Values
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_close(int argc, VALUE *argv, VALUE self)
{
  VALUE connection = Qnil;
  conn_handle *conn_res;
  int rc;
  VALUE return_value = Qtrue;
  end_tran_args *end_X_args;

  rb_scan_args(argc, argv, "1", &connection);

  if (!NIL_P(connection)) {
    /* Check to see if it's a persistent connection; if so, just return true */
    Data_Get_Struct(connection, conn_handle, conn_res);

	
    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }

    if ( conn_res->handle_active && !conn_res->flag_pconnect ) {
      /* Disconnect from DB. If stmt is allocated, it is freed automatically */
      if (conn_res->auto_commit == 0) {
        end_X_args = ALLOC( end_tran_args );
        memset(end_X_args,'\0',sizeof(struct _ibm_db_end_tran_args_struct));

        end_X_args->hdbc            =  &(conn_res->hdbc);
        end_X_args->handleType      =  SQL_HANDLE_DBC;
        end_X_args->completionType  =  SQL_ROLLBACK;        /*Remeber you are rolling back the transaction*/

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLEndTran, end_X_args,
                         (void *)_ruby_ibm_db_Connection_level_UBF, NULL);
		  rc = end_X_args->rc;
        #else
          rc = _ruby_ibm_db_SQLEndTran( end_X_args );
        #endif

        /*Free the memory allocated*/
        if(end_X_args != NULL) {
          ruby_xfree( end_X_args );
          end_X_args = NULL;
        }
        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
          return Qfalse;
        }
      }

      #ifdef UNICODE_SUPPORT_VERSION
	    rc = ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLDisconnect_helper, &(conn_res->hdbc),
                       (void *)_ruby_ibm_db_Connection_level_UBF, NULL);		
      #else
		rc = _ruby_ibm_db_SQLDisconnect_helper( &(conn_res->hdbc) );        
      #endif

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        return_value = Qfalse;
      } else {
        rc = SQLFreeHandle( SQL_HANDLE_DBC, conn_res->hdbc);
        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
          return_value = Qfalse;
        } else {
          conn_res->handle_active = 0;

          connection = Qnil;

          rc = SQLFreeHandle(SQL_HANDLE_ENV, conn_res->henv );

          return_value = Qtrue;
        }
      }
    } else if ( conn_res->flag_pconnect ) {
      /* Do we need to call FreeStmt or something to close cursors? */
      return_value = Qtrue;
    } else {
      return_value = Qfalse;
    }
  } else {
    return_value   = Qfalse;
  }
  
  return return_value;
}
/*  */

/*
 * IBM_DB.column_privileges --  Returns a result set listing the columns and associated privileges for a table
 * 
 * ===Description
 * resource IBM_DB.column_privileges ( resource connection [, string qualifier [, string schema 
 *                                               [, string table-name [, string column-name]]]] )
 * 
 * Returns a result set listing the columns and associated privileges for a table.
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases,
 *     pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the tables. To match all schemas, pass NULL or an empty string. 
 * 
 * table-name
 *     The name of the table or view. To match all tables in the database, pass NULL or an empty string. 
 * 
 * column-name
 *     The name of the column. To match all columns in the table, pass NULL or an empty string. 
 * 
 * ===Return Values
 * Returns a statement resource with a result set containing rows describing the column privileges
 * for columns matching the specified parameters. The rows are composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * TABLE_CAT:: Name of the catalog. The value is NULL if this table does not have catalogs.
 * TABLE_SCHEM:: Name of the schema.
 * TABLE_NAME:: Name of the table or view.
 * COLUMN_NAME:: Name of the column.
 * GRANTOR:: Authorization ID of the user who granted the privilege.
 * GRANTEE:: Authorization ID of the user to whom the privilege was granted.
 * PRIVILEGE:: The privilege for the column.
 * IS_GRANTABLE:: Whether the GRANTEE is permitted to grant this privilege to other users.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_column_privileges(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier          =  Qnil;
  VALUE r_owner              =  Qnil;
  VALUE r_table_name         =  Qnil;
  VALUE r_column_name        =  Qnil;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16    =  Qnil;
  VALUE r_owner_utf16        =  Qnil;
  VALUE r_table_name_utf16   =  Qnil;
  VALUE r_column_name_utf16  =  Qnil;
#endif

  VALUE connection           =  Qnil;
  VALUE return_value         =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  metadata_args *col_privileges_args = NULL;

  int rc;

  rb_scan_args(argc, argv, "14", &connection, 
    &r_qualifier, &r_owner, &r_table_name, &r_column_name);

  col_privileges_args = ALLOC( metadata_args );
  memset(col_privileges_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  col_privileges_args->qualifier        =  NULL;
  col_privileges_args->owner            =  NULL;
  col_privileges_args->table_name       =  NULL;
  col_privileges_args->column_name      =  NULL;
  col_privileges_args->qualifier_len    =  0;
  col_privileges_args->owner_len        =  0;
  col_privileges_args->table_name_len   =  0;
  col_privileges_args->column_name_len  =  0;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if ( !conn_res || !conn_res->handle_active ) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {

        stmt_res = _ibm_db_new_stmt_struct(conn_res);

        rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
        if (rc == SQL_ERROR) {
          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
          return_value = Qfalse;
        } else {
          if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
            r_qualifier_utf16                     =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
            col_privileges_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
            col_privileges_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
            col_privileges_args->qualifier        =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
            col_privileges_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
          }
          if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
            r_owner_utf16                         =   _ruby_ibm_db_export_str_to_utf16( r_owner  );
            col_privileges_args->owner            =   (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
            col_privileges_args->owner_len        =   (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else 
            col_privileges_args->owner            =   (SQLCHAR*)    RSTRING_PTR( r_owner );
            col_privileges_args->owner_len        =   (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
          }
          if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
            r_table_name_utf16                    =   _ruby_ibm_db_export_str_to_utf16( r_table_name );
            col_privileges_args->table_name       =   (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
            col_privileges_args->table_name_len   =   (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
            col_privileges_args->table_name       =   (SQLCHAR*)    RSTRING_PTR( r_table_name );
            col_privileges_args->table_name_len   =   (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
          }
          if (!NIL_P(r_column_name)) {
#ifdef UNICODE_SUPPORT_VERSION
            r_column_name_utf16                   =   _ruby_ibm_db_export_str_to_utf16( r_column_name );
            col_privileges_args->column_name      =   (SQLWCHAR*)   RSTRING_PTR( r_column_name_utf16 );
            col_privileges_args->column_name_len  =   (SQLSMALLINT) RSTRING_LEN( r_column_name_utf16 )/sizeof(SQLWCHAR);
#else
            col_privileges_args->column_name      =   (SQLCHAR*)    RSTRING_PTR( r_column_name );
            col_privileges_args->column_name_len  =   (SQLSMALLINT) RSTRING_LEN( r_column_name  );
#endif
          }
          col_privileges_args->stmt_res  =  stmt_res;

          #ifdef UNICODE_SUPPORT_VERSION            
			ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLColumnPrivileges_helper, col_privileges_args,
                           (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
			rc = col_privileges_args->rc;
          #else
            rc = _ruby_ibm_db_SQLColumnPrivileges_helper( col_privileges_args );
          #endif

          if (rc == SQL_ERROR ) {

            _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                      NULL, NULL, -1, 1, 1 );
            _ruby_ibm_db_free_stmt_struct( stmt_res );
            stmt_res = NULL;

            return_value = Qfalse;
          } else {
            return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
                stmt_res);
          } /* SQLColumnPrivileges -> rc == SQL_ERROR */
        } /*  SQLAllocHandle -> rc == SQL_ERROR      */
    } /*    !conn_res->handle_active               */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if(col_privileges_args != NULL) {
    ruby_xfree( col_privileges_args );
    col_privileges_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.columns --  Returns a result set listing the columns and associated metadata for a table
 * ===Description
 * resource IBM_DB.columns ( resource connection [, string qualifier [, string schema [, string table-name [, string column-name]]]] )
 * 
 * Returns a result set listing the columns and associated metadata for a table.
 * 
 * ===Parameters
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the tables. To match all schemas, pass '%'. 
 * 
 * table-name
 *     The name of the table or view. To match all tables in the database, pass NULL or an empty string. 
 * 
 * column-name
 *     The name of the column. To match all columns in the table, pass NULL or an empty string. 
 * 
 * ===Return Values
 * Returns a statement resource with a result set containing rows describing the columns matching the specified parameters.
 * The rows are composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * TABLE_CAT:: Name of the catalog. The value is NULL if this table does not have catalogs.
 * TABLE_SCHEM:: Name of the schema.
 * TABLE_NAME:: Name of the table or view.
 * COLUMN_NAME:: Name of the column.
 * DATA_TYPE:: The SQL data type for the column represented as an integer value.
 * TYPE_NAME:: A string representing the data type for the column.
 * COLUMN_SIZE:: An integer value representing the size of the column.
 * BUFFER_LENGTH:: Maximum number of bytes necessary to store data from this column.
 * DECIMAL_DIGITS:: The scale of the column, or NULL where scale is not applicable.
 * NUM_PREC_RADIX:: An integer value of either 10 (representing an exact numeric data type), 2 (representing an approximate numeric data type), or NULL (representing a data type for which radix is not applicable).
 * NULLABLE:: An integer value representing whether the column is nullable or not.
 * REMARKS:: Description of the column.
 * COLUMN_DEF:: Default value for the column.
 * SQL_DATA_TYPE:: An integer value representing the size of the column.
 * SQL_DATETIME_SUB:: Returns an integer value representing a datetime subtype code, or NULL for SQL data types to which this does not apply.
 * CHAR_OCTET_LENGTH::  Maximum length in octets for a character data type column, which matches COLUMN_SIZE for single-byte character set data, or NULL for non-character data types.
 * ORDINAL_POSITION:: The 1-indexed position of the column in the table.
 * IS_NULLABLE:: A string value where 'YES' means that the column is nullable and 'NO' means that the column is not nullable.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_columns(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier         =  Qnil;
  VALUE r_owner             =  Qnil;
  VALUE r_table_name        =  Qnil;
  VALUE r_column_name       =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16   =  Qnil;
  VALUE r_owner_utf16       =  Qnil;
  VALUE r_table_name_utf16  =  Qnil;
  VALUE r_column_name_utf16 =  Qnil;
#endif
  VALUE connection          =  Qnil;
  VALUE return_value        =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  metadata_args *col_metadata_args = NULL;

  int rc;

  rb_scan_args(argc, argv, "14", &connection, 
    &r_qualifier, &r_owner, &r_table_name, &r_column_name);

  col_metadata_args = ALLOC( metadata_args );
  memset(col_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  col_metadata_args->qualifier        =  NULL;
  col_metadata_args->owner            =  NULL;
  col_metadata_args->table_name       =  NULL;
  col_metadata_args->column_name      =  NULL;
  col_metadata_args->qualifier_len    =  0;
  col_metadata_args->owner_len        =  0;
  col_metadata_args->table_name_len   =  0;
  col_metadata_args->column_name_len  =  0;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if ( !conn_res || !conn_res->handle_active ) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {
      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                   =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          col_metadata_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->qualifier        =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                       =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          col_metadata_args->owner            =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->owner            =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_name_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_table_name );
          col_metadata_args->table_name       =  (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->table_name       =  (SQLCHAR*)    RSTRING_PTR( r_table_name );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
        }
        if (!NIL_P(r_column_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_column_name_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_column_name );
          col_metadata_args->column_name       =  (SQLWCHAR*)   RSTRING_PTR( r_column_name_utf16 );
          col_metadata_args->column_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_column_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->column_name       =  (SQLCHAR*)    RSTRING_PTR( r_column_name );
          col_metadata_args->column_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_column_name );
#endif
        }
        col_metadata_args->stmt_res  =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLColumns_helper, col_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		  rc = col_metadata_args->rc;
        #else
          rc = _ruby_ibm_db_SQLColumns_helper( col_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                      NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLColumns -> rc == SQL_ERROR     */
      } /*  SQLAllocHandle -> rc == SQL_ERROR */
    } /*   !conn_res->handle_active          */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if(col_metadata_args != NULL) {
    ruby_xfree( col_metadata_args );
    col_metadata_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.foreign_keys --  Returns a result set listing the foreign keys for a table
 * 
 * ===Description
 * resource IBM_DB.foreign_keys ( resource connection, string qualifier, string schema, string table-name )
 * 
 * Returns a result set listing the foreign keys for a table.
 * 
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL
 *     or an empty string. 
 * 
 * schema
 *     The schema which contains the tables. If schema is NULL, IBM_DB.foreign_keys() matches the schema
 *     for the current connection. 
 * 
 * table-name
 *     The name of the table. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows describing the foreign keys for
 * the specified table. The result set is composed of the following columns:
 * 
 * <b>Column name</b>::  <b>Description</b>
 * PKTABLE_CAT:: Name of the catalog for the table containing the primary key. The value is NULL if this table does not have catalogs.
 * PKTABLE_SCHEM:: Name of the schema for the table containing the primary key.
 * PKTABLE_NAME:: Name of the table containing the primary key.
 * PKCOLUMN_NAME:: Name of the column containing the primary key.
 * FKTABLE_CAT:: Name of the catalog for the table containing the foreign key. The value is NULL if this table does not have catalogs.
 * FKTABLE_SCHEM:: Name of the schema for the table containing the foreign key.
 * FKTABLE_NAME:: Name of the table containing the foreign key.
 * FKCOLUMN_NAME:: Name of the column containing the foreign key.
 * KEY_SEQ:: 1-indexed position of the column in the key.
 * UPDATE_RULE:: Integer value representing the action applied to the foreign key when the SQL operation is UPDATE.
 * DELETE_RULE:: Integer value representing the action applied to the foreign key when the SQL operation is DELETE.
 * FK_NAME:: The name of the foreign key.
 * PK_NAME:: The name of the primary key.
 * DEFERRABILITY:: An integer value representing whether the foreign key deferrability is SQL_INITIALLY_DEFERRED, SQL_INITIALLY_IMMEDIATE, or SQL_NOT_DEFERRABLE.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_foreign_keys(int argc, VALUE *argv, VALUE self)
{
	
  VALUE r_qualifier         =  Qnil;
  VALUE r_owner             =  Qnil;
  VALUE r_table_name        =  Qnil;
  VALUE r_is_fk_table 		=  Qfalse;
  
#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16   =  Qnil;
  VALUE r_owner_utf16       =  Qnil;
  VALUE r_table_name_utf16  =  Qnil;
#endif
  VALUE connection          =  Qnil;
  VALUE return_value        =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  metadata_args *col_metadata_args = NULL;

  int rc;

  rb_scan_args(argc, argv, "41", &connection, 
    &r_qualifier, &r_owner, &r_table_name, &r_is_fk_table);

  col_metadata_args = ALLOC( metadata_args );
  memset(col_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  col_metadata_args->qualifier        =  NULL;
  col_metadata_args->owner            =  NULL;
  col_metadata_args->table_name       =  NULL;
  col_metadata_args->qualifier_len    =  0;
  col_metadata_args->owner_len        =  0;
  col_metadata_args->table_name_len   =  0;
  if(!NIL_P(r_is_fk_table)){		
		col_metadata_args->table_type       =  (SQLWCHAR*) "FK_TABLE";
	}

  if (connection) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {

      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                   =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          col_metadata_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->qualifier        =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                       =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          col_metadata_args->owner            =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->owner            =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_name_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_table_name );
          col_metadata_args->table_name       =  (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->table_name       =  (SQLCHAR*)    RSTRING_PTR( r_table_name );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
        }

        col_metadata_args->stmt_res  =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLForeignKeys_helper, col_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		  rc = col_metadata_args->rc;
        #else
          rc = _ruby_ibm_db_SQLForeignKeys_helper( col_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                    NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLForeignKeys -> rc == SQL_ERROR */
      } /*  SQLAllocHandle -> rc == SQL_ERROR */
    } /*   !conn_res->handle_active          */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if(col_metadata_args != NULL) {
    ruby_xfree( col_metadata_args );
    col_metadata_args = NULL;
  }  

  return return_value;
}
/*  */

/*
 * IBM_DB.primary_keys --  Returns a result set listing primary keys for a table
 * 
 * ===Description
 * resource IBM_DB.primary_keys ( resource connection, string qualifier, string schema, string table-name )
 * 
 * Returns a result set listing the primary keys for a table.
 *
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the tables. If schema is NULL, IBM_DB.primary_keys() matches the schema for the current connection. 
 * 
 * table-name
 *     The name of the table. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows describing the primary keys for the specified table.
 * The result set is composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * TABLE_CAT:: Name of the catalog for the table containing the primary key. The value is NULL if this table does not have catalogs.
 * TABLE_SCHEM:: Name of the schema for the table containing the primary key.
 * TABLE_NAME:: Name of the table containing the primary key.
 * COLUMN_NAME:: Name of the column containing the primary key.
 * KEY_SEQ:: 1-indexed position of the column in the key.
 * PK_NAME:: The name of the primary key.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_primary_keys(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier         =  Qnil;
  VALUE r_owner             =  Qnil;
  VALUE r_table_name        =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16   =  Qnil;
  VALUE r_owner_utf16       =  Qnil;
  VALUE r_table_name_utf16  =  Qnil;
#endif
  VALUE connection          =  Qnil;
  VALUE return_value        =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  metadata_args *col_metadata_args = NULL;

  int rc;

  rb_scan_args(argc, argv, "4", &connection, 
    &r_qualifier, &r_owner, &r_table_name);

  col_metadata_args = ALLOC( metadata_args );
  memset(col_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  col_metadata_args->qualifier        =  NULL;
  col_metadata_args->owner            =  NULL;
  col_metadata_args->table_name       =  NULL;
  col_metadata_args->qualifier_len    =  0;
  col_metadata_args->owner_len        =  0;
  col_metadata_args->table_name_len   =  0;

  if (connection) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {

      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                   =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          col_metadata_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->qualifier        =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                       =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          col_metadata_args->owner            =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->owner            =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_name_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_table_name );
          col_metadata_args->table_name       =  (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->table_name       =  (SQLCHAR*)    RSTRING_PTR( r_table_name );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
        }
        col_metadata_args->stmt_res  =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLPrimaryKeys_helper, col_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		  rc = col_metadata_args->rc;
        #else
          rc = _ruby_ibm_db_SQLPrimaryKeys_helper( col_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                    NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLPrimaryKeys -> rc == SQL_ERROR */
      } /*  SQLAllocHandle -> rc == SQL_ERROR */
    } /*   !conn_res->handle_active          */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if(col_metadata_args != NULL) {
    ruby_xfree( col_metadata_args );
    col_metadata_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.procedure_columns --  Returns a result set listing stored procedure parameters
 * 
 * ===Description
 * resource IBM_DB.procedure_columns ( resource connection, string qualifier, string schema, string procedure, string parameter )
 * 
 * Returns a result set listing the parameters for one or more stored procedures.
 * 
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the procedures. This parameter accepts a search pattern containing _ and % as wildcards. 
 * 
 * procedure
 *     The name of the procedure. This parameter accepts a search pattern containing _ and % as wildcards. 
 * 
 * parameter
 *     The name of the parameter. This parameter accepts a search pattern containing _ and % as wildcards.
 *     If this parameter is NULL, all parameters for the specified stored procedures are returned. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows describing the parameters for the stored procedures
 * matching the specified parameters. The rows are composed of the following columns:
 * 
 * <b>Column name</b>::  <b>Description</b>
 * PROCEDURE_CAT:: The catalog that contains the procedure. The value is NULL if this table does not have catalogs.
 * PROCEDURE_SCHEM:: Name of the schema that contains the stored procedure.
 * PROCEDURE_NAME:: Name of the procedure.
 * COLUMN_NAME:: Name of the parameter.
 * COLUMN_TYPE:: An integer value representing the type of the parameter:
 *               Return value:: Parameter type
 *               1:: (SQL_PARAM_INPUT)  Input (IN) parameter.
 *               2:: (SQL_PARAM_INPUT_OUTPUT) Input/output (INOUT) parameter.
 *               3:: (SQL_PARAM_OUTPUT) Output (OUT) parameter.
 * DATA_TYPE:: The SQL data type for the parameter represented as an integer value.
 * TYPE_NAME:: A string representing the data type for the parameter.
 * COLUMN_SIZE:: An integer value representing the size of the parameter.
 * BUFFER_LENGTH:: Maximum number of bytes necessary to store data for this parameter.
 * DECIMAL_DIGITS:: The scale of the parameter, or NULL where scale is not applicable.
 * NUM_PREC_RADIX:: An integer value of either 10 (representing an exact numeric data type), 2 (representing anapproximate numeric data type), or NULL (representing a data type for which radix is not applicable).
 * NULLABLE:: An integer value representing whether the parameter is nullable or not.
 * REMARKS:: Description of the parameter.
 * COLUMN_DEF:: Default value for the parameter.
 * SQL_DATA_TYPE:: An integer value representing the size of the parameter.
 * SQL_DATETIME_SUB:: Returns an integer value representing a datetime subtype code, or NULL for SQL data types to which this does not apply.
 * CHAR_OCTET_LENGTH:: Maximum length in octets for a character data type parameter, which matches COLUMN_SIZE for single-byte character set data, or NULL for non-character data types.
 * ORDINAL_POSITION:: The 1-indexed position of the parameter in the CALL statement.
 * IS_NULLABLE:: A string value where 'YES' means that the parameter accepts or returns NULL values and 'NO' means that the parameter does not accept or return NULL values.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_procedure_columns(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier          =  Qnil;
  VALUE r_owner              =  Qnil;
  VALUE r_proc_name          =  Qnil;
  VALUE r_column_name        =  Qnil;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16    =  Qnil;
  VALUE r_owner_utf16        =  Qnil;
  VALUE r_proc_name_utf16    =  Qnil;
  VALUE r_column_name_utf16  =  Qnil;
#endif

  VALUE connection           =  Qnil;
  VALUE return_value         =  Qnil;

  metadata_args *col_metadata_args;

  int rc = 0;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  rb_scan_args(argc, argv, "5", &connection, 
    &r_qualifier, &r_owner, &r_proc_name, &r_column_name);

  col_metadata_args = ALLOC( metadata_args );
  memset(col_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  col_metadata_args->qualifier        =  NULL;
  col_metadata_args->owner            =  NULL;
  col_metadata_args->proc_name        =  NULL;
  col_metadata_args->column_name      =  NULL;
  col_metadata_args->qualifier_len    =  0;
  col_metadata_args->owner_len        =  0;
  col_metadata_args->proc_name_len    =  0;
  col_metadata_args->column_name_len  =  0;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {
      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          col_metadata_args->qualifier       =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          col_metadata_args->qualifier_len   =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->qualifier       =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          col_metadata_args->qualifier_len   =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                      =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          col_metadata_args->owner           =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          col_metadata_args->owner_len       =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->owner           =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          col_metadata_args->owner_len       =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_proc_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_proc_name_utf16                      =  _ruby_ibm_db_export_str_to_utf16( r_proc_name );
          col_metadata_args->proc_name           =  (SQLWCHAR*)   RSTRING_PTR( r_proc_name_utf16 );
          col_metadata_args->proc_name_len       =  (SQLSMALLINT) RSTRING_LEN( r_proc_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->proc_name           =  (SQLCHAR*)    RSTRING_PTR( r_proc_name );
          col_metadata_args->proc_name_len       =  (SQLSMALLINT) RSTRING_LEN( r_proc_name );
#endif
        }
        if (!NIL_P(r_column_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_column_name_utf16                    =  _ruby_ibm_db_export_str_to_utf16( r_column_name );
          col_metadata_args->column_name         =  (SQLWCHAR*)   RSTRING_PTR( r_column_name_utf16 );
          col_metadata_args->column_name_len     =  (SQLSMALLINT) RSTRING_LEN( r_column_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->column_name         =  (SQLCHAR*)    RSTRING_PTR( r_column_name );
          col_metadata_args->column_name_len     =  (SQLSMALLINT) RSTRING_LEN( r_column_name );
#endif
        }
        col_metadata_args->stmt_res  =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLProcedureColumns_helper, col_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res);
		  rc = col_metadata_args->rc;
        #else
          rc = _ruby_ibm_db_SQLProcedureColumns_helper( col_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                    NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLProcedureColumns -> rc == SQL_ERROR  */
      } /*  SQLAllocHandle -> rc == SQL_ERROR       */ 
    } /*   !conn_res->handle_active                */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if(col_metadata_args != NULL) {
    ruby_xfree( col_metadata_args );
    col_metadata_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.procedures --  Returns a result set listing the stored procedures registered in a database
 * 
 * ===Description
 * resource IBM_DB.procedures ( resource connection, string qualifier, string schema, string procedure )
 * 
 * Returns a result set listing the stored procedures registered in a database.
 * 
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the procedures. This parameter accepts a search pattern containing _ and % as wildcards. 
 * 
 * procedure
 *     The name of the procedure. This parameter accepts a search pattern containing _ and % as wildcards. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows describing the stored procedures matching the specified parameters. The rows are composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * PROCEDURE_CAT:: The catalog that contains the procedure. The value is NULL if this table does not have catalogs.
 * PROCEDURE_SCHEM:: Name of the schema that contains the stored procedure.
 * PROCEDURE_NAME:: Name of the procedure.
 * NUM_INPUT_PARAMS:: Number of input (IN) parameters for the stored procedure.
 * NUM_OUTPUT_PARAMS:: Number of output (OUT) parameters for the stored procedure.
 * NUM_RESULT_SETS:: Number of result sets returned by the stored procedure.
 * REMARKS:: Any comments about the stored procedure.
 * PROCEDURE_TYPE:: Always returns 1, indicating that the stored procedure does not return a return value.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_procedures(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier  =  Qnil;
  VALUE r_owner      =  Qnil;
  VALUE r_proc_name  =  Qnil;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16  =  Qnil;
  VALUE r_owner_utf16      =  Qnil;
  VALUE r_proc_name_utf16  =  Qnil;
#endif

  VALUE return_value =  Qnil;
  VALUE connection   =  Qnil;

  metadata_args *proc_metadata_args = NULL;

  int rc = 0;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  rb_scan_args(argc, argv, "4", &connection, 
    &r_qualifier, &r_owner, &r_proc_name);

  proc_metadata_args = ALLOC( metadata_args );
  memset(proc_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  proc_metadata_args->qualifier      =  NULL;
  proc_metadata_args->owner          =  NULL;
  proc_metadata_args->proc_name      =  NULL;
  proc_metadata_args->qualifier_len  =  0;
  proc_metadata_args->owner_len      =  0;
  proc_metadata_args->proc_name_len  =  0;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {
      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          proc_metadata_args->qualifier      =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          proc_metadata_args->qualifier_len  =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          proc_metadata_args->qualifier      =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          proc_metadata_args->qualifier_len  =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                      =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          proc_metadata_args->owner          =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          proc_metadata_args->owner_len      =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          proc_metadata_args->owner          =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          proc_metadata_args->owner_len      =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_proc_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_proc_name_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_proc_name );
          proc_metadata_args->proc_name      =  (SQLWCHAR*)   RSTRING_PTR( r_proc_name_utf16 );
          proc_metadata_args->proc_name_len  =  (SQLSMALLINT) RSTRING_LEN( r_proc_name_utf16 )/sizeof(SQLWCHAR);
#else
          proc_metadata_args->proc_name      =  (SQLCHAR*)    RSTRING_PTR(r_proc_name);
          proc_metadata_args->proc_name_len  =  (SQLSMALLINT) RSTRING_LEN( r_proc_name );
#endif
        }
        proc_metadata_args->stmt_res     =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLProcedures_helper, proc_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res);
		  rc = proc_metadata_args->rc;
        #else
          rc = _ruby_ibm_db_SQLProcedures_helper( proc_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                    NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLProcedures -> rc == SQL_ERROR   */
      } /*  SQLAllocHandle -> rc == SQL_ERROR  */
    } /*   !conn_res->handle_active           */
  } else {
    return_value = Qfalse;
  }
  
  /*Free memory allocated*/
  if(proc_metadata_args != NULL) {
    ruby_xfree( proc_metadata_args );
    proc_metadata_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.special_columns --  Returns a result set listing the unique row identifier columns for a table
 * 
 * ===Description
 * resource IBM_DB.special_columns ( resource connection, string qualifier, string schema, string table_name, int scope )
 * 
 * Returns a result set listing the unique row identifier columns for a table.
 * 
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the tables. 
 * 
 * table_name
 *     The name of the table. 
 * 
 * scope
 *     Integer value representing the minimum duration for which the unique row identifier is valid. This can be one of the following values:
 * 
 *     0: Row identifier is valid only while the cursor is positioned on the row. (SQL_SCOPE_CURROW)
 *     1: Row identifier is valid for the duration of the transaction. (SQL_SCOPE_TRANSACTION)
 *     2: Row identifier is valid for the duration of the connection. (SQL_SCOPE_SESSION)
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows with unique row identifier information for a table.
 * The rows are composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * SCOPE:: Integer value representing the minimum duration for which the unique row identifier is valid.
 *
 *         0: Row identifier is valid only while the cursor is positioned on the row. (SQL_SCOPE_CURROW)
 *
 *         1: Row identifier is valid for the duration of the transaction. (SQL_SCOPE_TRANSACTION)
 *
 *         2: Row identifier is valid for the duration of the connection. (SQL_SCOPE_SESSION)
 * COLUMN_NAME:: Name of the unique column.
 * DATA_TYPE:: SQL data type for the column.
 * TYPE_NAME:: Character string representation of the SQL data type for the column.
 * COLUMN_SIZE:: An integer value representing the size of the column.
 * BUFFER_LENGTH:: Maximum number of bytes necessary to store data from this column.
 * DECIMAL_DIGITS:: The scale of the column, or NULL where scale is not applicable.
 * NUM_PREC_RADIX:: An integer value of either 10 (representing an exact numeric data type),2 (representing an
 *                  approximate numeric data type), or NULL (representing a data type for which radix is not applicable).
 * PSEUDO_COLUMN:: Always returns 1.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_special_columns(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier         =  Qnil;
  VALUE r_owner             =  Qnil;
  VALUE r_table_name        =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16   =  Qnil;
  VALUE r_owner_utf16       =  Qnil;
  VALUE r_table_name_utf16  =  Qnil;
#endif
  VALUE r_scope             =  Qnil;
  VALUE connection          =  Qnil;
  VALUE return_value        =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  metadata_args *col_metadata_args = NULL;

  int rc;

  rb_scan_args(argc, argv, "5", &connection, &r_qualifier,
    &r_owner, &r_table_name, &r_scope);

  col_metadata_args = ALLOC( metadata_args );
  memset(col_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  col_metadata_args->qualifier        =  NULL;
  col_metadata_args->owner            =  NULL;
  col_metadata_args->table_name       =  NULL;
  col_metadata_args->scope            =  0;
  col_metadata_args->qualifier_len    =  0;
  col_metadata_args->owner_len        =  0;
  col_metadata_args->table_name_len   =  0;


  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {
      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                   =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          col_metadata_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->qualifier        =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                       =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          col_metadata_args->owner            =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->owner            =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_name_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_table_name );
          col_metadata_args->table_name       =  (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->table_name       =  (SQLCHAR*)    RSTRING_PTR( r_table_name );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
        }
        if (!NIL_P(r_scope)) {
          col_metadata_args->scope        =  (int)NUM2INT(r_scope);
        }
        col_metadata_args->stmt_res       =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLSpecialColumns_helper, col_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res);
		  rc = col_metadata_args->rc;				 
        #else
          rc = _ruby_ibm_db_SQLSpecialColumns_helper( col_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                    NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLSpecialColumns -> rc == SQL_ERROR */
      } /*  SQLAllocHandle -> rc == SQL_ERROR    */
    } /*   !conn_res->handle_active             */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if( col_metadata_args != NULL ) {
    ruby_xfree( col_metadata_args );
    col_metadata_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.statistics --  Returns a result set listing the index and statistics for a table
 * 
 * ===Description
 * resource IBM_DB.statistics ( resource connection, string qualifier, string schema, string table-name, int unique )
 * 
 * Returns a result set listing the index and statistics for a table.
 * 
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL or an empty string. 
 * 
 * schema
 *     The schema that contains the targeted table. If this parameter is NULL, the statistics and indexes are
 *     returned for the schema of the current user. 
 * 
 * table_name
 *     The name of the table. 
 * 
 * unique
 *     A integer value representing the type of index information to return.
 *      
 *     0    Return only the information for unique indexes on the table. 
 *     
 *     1    Return the information for all indexes on the table. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows describing the statistics and indexes for the base tables
 * matching the specified parameters. The rows are composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * TABLE_CAT:: The catalog that contains the table. The value is NULL if this table does not have catalogs.
 * TABLE_SCHEM:: Name of the schema that contains the table.
 * TABLE_NAME:: Name of the table.
 * NON_UNIQUE:: An integer value representing whether the index prohibits unique values, or whether the row represents
 *              statistics on the table itself:
 * 
 *              Return value:: Parameter type
 *              0 (SQL_FALSE):: The index allows duplicate values.
 *              1 (SQL_TRUE):: The index values must be unique.
 *              NULL:: This row is statistics information for the table itself.
 * 
 * INDEX_QUALIFIER:: A string value representing the qualifier that would have to be prepended to INDEX_NAME to fully qualify the index.
 * INDEX_NAME:: A string representing the name of the index.
 * TYPE:: An integer value representing the type of information contained in this row of the result set:
 * 
 *        Return value:: Parameter type
 *        0 (SQL_TABLE_STAT):: The row contains statistics about the table itself.
 *        1 (SQL_INDEX_CLUSTERED):: The row contains information about a clustered index.
 *        2 (SQL_INDEX_HASH):: The row contains information about a hashed index.
 *        3 (SQL_INDEX_OTHER):: The row contains information about a type of index that is neither clustered nor hashed.
 * 
 * ORDINAL_POSITION:: The 1-indexed position of the column in the index. NULL if the row contains statistics information about the table itself.
 * COLUMN_NAME:: The name of the column in the index. NULL if the row contains statistics information about the table itself.
 * ASC_OR_DESC:: A if the column is sorted in ascending order, D if the column is sorted in descending order, NULL
 *               if the row contains statistics information about the table itself.
 * CARDINALITY:: If the row contains information about an index, this column contains an integer value representing the number
 *               of unique values in the index.
 *               If the row contains information about the table itself, this column contains an integer value representing the
 *               number of rows in the table.
 * PAGES:: If the row contains information about an index, this column contains an integer value representing the number of pages
 *         used to store the index.
 *         If the row contains information about the table itself, this column contains an integer value representing the number
 *         of pages used to store the table.
 * FILTER_CONDITION:: Always returns NULL.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_statistics(int argc, VALUE *argv, VALUE self)
{
	
  VALUE r_qualifier         =  Qnil;
  VALUE r_owner             =  Qnil;
  VALUE r_table_name        =  Qnil;
  VALUE r_unique            =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16   =  Qnil;
  VALUE r_owner_utf16       =  Qnil;
  VALUE r_table_name_utf16  =  Qnil;
#endif
  VALUE connection    =  Qnil;
  VALUE return_value  =  Qnil;

  int rc = 0;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  metadata_args *col_metadata_args = NULL;

  col_metadata_args = ALLOC( metadata_args );
  memset(col_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  col_metadata_args->qualifier        =  NULL;
  col_metadata_args->owner            =  NULL;
  col_metadata_args->table_name       =  NULL;
  col_metadata_args->unique           =  0;
  col_metadata_args->qualifier_len    =  0;
  col_metadata_args->owner_len        =  0;
  col_metadata_args->table_name_len   =  0;

  rb_scan_args(argc, argv, "5", &connection, &r_qualifier,
    &r_owner, &r_table_name, &r_unique);

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {
      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                   =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          col_metadata_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else 
          col_metadata_args->qualifier        =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          col_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                       =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          col_metadata_args->owner            =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->owner            =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          col_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_name_utf16                  =  _ruby_ibm_db_export_str_to_utf16( r_table_name );
          col_metadata_args->table_name       =  (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
          col_metadata_args->table_name       =  (SQLCHAR*)    RSTRING_PTR( r_table_name );
          col_metadata_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
        }
        if (!NIL_P(r_unique)) {
          col_metadata_args->unique      =  (int)NUM2INT(r_unique);
        }
        col_metadata_args->stmt_res      =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLStatistics_helper, col_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		   rc = col_metadata_args->rc;
        #else
          rc = _ruby_ibm_db_SQLStatistics_helper( col_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                    NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLStatistics -> rc == SQL_ERROR   */
      } /*  SQLAllocHandle -> rc == SQL_ERROR  */
    } /*   !conn_res->handle_active           */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if( col_metadata_args != NULL ) {
    ruby_xfree( col_metadata_args );
    col_metadata_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.table_privileges --  Returns a result set listing the tables and associated privileges in a database
 * 
 * ===Description
 * resource IBM_DB.table_privileges ( resource connection [, string qualifier [, string schema [, string table_name]]] )
 * 
 * Returns a result set listing the tables and associated privileges in a database.
 * 
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, 
 *     pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the tables. This parameter accepts a search pattern containing _ 
 *     and % as wildcards. 
 * 
 * table_name
 *     The name of the table. This parameter accepts a search pattern containing _ and % as wildcards. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows describing the privileges for the
 * tables that match the specified parameters. The rows are composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * TABLE_CAT:: The catalog that contains the table. The value is NULL if this table does not have catalogs.
 * TABLE_SCHEM:: Name of the schema that contains the table.
 * TABLE_NAME:: Name of the table.
 * GRANTOR:: Authorization ID of the user who granted the privilege.
 * GRANTEE:: Authorization ID of the user to whom the privilege was granted.
 * PRIVILEGE:: The privilege that has been granted. This can be one of ALTER, CONTROL, DELETE, INDEX,
 *             INSERT, REFERENCES, SELECT, or UPDATE.
 * IS_GRANTABLE:: A string value of "YES" or "NO" indicating whether the grantee can grant the privilege to other users.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_table_privileges(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier         =  Qnil;
  VALUE r_owner             =  Qnil;
  VALUE r_table_name        =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16   =  Qnil;
  VALUE r_owner_utf16       =  Qnil;
  VALUE r_table_name_utf16  =  Qnil;
#endif
  VALUE connection          =  Qnil;
  VALUE return_value        =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  int rc;

  metadata_args *table_privileges_args = NULL;

  rb_scan_args(argc, argv, "13", &connection, &r_qualifier,
          &r_owner, &r_table_name);

  table_privileges_args = ALLOC( metadata_args );
  memset(table_privileges_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  table_privileges_args->qualifier       =  NULL;
  table_privileges_args->owner           =  NULL;
  table_privileges_args->table_name      =  NULL;
  table_privileges_args->qualifier_len   =  0;
  table_privileges_args->owner_len       =  0;
  table_privileges_args->table_name_len  =  0;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {
      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                       =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          table_privileges_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          table_privileges_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          table_privileges_args->qualifier        =  (SQLCHAR*)    RSTRING_PTR( r_qualifier );
          table_privileges_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                           =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          table_privileges_args->owner            =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          table_privileges_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          table_privileges_args->owner            =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          table_privileges_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_name_utf16                      =  _ruby_ibm_db_export_str_to_utf16( r_table_name );
          table_privileges_args->table_name       =  (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
          table_privileges_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
          table_privileges_args->table_name       =  (SQLCHAR*)    RSTRING_PTR( r_table_name );
          table_privileges_args->table_name_len   =  (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
        }

        table_privileges_args->stmt_res       =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLTablePrivileges_helper, table_privileges_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		  rc = table_privileges_args->rc;
        #else
          rc = _ruby_ibm_db_SQLTablePrivileges_helper( table_privileges_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                  NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLTableprivileges -> rc == SQL_ERROR */
      } /* SQLAllocHandle -> rc == SQL_ERROR      */
    } /* !conn_res->handle_active                 */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if( table_privileges_args != NULL ) {
    ruby_xfree( table_privileges_args );
    table_privileges_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.tables --  Returns a result set listing the tables and associated metadata in a database
 * 
 * ===Description
 * resource IBM_DB.tables ( resource connection [, string qualifier [, string schema [, string table-name [, string table-type]]]] )
 * 
 * Returns a result set listing the tables and associated metadata in a database.
 *
 * ===Parameters
 * 
 * connection
 *     A valid connection to an IBM DB2, Cloudscape, or Apache Derby database. 
 * 
 * qualifier
 *     A qualifier for DB2 databases running on OS/390 or z/OS servers. For other databases, pass NULL or an empty string. 
 * 
 * schema
 *     The schema which contains the tables. This parameter accepts a search pattern containing _ and % as wildcards. 
 * 
 * table-name
 *     The name of the table. This parameter accepts a search pattern containing _ and % as wildcards. 
 * 
 * table-type
 *     A list of comma-delimited table type identifiers. To match all table types, pass NULL or an empty string.
 *     Valid table type identifiers include: ALIAS, HIERARCHY TABLE, INOPERATIVE VIEW, NICKNAME, MATERIALIZED QUERY
 *     TABLE, SYSTEM TABLE, TABLE, TYPED TABLE, TYPED VIEW, and VIEW. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource with a result set containing rows describing the tables that match the specified parameters.
 * The rows are composed of the following columns:
 * 
 * <b>Column name</b>:: <b>Description</b>
 * TABLE_CAT:: The catalog that contains the table. The value is NULL if this table does not have catalogs.
 * TABLE_SCHEMA:: Name of the schema that contains the table.
 * TABLE_NAME:: Name of the table.
 * TABLE_TYPE:: Table type identifier for the table.
 * REMARKS:: Description of the table.
 *
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_tables(int argc, VALUE *argv, VALUE self)
{
  VALUE r_qualifier         =  Qnil;
  VALUE r_owner             =  Qnil;
  VALUE r_table_name        =  Qnil;
  VALUE r_table_type        =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE r_qualifier_utf16   =  Qnil;
  VALUE r_owner_utf16       =  Qnil;
  VALUE r_table_name_utf16  =  Qnil;
  VALUE r_table_type_utf16  =  Qnil;
#endif
  VALUE connection   =  Qnil;
  VALUE return_value =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

  metadata_args *table_metadata_args = NULL;

  int rc;

  rb_scan_args(argc, argv, "14", &connection, 
    &r_qualifier, &r_owner, &r_table_name, &r_table_type);

  table_metadata_args = ALLOC( metadata_args );
  memset(table_metadata_args,'\0',sizeof(struct _ibm_db_metadata_args_struct));

  table_metadata_args->qualifier        =  NULL;
  table_metadata_args->owner            =  NULL;
  table_metadata_args->table_name       =  NULL;
  table_metadata_args->table_type       =  NULL;
  table_metadata_args->qualifier_len    =  0;
  table_metadata_args->owner_len        =  0;
  table_metadata_args->table_name_len   =  0;
  table_metadata_args->table_type_len   =  0;

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return_value = Qfalse;
    } else {

      stmt_res = _ibm_db_new_stmt_struct(conn_res);

      rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
      if (rc == SQL_ERROR) {
        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
        ruby_xfree( stmt_res );
        stmt_res = NULL;
        return_value = Qfalse;
      } else {
        if (!NIL_P(r_qualifier)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_qualifier_utf16                     =  _ruby_ibm_db_export_str_to_utf16( r_qualifier );
          table_metadata_args->qualifier        =  (SQLWCHAR*)   RSTRING_PTR( r_qualifier_utf16 );
          table_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier_utf16 )/sizeof(SQLWCHAR);
#else
          table_metadata_args->qualifier        =  (SQLCHAR*)    RSTRING( r_qualifier );
          table_metadata_args->qualifier_len    =  (SQLSMALLINT) RSTRING_LEN( r_qualifier );
#endif
        }
        if (!NIL_P(r_owner)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_owner_utf16                         =  _ruby_ibm_db_export_str_to_utf16( r_owner );
          table_metadata_args->owner            =  (SQLWCHAR*)   RSTRING_PTR( r_owner_utf16 );
          table_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner_utf16 )/sizeof(SQLWCHAR);
#else
          table_metadata_args->owner            =  (SQLCHAR*)    RSTRING_PTR( r_owner );
          table_metadata_args->owner_len        =  (SQLSMALLINT) RSTRING_LEN( r_owner );
#endif
        }
        if (!NIL_P(r_table_name)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_name_utf16                     =  _ruby_ibm_db_export_str_to_utf16( r_table_name );
          table_metadata_args->table_name        =  (SQLWCHAR*)   RSTRING_PTR( r_table_name_utf16 );
          table_metadata_args->table_name_len    =  (SQLSMALLINT) RSTRING_LEN( r_table_name_utf16 )/sizeof(SQLWCHAR);
#else
          table_metadata_args->table_name        =  (SQLCHAR*)    RSTRING_PTR( r_table_name );
          table_metadata_args->table_name_len    =  (SQLSMALLINT) RSTRING_LEN( r_table_name );
#endif
        }
        if (!NIL_P(r_table_type)) {
#ifdef UNICODE_SUPPORT_VERSION
          r_table_type_utf16                     =  _ruby_ibm_db_export_str_to_utf16( r_table_type );
          table_metadata_args->table_type        =  (SQLWCHAR*)   RSTRING_PTR( r_table_type_utf16 );
          table_metadata_args->table_type_len    =  (SQLSMALLINT) RSTRING_LEN( r_table_type_utf16 )/sizeof(SQLWCHAR);
#else
          table_metadata_args->table_type        =  (SQLCHAR*)    RSTRING_PTR( r_table_type );
          table_metadata_args->table_type_len    =  (SQLSMALLINT) RSTRING_LEN( r_table_type );
#endif
        }

        table_metadata_args->stmt_res      =  stmt_res;

        #ifdef UNICODE_SUPPORT_VERSION          
		  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLTables_helper, table_metadata_args,
                         (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		  rc = table_metadata_args->rc;
        #else
          rc = _ruby_ibm_db_SQLTables_helper( table_metadata_args );
        #endif

        if (rc == SQL_ERROR ) {

          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                    NULL, NULL, -1, 1, 1 );
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;

          return_value = Qfalse;
        } else {
          return_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            stmt_res);
        } /* SQLTables -> rc == SQL_ERROR       */
      } /*  SQLAllocHandle -> rc == SQL_ERROR  */
    } /*   !conn_res->handle_active           */
  } else {
    return_value = Qfalse;
  }

  /*Free memory allocated*/
  if( table_metadata_args != NULL ) {
    ruby_xfree( table_metadata_args );
    table_metadata_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.commit --  Commits a transaction
 * ===Description
 * bool IBM_DB.commit ( resource connection )
 * 
 * Commits an in-progress transaction on the specified connection resource and begins a new transaction.
 * Ruby applications normally default to AUTOCOMMIT mode, so IBM_DB.commit() is not necessary unless
 * AUTOCOMMIT has been turned off for the connection resource.
 *
 * <b>Note:</b> If the specified connection resource is a persistent connection, all transactions
 * in progress for all applications using that persistent connection will be committed. For this reason,
 * persistent connections are not recommended for use in applications that require transactions. 
 * 
 * ===Parameters
 * 
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect(). 
 * 
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_commit(int argc, VALUE *argv, VALUE self)
{
  VALUE connection = Qnil;
  conn_handle *conn_res;
  int rc;
  end_tran_args *end_X_args = NULL;

  rb_scan_args(argc, argv, "1", &connection);

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }

    end_X_args = ALLOC( end_tran_args );
    memset(end_X_args,'\0',sizeof(struct _ibm_db_end_tran_args_struct));

    end_X_args->hdbc            =  &(conn_res->hdbc);
    end_X_args->handleType      =  SQL_HANDLE_DBC;
    end_X_args->completionType  =  SQL_COMMIT;        /*Remeber you are Commiting the transaction*/

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLEndTran, end_X_args,
                     (void *)_ruby_ibm_db_Connection_level_UBF, NULL);
	  rc = end_X_args->rc;
    #else
      rc = _ruby_ibm_db_SQLEndTran( end_X_args );
    #endif

    /*Free the memory allocated*/
    if(end_X_args != NULL) {
      ruby_xfree( end_X_args );
      end_X_args = NULL;
    }

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
      return Qfalse;
    } else {
      conn_res->transaction_active = 0; 
      return Qtrue;
    }
  }
  return Qfalse;
}
/*  */

/*  static int _ruby_ibm_db_do_prepare(conn_handle *conn_res, VALUE stmt, stmt_handle *stmt_res, 
                                       VALUE options)
*/
static int _ruby_ibm_db_do_prepare(conn_handle *conn_res, VALUE stmt, stmt_handle *stmt_res, 
                                   VALUE options)
{
  int   rc;

  VALUE  error         =  Qnil;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE  stmt_utf16   =  Qnil;
#endif

  exec_cum_prepare_args  *prepare_args  =  NULL;

  /* get the string and its length */
  if ( !NIL_P(stmt) ) {
    prepare_args = ALLOC( exec_cum_prepare_args );
    memset(prepare_args,'\0',sizeof(struct _ibm_db_exec_direct_args_struct));
#ifdef UNICODE_SUPPORT_VERSION
    stmt_utf16                     =  _ruby_ibm_db_export_str_to_utf16(stmt);
    prepare_args->stmt_string      =  (SQLWCHAR*) RSTRING_PTR(stmt_utf16);
    prepare_args->stmt_string_len  =  RSTRING_LEN(stmt_utf16)/sizeof(SQLWCHAR);
#else
    prepare_args->stmt_string      = (SQLCHAR*)rb_str2cstr(stmt, &(prepare_args->stmt_string_len));
#endif
  } else {
    rb_warn("Supplied parameter is invalid");
    stmt_res->is_freed = 1; /* At this point there is no handle allocated or resource used hence is_freed is set to 1*/
    return SQL_ERROR;
  }

  /* alloc handle and return only if it errors */
  rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));

  if ( rc < SQL_SUCCESS ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );

  } else {

    if ( !NIL_P(options) ) {
      rc = _ruby_ibm_db_parse_options( options, SQL_HANDLE_STMT, stmt_res, &error );
      if ( rc == SQL_ERROR ) {
        ruby_xfree( prepare_args );
        prepare_args = NULL;
        rb_warn( RSTRING_PTR(error) );
        return rc;
      }
    }

    prepare_args->stmt_res    =  stmt_res;

    /* Prepare the stmt. The cursor type requested has already been set in _ruby_ibm_db_assign_options */
    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLPrepare_helper, prepare_args,
                     (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	  rc = prepare_args->rc;
    #else
      rc = _ruby_ibm_db_SQLPrepare_helper( prepare_args );
    #endif

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, 
                NULL, NULL, -1, 1, 1 );
    }
  }

  /* Free Allocated Memory */
  if( prepare_args != NULL ) {
    ruby_xfree( prepare_args );
    prepare_args = NULL;
  }

  return rc;
}
/*  */

/*
 * IBM_DB.exec --  Executes an SQL statement directly
 * ===Description
 * resource IBM_DB.exec ( resource connection, string statement [, array options] )
 * 
 * Prepares and executes an SQL statement.
 * 
 * If you plan to interpolate Ruby variables into the SQL statement, understand that this is one of
 * the more common security exposures. Consider calling IBM_DB.prepare() to prepare an SQL statement with
 * parameter markers for input values. Then you can call IBM_DB.execute() to pass in the input values
 * and avoid SQL injection attacks.
 * 
 * If you plan to repeatedly issue the same SQL statement with different parameters, consider calling
 * IBM_DB.prepare() and IBM_DB.execute() to enable the database server to reuse its access plan and increase
 * the efficiency of your database access.
 * ===Parameters
 * 
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect(). 
 * 
 * statement
 *     An SQL statement. The statement cannot contain any parameter markers. 
 * 
 * options
 *     An associative array containing statement options. You can use this parameter to request
 *     a scrollable cursor on database servers that support this functionality.
 * 
 *     cursor
 *         Passing the SQL_SCROLL_FORWARD_ONLY value requests a forward-only cursor for this SQL statement.
 *         This is the default type of cursor, and it is supported by all database servers.
 *         It is also much faster than a scrollable cursor.
 *         Passing the SQL_CURSOR_KEYSET_DRIVEN value requests a scrollable cursor for this SQL statement.
 *         This type of cursor enables you to fetch rows non-sequentially from the database server.
 *         However, it is only supported by DB2 servers, and is much slower than forward-only cursors. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource if the SQL statement was issued successfully, or FALSE if the database failed to execute the SQL statement. 
 */
VALUE ibm_db_exec(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt         =  Qnil;
#ifdef UNICODE_SUPPORT_VERSION
  VALUE stmt_utf16   =  Qnil;
#endif
  VALUE connection   =  Qnil;
  VALUE options      =  Qnil;
  VALUE return_value =  Qnil;

  stmt_handle *stmt_res;
  conn_handle *conn_res;
  exec_cum_prepare_args *exec_direct_args = NULL;

  int rc;
  VALUE error = Qnil;

  /* This function basically is a wrap of the _ruby_ibm_db_do_prepare and _ruby_ibm_db_execute_stmt */
  /* After completing statement execution, it returns the statement resource */
  rb_scan_args(argc, argv, "21", &connection, &stmt, &options);
  

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);
		
    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }
	
	
    if (!NIL_P(stmt)) {
      exec_direct_args = ALLOC( exec_cum_prepare_args );
      memset(exec_direct_args,'\0',sizeof(struct _ibm_db_exec_direct_args_struct));

#ifdef UNICODE_SUPPORT_VERSION
      stmt_utf16                        =  _ruby_ibm_db_export_str_to_utf16(stmt);
      exec_direct_args->stmt_string     =  (SQLWCHAR*)RSTRING_PTR(stmt_utf16);
      exec_direct_args->stmt_string_len =  RSTRING_LEN(stmt_utf16)/sizeof(SQLWCHAR); /*RSTRING_LEN returns number of bytes*/
#else
      exec_direct_args->stmt_string = (SQLCHAR*)rb_str2cstr(stmt, &(exec_direct_args->stmt_string_len));
#endif

    } else {
      rb_warn("Supplied parameter is invalid");
      return Qfalse;
    }
	
    _ruby_ibm_db_clear_stmt_err_cache();

    stmt_res = _ibm_db_new_stmt_struct(conn_res);
	
    /* Allocates the stmt handle */
    /* returns the stat_handle back to the calling function */
    rc = SQLAllocHandle(SQL_HANDLE_STMT, conn_res->hdbc, &(stmt_res->hstmt));
    if ( rc < SQL_SUCCESS ) {
      _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
      ruby_xfree( stmt_res );
      stmt_res = NULL;
      return_value = Qfalse;
    } else {

      if (!NIL_P(options)) {
        rc = _ruby_ibm_db_parse_options( options, SQL_HANDLE_STMT, stmt_res, &error );
        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_free_stmt_struct( stmt_res );
          stmt_res = NULL;
          ruby_xfree( exec_direct_args );
          exec_direct_args = NULL;
          rb_warn( RSTRING_PTR(error) );
          return Qfalse;
        }
      }

      conn_res->transaction_active = 1; /*A transaction begins with prepare of exec*/

      exec_direct_args->stmt_res    =  stmt_res;

	  
      #ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLExecDirect_helper, exec_direct_args,
                       (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		rc = exec_direct_args->rc;
      #else
        rc = _ruby_ibm_db_SQLExecDirect_helper( exec_direct_args );
      #endif
		
      if ( rc == SQL_ERROR ) {

        _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, stmt_res->hstmt, 
                  SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
        _ruby_ibm_db_free_stmt_struct( stmt_res );
        stmt_res = NULL;

        return_value = Qfalse;
      } else {
        return_value = Data_Wrap_Struct(le_stmt_struct,
          _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
          stmt_res);
      }
    }
  }
  /*Free memory allocated*/
  if( exec_direct_args != NULL ) {
    ruby_xfree( exec_direct_args );
    exec_direct_args = NULL;
  }
  return return_value;
}
/*  */

/*
 * IBM_DB.free_result --  Frees resources associated with a result set
 * 
 * ===Description
 * bool IBM_DB.free_result ( resource stmt )
 * 
 * Frees the system and database resources that are associated with a result set. These resources
 * are freed implicitly when a script finishes, but you can call IBM_DB.free_result() to explicitly
 * free the result set resources before the end of the script.
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid statement resource. 
 * 
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_free_result(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt   =  Qnil;
  int   rc     =  0;

  stmt_handle         *stmt_res       =  NULL;
  free_stmt_args      *freeStmt_args  =  NULL;

#ifdef UNICODE_SUPPORT_VERSION
  char                *err_str        =  NULL;
#endif

  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
    if ( stmt_res->hstmt ) {
      freeStmt_args = ALLOC( free_stmt_args  );
      memset(freeStmt_args, '\0', sizeof( struct _ibm_db_free_stmt_struct ) );

      freeStmt_args->stmt_res  =  stmt_res;
      freeStmt_args->option    =  SQL_CLOSE;

      #ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLFreeStmt_helper, freeStmt_args, 
                       (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		rc = freeStmt_args->rc;
      #else
        rc = _ruby_ibm_db_SQLFreeStmt_helper( freeStmt_args );
      #endif

      ruby_xfree( freeStmt_args );
      freeStmt_args = NULL;

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
#ifdef UNICODE_SUPPORT_VERSION
        err_str = RSTRING_PTR(
                    _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                      stmt_res->ruby_stmt_err_msg_len )
                  );
        rb_warn( "Statement Free Failed: %s", err_str );
#else
        rb_warn( "Statement Free Failed: %s", (char *) stmt_res->ruby_stmt_err_msg);
#endif
        return Qfalse;
      }
    }
    _ruby_ibm_db_free_result_struct( stmt_res );
  } else {
    rb_warn("Supplied parameter is invalid");
    return Qfalse;
  }
  return Qtrue;
}
/*  */

/*
 * IBM_DB.prepare --  Prepares an SQL statement to be executed
 * 
 * ===Description
 * resource IBM_DB.prepare ( resource connection, string statement [, array options] )
 * 
 * IBM_DB.prepare() creates a prepared SQL statement which can include 0 or more parameter markers
 * (? characters) representing parameters for input, output, or input/output. You can pass parameters
 * to the prepared statement using IBM_DB.bind_param(), or for input values only, as an array passed to
 * IBM_DB.execute().
 * 
 * There are three main advantages to using prepared statements in your application:
 *     * Performance: when you prepare a statement, the database server creates an optimized access plan
 *       for retrieving data with that statement. Subsequently issuing the prepared statement with
 *       IBM_DB.execute() enables the statements to reuse that access plan and avoids the overhead of dynamically
 *       creating a new access plan for every statement you issue.
 *     * Security: when you prepare a statement, you can include parameter markers for input values.
 *       When you execute a prepared statement with input values for placeholders, the database server checks
 *       each input value to ensure that the type matches the column definition or parameter definition.
 *     * Advanced functionality: Parameter markers not only enable you to pass input values to prepared
 *       SQL statements, they also enable you to retrieve OUT and INOUT parameters from stored procedures
 *       using IBM_DB.bind_param(). 
 * 
 * ===Parameters
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect(). 
 * 
 * statement
 *     An SQL statement, optionally containing one or more parameter markers.. 
 * 
 * options
 *     An associative array containing statement options. You can use this parameter to request a
 *     scrollable cursor on database servers that support this functionality.
 * 
 *     cursor
 *         Passing the SQL_SCROLL_FORWARD_ONLY value requests a forward-only cursor for this SQL statement.
 *         This is the default type of cursor, and it is supported by all database servers. It is also
 *         much faster than a scrollable cursor.
 *         Passing the SQL_CURSOR_KEYSET_DRIVEN value requests a scrollable cursor for this SQL statement. 
 *         This type of cursor enables you to fetch rows non-sequentially from the database server.
 *         However, it is only supported by DB2 servers, and is much slower than forward-only cursors. 
 * 
 * ===Return Values
 * 
 * Returns a statement resource if the SQL statement was successfully parsed and prepared by the database server. Returns FALSE if the database server returned an error. 
 * You can determine which error was returned by calling IBM_DB.getErrormsg() or IBM_DB.getErrorState() with resource type connection. 
 */
VALUE ibm_db_prepare(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt         =  Qnil;
  VALUE connection   =  Qnil;
  VALUE options      =  Qnil;
  VALUE return_value =  Qnil;

  conn_handle *conn_res;
  stmt_handle *stmt_res;

#ifdef UNICODE_SUPPORT_VERSION
  char *err_str  =  NULL;
#endif

  int rc;

  rb_scan_args(argc, argv, "21", &connection, &stmt, &options);

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }

    _ruby_ibm_db_clear_stmt_err_cache();

    /* Initialize stmt resource members with default values. */
    /* Parsing will update options if needed */

    stmt_res = _ibm_db_new_stmt_struct(conn_res);

    conn_res->transaction_active = 1; /*A transaction begins with prepare of exec*/

    /* Allocates the stmt handle */
    /* Prepares the statement */
    /* returns the stat_handle back to the calling function */
    rc = _ruby_ibm_db_do_prepare( conn_res, stmt, stmt_res, options );

    if ( rc < SQL_SUCCESS ) {
      _ruby_ibm_db_free_stmt_struct(stmt_res);
      stmt_res = NULL;

#ifdef UNICODE_SUPPORT_VERSION
      err_str = RSTRING_PTR( _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( conn_res->ruby_error_msg,
                                          DB2_MAX_ERR_MSG_LEN * sizeof(SQLWCHAR) )
                           );
      rb_warn("Statement Prepare Failed: %s", err_str );
#else
      rb_warn("Statement Prepare Failed: %s", (char *) conn_res->ruby_error_msg);
#endif

      return_value = Qfalse;
    } else {
      return_value = Data_Wrap_Struct(le_stmt_struct,
          _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
          stmt_res);
    }
  }

  return return_value;
}
/*  */

/*  static param_node* build_list( stmt_res, param_no, data_type, precision, scale, nullable )
*/
static param_node* build_list( stmt_handle *stmt_res, int param_no, SQLSMALLINT data_type, SQLUINTEGER precision, SQLSMALLINT scale, SQLSMALLINT nullable )
{
  param_node *tmp_curr = NULL, *curr = stmt_res->head_cache_list, *prev = NULL;

  /* Allocate memory and make new node to be added */
  tmp_curr = ALLOC(param_node);
  memset(tmp_curr,'\0',sizeof(param_node));
  /* assign values */
  tmp_curr->data_type    =  data_type;
  tmp_curr->param_size   =  precision;
  tmp_curr->nullable     =  nullable;
  tmp_curr->scale        =  scale;
  tmp_curr->param_num    =  param_no;
  tmp_curr->file_options =  SQL_FILE_READ;
  tmp_curr->param_type   =  SQL_PARAM_INPUT;
  tmp_curr->varname      =  NULL;
  tmp_curr->svalue       =  NULL;

  while ( curr != NULL ) {
    prev = curr;
    curr = curr->next;
  }

  if (stmt_res->head_cache_list == NULL) {
    stmt_res->head_cache_list = tmp_curr;
  } else {
    prev->next = tmp_curr;
  }

  tmp_curr->next = curr;

  return tmp_curr;
}

/*
   static int _ruby_ibm_db_bind_parameter_helper(stmt_handle *stmt_res, param_node *curr, VALUE *bind_data)
   This function sets different parameters that needs to be passed to SQLBindparamter cli call
   with appropriate values depending on the type of data value passed and the column type
*/
static int _ruby_ibm_db_bind_parameter_helper(stmt_handle *stmt_res, param_node *curr, VALUE *bind_data) {
  int rc;
  int origlen       = 0;
  int is_known_type = 1;
#ifdef UNICODE_SUPPORT_VERSION
  int is_binary     = 0; /*Indicates if the column is either SQL_BLOB, SQL_BINARY, SQL_VARBINARY or SQL_LONGVARBINARY*/
#endif

  SQLPOINTER  tmp_str;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE    bindData_utf16;
  VALUE    tmpBuff;
#endif

  SQLSMALLINT valueType;
  SQLPOINTER  paramValuePtr;

  bind_parameter_args  *bindParameter_args = NULL;

  bindParameter_args =  ALLOC( bind_parameter_args );
  memset(bindParameter_args,'\0',sizeof(struct _ibm_db_bind_parameter_struct));

  bindParameter_args->stmt_res       =  stmt_res;
  bindParameter_args->param_num      =  curr->param_num;
  bindParameter_args->IOType         =  curr->param_type;
  bindParameter_args->paramType      =  curr->data_type;
  bindParameter_args->colSize        =  curr->param_size;
  bindParameter_args->decimalDigits  =  curr->scale;

  switch(TYPE(*bind_data)) {
    case T_BIGNUM:
#ifdef UNICODE_SUPPORT_VERSION
      tmpBuff      =  rb_big2str(*bind_data,10);
      tmp_str      =  (SQLCHAR *) RSTRING_PTR(tmpBuff);
      curr->ivalue =  RSTRING_LEN(tmpBuff);
#else
      tmp_str = (SQLCHAR *) rb_str2cstr( rb_big2str(*bind_data,10), (long*)&curr->ivalue );
#endif

      curr->svalue = (SQLCHAR *) ALLOC_N(char, curr->ivalue+1);
      memset(curr->svalue, '\0', curr->ivalue+1);
      memcpy(curr->svalue, tmp_str, curr->ivalue);

      bindParameter_args->valueType    =  SQL_C_CHAR;
      bindParameter_args->paramValPtr  =  curr->svalue;
      bindParameter_args->buff_length  =  0;
      bindParameter_args->out_length   =  NULL;

      rc = _ruby_ibm_db_SQLBindParameter_helper( bindParameter_args );

      break;

    case T_FIXNUM:
      curr->ivalue = FIX2LONG( *bind_data );
      if(curr->data_type == SQL_BIGINT) {
        valueType = SQL_C_DEFAULT;
      } else {
        valueType = SQL_C_SBIGINT;
      }

      bindParameter_args->valueType    =  valueType;
      bindParameter_args->paramValPtr  =  &curr->ivalue;
      bindParameter_args->buff_length  =  0;
      bindParameter_args->out_length   =  NULL;

      rc = _ruby_ibm_db_SQLBindParameter_helper( bindParameter_args );

      curr->data_type = SQL_C_LONG;
      break;

    /* Convert BOOLEAN types to LONG for DB2 / Cloudscape */
    case T_FALSE:
      curr->ivalue = 0;

      bindParameter_args->valueType    =  SQL_C_SBIGINT;
      bindParameter_args->paramValPtr  =  &curr->ivalue;
      bindParameter_args->buff_length  =  0;
      bindParameter_args->out_length   =  NULL;

      rc = _ruby_ibm_db_SQLBindParameter_helper( bindParameter_args );

      curr->data_type = SQL_C_LONG;
      break;

    case T_TRUE:
      curr->ivalue = 1;

      bindParameter_args->valueType    =  SQL_C_SBIGINT;
      bindParameter_args->paramValPtr  =  &curr->ivalue;
      bindParameter_args->buff_length  =  0;
      bindParameter_args->out_length   =  NULL;

      rc = _ruby_ibm_db_SQLBindParameter_helper( bindParameter_args );

      curr->data_type = SQL_C_LONG;
      break;

    case T_FLOAT:
      curr->fvalue = NUM2DBL( *bind_data );

      bindParameter_args->valueType    =  SQL_C_DOUBLE;
      bindParameter_args->paramValPtr  =  &curr->fvalue;
      bindParameter_args->buff_length  =  0;
      bindParameter_args->out_length   =  NULL;

      rc = _ruby_ibm_db_SQLBindParameter_helper( bindParameter_args );

      curr->data_type = SQL_C_DOUBLE;
      break;

    case T_STRING:
#ifdef UNICODE_SUPPORT_VERSION
     if( curr->data_type == SQL_BLOB || curr->data_type == SQL_LONGVARBINARY || curr->data_type == SQL_VARBINARY ||
           curr->data_type == SQL_BINARY || curr->data_type == SQL_XML ){
       is_binary = 1;
     } else {
       is_binary = 0;
     }

     if( is_binary ){
       tmp_str = (SQLCHAR *) RSTRING_PTR( *bind_data );
       origlen = curr->ivalue = RSTRING_LEN( *bind_data );
     } else {
       bindData_utf16 = _ruby_ibm_db_export_str_to_utf16( *bind_data );
       tmp_str = (SQLWCHAR *) RSTRING_PTR( bindData_utf16 );
       origlen = curr->ivalue = RSTRING_LEN( bindData_utf16 );
     } 
#else
      tmp_str = (SQLCHAR *) rb_str2cstr( *bind_data, (long*) &curr->ivalue );
      origlen = curr->ivalue;
#endif
      if (curr->param_type == SQL_PARAM_OUTPUT || curr->param_type == SQL_PARAM_INPUT_OUTPUT) {
        /*
         * An extra parameter is given by the client to pick the size of the string
         * returned.  The string is then truncate past that size.  If no size is
         * given then use BUFSIZ to return the string.
         */
        if ( curr->size <= 0 ) {
#ifdef UNICODE_SUPPORT_VERSION
          if( is_binary ) {
            if (curr->ivalue < curr->param_size ) {
              curr->ivalue = curr->param_size;
            }
          } else {
            if (curr->ivalue < ( (curr->param_size + 1) * sizeof(SQLWCHAR) ) ) {
              curr->ivalue = (curr->param_size + 1)* sizeof(SQLWCHAR);
            }
          }
#else
          if (curr->ivalue < curr->param_size ) {
            curr->ivalue = curr->param_size + 1;
          }

          if ( curr->data_type == SQL_GRAPHIC || curr->data_type == SQL_VARGRAPHIC ){
           /* graphic strings are 2 byte characters.
            * Not required for unicode support, as datatype is w equivalent of char.
           */
           curr->ivalue = curr->ivalue * 2; 
          }
#endif
        } else {
          if( curr->param_type == SQL_PARAM_INPUT_OUTPUT ) {
#ifdef UNICODE_SUPPORT_VERSION
            if( is_binary ) {
              if( curr->size > curr->ivalue ) {
                curr->ivalue = curr->size + 1;
              }
            } else {
              if( ( curr->size * sizeof(SQLWCHAR) ) > curr->ivalue ) {
                curr->ivalue = curr->size * sizeof(SQLWCHAR) + 2;
              }
            }
#else
            if( curr->size > curr->ivalue ) {
              curr->ivalue = curr->size + 1;
            }
            if ( curr->data_type == SQL_GRAPHIC || curr->data_type == SQL_VARGRAPHIC ){
             /* graphic strings are 2 byte characters.
              * Not required for unicode support, as datatype is w equivalent of char.
              */
             curr->ivalue = curr->ivalue * 2;
            }
#endif
          } else {
#ifdef UNICODE_SUPPORT_VERSION
              if( is_binary ) {
                curr->ivalue = curr->size + 1;
              } else {
                curr->ivalue = curr->size * sizeof(SQLWCHAR) + 2;
              }
#else
              curr->ivalue = curr->size + 1;
              if ( curr->data_type == SQL_GRAPHIC || curr->data_type == SQL_VARGRAPHIC ){
               /* graphic strings are 2 byte characters.
                * Not required for unicode support, as datatype is w equivalent of char.
                */
               curr->ivalue = curr->ivalue * 2;
              }
#endif
          }
        }
      }

#ifdef UNICODE_SUPPORT_VERSION
      if( is_binary ){
        curr->svalue  = (SQLCHAR *) ALLOC_N(SQLCHAR, curr->ivalue);
      } else {
        /*char is passed to ALLOC_N because curr->ivalue contains the size required in bytes.*/
        curr->svalue  = (SQLWCHAR *) ALLOC_N(SQLCHAR, curr->ivalue);
      }
#else
      curr->svalue    = (SQLCHAR *) ALLOC_N(SQLCHAR, curr->ivalue);
#endif
      memset(curr->svalue, '\0', curr->ivalue);
      memcpy(curr->svalue, tmp_str, origlen);

      switch ( curr->data_type ) {
        case SQL_CLOB:
          if ( curr->param_type == SQL_PARAM_OUTPUT ) {
            curr->bind_indicator             =  curr->ivalue;
            bindParameter_args->buff_length  =  curr->ivalue;
            paramValuePtr                    =  (SQLPOINTER)curr->svalue;
          } else if (curr->param_type == SQL_PARAM_INPUT_OUTPUT) {
            curr->bind_indicator             =  origlen;
            bindParameter_args->buff_length  =  curr->ivalue;
            paramValuePtr                    =  (SQLPOINTER)curr->svalue;
          } else {
            curr->bind_indicator = SQL_DATA_AT_EXEC;
            /* The correct dataPtr will be set during SQLPutData with the len from this struct */
#ifndef PASE
            paramValuePtr  = (SQLPOINTER)(curr);
#else
            paramValuePtr  = (SQLPOINTER)&(curr);
#endif
          }
#ifdef UNICODE_SUPPORT_VERSION
            valueType = SQL_C_WCHAR;
#else
            valueType = SQL_C_CHAR;
#endif
          break;

        case SQL_BLOB:
          if (curr->param_type == SQL_PARAM_OUTPUT || curr->param_type == SQL_PARAM_INPUT_OUTPUT) {
            curr->bind_indicator             = curr->ivalue;
            bindParameter_args->buff_length  = curr->ivalue;
            paramValuePtr                    = (SQLPOINTER)curr->svalue;
          } else {
            curr->bind_indicator = SQL_DATA_AT_EXEC;
#ifndef PASE
            paramValuePtr = (SQLPOINTER)(curr);
#else
            paramValuePtr = (SQLPOINTER)&(curr);
#endif
          }
          valueType =  SQL_C_BINARY;
          break;

        case SQL_BINARY:
#ifndef PASE /* i5/OS SQL_LONGVARBINARY is SQL_VARBINARY */
        case SQL_LONGVARBINARY:
#endif /* PASE */
        case SQL_VARBINARY:
        case SQL_XML:
         /* account for bin_mode settings as well */
          curr->bind_indicator             =  curr->ivalue;
          valueType                        =  SQL_C_BINARY;
          bindParameter_args->buff_length  =  curr->ivalue;
          paramValuePtr                    =  (SQLPOINTER)curr->svalue;
          break;

        /* This option should handle most other types such as DATE, VARCHAR etc */
        default:
          if ( curr->param_type == SQL_PARAM_INPUT_OUTPUT ) {
            curr->bind_indicator             =  origlen;
          } else {
            if( curr->param_type == SQL_PARAM_INPUT && 
                (curr->data_type == SQL_GRAPHIC || curr->data_type == SQL_VARGRAPHIC)){
              curr->bind_indicator             =  origlen;
            } else {
              curr->bind_indicator             =  curr->ivalue;
            }
          }
          bindParameter_args->buff_length  =  curr->ivalue;
#ifdef UNICODE_SUPPORT_VERSION
          valueType = SQL_C_WCHAR;
#else
          valueType = SQL_C_CHAR;
#endif
          paramValuePtr = (SQLPOINTER)(curr->svalue);
      }

      bindParameter_args->valueType    =  valueType;
      bindParameter_args->paramValPtr  =  paramValuePtr;
      bindParameter_args->out_length   =  &(curr->bind_indicator);

      rc = _ruby_ibm_db_SQLBindParameter_helper( bindParameter_args );

      break;

    case T_NIL:
      curr->ivalue = SQL_NULL_DATA;
      curr->bind_indicator = SQL_NULL_DATA;

      bindParameter_args->valueType    =  SQL_C_DEFAULT;
      bindParameter_args->paramValPtr  =  &curr->ivalue;
      bindParameter_args->buff_length  =  0;
      bindParameter_args->out_length   =  &(curr->bind_indicator);

      rc = _ruby_ibm_db_SQLBindParameter_helper( bindParameter_args );

      break;

    default:
      is_known_type = 0;
      rc = SQL_ERROR;
  }

  if ( rc == SQL_ERROR && is_known_type == 1 ) {
     _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
  }

  /*Free Memory Allocated*/
  if( bindParameter_args != NULL ) {
    ruby_xfree( bindParameter_args );
    bindParameter_args  =  NULL;
  }
  return rc;
}

/*  */

/*  static int _ruby_ibm_db_bind_data( stmt_handle *stmt_res, param_node *curr, VALUE *bind_data )
*/
static int _ruby_ibm_db_bind_data( stmt_handle *stmt_res, param_node *curr, VALUE *bind_data)
{
  int rc;

  /* Have to use SQLBindFileToParam if PARAM is type PARAM_FILE */
  if ( curr->param_type == PARAM_FILE) {
    /* Only string types can be bound */
    if ( TYPE(*bind_data) != T_STRING) {
      return SQL_ERROR;
    }
    curr->bind_indicator  =  0;

#ifdef UNICODE_SUPPORT_VERSION
    curr->svalue          =  (SQLCHAR *) RSTRING_PTR(*bind_data);
    curr->ivalue          =  RSTRING_LEN(*bind_data);
#else
    curr->svalue          =  (SQLCHAR *) rb_str2cstr(*bind_data, (long*) &curr->ivalue);
#endif

    /* Bind file name string */
    rc = _ruby_ibm_db_SQLBindFileToParam_helper(stmt_res, curr);

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
    }

    return rc;
  }

  rc = _ruby_ibm_db_bind_parameter_helper(stmt_res, curr, bind_data);

  return rc;
}
/*
  static int _ruby_ibm_db_bind_param_list(stmt_handle *stmt_res, VALUE *error)
*/
static int _ruby_ibm_db_bind_param_list(stmt_handle *stmt_res, VALUE *error ) {
  int rc;
  VALUE bind_data;          /* Data value from symbol table */
  param_node *curr = NULL;  /* To traverse the list */

  /* Bind the complete list sequentially */
  /* Used when no parameters array is passed in */
  curr = stmt_res->head_cache_list;

  while (curr != NULL ) {
    /* Fetch data from symbol table */
    bind_data = rb_eval_string(curr->varname);

    rc  = _ruby_ibm_db_bind_data( stmt_res, curr, &bind_data);

    if ( rc == SQL_ERROR ) {
      if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Binding Error 1: "),
                   _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                stmt_res->ruby_stmt_err_msg_len )
                 );
#else
        *error = rb_str_cat2(rb_str_new2("Binding Error 1: "), stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        *error = _ruby_ibm_db_export_char_to_utf8_rstr("Binding Error 1: <error message could not be retrieved>");
#else
        *error = rb_str_new2("Binding Error 1: <error message could not be retrieved>");
#endif
      }
      return rc;
    }
    curr = curr->next;
  }

  return 0;
}
/*  */

/*  static int _ruby_ibm_db_execute_helper2(stmt_res, data, int bind_cmp_list, int bind_params, VALUE *error )
  */
static int _ruby_ibm_db_execute_helper2(stmt_handle *stmt_res, VALUE *data, int bind_cmp_list, 
                                        int bind_params, VALUE *error )
{
	
  int rc            =  SQL_SUCCESS;
  param_node *curr  =  NULL;  /* To traverse the list */

  describeparam_args *desc_param_args  =  NULL;

  /* This variable means that we bind the complete list of params cached */
  /* The values used are fetched from the active symbol table */
  /* TODO: Enhance this part to check for stmt_res->file_param */
  /* If this flag is set, then use SQLBindParam, else use SQLExtendedBind */
  if ( bind_cmp_list ) {

    return _ruby_ibm_db_bind_param_list( stmt_res, error );

  } else {

    /* Bind only the data value passed in to the Current Node */
    if ( data != NULL ) {
      if ( bind_params ) {

        /*
          This condition applies if the parameter has not been
          bound using IBM_DB.bind_param. Need to describe the
          parameter and then bind it.
        */

        desc_param_args = ALLOC( describeparam_args );
        memset(desc_param_args,'\0',sizeof(struct _ibm_db_describeparam_args_struct));

        desc_param_args->param_no          =  ++stmt_res->num_params;
        desc_param_args->sql_data_type     =  0;
        desc_param_args->sql_precision     =  0;
        desc_param_args->sql_scale         =  0;
        desc_param_args->sql_nullable      =  SQL_NO_NULLS;
        desc_param_args->stmt_res          =  stmt_res;

        rc = _ruby_ibm_db_SQLDescribeParam_helper( desc_param_args );


        if ( rc == SQL_ERROR ) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
          if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
            *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr( "Describe Param Failed: " ),
                       _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                    stmt_res->ruby_stmt_err_msg_len )
                     );
#else
            *error = rb_str_cat2(rb_str_new2("Describe Param Failed: "), stmt_res->ruby_stmt_err_msg );
#endif
          } else {
#ifdef UNICODE_SUPPORT_VERSION
            *error = _ruby_ibm_db_export_char_to_utf8_rstr("Describe Param Failed: <error message could not be retrieved>");
#else
            *error = rb_str_new2("Describe Param Failed: <error message could not be retrieved>");
#endif
          }

          if(desc_param_args != NULL) {
            ruby_xfree( desc_param_args );
            desc_param_args = NULL;
          }

          return rc;
        }

        curr = build_list( stmt_res, desc_param_args->param_no, desc_param_args->sql_data_type, 
                    desc_param_args->sql_precision, desc_param_args->sql_scale, desc_param_args->sql_nullable );

        if(desc_param_args != NULL) {
           ruby_xfree( desc_param_args );
           desc_param_args = NULL;
        }

        rc = _ruby_ibm_db_bind_data( stmt_res, curr, data );

        if ( rc == SQL_ERROR ) {
          if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
            *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Binding Error 2: "),
                       _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                    stmt_res->ruby_stmt_err_msg_len )
                     );
#else
            *error = rb_str_cat2(rb_str_new2("Binding Error 2: "), stmt_res->ruby_stmt_err_msg );
#endif
          } else {
#ifdef UNICODE_SUPPORT_VERSION
            *error = _ruby_ibm_db_export_char_to_utf8_rstr("Binding Error 2: <error message could not be retrieved>");
#else
            *error = rb_str_new2("Binding Error 2: <error message could not be retrieved>");
#endif
          }
          return rc;
        }
      } else {
        /*
          This is always at least the head_cache_node -- assigned in
          IBM_DB.execute(), if params have been bound.
        */
        curr = stmt_res->current_node;

        if ( curr != NULL ) {

          rc  =  _ruby_ibm_db_bind_data( stmt_res, curr, data);

          if ( rc == SQL_ERROR ) {
            if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
              *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Binding Error 2: "),
                       _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                    stmt_res->ruby_stmt_err_msg_len )
                     );
#else
              *error = rb_str_cat2(rb_str_new2("Binding Error 2: "), stmt_res->ruby_stmt_err_msg );
#endif
            } else {
#ifdef UNICODE_SUPPORT_VERSION
              *error = _ruby_ibm_db_export_char_to_utf8_rstr("Binding Error 2: <error message could not be retrieved>");
#else
              *error = rb_str_new2("Binding Error 2: <error message could not be retrieved>");
#endif
            }
            return rc;
          }
          stmt_res->current_node  =  curr->next;
        }
      }
      return rc;
    }
  }
  return rc;
}
/*  */

void var_assign(char *name, VALUE value) {
#ifdef TODO
  /* this compiles and links, but fails to resolve at runtime */
  rb_dvar_asgn(rb_intern(name_id), value);
#else
  /* so we do it the hard way */
  ID inspect; 
  char *expr, *statement;
  long expr_len;

  inspect   =  rb_intern("inspect");
  value     =  rb_funcall(value, inspect, 0);

#ifdef UNICODE_SUPPORT_VERSION
  expr      =  RSTRING_PTR(value);
  expr_len  =  RSTRING_LEN(value);
#else
  expr      =  rb_str2cstr(value, &expr_len);
#endif

  statement =  ALLOC_N(char, strlen(name)+1+expr_len+1);
  strcpy(statement, name);
  strcat(statement, "=");
  strcat(statement, expr);
  rb_eval_string( statement );
  ruby_xfree( statement );
  statement = NULL;
#endif

}

/* 
  static VALUE _ruby_ibm_db_desc_and_bind_param_list(stmt_bind_array *bind_array, VALUE *error)
*/
static VALUE _ruby_ibm_db_desc_and_bind_param_list(stmt_bind_array *bind_array, VALUE *error ) {
  int rc, numOpts, i = 0;

  VALUE data;

  if ( bind_array->stmt_res->head_cache_list == NULL ) {
    bind_array->bind_params = 1;
  }

  numOpts = RARRAY_LEN(*(bind_array->parameters_array));

  if (numOpts > bind_array->num) {
    /* More are passed in -- Warning - Use the max number present */
    rb_warn("Number of params passed in are more than bound parameters");
    numOpts = bind_array->num;
  } else if (numOpts < bind_array->num) {
    /* If there are less params passed in, than are present -- Error */
#ifdef UNICODE_SUPPORT_VERSION
    *error = _ruby_ibm_db_export_char_to_utf8_rstr("Number of params passed in are less than bound parameters");
#else
    *error = rb_str_new2("Number of params passed in are less than bound parameters");
#endif
    return Qnil;
  }

  for ( i = 0; i < numOpts; i++) {
    /* Bind values from the parameters_array to params */
    data = rb_ary_entry(*(bind_array->parameters_array),i);

    /*
     The 0 denotes that you work only with the current node.
     The 4th argument specifies whether the data passed in
     has been described. So we need to call SQLDescribeParam
     before binding depending on this.
    */

    rc  =  _ruby_ibm_db_execute_helper2(bind_array->stmt_res, &data, 0, bind_array->bind_params, error );

    if ( rc == SQL_ERROR) {
      return Qnil;
    }
  }
  return Qtrue;
}
/*  static int _ruby_ibm_db_execute_helper(stmt_res, data, int bind_cmp_list)
*/
static VALUE _ruby_ibm_db_execute_helper(stmt_bind_array *bind_array) {
  VALUE        ret_value = Qtrue;
  stmt_handle  *stmt_res = NULL;

  VALUE *error;
  int rc = 0;

  SQLSMALLINT              num                       =  0;
  param_cum_put_data_args  *put_param_data_args      =  NULL;
  row_col_count_args       *num_params_args          =  NULL;
  free_stmt_args           *freeStmt_args            =  NULL;

  stmt_res =  bind_array->stmt_res;
  error    =  bind_array->error;

  /* Free any cursors that might have been allocated in a previous call to SQLExecute */

  freeStmt_args = ALLOC( free_stmt_args );
  memset(freeStmt_args, '\0', sizeof( struct _ibm_db_free_stmt_struct ) );

  freeStmt_args->stmt_res  =  stmt_res;
  freeStmt_args->option    =  SQL_CLOSE;

  _ruby_ibm_db_SQLFreeStmt_helper( freeStmt_args );

  ruby_xfree( freeStmt_args );
  freeStmt_args = NULL;

  num_params_args = ALLOC( row_col_count_args );
  memset(num_params_args,'\0',sizeof(struct _ibm_db_row_col_count_struct));

  num_params_args->stmt_res  =  stmt_res;
  num_params_args->count     =  0;

  rc   =  _ruby_ibm_db_SQLNumParams_helper( num_params_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
    ruby_xfree( num_params_args );
    num_params_args = NULL;
    if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
      *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Execute Failed due to: "),
                 _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg, 
                              stmt_res->ruby_stmt_err_msg_len )
               );
#else
      *error = rb_str_cat2(rb_str_new2("Execute Failed due to: "), stmt_res->ruby_stmt_err_msg );
#endif
    } else {
#ifdef UNICODE_SUPPORT_VERSION
      *error = _ruby_ibm_db_export_char_to_utf8_rstr("Execute Failed due to: <error message could not be retrieved>");
#else
      *error = rb_str_new2("Execute Failed due to: <error message could not be retrieved>");
#endif
    }
	bind_array->return_value = Qnil;
    return Qnil;
  }

  num  =  num_params_args->count;

  ruby_xfree( num_params_args );
  num_params_args = NULL;

  if ( num != 0 ) {

    bind_array->num = num;

    /* Parameter Handling */
    if ( !NIL_P( *(bind_array->parameters_array) ) ) {
      /* Make sure IBM_DB.bind_param has been called */
      /* If the param list is NULL -- ERROR */
      if (TYPE( *(bind_array->parameters_array) ) != T_ARRAY) {
#ifdef UNICODE_SUPPORT_VERSION
        *error = _ruby_ibm_db_export_char_to_utf8_rstr("Param is not an array");
#else
        *error = rb_str_new2("Param is not an array");
#endif
        bind_array->return_value = Qnil;
        return Qnil;
      }

      ret_value  =  _ruby_ibm_db_desc_and_bind_param_list(bind_array, error );

      if(ret_value == Qnil ) {
		bind_array->return_value = Qnil;
        return Qnil;
      }
      if(ret_value == Qfalse) {
		bind_array->return_value = Qfalse;
        return Qfalse;
      }

    } else {

      /* No additional params passed in. Use values already bound. */
      if ( num > stmt_res->num_params ) {
        /* More parameters than we expected */
#ifdef UNICODE_SUPPORT_VERSION
        *error = _ruby_ibm_db_export_char_to_utf8_rstr("Number of params passed are more than bound parameters");
#else
        *error = rb_str_new2("Number of params passed are more than bound parameters");
#endif
		bind_array->return_value = Qnil;
        return Qnil;
      } else if ( num < stmt_res->num_params ) {
        /* Fewer parameters than we expected */
#ifdef UNICODE_SUPPORT_VERSION
        *error = _ruby_ibm_db_export_char_to_utf8_rstr("Number of params passed are less than bound parameters");
#else
        *error = rb_str_new2("Number of params passed are less than bound parameters");
#endif
		bind_array->return_value = Qnil;
        return Qnil;
      }

      /* Param cache node list is empty -- No params bound */
      if ( stmt_res->head_cache_list == NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        *error = _ruby_ibm_db_export_char_to_utf8_rstr("Parameters not bound");
#else
        *error = rb_str_new2("Parameters not bound");
#endif
		bind_array->return_value = Qnil;
        return Qnil;
      } else {
        /* The 1 denotes that you work with the whole list */
        /* And bind sequentially */

        rc  =  _ruby_ibm_db_execute_helper2(stmt_res, NULL, 1, 0, error );

        if ( rc == SQL_ERROR ) {
		  bind_array->return_value = Qnil;
          return Qnil;
        }
      }
    }
  }

  /* Execute Stmt -- All parameters (if any) bound */
  rc  =  _ruby_ibm_db_SQLExecute_helper( stmt_res );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
    if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
      *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Statement Execute Failed: "),
                 _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                              stmt_res->ruby_stmt_err_msg_len )
               );
#else
      *error = rb_str_cat2(rb_str_new2("Statement Execute Failed: "), stmt_res->ruby_stmt_err_msg );
#endif
    } else {
#ifdef UNICODE_SUPPORT_VERSION
      *error = _ruby_ibm_db_export_char_to_utf8_rstr("Statement Execute Failed: <error message could not be retrieved>");
#else
      *error = rb_str_new2("Statement Execute Failed: <error message could not be retrieved>");
#endif
    }
	bind_array->return_value = Qnil;
    return Qnil;
  }

  if ( rc == SQL_NEED_DATA ) {

    put_param_data_args = ALLOC( param_cum_put_data_args );
    memset(put_param_data_args,'\0',sizeof(struct _ibm_db_param_and_put_data_struct));

    put_param_data_args->stmt_res  =  stmt_res;

    rc = _ruby_ibm_db_SQLParamData_helper( put_param_data_args );
    while ( rc == SQL_NEED_DATA ) {

      /* passing data value for a parameter */
      rc  = _ruby_ibm_db_SQLPutData_helper(put_param_data_args);

      if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
        if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr( "Sending data failed: "),
                     _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                  stmt_res->ruby_stmt_err_msg_len )
                   );
#else
          *error = rb_str_cat2(rb_str_new2("Sending data failed: "), stmt_res->ruby_stmt_err_msg );
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          *error = _ruby_ibm_db_export_char_to_utf8_rstr("Sending data failed: <error message could not be retrieved>");
#else
          *error = rb_str_new2("Sending data failed: <error message could not be retrieved>");
#endif
        }

        if (put_param_data_args != NULL) {
          ruby_xfree( put_param_data_args );
          put_param_data_args = NULL;
        }
		bind_array->return_value = Qnil;
        return Qnil;
      }
	  rc = _ruby_ibm_db_SQLParamData_helper( put_param_data_args );
    }

    if (put_param_data_args != NULL) {
      ruby_xfree( put_param_data_args );
      put_param_data_args = NULL;
    }

    if ( rc == SQL_ERROR ) {
        _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
      if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        *error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr( "Sending data failed: "),
                   _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                  stmt_res->ruby_stmt_err_msg_len )
                 );
#else
        *error = rb_str_cat2(rb_str_new2("Sending data failed: "), stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        *error = _ruby_ibm_db_export_char_to_utf8_rstr("Sending data failed: <error message could not be retrieved>");
#else
        *error = rb_str_new2("Sending data failed: <error message could not be retrieved>");
#endif
      }
	  bind_array->return_value = Qnil;
      return Qnil;
    }
  }

  bind_array->return_value = Qtrue;
  return Qtrue;
}
/*
 * IBM_DB.execute --  Executes a prepared SQL statement
 * 
 * ===Description
 * bool IBM_DB.execute ( resource stmt [, array parameters] )
 * 
 * IBM_DB.execute() executes an SQL statement that was prepared by IBM_DB.prepare().
 * 
 * If the SQL statement returns a result set, for example, a SELECT statement or a CALL to a stored procedure that returns one or more result sets, you can retrieve a row as an array from the stmt resource using IBM_DB.fetch_assoc(), IBM_DB.fetch_both(), or IBM_DB.fetch_array(). Alternatively, you can use IBM_DB.fetch_row() to move the result set pointer to the next row and fetch a column at a time from that row with IBM_DB.result().
 * 
 * Refer to IBM_DB.prepare() for a brief discussion of the advantages of using IBM_DB.prepare() and IBM_DB.execute() rather than IBM_DB.exec().
 * 
 * ===Parameters
 * stmt
 *     A prepared statement returned from IBM_DB.prepare(). 
 * 
 * parameters
 *     An array of input parameters matching any parameter markers contained in the prepared statement. 
 * 
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure.
 */
VALUE ibm_db_execute(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt                   =  Qnil;
  VALUE parameters_array       =  Qnil;
  VALUE ret_value              =  Qtrue;

  stmt_handle     *stmt_res    =  NULL;
  stmt_bind_array *bind_array  =  NULL;

  /* This is used to loop over the param cache */
  param_node *tmp_curr, *prev_ptr, *curr_ptr;

  VALUE error = Qnil;

  rb_scan_args(argc, argv, "11", &stmt, &parameters_array);

  /* Get values from symbol tables */
  /* Assign values into param nodes */
  /* Check types/conversions */
  /* Bind parameters */
  /* Execute */
  /* Return values back to symbol table for OUT params */

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

    /* This ensures that each call to IBM_DB.execute start from scratch */
    stmt_res->current_node = stmt_res->head_cache_list;

    bind_array = ALLOC( stmt_bind_array );
    memset(bind_array,'\0',sizeof(struct _stmt_bind_data_array));

    bind_array->parameters_array  =  &parameters_array;
    bind_array->stmt_res          =  stmt_res;
    bind_array->bind_params       =  0;
    bind_array->num               =  0;
    bind_array->error             =  &error;

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_execute_helper, bind_array,
                            (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	  ret_value = bind_array->return_value;
    #else
      ret_value = _ruby_ibm_db_execute_helper( bind_array );
    #endif

    if( ret_value == Qnil || ret_value == Qfalse ) {
      rb_warn( RSTRING_PTR(error) );
      ruby_xfree( bind_array );
      bind_array = NULL;
      return Qfalse;
    }

    /* cleanup dynamic bindings if present */
    if ( bind_array->bind_params == 1 ) {
      /* Free param cache list */
      curr_ptr = stmt_res->head_cache_list;
      prev_ptr = stmt_res->head_cache_list;

      while (curr_ptr != NULL) {
        curr_ptr = curr_ptr->next;

        /* Free Values */
        if ( prev_ptr->svalue != NULL ) {
          ruby_xfree( prev_ptr->svalue );
          prev_ptr->svalue = NULL;
        }

        if ( prev_ptr->varname != NULL ) {
          ruby_xfree( prev_ptr->varname );
          prev_ptr->varname = NULL;
        }

        ruby_xfree( prev_ptr );

        prev_ptr = curr_ptr;
      }

      stmt_res->head_cache_list =  NULL;
      stmt_res->num_params      =  0;
      stmt_res->current_node    =  NULL;
    } else {
      /* Bind the IN/OUT Params back into the active symbol table */
      tmp_curr = stmt_res->head_cache_list;
      while (tmp_curr != NULL) {
        switch(tmp_curr->param_type) {
          case SQL_PARAM_OUTPUT:
          case SQL_PARAM_INPUT_OUTPUT:
            if( (tmp_curr->bind_indicator != SQL_NULL_DATA 
               && tmp_curr->bind_indicator != SQL_NO_TOTAL )){
              switch (tmp_curr->data_type) {
                case SQL_SMALLINT:
                case SQL_INTEGER:
                case SQL_BIGINT:
                  var_assign(tmp_curr->varname, INT2NUM(tmp_curr->ivalue));
                  break;
                case SQL_REAL:
                case SQL_FLOAT:
                case SQL_DOUBLE:
                case SQL_DECIMAL:
                case SQL_NUMERIC:
                  var_assign(tmp_curr->varname, rb_float_new(tmp_curr->fvalue));
                  break;
                case SQL_XML:
#ifdef UNICODE_SUPPORT_VERSION
                    var_assign(tmp_curr->varname,rb_str_new2((char *) "")); /*Ensure it is a string object*/
                    if( tmp_curr-> size > 0 && tmp_curr->bind_indicator > tmp_curr->size ){
                      rb_funcall(rb_eval_string(tmp_curr->varname), rb_intern("replace"), 1, _ruby_ibm_db_export_sqlchar_to_utf8_rstr( (SQLCHAR *) tmp_curr->svalue, tmp_curr->size ));
                    } else {
                      rb_funcall(rb_eval_string(tmp_curr->varname), rb_intern("replace"), 1, _ruby_ibm_db_export_sqlchar_to_utf8_rstr( (SQLCHAR *) tmp_curr->svalue, tmp_curr->bind_indicator));
                    }
#else
                  var_assign(tmp_curr->varname, rb_str_new2((char *)tmp_curr->svalue));
#endif
                   break;
                case SQL_BLOB:
                case SQL_BINARY:
                case SQL_VARBINARY:
                case SQL_LONGVARBINARY:
                   if( tmp_curr-> size > 0 && tmp_curr->bind_indicator > tmp_curr->size ) {
                     var_assign(tmp_curr->varname, rb_str_new((char *)tmp_curr->svalue, tmp_curr->size ));
                   } else {
                     var_assign(tmp_curr->varname, rb_str_new((char *)tmp_curr->svalue,  tmp_curr->bind_indicator ));
                   }
                   break;
                default:
#ifdef UNICODE_SUPPORT_VERSION
                    var_assign(tmp_curr->varname,rb_str_new2((char *) "")); /*Ensure it is a string object*/
                    if( tmp_curr-> size > 0 && tmp_curr->bind_indicator > (tmp_curr->size * sizeof(SQLWCHAR))+ 2 ){
                      rb_funcall(rb_eval_string(tmp_curr->varname), rb_intern("replace"), 1, _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( (SQLWCHAR *) tmp_curr->svalue, (tmp_curr->size * sizeof(SQLWCHAR)) + 2 ));
                    } else {
                      rb_funcall(rb_eval_string(tmp_curr->varname), rb_intern("replace"), 1, _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( (SQLWCHAR *) tmp_curr->svalue, tmp_curr->bind_indicator));
                    }
#else
                  var_assign(tmp_curr->varname, rb_str_new2((char *)tmp_curr->svalue));
#endif
                  break;
              }

            }
          default:
            break;
        }
        tmp_curr = tmp_curr->next;
      }
    }

    if ( bind_array != NULL) {
      ruby_xfree( bind_array );
      bind_array = NULL;
    }

    return Qtrue;

  } else {
    rb_warn("Supplied parameter is invalid");
    return Qfalse;
  }

  return Qnil;
}
/*  */

/*
 * IBM_DB.conn_errormsg --  Returns the last connection error message and SQLCODE value
 * 
 * ===Description
 * string IBM_DB.conn_errormsg ( [resource connection] )
 * 
 * IBM_DB.conn_errormsg() returns an error message and SQLCODE value representing the reason
 * the last database connection attempt failed. As IBM_DB.connect() returns FALSE in the event
 * of a failed connection attempt, do not pass any parameters to IBM_DB.conn_errormsg() to retrieve
 * the associated error message and SQLCODE value.
 * 
 * If, however, the connection was successful but becomes invalid over time, you can pass the connection
 * parameter to retrieve the associated error message and SQLCODE value for a specific connection.
 * ===Parameters
 * 
 * connection
 *     A connection resource associated with a connection that initially succeeded, but which over time
 * became invalid. 
 * 
 * ===Return Values
 * 
 * Returns a string containing the error message and SQLCODE value resulting from a failed connection attempt. If there is no error associated with the last connection attempt, IBM_DB.conn_errormsg() returns an empty string. 
 *
 * ===Deprecated
 * Use getErrormsg
 */
VALUE ibm_db_conn_errormsg(int argc, VALUE *argv, VALUE self)
{
  VALUE         connection      =  Qnil;
  VALUE         ret_val         =  Qnil;
  conn_handle   *conn_res       =  NULL;
  SQLPOINTER    return_str      =  NULL;  /* This variable is used by _ruby_ibm_db_check_sql_errors to return err strings */
  SQLSMALLINT   return_str_len  =  0;

  rb_scan_args(argc, argv, "01", &connection);

  /*rb_warn("Method conn_errormsg is deprecated, use getErrormsg");*/

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qnil;
    }

#ifdef UNICODE_SUPPORT_VERSION
    return_str = ALLOC_N( SQLWCHAR, DB2_MAX_ERR_MSG_LEN + 1 );
    memset(return_str, '\0', (DB2_MAX_ERR_MSG_LEN + 1 ) * sizeof(SQLWCHAR) );
#else
    return_str = ALLOC_N(char, DB2_MAX_ERR_MSG_LEN+1);
    memset(return_str, '\0', DB2_MAX_ERR_MSG_LEN+1);
#endif

    _ruby_ibm_db_check_sql_errors(conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, -1, 0, return_str, &return_str_len, DB_ERRMSG, conn_res->errormsg_recno_tracker, 1 );

    if(conn_res->errormsg_recno_tracker - conn_res->error_recno_tracker >= 1)
      conn_res->error_recno_tracker = conn_res->errormsg_recno_tracker;

    conn_res->errormsg_recno_tracker++;

#ifdef UNICODE_SUPPORT_VERSION
    ret_val  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( (SQLWCHAR *)return_str, return_str_len );
#else
    ret_val  =  rb_str_new2(return_str);
#endif
    ruby_xfree( return_str );

    return ret_val;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    return _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( IBM_DB_G(__ruby_conn_err_msg), DB2_MAX_ERR_MSG_LEN * sizeof(SQLWCHAR) );
#else
    return rb_str_new2(IBM_DB_G(__ruby_conn_err_msg));
#endif
  }
}
/*  */

/*
 * IBM_DB.stmt_errormsg --  Returns a string containing the last SQL statement error message
 * 
 * ===Description
 * string IBM_DB.stmt_errormsg ( [resource stmt] )
 * 
 * Returns a string containing the last SQL statement error message.
 * 
 * If you do not pass a statement resource as an argument to IBM_DB.stmt_errormsg(), the driver returns the error message associated with the last attempt to return a statement resource, for example, from IBM_DB.prepare() or IBM_DB.exec().
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid statement resource. 
 * 
 * ===Return Values
 * 
 * Returns a string containing the error message and SQLCODE value for the last error that occurred issuing an SQL statement. 
 *
 * ===Deprecated
 * Use getErrormsg
 */
VALUE ibm_db_stmt_errormsg(int argc, VALUE *argv, VALUE self)
{
  VALUE        stmt            =  Qnil;
  VALUE        ret_val         =  Qnil;
  stmt_handle  *stmt_res       =  NULL;
  SQLPOINTER   return_str      =  NULL; /* This variable is used by _ruby_ibm_db_check_sql_errors to return err strings */
  SQLSMALLINT  return_str_len  =  0;

  rb_scan_args(argc, argv, "01", &stmt);

  rb_warn("Method stmt_errormsg is deprecated, use getErrormsg");

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

#ifdef UNICODE_SUPPORT_VERSION
    return_str = ALLOC_N(SQLWCHAR, DB2_MAX_ERR_MSG_LEN + 1 );
    memset(return_str, '\0', (DB2_MAX_ERR_MSG_LEN + 1 ) * sizeof(SQLWCHAR) );
#else
    return_str = ALLOC_N(char, DB2_MAX_ERR_MSG_LEN+1);
    memset(return_str, '\0', DB2_MAX_ERR_MSG_LEN+1);
#endif

    _ruby_ibm_db_check_sql_errors(stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, -1, 0, 
             return_str, &return_str_len, DB_ERRMSG, stmt_res->errormsg_recno_tracker, 1);

    if(stmt_res->errormsg_recno_tracker - stmt_res->error_recno_tracker >= 1)
      stmt_res->error_recno_tracker = stmt_res->errormsg_recno_tracker;

    stmt_res->errormsg_recno_tracker++;

#ifdef UNICODE_SUPPORT_VERSION
    ret_val  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( return_str, return_str_len );
#else
    ret_val  =  rb_str_new2( return_str );
#endif
    ruby_xfree( return_str );

    return ret_val;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    return _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( IBM_DB_G(__ruby_stmt_err_msg), DB2_MAX_ERR_MSG_LEN * sizeof(SQLWCHAR) );
#else
    return rb_str_new2(IBM_DB_G(__ruby_stmt_err_msg));
#endif
  }
}
/*  */

/*
 * IBM_DB.conn_error --  Returns a string containing the SQLSTATE returned by the last connection attempt
 * ===Description
 * string IBM_DB.conn_error ( [resource connection] )
 * 
 * IBM_DB.conn_error() returns an SQLSTATE value representing the reason the last attempt to connect
 * to a database failed. As IBM_DB.connect() returns FALSE in the event of a failed connection attempt,
 * you do not pass any parameters to IBM_DB.conn_error() to retrieve the SQLSTATE value.
 * 
 * If, however, the connection was successful but becomes invalid over time, you can pass the connection
 * parameter to retrieve the SQLSTATE value for a specific connection.
 * 
 * To learn what the SQLSTATE value means, you can issue the following command at a DB2 Command Line
 * Processor prompt: db2 '? sqlstate-value'. You can also call IBM_DB.conn_errormsg() to retrieve
 * an explicit error message and the associated SQLCODE value.
 * 
 * ===Parameters
 * 
 * connection
 *     A connection resource associated with a connection that initially succeeded, but which over time
 * became invalid. 
 * 
 * ===Return Values
 * 
 * Returns the SQLSTATE value resulting from a failed connection attempt. 
 * Returns an empty string if there is no error associated with the last connection attempt.
 *
 * ===Deprecated
 * Use getErrorstate
 */
VALUE ibm_db_conn_error(int argc, VALUE *argv, VALUE self)
{
  VALUE         connection      =  Qnil;
  VALUE         ret_val         =  Qnil;
  conn_handle   *conn_res       =  NULL;
  SQLPOINTER    return_str      =  NULL; /* This variable is used by _ruby_ibm_db_check_sql_errors to return err strings */
  SQLSMALLINT   return_str_len  =  0;

  rb_scan_args(argc, argv, "01", &connection);

  /*rb_warn("Method conn_error is deprecated, use getErrorstate");*/

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qnil;
    }

#ifdef UNICODE_SUPPORT_VERSION
    return_str = ALLOC_N(SQLWCHAR, SQL_SQLSTATE_SIZE + 1);
    memset(return_str, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
#else
    return_str = ALLOC_N(char, SQL_SQLSTATE_SIZE + 1);
    memset(return_str, '\0', SQL_SQLSTATE_SIZE + 1);
#endif

    _ruby_ibm_db_check_sql_errors(conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, -1, 0, 
              return_str, &return_str_len, DB_ERR_STATE, conn_res->error_recno_tracker, 1);

    if (conn_res->error_recno_tracker - conn_res->errormsg_recno_tracker >= 1) {
      conn_res->errormsg_recno_tracker = conn_res->error_recno_tracker;
    }

    conn_res->error_recno_tracker++;

#ifdef UNICODE_SUPPORT_VERSION
    ret_val = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( return_str, SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR) );
#else
    ret_val = rb_str_new2( return_str );
#endif
    ruby_xfree( return_str );

    return ret_val;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    return _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( IBM_DB_G(__ruby_conn_err_state),
              SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR)
           );
#else
    return rb_str_new2( IBM_DB_G(__ruby_conn_err_state) );
#endif
  }
}
/*  */

/*
 * IBM_DB.stmt_error --  Returns a string containing the SQLSTATE returned by an SQL statement
 * 
 * ===Description
 * string IBM_DB.stmt_error ( [resource stmt] )
 * 
 * Returns a string containing the SQLSTATE value returned by an SQL statement.
 * 
 * If you do not pass a statement resource as an argument to IBM_DB.stmt_error(), the driver returns the SQLSTATE value associated with the last attempt to return a statement resource, for example, from IBM_DB.prepare() or IBM_DB.exec().
 * 
 * To learn what the SQLSTATE value means, you can issue the following command at a DB2 Command Line Processor prompt: db2 '? sqlstate-value'. You can also call IBM_DB.stmt_errormsg() to retrieve an explicit error message and the associated SQLCODE value.
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid statement resource. 
 * 
 * ===Return Values
 * 
 * Returns a string containing an SQLSTATE value.
 *
 * ===Deprecated
 * Use getErrorstate
 */
VALUE ibm_db_stmt_error(int argc, VALUE *argv, VALUE self)
{
  VALUE         stmt            =  Qnil;
  VALUE         ret_val         =  Qnil;
  stmt_handle   *stmt_res       =  NULL;
  SQLPOINTER    return_str      =  NULL; /* This variable is used by _ruby_ibm_db_check_sql_errors to return err strings */
  SQLSMALLINT   return_str_len  =  0;

  rb_scan_args(argc, argv, "01", &stmt);

  rb_warn("Method stmt_error is deprecated, use getErrorstate");

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

#ifdef UNICODE_SUPPORT_VERSION
    return_str = ALLOC_N(SQLWCHAR, SQL_SQLSTATE_SIZE + 1);
    memset(return_str, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
#else
    return_str = ALLOC_N(char, SQL_SQLSTATE_SIZE + 1);
    memset(return_str, '\0', SQL_SQLSTATE_SIZE + 1);
#endif

    _ruby_ibm_db_check_sql_errors(stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, -1, 0, 
                 return_str, &return_str_len, DB_ERR_STATE, stmt_res->error_recno_tracker, 1 );

    if (stmt_res->error_recno_tracker - stmt_res->errormsg_recno_tracker >= 1) {
      stmt_res->errormsg_recno_tracker = stmt_res->error_recno_tracker;
    }

    stmt_res->error_recno_tracker++;

#ifdef UNICODE_SUPPORT_VERSION
    ret_val = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( return_str, SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR) );
#else
    ret_val = rb_str_new2( return_str );
#endif
    ruby_xfree( return_str );

    return ret_val;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    return _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( IBM_DB_G(__ruby_stmt_err_state), 
             SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR) 
           );
#else
    return rb_str_new2(IBM_DB_G(__ruby_stmt_err_state));
#endif
  }
}
/*  */

/*
 * IBM_DB.getErrormsg --  Returns a string containing the last SQL statement error message
 * 
 * ===Description
 * string IBM_DB.getErrormsg ( resource conn_or_stmt, value resourceType)
 * 
 * Returns a string containing the last diagnostic error message.
 * 
 * ===Parameters
 * 
 * conn_or_stmt
 *     A valid connection or statement resource.
 *
 * resourceType
 *
 *     Value indicating if connection or statement resource is passed
 *
 *     IBM_DB::DB_CONN if resource is connection and IBM_DB::DB_STMT if resource is statement or
 *     1 = Connection, non - 1 = Statement
 *
 * ===Return Values
 * 
 * Returns a string containing the error message and SQLCODE value for the last error that occurred. 
 *
 */
VALUE ibm_db_getErrormsg(int argc, VALUE *argv, VALUE self)
{
  VALUE        conn_or_stmt    =  Qnil;
  VALUE        resourceType    =  Qnil;

  VALUE        return_value    =  Qnil;

  stmt_handle  *stmt_res       =  NULL;
  conn_handle  *conn_res       =  NULL;

  int          resType         =  0;
  SQLPOINTER   return_str      =  NULL; /* This variable is used by _ruby_ibm_db_check_sql_errors to return err strings */
  SQLSMALLINT  return_str_len  =  0;

  rb_scan_args(argc, argv, "2", &conn_or_stmt, &resourceType );

  if (!NIL_P(conn_or_stmt) && !NIL_P(resourceType) ) {

    resType   =   FIX2INT( resourceType );

    if( resType == DB_CONN ) {   /*Resource Type is connection*/
      Data_Get_Struct(conn_or_stmt, conn_handle, conn_res);

      if (!conn_res || !conn_res->handle_active ) {
        rb_warn("Connection is not active");
        return Qnil;
      }

      if( conn_res->errorType != 1 ) {
        if( conn_res->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          return_value  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( conn_res->ruby_error_msg, conn_res->ruby_error_msg_len );
#else
          return_value  =  rb_str_new2( conn_res->ruby_error_msg );
#endif
        } else {
          return_value = Qnil;
        }
      } else {

        if( conn_res->errormsg_recno_tracker == 1 && conn_res->ruby_error_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          return_value  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( conn_res->ruby_error_msg, conn_res->ruby_error_msg_len );
#else
          return_value  =  rb_str_new2( conn_res->ruby_error_msg );
#endif
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          return_str = ALLOC_N(SQLWCHAR, DB2_MAX_ERR_MSG_LEN+1);
          memset(return_str, '\0', (DB2_MAX_ERR_MSG_LEN + 1) * sizeof(SQLWCHAR) );
#else
          return_str = ALLOC_N(char, DB2_MAX_ERR_MSG_LEN+1);
          memset(return_str, '\0', DB2_MAX_ERR_MSG_LEN+1);
#endif

          _ruby_ibm_db_check_sql_errors(conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, -1, 0, return_str,
                      &return_str_len, DB_ERRMSG, conn_res->errormsg_recno_tracker, 1 );

          if(conn_res->errormsg_recno_tracker - conn_res->error_recno_tracker >= 1) {
             conn_res->error_recno_tracker = conn_res->errormsg_recno_tracker;
          }

#ifdef UNICODE_SUPPORT_VERSION
          return_value = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( return_str, return_str_len );
#else
          return_value = rb_str_new2( return_str );
#endif
          ruby_xfree( return_str );
        }
        conn_res->errormsg_recno_tracker++;
      }
    } else {  /*Resource Type is statement*/
      Data_Get_Struct(conn_or_stmt, stmt_handle, stmt_res);

      if( stmt_res->errormsg_recno_tracker == 1 && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        return_value  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg, stmt_res->ruby_stmt_err_msg_len );
#else
        return_value  =  rb_str_new2( stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        return_str = ALLOC_N(SQLWCHAR, DB2_MAX_ERR_MSG_LEN + 1 );
        memset(return_str, '\0', (DB2_MAX_ERR_MSG_LEN + 1 ) * sizeof(SQLWCHAR) );
#else
        return_str = ALLOC_N(char, DB2_MAX_ERR_MSG_LEN + 1 );
        memset(return_str, '\0', DB2_MAX_ERR_MSG_LEN + 1 );
#endif

        _ruby_ibm_db_check_sql_errors(stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, -1, 0, 
                      return_str, &return_str_len, DB_ERRMSG, stmt_res->errormsg_recno_tracker, 1);

        if(stmt_res->errormsg_recno_tracker - stmt_res->error_recno_tracker >= 1) {
          stmt_res->error_recno_tracker = stmt_res->errormsg_recno_tracker;
        }

#ifdef UNICODE_SUPPORT_VERSION
        return_value  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( return_str, return_str_len );
#else
        return_value = rb_str_new2( return_str );
#endif
        ruby_xfree( return_str );
      }
      stmt_res->errormsg_recno_tracker++;
    } /*End of Resource Type check */

  } else {
    rb_warn("Invalid Parameter(s) specified");
    return_value = Qnil;
  }

  return return_value;
}

/*  */

/*
 * IBM_DB.getErrorstate --  Returns a string containing the SQLSTATE of the last error condition
 * 
 * ===Description
 * string IBM_DB.getErrorstate ( resource conn_or_stmt, value resourceType,  value errorType)
 * 
 * Returns a string containing the last error's SQLSTATE.
 * 
 * ===Parameters
 * 
 * conn_or_stmt
 *     A valid connection or statement resource.
 *
 * resourceType
 *
 *     Value indicating if connection or statement resource is passed
 *
 *
 *     IBM_DB::DB_CONN if resource is connection and IBM_DB::DB_STMT if resource is statement or
 *     1 = Connection, non - 1 = Statement
 *
 * ===Return Values
 * 
 * Returns a string containing the error message and SQLCODE value for the last error that occurred issuing an SQL statement. 
 *
 */
VALUE ibm_db_getErrorstate(int argc, VALUE *argv, VALUE self)
{
  VALUE        conn_or_stmt    =  Qnil;
  VALUE        resourceType    =  Qnil;

  VALUE        return_value    =  Qnil;

  stmt_handle  *stmt_res       =  NULL;
  conn_handle  *conn_res       =  NULL;

  int          resType         =  0;
  SQLPOINTER   return_str      =  NULL; /* This variable is used by _ruby_ibm_db_check_sql_errors to return err strings */
  SQLSMALLINT  return_str_len  =  0;

  rb_scan_args(argc, argv, "2", &conn_or_stmt, &resourceType );

  if (!NIL_P(conn_or_stmt) && !NIL_P(resourceType) ) {

    resType   =   FIX2INT( resourceType );

    if( resType == DB_CONN ) {   /*Resource Type is connection*/
      Data_Get_Struct(conn_or_stmt, conn_handle, conn_res);

      if ( !conn_res->handle_active ) {
        rb_warn("Connection is not active");
        return Qnil;
      }

      if( conn_res->errorType != 1 ) {
          if( conn_res->ruby_error_state != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
            return_value  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( conn_res->ruby_error_state,
                                SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR) 
                             );
#else
            return_value  =  rb_str_new2( conn_res->ruby_error_state );
#endif
          } else {
            return_value = Qnil;
          }
      } else {

        if( conn_res->error_recno_tracker == 1 && conn_res->ruby_error_state != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
          return_value  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( conn_res->ruby_error_state, 
                              SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR)
                           );
#else
          return_value  =  rb_str_new2( conn_res->ruby_error_state );
#endif
        } else {

#ifdef UNICODE_SUPPORT_VERSION
          return_str = ALLOC_N(SQLWCHAR, SQL_SQLSTATE_SIZE + 1 );
          memset(return_str, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
#else
          return_str = ALLOC_N(char, SQL_SQLSTATE_SIZE + 1 );
          memset(return_str, '\0', SQL_SQLSTATE_SIZE + 1 );
#endif

          _ruby_ibm_db_check_sql_errors(conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, -1, 0, return_str, 
                       &return_str_len, DB_ERR_STATE, conn_res->error_recno_tracker, 1 );

          if(conn_res->error_recno_tracker - conn_res->errormsg_recno_tracker >= 1) {
             conn_res->errormsg_recno_tracker = conn_res->error_recno_tracker;
          }

#ifdef UNICODE_SUPPORT_VERSION
          return_value = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( return_str, SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR) );
#else
          return_value = rb_str_new2( return_str );
#endif
          ruby_xfree( return_str );
        }
        conn_res->error_recno_tracker++;
      }
    } else {  /*Resource Type is statement*/
      Data_Get_Struct(conn_or_stmt, stmt_handle, stmt_res);

      if( stmt_res->error_recno_tracker == 1 && stmt_res->ruby_stmt_err_state != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        return_value  =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_state, 
                            SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR) 
                         );
#else
        return_value  =  rb_str_new2( stmt_res->ruby_stmt_err_state );
#endif
      } else {

#ifdef UNICODE_SUPPORT_VERSION
        return_str = ALLOC_N(SQLWCHAR, SQL_SQLSTATE_SIZE + 1 );
        memset(return_str, '\0', (SQL_SQLSTATE_SIZE + 1) * sizeof(SQLWCHAR) );
#else
        return_str = ALLOC_N(char, SQL_SQLSTATE_SIZE + 1 );
        memset(return_str, '\0', SQL_SQLSTATE_SIZE + 1 );
#endif

        _ruby_ibm_db_check_sql_errors(stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, -1, 0, 
                      return_str, &return_str_len, DB_ERR_STATE, stmt_res->error_recno_tracker, 1);

        if(stmt_res->error_recno_tracker - stmt_res->errormsg_recno_tracker >= 1) {
          stmt_res->errormsg_recno_tracker = stmt_res->error_recno_tracker;
        }
#ifdef UNICODE_SUPPORT_VERSION
        return_value = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( return_str,
                          SQL_SQLSTATE_SIZE * sizeof(SQLWCHAR)
                       );
#else
        return_value = rb_str_new2( return_str );
#endif
        ruby_xfree( return_str );
      }
      stmt_res->error_recno_tracker++;
    } /*End of Resource Type check */

  } else {
    rb_warn("Invalid Parameter(s) specified");
    return_value = Qnil;
  }

  return return_value;
}

/*  */

/*
 * IBM_DB.next_result --  Requests the next result set from a stored procedure
 * 
 * ===Description
 * resource IBM_DB.next_result ( resource stmt )
 * 
 * A stored procedure can return zero or more result sets. While you handle the first result set in exactly the same way you would handle the results returned by a simple SELECT statement, to fetch the second and subsequent result sets from a stored procedure you must call the IBM_DB.next_result() function and return the result to a uniquely named Ruby variable.
 * 
 * ===Parameters
 * stmt
 *     A prepared statement returned from IBM_DB.exec() or IBM_DB.execute(). 
 * 
 * ===Return Values
 * 
 * Returns a new statement resource containing the next result set if the stored procedure returned another result set. Returns FALSE if the stored procedure did not return another result set.
 */
VALUE ibm_db_next_result(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt      = Qnil;
  VALUE ret_value = Qnil;

  stmt_handle *stmt_res, *new_stmt_res = NULL;
  next_result_args *nextresultparams   = NULL;

  SQLHANDLE new_hstmt;

  int rc = 0;

  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

    _ruby_ibm_db_clear_stmt_err_cache();

    /* alloc handle and return only if it errors */
    rc = SQLAllocHandle(SQL_HANDLE_STMT, stmt_res->hdbc, &new_hstmt);

    if ( rc < SQL_SUCCESS ) {
      if ( stmt_res->ruby_stmt_err_msg == NULL ) {
        stmt_res->ruby_stmt_err_msg  =  ALLOC_N(char, DB2_MAX_ERR_MSG_LEN+1 );
      }
      memset( stmt_res->ruby_stmt_err_msg, '\0', DB2_MAX_ERR_MSG_LEN+1 );

      _ruby_ibm_db_check_sql_errors( stmt_res , DB_STMT, stmt_res->hdbc, SQL_HANDLE_DBC, rc, 0, 
                stmt_res->ruby_stmt_err_msg, &(stmt_res->ruby_stmt_err_msg_len), 1, 1, 1 );

      ret_value = Qfalse;
    } else {

      nextresultparams = ALLOC( next_result_args );
      memset(nextresultparams,'\0',sizeof(struct _ibm_db_next_result_args_struct));

      nextresultparams->stmt_res  =  stmt_res;
      nextresultparams->new_hstmt =  &new_hstmt;

      #ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLNextResult_helper, nextresultparams,
                       (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		rc = nextresultparams->rc;
      #else
        rc = _ruby_ibm_db_SQLNextResult_helper( nextresultparams );
      #endif

      if( rc != SQL_SUCCESS ) {
        if(rc < SQL_SUCCESS) {
          _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
        }
        SQLFreeHandle(SQL_HANDLE_STMT, new_hstmt);
        ruby_xfree( nextresultparams );
        nextresultparams = NULL;
        ret_value = Qfalse;
      } else {

        /* Initialize stmt resource members with default values. */
        /* Parsing will update options if needed */
        new_stmt_res = ALLOC(stmt_handle);
        memset(new_stmt_res, '\0', sizeof(stmt_handle));

        new_stmt_res->s_bin_mode      =  stmt_res->s_bin_mode;
        new_stmt_res->cursor_type     =  stmt_res->cursor_type;
        new_stmt_res->s_case_mode     =  stmt_res->s_case_mode;
        new_stmt_res->head_cache_list =  NULL;
        new_stmt_res->current_node    =  NULL;
        new_stmt_res->num_params      =  0;
        new_stmt_res->file_param      =  0;
        new_stmt_res->column_info     =  NULL;
        new_stmt_res->num_columns     =  0;
        new_stmt_res->row_data        =  NULL;
        new_stmt_res->hstmt           =  new_hstmt;
        new_stmt_res->hdbc            =  stmt_res->hdbc;
        new_stmt_res->is_freed        =  0;
		
        ret_value = Data_Wrap_Struct(le_stmt_struct,
            _ruby_ibm_db_mark_stmt_struct, _ruby_ibm_db_free_stmt_struct,
            new_stmt_res);
      }
    }
  } else {
    rb_warn("Supplied parameter is invalid");
    ret_value = Qfalse;
  }

  /*Free any memory allocated*/
  if ( nextresultparams != NULL ) {
    ruby_xfree( nextresultparams );
    nextresultparams = NULL;
  }
  
  return ret_value;
}
/*  */

/*
 * IBM_DB.num_fields --  Returns the number of fields contained in a result set
 * 
 * ===Description
 * int IBM_DB.num_fields ( resource stmt )
 * 
 * Returns the number of fields contained in a result set. This is most useful for handling the
 * result sets returned by dynamically generated queries, or for result sets returned by stored procedures,
 * where your application cannot otherwise know how to retrieve and use the results.
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid statement resource containing a result set. 
 * 
 * ===Return Values
 * 
 * Returns an integer value representing the number of fields in the result set associated with the
 * specified statement resource. Returns FALSE in case of any failures. 
 */
VALUE ibm_db_num_fields(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt    = Qnil;
  VALUE ret_val = Qnil;
  stmt_handle *stmt_res;
  int rc = 0;

#ifdef UNICODE_SUPPORT_VERSION
  char *err_str  =  NULL;
#endif

  row_col_count_args *result_cols_args = NULL;

  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

    result_cols_args = ALLOC( row_col_count_args );
    memset(result_cols_args,'\0',sizeof(struct _ibm_db_row_col_count_struct));

    result_cols_args->stmt_res  =  stmt_res;
    result_cols_args->count     =  0;

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLNumResultCols_helper, result_cols_args,
                     (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	  rc = result_cols_args->rc;
    #else
      rc = _ruby_ibm_db_SQLNumResultCols_helper( result_cols_args );
    #endif

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
#ifdef UNICODE_SUPPORT_VERSION
      err_str = RSTRING_PTR( _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->ruby_stmt_err_msg,
                                          stmt_res->ruby_stmt_err_msg_len )
                           );
      rb_warn("Failed to retrieve the number of fields: %s", err_str );
#else
      rb_warn("Failed to retrieve the number of fields: %s", (char *) stmt_res->ruby_stmt_err_msg );
#endif
      ret_val = Qfalse;
    } else {
      ret_val = INT2NUM(result_cols_args->count);
    }
  } else {
    rb_warn("Supplied parameter is invalid");
    ret_val = Qfalse;
  }

  /*Free Any memory used*/
  if ( result_cols_args != NULL ) {
    ruby_xfree( result_cols_args );
    result_cols_args = NULL;
  }
  return ret_val;
}
/*  */

/*
 * IBM_DB.num_rows --  Returns the number of rows affected by an SQL statement
 * 
 * ===Description
 * int IBM_DB.num_rows ( resource stmt )
 * 
 * Returns the number of rows deleted, inserted, or updated by an SQL statement.
 * 
 * To determine the number of rows that will be returned by a SELECT statement, issue SELECT COUNT(*)
 * with the same predicates as your intended SELECT statement and retrieve the value.
 * If your application logic checks the number of rows returned by a SELECT statement and branches
 * if the number of rows is 0, consider modifying your application to attempt to return the first row
 * with one of IBM_DB.fetch_assoc(), IBM_DB.fetch_both(), IBM_DB.fetch_array(), or IBM_DB.fetch_row(), and branch
 * if the fetch function returns FALSE.
 *
 * <b>Note:</b> If you issue a SELECT statement using a scrollable cursor, IBM_DB.num_rows() returns the
 * number of rows returned by the SELECT statement. However, the overhead associated with scrollable cursors
 * significantly degrades the performance of your application, so if this is the only reason you are
 * considering using scrollable cursors, you should use a forward-only cursor and either 
 * call SELECT COUNT(*) or rely on the boolean return value of the fetch functions to achieve the
 * equivalent functionality with much better performance. 
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid stmt resource containing a result set. 
 * 
 * ===Return Values
 * 
 * Returns the number of rows affected by the last SQL statement issued by the specified statement handle or 
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_num_rows(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt    = Qnil;
  VALUE ret_val = Qnil;

  stmt_handle *stmt_res;
  int rc = 0;

  sql_row_count_args *row_count_args = NULL;

#ifdef UNICODE_SUPPORT_VERSION
  char *err_str  =  NULL;
#endif

  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

    row_count_args = ALLOC( sql_row_count_args );
    memset(row_count_args,'\0',sizeof(struct _ibm_db_row_count_struct));

    row_count_args->stmt_res  =  stmt_res;
    row_count_args->count     =  0;

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLRowCount_helper, row_count_args,
                     (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	  rc = row_count_args->rc;
    #else
      rc = _ruby_ibm_db_SQLRowCount_helper( row_count_args );
    #endif

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );

#ifdef UNICODE_SUPPORT_VERSION
      err_str = RSTRING_PTR( _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->ruby_stmt_err_msg,
                                          stmt_res->ruby_stmt_err_msg_len )
                           );
      rb_warn("Retrieval of number of rows failed: %s", err_str );
#else
      rb_warn("Retrieval of number of rows failed: %s", (char *) stmt_res->ruby_stmt_err_msg );
#endif

      ret_val = Qfalse;
    } else {
      ret_val = INT2NUM( row_count_args->count );
    }
  } else {
    rb_warn("Supplied parameter is invalid");
    ret_val = Qfalse;
  }

    /*Free Any memory used*/
  if ( row_count_args != NULL ) {
    ruby_xfree( row_count_args );
    row_count_args = NULL;
  }

  return ret_val;
}
/*  */

/*  static int _ruby_ibm_db_get_column_by_name(stmt_handle *stmt_res, VALUE column, int release_gil)
  */
static int _ruby_ibm_db_get_column_by_name(stmt_handle *stmt_res, VALUE column, int release_gil)
{
  int rc;
  int index;

#ifdef UNICODE_SUPPORT_VERSION
  VALUE col_name  =  Qnil;
#else
  char *col_name  =  NULL;
#endif
  int  col        =  -1;

  /* get column header info*/
  if ( stmt_res->column_info == NULL ) {
    if ( release_gil == 1 ) {

      #ifdef UNICODE_SUPPORT_VERSION        
		ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_get_result_set_info, stmt_res,
                      (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
		rc = stmt_res->rc;
      #else
        rc = _ruby_ibm_db_get_result_set_info( stmt_res );
      #endif

    } else {
      rc = _ruby_ibm_db_get_result_set_info( stmt_res );
    }

    if ( rc < 0) {
      return -1;
    }
  }

  if ( TYPE(column) == T_FIXNUM ) {
    col = FIX2LONG( column );
  } else if (RTEST( column )) {
#ifdef UNICODE_SUPPORT_VERSION
    col_name = _ruby_ibm_db_export_str_to_utf16( column );
#else
    col_name = STR2CSTR( column );
#endif
  }

#ifdef UNICODE_SUPPORT_VERSION
  if ( col_name == Qnil ) {
#else
  if ( col_name == NULL ) {
#endif
    if ( col >= 0 && col < stmt_res->num_columns) {
      return col;
    } else {
      rb_warn("Column number specified is not valid");
      return -1;
    }
  }

  /* should start from 0 */
  index = 0;
  while (index < stmt_res->num_columns) {
#ifdef UNICODE_SUPPORT_VERSION
    if ( rb_str_equal(_ruby_ibm_db_export_sqlwchar_to_utf16_rstr(stmt_res->column_info[index].name, stmt_res->column_info[index].name_length * sizeof(SQLWCHAR)), _ruby_ibm_db_export_str_to_utf16(col_name) ) ) {
#else
    if (strcmp((char*)stmt_res->column_info[index].name,col_name) == 0) {
#endif
      return index;
    }
    index++;
  }
  rb_warn("Column name specified is not valid");
  return -1;
}
/*  */

/*
 * IBM_DB.field_name --  Returns the name of the column in the result set
 * 
 * ===Description
 * string IBM_DB.field_name ( resource stmt, mixed column )
 * 
 * Returns the name of the specified column in the result set.
 * 
 * ===Parameters
 * 
 * stmt
 *     Specifies a statement resource containing a result set. 
 * 
 * column
 *     Specifies the column in the result set. This can either be an integer representing the 0-indexed position of the column, or a string containing the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns a string containing the name of the specified column. If the specified column does not exist in the result set, IBM_DB.field_name() returns FALSE. 
 */
VALUE ibm_db_field_name(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt            =  Qnil;
  VALUE column          =  Qnil;
  stmt_handle* stmt_res =  NULL;
  int col               =  -1;

  rb_scan_args( argc, argv, "2", &stmt, &column );

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  /* 1 indicates that the operation is to be performed with the GIL being released*/
  col = _ruby_ibm_db_get_column_by_name(stmt_res,column, 1);

  if ( col < 0 ) {
    return Qfalse;
  }
#ifdef UNICODE_SUPPORT_VERSION
  return _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->column_info[col].name, stmt_res->column_info[col].name_length * sizeof(SQLWCHAR));
#else
  return rb_str_new2((char*)stmt_res->column_info[col].name);
#endif
}
/*  */

/*
 * IBM_DB.field_display_size --  Returns the maximum number of bytes required to display a column
 * 
 * ===Description
 * int IBM_DB.field_display_size ( resource stmt, mixed column )
 * 
 * Returns the maximum number of bytes required to display a column in a result set.
 * 
 * ===Parameters
 * stmt
 *     Specifies a statement resource containing a result set. 
 * 
 * column
 *     Specifies the column in the result set. This can either be an integer representing the
 *     0-indexed position of the column, or a string containing the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns an integer value with the maximum number of bytes required to display the specified column.
 * If the column does not exist in the result set, IBM_DB.field_display_size() returns FALSE. 
 */
VALUE ibm_db_field_display_size(int argc, VALUE *argv, VALUE self)
{
  VALUE          stmt            =  Qnil;
  VALUE          column          =  Qnil;
  VALUE          ret_val         =  Qnil;

  int            col             =  - 1;
  stmt_handle    *stmt_res       =  NULL;
  col_attr_args  *colattr_args   =  NULL;

  int rc;

  rb_scan_args(argc, argv, "2", &stmt, &column);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  /*1 indicates that the operation is to be performed with the GIL being released*/
  col = _ruby_ibm_db_get_column_by_name(stmt_res,column, 1);

  if ( col < 0 ) {
    ret_val = Qfalse;
  } else {

    colattr_args = ALLOC( col_attr_args );
    memset( colattr_args,'\0',sizeof(struct _ibm_db_col_attr_struct) );

    colattr_args->stmt_res        =  stmt_res;
    colattr_args->num_attr        =  0;
    colattr_args->col_num         =  col+1;
    colattr_args->FieldIdentifier =  SQL_DESC_DISPLAY_SIZE;

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLColAttributes_helper, colattr_args,
                     (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	  rc = colattr_args->rc;
    #else
      rc = _ruby_ibm_db_SQLColAttributes_helper( colattr_args );
    #endif

    if ( rc < SQL_SUCCESS ) {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
      ret_val = Qfalse;
    } else {
      ret_val = INT2NUM(colattr_args->num_attr);
    }
  }

  /* Free any memory used */
  if ( colattr_args != NULL ) {
    ruby_xfree( colattr_args );
    colattr_args = NULL;
  }

  return ret_val;
}
/*  */

/*
 * IBM_DB.field_num --  Returns the position of the named column in a result set
 * 
 * ===Description
 * int IBM_DB.field_num ( resource stmt, mixed column )
 * 
 * Returns the position of the named column in a result set.
 * 
 * ===Parameters
 * 
 * stmt
 *     Specifies a statement resource containing a result set. 
 * 
 * column
 *     Specifies the column in the result set. This can either be an integer representing the
 *     0-indexed position of the column, or a string containing the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns an integer containing the 0-indexed position of the named column in the result set. 
 * If the specified column does not exist in the result set, IBM_DB.field_num() returns FALSE. 
 */
VALUE ibm_db_field_num(int argc, VALUE *argv, VALUE self)
{
  VALUE        stmt         =  Qnil;
  VALUE        column       =  Qnil;
  stmt_handle  *stmt_res    =  NULL;
  int          col          =  -1;

  rb_scan_args(argc, argv, "2", &stmt, &column);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  /* 1 indicates that the operation is to be performed with the GIL being released*/
  col = _ruby_ibm_db_get_column_by_name(stmt_res,column, 1);

  if ( col < 0 ) {
    return Qfalse;
  }
  return INT2NUM( col );
}
/*  */

/*
 * IBM_DB.field_precision --  Returns the precision of the indicated column in a result set
 * 
 * ===Description
 * int IBM_DB.field_precision ( resource stmt, mixed column )
 * 
 * Returns the precision of the indicated column in a result set.
 * 
 * ===Parameters
 * 
 * stmt
 *     Specifies a statement resource containing a result set. 
 * 
 * column
 *     Specifies the column in the result set. This can either be an integer representing the
 *     0-indexed position of the column, or a string containing the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns an integer containing the precision of the specified column. If the specified column
 * does not exist in the result set, IBM_DB.field_precision() returns FALSE. 
 */
VALUE ibm_db_field_precision(int argc, VALUE *argv, VALUE self)
{
  VALUE        stmt       =  Qnil;
  VALUE        column     =  Qnil;
  stmt_handle  *stmt_res  =  NULL;
  int          col        =  -1;

  rb_scan_args(argc, argv, "2", &stmt, &column);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  /*One indicates that the operation is to be performed with the GIL being released*/
  col = _ruby_ibm_db_get_column_by_name(stmt_res,column, 1);

  if ( col < 0 ) {
    return Qfalse;
  }
  return INT2NUM( stmt_res->column_info[col].size );

}
/*  */

/*
 * IBM_DB.field_scale --  Returns the scale of the indicated column in a result set
 * 
 * ===Description
 * int IBM_DB.field_scale ( resource stmt, mixed column )
 * 
 * Returns the scale of the indicated column in a result set.
 * 
 * ===Parameters
 * stmt
 *     Specifies a statement resource containing a result set. 
 * 
 * column
 *     Specifies the column in the result set. This can either be an integer representing the
 *     0-indexed position of the column, or a string containing the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns an integer containing the scale of the specified column. If the specified column
 * does not exist in the result set, IBM_DB.field_scale() returns FALSE. 
 */
VALUE ibm_db_field_scale(int argc, VALUE *argv, VALUE self)
{
  VALUE        stmt       =  Qnil;
  VALUE        column     =  Qnil;
  stmt_handle  *stmt_res  =  NULL;
  int          col        =  -1;

  rb_scan_args(argc, argv, "2", &stmt, &column);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  /*1 indicates that the operation is to be performed with the GIL being released*/
  col = _ruby_ibm_db_get_column_by_name(stmt_res,column, 1);

  if ( col < 0 ) {
    return Qfalse;
  }
  return INT2NUM( stmt_res->column_info[col].scale );
}
/*  */

/*
 * IBM_DB.field_type --  Returns the data type of the indicated column in a result set
 * 
 * ===Description
 * string IBM_DB.field_type ( resource stmt, mixed column )
 * 
 * Returns the data type of the indicated column in a result set.
 * 
 * ===Parameters
 * stmt
 *     Specifies a statement resource containing a result set. 
 * 
 * column
 *     Specifies the column in the result set. This can either be an integer representing the
 *     0-indexed position of the column, or a string containing the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns a string containing the defined data type of the specified column. If the specified column
 * does not exist in the result set, IBM_DB.field_type() returns FALSE. 
 */
VALUE ibm_db_field_type(int argc, VALUE *argv, VALUE self)
{
  VALUE        stmt       =  Qnil;
  VALUE        column     =  Qnil;
  stmt_handle  *stmt_res  =  NULL;
  char         *str_val   =  "";
  int          col        =  -1;

  rb_scan_args(argc, argv, "2", &stmt, &column);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  /*1 indicates that the operation is to be performed with the GIL being released*/
  col = _ruby_ibm_db_get_column_by_name(stmt_res,column, 1);

  if ( col < 0 ) {
    return Qfalse;
  }

  switch (stmt_res->column_info[col].type) {
    case SQL_SMALLINT:
    case SQL_INTEGER:
    case SQL_BIGINT:
      str_val = "int";
      break;
    case SQL_REAL:
    case SQL_FLOAT:
    case SQL_DOUBLE:
    case SQL_DECIMAL:
    case SQL_NUMERIC:
    case SQL_DECFLOAT:
      str_val = "real";
      break;
    case SQL_CLOB:
      str_val = "clob";
      break;
    case SQL_BLOB:
      str_val = "blob";
      break;
    case SQL_XML:
      str_val = "xml";
      break;
    case SQL_TYPE_DATE:
      str_val = "date";
      break;
    case SQL_TYPE_TIME:
      str_val = "time";
      break;
    case SQL_TYPE_TIMESTAMP:
      str_val = "timestamp";
      break;
    default:
      str_val = "string";
      break;
  }
#ifdef UNICODE_SUPPORT_VERSION
  return _ruby_ibm_db_export_char_to_utf8_rstr(str_val);
#else
  return rb_str_new2( str_val );
#endif
}
/*  */

/*
 * IBM_DB.field_width --  Returns the width of the current value of the indicated column in a result set
 * 
 * ===Description
 * int IBM_DB.field_width ( resource stmt, mixed column )
 * 
 * Returns the width of the current value of the indicated column in a result set. This is the maximum
 * width of the column for a fixed-length data type, or the actual width of the column for a
 * variable-length data type.
 * 
 * ===Parameters
 * 
 * stmt
 *     Specifies a statement resource containing a result set. 
 * 
 * column
 *     Specifies the column in the result set. This can either be an integer representing the
 *     0-indexed position of the column, or a string containing the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns an integer containing the width of the specified character or binary data type column
 * in a result set. If the specified column does not exist in the result set, IBM_DB.field_width()
 * returns FALSE. 
 */
VALUE ibm_db_field_width(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt    =  Qnil;
  VALUE column  =  Qnil;
  VALUE ret_val =  Qnil;

  int col = -1;

  stmt_handle    *stmt_res      =  NULL;
  col_attr_args  *colattr_args  =  NULL;

  int rc;

  rb_scan_args(argc, argv, "2", &stmt, &column);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  /*1 indicates that the operation is to be performed with the GIL being released*/
  col = _ruby_ibm_db_get_column_by_name(stmt_res,column, 1);

  if ( col < 0 ) {
    ret_val = Qfalse;
  } else {

    colattr_args = ALLOC( col_attr_args );
    memset( colattr_args,'\0',sizeof(struct _ibm_db_col_attr_struct) );

    colattr_args->stmt_res         =  stmt_res;
    colattr_args->num_attr         =  0;
    colattr_args->col_num          =  col+1;
    colattr_args->FieldIdentifier  =  SQL_DESC_LENGTH;

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLColAttributes_helper, colattr_args,
                     (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	  rc = colattr_args->rc;
    #else
      rc = _ruby_ibm_db_SQLColAttributes_helper( colattr_args );
    #endif

    if ( rc != SQL_SUCCESS ) {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
      ret_val = Qfalse;
    } else {
      ret_val = INT2NUM( colattr_args->num_attr );
    }
  }

  /* Free any memory used */
  if ( colattr_args != NULL ) {
    ruby_xfree( colattr_args );
    colattr_args = NULL;
  }
  return ret_val;
}
/*  */

/*
 * IBM_DB.cursor_type --  Returns the cursor type used by a statement resource
 * 
 * ===Description
 * int IBM_DB.cursor_type ( resource stmt )
 * 
 * Returns the cursor type used by a statement resource. Use this to determine if you are working with a forward-only cursor or scrollable cursor.
 * 
 * ===Parameters
 * stmt
 *     A valid statement resource. 
 * 
 * ===Return Values
 * 
 * Returns either SQL_SCROLL_FORWARD_ONLY if the statement resource uses a forward-only cursor or SQL_CURSOR_KEYSET_DRIVEN if the statement resource uses a scrollable cursor. 
 */
VALUE ibm_db_cursor_type(int argc, VALUE *argv, VALUE self)
{
  VALUE stmt = Qnil;
  stmt_handle *stmt_res = NULL;

  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource supplied");
    return Qfalse;
  }

  return INT2NUM( stmt_res->cursor_type != SQL_SCROLL_FORWARD_ONLY );
}
/*  */

/*
 * IBM_DB.rollback --  Rolls back a transaction
 * 
 * ===Description
 * bool IBM_DB.rollback ( resource connection )
 * 
 * Rolls back an in-progress transaction on the specified connection resource and begins a new transaction. Ruby
 * applications normally default to AUTOCOMMIT mode, so IBM_DB.rollback() normally has no effect unless AUTOCOMMIT
 * has been turned off for the connection resource.
 *
 * <b>Note:</b> If the specified connection resource is a persistent connection, all transactions in progress for all
 * applications using that persistent connection will be rolled back. For this reason, persistent connections are not
 * recommended for use in applications that require transactions. 
 * 
 * ===Parameters
 * 
 * connection
 *     A valid database connection resource variable as returned from IBM_DB.connect() or IBM_DB.pconnect(). 
 * 
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 */
VALUE ibm_db_rollback(int argc, VALUE *argv, VALUE self)
{
  VALUE connection = Qnil;
  conn_handle *conn_res;
  int rc;
  end_tran_args *end_X_args = NULL;

  rb_scan_args(argc, argv, "1", &connection);
  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);
    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }
    end_X_args = ALLOC( end_tran_args );
    memset(end_X_args,'\0',sizeof(struct _ibm_db_end_tran_args_struct));

    end_X_args->hdbc            =  &(conn_res->hdbc);
    end_X_args->handleType      =  SQL_HANDLE_DBC;
    end_X_args->completionType  =  SQL_ROLLBACK;    /*Remeber you are Rollingback the transaction*/
    #ifdef UNICODE_SUPPORT_VERSION
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_SQLEndTran, end_X_args,
                     (void *)_ruby_ibm_db_Connection_level_UBF, NULL);
	  rc = end_X_args->rc;
    #else
      rc = _ruby_ibm_db_SQLEndTran( end_X_args );
    #endif
    /*Free the memory allocated*/
    if(end_X_args != NULL) {
      ruby_xfree( end_X_args );
      end_X_args = NULL;
    }
    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
      return Qfalse;
    } else {
      conn_res->transaction_active = 0;
      return Qtrue;
    }
  }
  return Qfalse;
}
/*  */

/*  
 * IBM_DB.free_stmt --  Frees the indicated statement handle and any resources associated with it
 * 
 * ===Description
 * bool IBM_DB.free_stmt ( resource stmt )
 * 
 * Frees the system and database resources that are associated with a statement resource. These resources
 * are freed implicitly when a script finishes, but you can call IBM_DB.free_stmt() to explicitly free
 * the statement resources before the end of the script.
 *
 * ===Parameters
 * stmt
 *     A valid statement resource. 
 * 
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure. 
 *
 */
VALUE ibm_db_free_stmt(int argc, VALUE *argv, VALUE self)
{
  VALUE        stmt         =  Qnil;
  stmt_handle  *stmt_res    =  NULL;

  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

    _ruby_ibm_db_free_stmt_handle_and_resources( stmt_res );

  } else {
    rb_warn("Statement resource passed for freeing is not valid");
  }
  return Qtrue;
}
/*  */

/*  static RETCODE _ruby_ibm_db_get_data(stmt_handle *stmt_res, int col_num, short ctype, void *buff, int in_length, SQLINTEGER *out_length) */
static RETCODE _ruby_ibm_db_get_data(stmt_handle *stmt_res, int col_num, short ctype, void *buff, int in_length, SQLINTEGER *out_length)
{
  RETCODE rc = SQL_SUCCESS;
  get_data_args *getData_args;

  getData_args = ALLOC( get_data_args );
  memset(getData_args,'\0',sizeof(struct _ibm_db_get_data_args_struct));

  getData_args->stmt_res    =  stmt_res;
  getData_args->col_num     =  col_num;
  getData_args->targetType  =  ctype;
  getData_args->buff        =  buff;
  getData_args->buff_length =  in_length;
  getData_args->out_length  =  out_length;

  rc = _ruby_ibm_db_SQLGetData_helper( getData_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
  }

  /*Free memory allocated*/
  if ( getData_args != NULL) {
    ruby_xfree( getData_args );
    getData_args = NULL;
  }
  return rc;
}
/*  */

/* {{{ static RETCODE _ruby_ibm_db_get_length(stmt_handle* stmt_res, SQLUSMALLINT col_num, SQLINTEGER *sLength) */
static RETCODE _ruby_ibm_db_get_length(stmt_handle* stmt_res, SQLUSMALLINT col_num, SQLINTEGER *sLength)
{
  RETCODE          rc               = SQL_SUCCESS;
  SQLHANDLE        new_hstmt;
  get_length_args  *getLength_args  =  NULL;

  rc = SQLAllocHandle(SQL_HANDLE_STMT, stmt_res->hdbc, &new_hstmt);

  if ( rc < SQL_SUCCESS ) {
    if( stmt_res->ruby_stmt_err_msg == NULL ) {
      stmt_res->ruby_stmt_err_msg  =  ALLOC_N(char, DB2_MAX_ERR_MSG_LEN+1 );
    }
    memset( stmt_res->ruby_stmt_err_msg, '\0', DB2_MAX_ERR_MSG_LEN+1 );

    _ruby_ibm_db_check_sql_errors( stmt_res , DB_STMT, stmt_res->hdbc, SQL_HANDLE_DBC, rc, 0, 
              stmt_res->ruby_stmt_err_msg, &(stmt_res->ruby_stmt_err_msg_len), 1, 1, 0 );
    return SQL_ERROR;
  }

  getLength_args = ALLOC( get_length_args );
  memset(getLength_args,'\0',sizeof(struct _ibm_db_get_data_length_struct));

  getLength_args->new_hstmt    =  &( new_hstmt);
  getLength_args->col_num      =  col_num;
  getLength_args->stmt_res     =  stmt_res;
  getLength_args->sLength      =  sLength;

  rc = _ruby_ibm_db_SQLGetLength_helper( getLength_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)new_hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
  }

  /*Free Memory Allocated*/
  if ( getLength_args != NULL ) {
    ruby_xfree( getLength_args );
    getLength_args = NULL;
  }

  SQLFreeHandle(SQL_HANDLE_STMT, new_hstmt);

  return rc;
}
/* }}} */
     
/* {{{ static RETCODE _ruby_ibm_db_get_data2(stmt_handle *stmt_res, int col_num, short ctype, void *buff, int in_length, SQLINTEGER *out_length) */
static RETCODE _ruby_ibm_db_get_data2(stmt_handle *stmt_res, SQLUSMALLINT col_num, SQLSMALLINT ctype, SQLPOINTER buff, SQLLEN read_length, SQLLEN buff_length, SQLINTEGER *out_length)
{
  RETCODE rc = SQL_SUCCESS;
  SQLHANDLE new_hstmt;
  get_subString_args *getSubString_args;

  rc = SQLAllocHandle(SQL_HANDLE_STMT, stmt_res->hdbc, &new_hstmt);

  if ( rc < SQL_SUCCESS ) {
    if( stmt_res->ruby_stmt_err_msg == NULL ) {
      stmt_res->ruby_stmt_err_msg  =  ALLOC_N(char, DB2_MAX_ERR_MSG_LEN+1 );
    }
    memset( stmt_res->ruby_stmt_err_msg, '\0', DB2_MAX_ERR_MSG_LEN+1 );

    _ruby_ibm_db_check_sql_errors( stmt_res , DB_STMT, stmt_res->hdbc, SQL_HANDLE_DBC, rc, 0, 
              stmt_res->ruby_stmt_err_msg, &(stmt_res->ruby_stmt_err_msg_len),1, 1, 0 );

    return SQL_ERROR;
  }

  getSubString_args = ALLOC( get_subString_args );
  memset(getSubString_args,'\0', sizeof(struct _ibm_db_get_data_subString_struct) );

  getSubString_args->new_hstmt    =  &new_hstmt;
  getSubString_args->col_num      =  col_num;
  getSubString_args->stmt_res     =  stmt_res;
  getSubString_args->forLength    =  read_length;
  getSubString_args->targetCType  =  ctype;
  getSubString_args->buffer       =  buff;
  getSubString_args->buff_length  =  buff_length;
  getSubString_args->out_length   =  out_length;
  
  rc = _ruby_ibm_db_SQLGetSubString_helper( getSubString_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)new_hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
  }

  SQLFreeHandle(SQL_HANDLE_STMT, new_hstmt);

  if ( getSubString_args != NULL ) {
    ruby_xfree( getSubString_args );
    getSubString_args = NULL;
  }

  return rc;
}

/*Function to check if the value of the LOB in the column is null or not*/
int isNullLOB(VALUE *return_value,int i,stmt_handle *stmt_res,int op)
{
    VALUE colName;
    if (stmt_res->column_info[i].loc_ind == SQL_NULL_DATA) {
        if ( op & FETCH_ASSOC ) {
#ifdef UNICODE_SUPPORT_VERSION
          colName = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->column_info[i].name, stmt_res->column_info[i].name_length * sizeof(SQLWCHAR) );
#else
          colName = rb_str_new2( (char*)stmt_res->column_info[i].name );
#endif
          rb_hash_aset(*return_value, colName, Qnil);
        }
        if ( op == FETCH_INDEX ) {
          rb_ary_store(*return_value, i, Qnil);
        } else if ( op == FETCH_BOTH ) {
          rb_hash_aset(*return_value, INT2NUM(i), Qnil);
        }
          return 1;
    }
        return 0;
}

/*
  static VALUE _ruby_ibm_db_result_helper(ibm_db_result_args *data)

  In this function Qnil, Qfalse and Qtrue all are valid output values. Hence in this case a exception condition will be 
  thrown with a return value of Qnil and also the allocation of memory for error is to be done only when exception is raised
  This is because in the caller function a rb_throw call is made only if return value is Qnil and error == NULL.
  In all other cases the value returned will be either Qfalse (meaning SQL_NO_DATA), VALUE or Qnil (meaning the value is nil)
*/
static VALUE _ruby_ibm_db_result_helper(ibm_db_result_args *data) {
	
	
  long          col_num;
  RETCODE       rc;
  SQLPOINTER    out_ptr;
  double        double_val;

  SQLINTEGER    in_length, out_length      =  -10; /*Initialize out_length to some meaningless value*/
  SQLSMALLINT   column_type, lob_bind_type =  SQL_C_BINARY;
  SQLINTEGER    long_val;

  VALUE         return_value   =  Qnil;
  stmt_handle   *stmt_res      =  data->stmt_res;
  VALUE         column         =  data->column;
  VALUE 		ret_value;

  if(TYPE(column) == T_STRING) {
    col_num = _ruby_ibm_db_get_column_by_name(stmt_res, column, 0);
  } else {
    col_num = NUM2INT(column);
  }

  /* get column header info*/
  if ( stmt_res->column_info == NULL ) {
    if (_ruby_ibm_db_get_result_set_info(stmt_res)<0) {
      if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: "),
                           _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                     stmt_res->ruby_stmt_err_msg_len)
                         );
#else
        *(data->error) = rb_str_cat2(rb_str_new2("Column information cannot be retrieved: "), stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: <error message could not be retrieved>");
#else
        *(data->error) = rb_str_new2("Column information cannot be retrieved: <error message could not be retrieved>");
#endif
      }
	  data->return_value = Qnil;
      return Qnil;
    }
  }

  if(col_num < 0 || col_num >= stmt_res->num_columns) {
#ifdef UNICODE_SUPPORT_VERSION
    *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Column ordinal out of range" );
#else
    *(data->error) = rb_str_new2("Column ordinal out of range" );
#endif
    data->return_value = Qnil;
    return Qnil;
  }

  /* get the data */
  column_type = stmt_res->column_info[col_num].type;

  switch(column_type) {
    case SQL_CHAR:
    case SQL_WCHAR:
    case SQL_VARCHAR:
    case SQL_WVARCHAR:
    case SQL_GRAPHIC:
    case SQL_VARGRAPHIC:
#ifndef PASE /* i5/OS SQL_LONGVARCHAR is SQL_VARCHAR */
    case SQL_LONGVARCHAR:
    case SQL_WLONGVARCHAR:
      in_length = stmt_res->column_info[col_num].size + 1;

#ifdef UNICODE_SUPPORT_VERSION
      out_ptr = (SQLPOINTER)ALLOC_N(SQLWCHAR,in_length);
      memset(out_ptr, '\0', in_length * sizeof(SQLWCHAR) );
#else
      if( column_type == SQL_GRAPHIC || column_type == SQL_VARGRAPHIC ) {
          /* Graphic string is 2 byte character string.
           * Size multiply by 2 is required only for non-unicode support version because the W equivalent functions return
           * SQLType as wchar or wvarchar, respectively. Hence is handled properly.
          */
        in_length = in_length * 2;
      }
	  
      if( column_type == SQL_CHAR || column_type == SQL_VARCHAR ) {
          /* Multiply size by 4 to handle different client and server codepages.
           * factor of 4 should suffice as known characters today well fit in 4 bytes.
           */
        in_length = in_length * 4;
      }
	  
      out_ptr = (SQLPOINTER)ALLOC_N(char,in_length);
      memset(out_ptr, '\0', in_length);
#endif

      if ( out_ptr == NULL ) {
        rb_warn( "Failed to Allocate Memory while trying to retrieve the result" );
		data->return_value = Qnil;
        return Qnil;
      }

#ifdef UNICODE_SUPPORT_VERSION
      rc = _ruby_ibm_db_get_data(stmt_res, col_num+1, SQL_C_WCHAR, out_ptr, in_length * sizeof(SQLWCHAR) , &out_length);
#else
      rc = _ruby_ibm_db_get_data(stmt_res, col_num+1, SQL_C_CHAR, out_ptr, in_length, &out_length);
#endif

      if ( rc == SQL_ERROR ) {
		data->return_value = Qfalse;
        return Qfalse;
      }
      if (out_length == SQL_NULL_DATA) {
        ruby_xfree( out_ptr );
		data->return_value = Qnil;
        return Qnil;
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        return_value = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(out_ptr, out_length);
#else
        return_value = rb_str_new((char*)out_ptr, out_length);
#endif
        ruby_xfree( out_ptr );
        out_ptr = NULL;
		data->return_value = return_value;
        return return_value;
      }
      break;
#endif /* PASE */
    case SQL_TYPE_DATE:
    case SQL_TYPE_TIME:
    case SQL_TYPE_TIMESTAMP:
    case SQL_BIGINT:
    case SQL_DECIMAL:
    case SQL_NUMERIC:
    case SQL_DECFLOAT:
      if (column_type == SQL_DECIMAL || column_type == SQL_NUMERIC){
        in_length = stmt_res->column_info[col_num].size + stmt_res->column_info[col_num].scale + 2 + 1;
      } else {
        in_length = stmt_res->column_info[col_num].size+1;
      }

      out_ptr = (SQLPOINTER)ALLOC_N(char,in_length);
      memset(out_ptr, '\0', in_length);
  
      if ( out_ptr == NULL ) {
        rb_warn( "Failed to Allocate Memory while trying to retrieve the result" );
		data->return_value = Qnil;
        return Qnil;
      }

      rc = _ruby_ibm_db_get_data(stmt_res, col_num+1, SQL_C_CHAR, out_ptr, in_length, &out_length);

      if ( rc == SQL_ERROR ) {
		data->return_value = Qfalse;
        return Qfalse;
      }

      if (out_length == SQL_NULL_DATA) {
        ruby_xfree( out_ptr );
		data->return_value = Qnil;
        return Qnil;
      } else {
        return_value = rb_str_new2((char*)out_ptr);
        ruby_xfree( out_ptr );
        out_ptr = NULL;
		data->return_value = return_value;
        return return_value;
      }
      break; 
    case SQL_SMALLINT:
    case SQL_INTEGER:
      rc = _ruby_ibm_db_get_data(stmt_res, col_num+1, SQL_C_LONG, &long_val, sizeof(long_val), &out_length);
      if ( rc == SQL_ERROR ) {
		data->return_value = Qfalse;
        return Qfalse;
      }
      if (out_length == SQL_NULL_DATA) {
		data->return_value = Qnil;
        return Qnil;
      } else {
		VALUE ret_value = INT2NUM(long_val);
		data->return_value = ret_value;
        return ret_value;
      }
      break;

    case SQL_REAL:
    case SQL_FLOAT:
    case SQL_DOUBLE:
      rc = _ruby_ibm_db_get_data(stmt_res, col_num+1, SQL_C_DOUBLE, &double_val, sizeof(double_val), &out_length);
      if ( rc == SQL_ERROR ) {
		data->return_value = Qfalse;
        return Qfalse;
      }
      if (out_length == SQL_NULL_DATA) {
		data->return_value = Qnil;
        return Qnil;
      } else {
		VALUE ret_value = rb_float_new(double_val);
		data->return_value = ret_value;
        return ret_value;
      }
      break;

    case SQL_CLOB:

      rc = _ruby_ibm_db_get_length(stmt_res, col_num+1, &in_length);

      if ( rc == SQL_ERROR ) {
		data->return_value = Qfalse;
        return Qfalse;
      }

      if (in_length == SQL_NULL_DATA) {
		data->return_value = Qnil;
        return Qnil;
      }

#ifdef UNICODE_SUPPORT_VERSION
      out_ptr = (char*)ALLOC_N(SQLWCHAR,in_length+1);
      memset(out_ptr, '\0', (in_length + 1) * sizeof(SQLWCHAR)  );
#else
      out_ptr = (char*)ALLOC_N(char,in_length+1);
      memset(out_ptr, '\0', in_length +1 );
#endif

      if ( out_ptr == NULL ) {
        rb_warn( "Failed to Allocate Memory for LOB Data" );
		data->return_value = Qnil;
        return Qnil;
      }

#ifdef UNICODE_SUPPORT_VERSION
      rc = _ruby_ibm_db_get_data2(stmt_res, col_num+1, SQL_C_WCHAR, out_ptr, in_length, (in_length + 1) * sizeof(SQLWCHAR) , &out_length);
#else
      rc = _ruby_ibm_db_get_data2(stmt_res, col_num+1, SQL_C_CHAR, (void*)out_ptr, in_length, in_length+1, &out_length);
#endif

      if (rc == SQL_ERROR) {
		data->return_value = Qfalse;
        return Qfalse;
      }

#ifdef UNICODE_SUPPORT_VERSION
      return_value = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(out_ptr, out_length);
#else
      return_value = rb_str_new2(out_ptr);
#endif

      ruby_xfree( out_ptr );
      out_ptr = NULL;
      data->return_value = return_value;
      return return_value;
      break;

    case SQL_BLOB:
    case SQL_BINARY:
#ifndef PASE /* i5/OS SQL_LONGVARCHAR is SQL_VARCHAR */
    case SQL_LONGVARBINARY:
#endif /* PASE */
    case SQL_VARBINARY:

      rc = _ruby_ibm_db_get_length( stmt_res, col_num+1, &in_length );

      if ( rc == SQL_ERROR ) {
		data->return_value = Qfalse;
        return Qfalse;
      }

      if (in_length == SQL_NULL_DATA) {
		data->return_value = Qnil;
        return Qnil;
      }

      switch (stmt_res->s_bin_mode) {
        case PASSTHRU:		  
		  ret_value = rb_str_new("",0);
		  data->return_value = ret_value;
          return ret_value;
          break;
          /* returns here */
        case CONVERT:
          in_length *= 2;
          lob_bind_type = SQL_C_CHAR;
          /* fall-through */

        case BINARY:
          out_ptr = (SQLPOINTER)ALLOC_N(char,in_length);
          memset(out_ptr, '\0', in_length);

          if ( out_ptr == NULL ) {
            rb_warn( "Failed to Allocate Memory for LOB Data" );
			data->return_value = Qnil;
            return Qnil;
          }

          rc = _ruby_ibm_db_get_data2(stmt_res, col_num+1, lob_bind_type, out_ptr, in_length, in_length, &out_length);

          if (rc == SQL_ERROR) {
			data->return_value = Qfalse;
            return Qfalse;
          }
          return_value = rb_str_new((char*)out_ptr,out_length);
          ruby_xfree( out_ptr );
          out_ptr = NULL;
		  data->return_value = return_value;
          return return_value;
        default:
          break;
      }
      break;
    case SQL_XML:

      rc      =  _ruby_ibm_db_get_data(stmt_res, col_num+1, SQL_C_BINARY, NULL, 0, (SQLINTEGER *)&in_length);

      if ( rc == SQL_ERROR ) {
		data->return_value = Qfalse;
        return Qfalse;
      }

      if (in_length == SQL_NULL_DATA) {
		data->return_value = Qnil;
        return Qnil;
      }

      out_ptr = (SQLPOINTER)ALLOC_N(char, in_length);
      memset(out_ptr, '\0', in_length );

      if ( out_ptr == NULL ) {
        rb_warn( "Failed to Allocate Memory for LOB Data" );
		data->return_value = Qnil;
        return Qnil;
      }

      rc = _ruby_ibm_db_get_data(stmt_res, col_num+1, SQL_C_BINARY, out_ptr, in_length, &out_length);

      if (rc == SQL_ERROR) {
        ruby_xfree( out_ptr );
        out_ptr  =  NULL;
		data->return_value = Qfalse;
        return Qfalse;
      }

#ifdef UNICODE_SUPPORT_VERSION
      return_value = _ruby_ibm_db_export_sqlchar_to_utf8_rstr(out_ptr, out_length);
#else
      return_value = rb_str_new((char*)out_ptr,out_length);
#endif

      ruby_xfree( out_ptr );
      out_ptr  =  NULL;
      data->return_value = return_value;
      return return_value;

    default:
      break;
  }

  data->return_value = Qfalse;
  return Qfalse;
}
/* }}} */

/*
 * IBM_DB.result --  Returns a single column from a row in the result set
 * 
 * ===Description
 * mixed IBM_DB.result ( resource stmt, mixed column )
 * 
 * Use IBM_DB.result() to return the value of a specified column in the current row of a result set. You must call IBM_DB.fetch_row() before calling IBM_DB.result() to set the location of the result set pointer.
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid stmt resource. 
 * 
 * column
 *     Either an integer mapping to the 0-indexed field in the result set, or a string matching the name of the column. 
 * 
 * ===Return Values
 * 
 * Returns the value of the requested field if the field exists in the result set. Returns NULL if the field does not exist, and issues a warning. 
 */
VALUE ibm_db_result(int argc, VALUE *argv, VALUE self)
{
  ibm_db_result_args *result_args  =  NULL;
  VALUE ret_val                    =  Qfalse;
  VALUE stmt                       =  Qnil;

  VALUE error  =  Qnil;

  result_args = ALLOC( ibm_db_result_args );
  memset(result_args,'\0',sizeof(struct _ibm_db_result_args_struct));

  result_args->stmt_res   =  NULL;
  result_args->column     =  Qnil;
  result_args->error      =  &error;

  rb_scan_args(argc, argv, "2", &stmt, &(result_args->column) );

  if ( !NIL_P( stmt ) ) {
    Data_Get_Struct(stmt, stmt_handle, result_args->stmt_res);

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_result_helper, result_args,
                          (void *)_ruby_ibm_db_Statement_level_UBF, result_args->stmt_res );
	  ret_val = result_args->return_value;
    #else
      ret_val = _ruby_ibm_db_result_helper( result_args );
    #endif

  } else {
    rb_warn("Invalid Statement resource specified");
    ret_val = Qnil;
  }

  /* Free Memory Allocated */
  if ( result_args != NULL ) {
    ruby_xfree( result_args );
    result_args = NULL;
  }

  if( error != Qnil && ret_val == Qnil) {
    rb_warn( RSTRING_PTR(error) );
    ret_val = Qnil;
  }

  return ret_val;
}
/*  */

/*  static VALUE _ruby_ibm_db_bind_fetch_helper(ibm_db_fetch_helper_args *data)
*/
static VALUE _ruby_ibm_db_bind_fetch_helper(ibm_db_fetch_helper_args *data)
{
  int         rc             = -1;
  int         i;
  int         op;
  SQLLEN      row_number     =  -1;
  stmt_handle *stmt_res      =  NULL;

  SQLSMALLINT column_type, lob_bind_type = SQL_C_BINARY;

  ibm_db_row_data_type  *row_data;
  SQLINTEGER            out_length, tmp_length;
  SQLPOINTER            out_ptr;

  char  *tmpStr       =  NULL;

  VALUE return_value  =  Qnil;
  VALUE colName       =  Qnil;

  fetch_data_args *fetch_args = NULL;

  if (!NIL_P( data->row_number )) {
    row_number = NUM2LONG( data->row_number );
  }

  stmt_res  =  data->stmt_res;
  op        =  data->funcType;

  _ruby_ibm_db_init_error_info(stmt_res);

  /* get column header info*/
  if ( stmt_res->column_info == NULL ) {
    if (_ruby_ibm_db_get_result_set_info(stmt_res)<0) {
      if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: "),
                           _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->ruby_stmt_err_msg,
                                     stmt_res->ruby_stmt_err_msg_len)
                         );
#else
        *(data->error) = rb_str_cat2(rb_str_new2("Column information cannot be retrieved: "), stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: <error message could not be retrieved>");
#else
        *(data->error) = rb_str_new2("Column information cannot be retrieved: <error message could not be retrieved>");
#endif
      }
	  data->return_value = Qnil;
      return Qnil;
    }
  }

  /* bind the data */
  if ( stmt_res->row_data == NULL ) {
    rc = _ruby_ibm_db_bind_column_helper(stmt_res);
    if ( rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO ) {
      if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Column binding cannot be done: "),
                           _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->ruby_stmt_err_msg,
                                     stmt_res->ruby_stmt_err_msg_len)
                         );
#else
        *(data->error) = rb_str_cat2(rb_str_new2("Column binding cannot be done: "), stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Column binding cannot be done: <error message could not be retrieved>");
#else
        *(data->error) = rb_str_new2("Column binding cannot be done: <error message could not be retrieved>");
#endif
      }
	  data->return_value = Qnil;
      return Qnil;
    }
  }

  /* check if row_number is present */
  if (data->arg_count == 2 && row_number > 0) {
    fetch_args = ALLOC( fetch_data_args );
    memset(fetch_args,'\0',sizeof(struct _ibm_db_fetch_data_struct));

    fetch_args->stmt_res  =  stmt_res;

#ifndef PASE /* i5/OS problem with SQL_FETCH_ABSOLUTE (temporary until fixed) */
    if (is_systemi) {
      fetch_args->fetchOrientation  =  SQL_FETCH_FIRST;
      fetch_args->fetchOffset       =  row_number;

      rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );

      if (row_number>1 && (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO)) {
        fetch_args->fetchOrientation =  SQL_FETCH_RELATIVE;
        fetch_args->fetchOffset      =  row_number - 1;

        rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );
      }
    } else {
      fetch_args->fetchOrientation  =  SQL_FETCH_ABSOLUTE;
      fetch_args->fetchOffset       =  row_number;

      rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );
    }
#else /*PASE */
    fetch_args->fetchOrientation    =  SQL_FETCH_FIRST;
    fetch_args->fetchOffset         =  row_number;

    rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );

    if (row_number>1 && (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO)) {
      fetch_args->fetchOrientation  =  SQL_FETCH_RELATIVE;
      fetch_args->fetchOffset       =  row_number - 1;

      rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );
    }
#endif /*PASE*/
  } else if (data->arg_count == 2 && row_number < 0) {
#ifdef UNICODE_SUPPORT_VERSION
    *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Requested row number must be a positive value");
#else
    *(data->error) = rb_str_new2("Requested row number must be a positive value");
#endif
    data->return_value = Qnil;
    return Qnil;
  } else {
    /*row_number is NULL or 0; just fetch next row*/
    fetch_args = ALLOC( fetch_data_args );
    memset(fetch_args,'\0',sizeof(struct _ibm_db_fetch_data_struct));

    fetch_args->stmt_res  =  stmt_res;

    rc = _ruby_ibm_db_SQLFetch_helper( fetch_args );
  }

  /*Free Memory Allocated*/
  if ( fetch_args != NULL ) {
    ruby_xfree( fetch_args );
    fetch_args = NULL;
  }

  if (rc == SQL_NO_DATA_FOUND) {
	data->return_value = Qfalse;
    return Qfalse;
  } else if ( rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
    _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
    if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
      *(data->error) = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Fetch Failure: "),
                         _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                      stmt_res->ruby_stmt_err_msg_len )
                       );
#else
      *(data->error) = rb_str_cat2(rb_str_new2("Fetch Failure: "), stmt_res->ruby_stmt_err_msg );
#endif
    } else {
#ifdef UNICODE_SUPPORT_VERSION
      *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Fetch Failure: <error message could not be retrieved>");
#else
      *(data->error) = rb_str_new2("Fetch Failure: <error message could not be retrieved>");
#endif
    }
	data->return_value = Qnil;
    return Qnil;
  }
  /* copy the data over return_value */
  if ( op & FETCH_ASSOC ) {
      return_value = rb_hash_new();
  } else if ( op == FETCH_INDEX ) {
      return_value = rb_ary_new();
  }

  for (i=0; i<stmt_res->num_columns; i++) {
    column_type  =  stmt_res->column_info[i].type;
    row_data     =  &stmt_res->row_data[i].data;
    out_length   =  stmt_res->row_data[i].out_length;

    switch(stmt_res->s_case_mode) {
      case CASE_LOWER:
#ifdef UNICODE_SUPPORT_VERSION
        strtolower((char*)stmt_res->column_info[i].name, stmt_res->column_info[i].name_length * sizeof(SQLWCHAR));
#else
        strtolower((char*)stmt_res->column_info[i].name, strlen((char*)stmt_res->column_info[i].name));
#endif
        break;
      case CASE_UPPER:
#ifdef UNICODE_SUPPORT_VERSION
        strtoupper((char*)stmt_res->column_info[i].name, stmt_res->column_info[i].name_length * sizeof(SQLWCHAR) );
#else
        strtoupper((char*)stmt_res->column_info[i].name, strlen((char*)stmt_res->column_info[i].name));
#endif
        break;
      case CASE_NATURAL:
      default:
        break;
    }

#ifdef UNICODE_SUPPORT_VERSION
    colName = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->column_info[i].name, stmt_res->column_info[i].name_length * sizeof(SQLWCHAR) );
#else
    colName = rb_str_new2((char*)stmt_res->column_info[i].name);
#endif

    if (out_length == SQL_NULL_DATA) {
      if ( op & FETCH_ASSOC ) {
        rb_hash_aset(return_value, colName, Qnil);
      }
      if ( op == FETCH_INDEX ) {
        rb_ary_store(return_value, i, Qnil);
      } else if ( op == FETCH_BOTH ) {
        rb_hash_aset(return_value, INT2NUM(i), Qnil);
      }
    } else {
      switch(column_type) {
        case SQL_CHAR:
        case SQL_WCHAR:
        case SQL_VARCHAR:
        case SQL_WVARCHAR:
        case SQL_GRAPHIC:
        case SQL_VARGRAPHIC:
#ifndef PASE /* i5/OS SQL_LONGVARCHAR is SQL_VARCHAR */
        case SQL_LONGVARCHAR:
        case SQL_WLONGVARCHAR:
          if ( op & FETCH_ASSOC ) {
#ifdef UNICODE_SUPPORT_VERSION
            rb_hash_aset(return_value, colName, _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(row_data->str_val, out_length ));
#else
            rb_hash_aset(return_value, colName, rb_str_new((char *)row_data->str_val, out_length));
#endif
          }
          if ( op == FETCH_INDEX ) {
#ifdef UNICODE_SUPPORT_VERSION
            rb_ary_store(return_value, i, _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(row_data->str_val, out_length ));
#else
            rb_ary_store(return_value, i, rb_str_new((char *)row_data->str_val, out_length));
#endif
          } else if ( op == FETCH_BOTH ) {
#ifdef UNICODE_SUPPORT_VERSION
            rb_hash_aset(return_value, INT2NUM(i), _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(row_data->str_val, out_length ));
#else
            rb_hash_aset(return_value, INT2NUM(i), rb_str_new((char *)row_data->str_val, out_length));
#endif
          }
          break;
#else /* PASE */
          /* i5/OS will xlate from EBCIDIC to ASCII (via SQLGetData) */
          tmp_length =  stmt_res->column_info[i].size;
          out_ptr    =  (SQLPOINTER)ALLOC_N(char, tmp_length+1);
          if ( out_ptr == NULL ) {
            rb_warn( "Failed to allocate Memory");
			data->return_value = Qnil;
            return Qnil;
          }
          memset(out_ptr,'\0',tmp_length+1);
          out_length = 0;
          rc = _ruby_ibm_db_get_data(stmt_res, i+1, SQL_C_CHAR, out_ptr, tmp_length+1, &out_length);
          if ( rc == SQL_ERROR ) {
            ruby_xfree( out_ptr );
            out_ptr = NULL;
			data->return_value = Qfalse;
            return Qfalse;
          }
          if (out_length == SQL_NULL_DATA) {
            if ( op & FETCH_ASSOC ) {
              rb_hash_aset(return_value, colName, Qnil);
            }
            if ( op & FETCH_INDEX ) {
              rb_ary_store(return_value, i, Qnil);
            }
          } else {
            out_ptr[tmp_length] = '\0';
            if ( op & FETCH_ASSOC ) {
              rb_hash_aset(return_value, colName, rb_str_new2((char *)out_ptr));
            }
            if ( op & FETCH_INDEX ) {
              rb_ary_store(return_value, i, rb_str_new2((char *)out_ptr));
            }
          }
          ruby_xfree( out_ptr );
          out_ptr = NULL;
          break;
#endif /* PASE */
        case SQL_TYPE_DATE:
        case SQL_TYPE_TIME:
        case SQL_TYPE_TIMESTAMP:
        case SQL_BIGINT:

          if ( op & FETCH_ASSOC ) {
            rb_hash_aset(return_value, colName, rb_str_new2((char *)row_data->str_val));
          }
          if ( op == FETCH_INDEX ) {
            rb_ary_store(return_value, i, rb_str_new2((char *)row_data->str_val));
          } else if ( op == FETCH_BOTH ) {
            rb_hash_aset(return_value, INT2NUM(i), rb_str_new2((char *)row_data->str_val));
          }
          break;

        case SQL_DECIMAL:
        case SQL_NUMERIC:
        case SQL_DECFLOAT:
          tmpStr = ALLOC_N(char, strlen(row_data->str_val) + 19);

          if(tmpStr == NULL ){
           rb_warn( "Failed to Allocate Memory for Decimal Data" );
		   data->return_value = Qnil;
           return Qnil; 
          }

          strcpy(tmpStr, "BigDecimal.new(\'");
          strcat(tmpStr, row_data->str_val);
          strcat(tmpStr, "\')");

          if ( op & FETCH_ASSOC ) {
            rb_hash_aset(return_value, colName, rb_eval_string(tmpStr));
          }
          if ( op == FETCH_INDEX ) {
            rb_ary_store(return_value, i, rb_eval_string(tmpStr) );
          } else if ( op == FETCH_BOTH ) {
            rb_hash_aset( return_value, INT2NUM(i), rb_eval_string( tmpStr ) );
          }

          ruby_xfree(tmpStr);
          tmpStr = NULL;

          break;
        case SQL_SMALLINT:
          if ( op & FETCH_ASSOC ) {
            rb_hash_aset(return_value, colName, INT2NUM(row_data->s_val));
          }
          if ( op == FETCH_INDEX ) {
            rb_ary_store(return_value, i, INT2NUM(row_data->s_val));
          } else if ( op == FETCH_BOTH ) {
            rb_hash_aset(return_value, INT2NUM(i), INT2NUM(row_data->s_val));
          }
          break;
        case SQL_INTEGER:
          if ( op & FETCH_ASSOC ) {
            rb_hash_aset(return_value, colName, INT2NUM(row_data->i_val));
          }
          if ( op == FETCH_INDEX ) {
            rb_ary_store(return_value, i, INT2NUM(row_data->i_val));
          } else if ( op == FETCH_BOTH ) {
            rb_hash_aset(return_value, INT2NUM(i), INT2NUM(row_data->i_val));
          }
          break;

        case SQL_REAL:
        case SQL_FLOAT:
          if ( op & FETCH_ASSOC ) {
            rb_hash_aset(return_value, colName, rb_float_new(row_data->f_val));
          }
          if ( op == FETCH_INDEX ) {
            rb_ary_store(return_value, i, rb_float_new(row_data->f_val));
          } else if ( op == FETCH_BOTH ) {
            rb_hash_aset(return_value, INT2NUM(i), rb_float_new(row_data->f_val));
          }
          break;

        case SQL_DOUBLE:
          if ( op & FETCH_ASSOC ) {
            rb_hash_aset(return_value, colName, rb_float_new(row_data->d_val));
          }
          if ( op == FETCH_INDEX ) {
            rb_ary_store(return_value, i, rb_float_new(row_data->d_val));
          } else if ( op == FETCH_BOTH ) {
            rb_hash_aset(return_value, INT2NUM(i), rb_float_new(row_data->d_val));
          }
          break;

        case SQL_BINARY:
#ifndef PASE /* i5/OS SQL_LONGVARBINARY is SQL_VARBINARY */
        case SQL_LONGVARBINARY:
#endif /* PASE */
        case SQL_VARBINARY:
          if ( stmt_res->s_bin_mode == PASSTHRU ) {
            if ( op & FETCH_ASSOC ) {
              rb_hash_aset(return_value, colName, rb_str_new("",0));
            }
            if ( op == FETCH_INDEX ) {
              rb_ary_store(return_value, i, rb_str_new("",0));
            } else if ( op == FETCH_BOTH ) {
              rb_hash_aset(return_value, INT2NUM(i), rb_str_new("",0));
            }
          } else {
            if ( op & FETCH_ASSOC ) {
              rb_hash_aset(return_value, colName, rb_str_new((char *)row_data->str_val, out_length));
            }
            if ( op == FETCH_INDEX ) {
              rb_ary_store(return_value, i, rb_str_new((char *)row_data->str_val, out_length));
            } else if ( op == FETCH_BOTH ) {
              rb_hash_aset(return_value, INT2NUM(i), rb_str_new((char *)row_data->str_val, out_length));
            }
          }
          break;

        case SQL_BLOB:
        
        /*Check if the data value in the column is null*/
        
          if(isNullLOB(&return_value,i,stmt_res,op))
          {
            break;
          }
          out_ptr  =  NULL;
          rc       =  _ruby_ibm_db_get_length(stmt_res, i+1, &tmp_length);

          if (tmp_length == SQL_NULL_DATA) {
            if ( op & FETCH_ASSOC ) {
              rb_hash_aset(return_value, colName, Qnil);
            }
            if ( op == FETCH_INDEX ) {
              rb_ary_store(return_value, i, Qnil);
            } else if ( op == FETCH_BOTH ) {
              rb_hash_aset(return_value, INT2NUM(i), Qnil);
            }
          } else {
            if (rc == SQL_ERROR) tmp_length = 0;
            switch (stmt_res->s_bin_mode) {
              case PASSTHRU:
                if ( op & FETCH_ASSOC ) {
                    rb_hash_aset(return_value, colName, Qnil);
                }
                if ( op == FETCH_INDEX ) {
                    rb_ary_store(return_value, i, Qnil);
                } else if ( op == FETCH_BOTH ) {
                    rb_hash_aset(return_value, INT2NUM(i), Qnil);
                }
                break;

              case CONVERT:
                tmp_length    =  2*tmp_length + 1;
                lob_bind_type =  SQL_C_CHAR;
                /* fall-through */

              case BINARY:
                out_ptr    = (SQLPOINTER)ALLOC_N(char, tmp_length);
                out_length = 0;

                rc = _ruby_ibm_db_get_data2(stmt_res, i+1, lob_bind_type, (char *)out_ptr, tmp_length, tmp_length, &out_length);
                if (rc == SQL_ERROR) {
                  ruby_xfree( out_ptr );
                  out_ptr = NULL;
                  out_length = 0;
				  data->return_value = Qfalse;
                  return Qfalse;
                }

                if ( op & FETCH_ASSOC ) {
                  rb_hash_aset(return_value, colName, rb_str_new((char*)out_ptr, out_length));
                }
                if ( op == FETCH_INDEX ) {
                  rb_ary_store(return_value, i, rb_str_new((char*)out_ptr, out_length));
                } else if ( op == FETCH_BOTH ) {
                  rb_hash_aset(return_value, INT2NUM(i), rb_str_new((char*)out_ptr, out_length));
                }

                ruby_xfree( out_ptr );
                out_ptr = NULL;
                out_length = 0;
                break;
              default:
                break;
            }
          }
          break;

        case SQL_XML:
        
        /*Check if the data value in the column is null*/

          if(isNullLOB(&return_value,i,stmt_res,op))
          {
            break;
          }

          out_ptr =  NULL;
          rc      =  _ruby_ibm_db_get_data(stmt_res, i+1, SQL_C_BINARY, NULL, 0, (SQLINTEGER *)&tmp_length);

          if ( rc == SQL_ERROR ) {
            if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
              *(data->error) = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Failed to Determine XML Size: "),
                                 _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                           stmt_res->ruby_stmt_err_msg_len)
                               );
#else
              *(data->error) = rb_str_cat2(rb_str_new2("Failed to Determine XML Size: "), stmt_res->ruby_stmt_err_msg );
#endif
            } else {
#ifdef UNICODE_SUPPORT_VERSION
              *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Failed to Determine XML Size: <error message could not be retrieved>");
#else
              *(data->error) = rb_str_new2("Failed to Determine XML Size: <error message could not be retrieved>");
#endif
            }
			data->return_value = Qnil;
            return Qnil;
          }

          if (tmp_length == SQL_NULL_DATA) {
            if ( op & FETCH_ASSOC ) {
              rb_hash_aset(return_value, colName, Qnil);
            }
            if ( op & FETCH_INDEX ) {
              rb_ary_store(return_value, i, Qnil);
            } else if ( op == FETCH_BOTH) {
              rb_hash_aset(return_value, INT2NUM(i), Qnil);
            }
          } else {
            out_ptr    = (SQLPOINTER)ALLOC_N(char, tmp_length);
            memset(out_ptr, '\0', tmp_length);
            out_length = 0;

            if ( out_ptr == NULL ) {
              rb_warn( "Failed to Allocate Memory for XML Data" );
			  data->return_value = Qnil;
              return Qnil;
            }

            rc = _ruby_ibm_db_get_data(stmt_res, i+1, SQL_C_BINARY, out_ptr, tmp_length, &out_length);
            if (rc == SQL_ERROR) {
              ruby_xfree( out_ptr );
              out_ptr = NULL;
			  data->return_value = Qfalse;
              return Qfalse;
            }

            if ( op & FETCH_ASSOC ) {
#ifdef UNICODE_SUPPORT_VERSION
              rb_hash_aset(return_value, colName, _ruby_ibm_db_export_sqlchar_to_utf8_rstr( (SQLCHAR *) out_ptr, out_length));
#else
              rb_hash_aset(return_value, colName, rb_str_new((char *)out_ptr, out_length));
#endif
            }
            if ( op == FETCH_INDEX ) {
#ifdef UNICODE_SUPPORT_VERSION
              rb_ary_store(return_value, i, _ruby_ibm_db_export_sqlchar_to_utf8_rstr( (SQLCHAR *) out_ptr, out_length));
#else
              rb_ary_store(return_value, i, rb_str_new((char *)out_ptr, out_length));
#endif
            } else if ( op == FETCH_BOTH ) {
#ifdef UNICODE_SUPPORT_VERSION
              rb_hash_aset(return_value, INT2NUM(i), _ruby_ibm_db_export_sqlchar_to_utf8_rstr( (SQLCHAR *) out_ptr, out_length));
#else
              rb_hash_aset(return_value, INT2NUM(i), rb_str_new((char *)out_ptr, out_length));
#endif
            }
            ruby_xfree( out_ptr );
            out_ptr = NULL;
          }
          break;

        case SQL_CLOB:
        
        /*Check if the data value in the column is null*/

          if(isNullLOB(&return_value,i,stmt_res,op))
          {
            break;
          }
          out_ptr =  NULL;
          rc      =  _ruby_ibm_db_get_length(stmt_res, i+1, &tmp_length);

          if (tmp_length == SQL_NULL_DATA) {
            if ( op & FETCH_ASSOC ) {
              rb_hash_aset(return_value, colName, Qnil);
            }
            if ( op == FETCH_INDEX ) {
              rb_ary_store(return_value, i, Qnil);
            } else if ( op == FETCH_BOTH ) {
              rb_hash_aset(return_value, INT2NUM(i), Qnil);
            }
          } else {
            if (rc == SQL_ERROR) tmp_length = 0;
#ifdef UNICODE_SUPPORT_VERSION
            out_ptr    = (SQLPOINTER)ALLOC_N(SQLWCHAR, tmp_length + 1);
            memset(out_ptr, '\0', (tmp_length+1) * sizeof(SQLWCHAR));
#else
            out_ptr    = (SQLPOINTER)ALLOC_N(char, tmp_length + 1);
            memset(out_ptr, '\0', tmp_length + 1);
#endif
            out_length = 0;

            if ( out_ptr == NULL ) {
              rb_warn( "Failed to Allocate Memory for LOB Data" );
			  data->return_value = Qnil;
              return Qnil;
            }

#ifdef UNICODE_SUPPORT_VERSION
            rc = _ruby_ibm_db_get_data2(stmt_res, i+1, SQL_C_WCHAR, out_ptr, tmp_length , (tmp_length + 1) * sizeof(SQLWCHAR) , &out_length);
#else
            rc = _ruby_ibm_db_get_data2(stmt_res, i+1, SQL_C_CHAR, out_ptr, tmp_length, tmp_length+1, &out_length);
#endif
            if (rc == SQL_ERROR) {
              ruby_xfree( out_ptr );
              out_ptr =  NULL;
              out_length = 0;
			  data->return_value = Qfalse;
              return Qfalse;
            }

            if ( op & FETCH_ASSOC ) {
#ifdef UNICODE_SUPPORT_VERSION
              rb_hash_aset(return_value, colName, _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(out_ptr, out_length));
#else
              rb_hash_aset(return_value, colName, rb_str_new((char*)out_ptr, out_length));
#endif
            }
            if ( op == FETCH_INDEX ) {
#ifdef UNICODE_SUPPORT_VERSION
              rb_ary_store(return_value, i, _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(out_ptr, out_length));
#else
              rb_ary_store(return_value, i, rb_str_new((char*)out_ptr, out_length));
#endif
            } else if ( op == FETCH_BOTH ) {
#ifdef UNICODE_SUPPORT_VERSION
              rb_hash_aset(return_value, INT2NUM(i), _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(out_ptr, out_length));
#else
              rb_hash_aset(return_value, INT2NUM(i), rb_str_new((char*)out_ptr, out_length));
#endif
            }
            ruby_xfree( out_ptr );
            out_ptr = NULL;
          }
          break;

        default:
          break;
      }
    }
  }

  data->return_value = return_value;
  return return_value;
}
/*
  static int _ruby_ibm_db_fetch_row_helper( ibm_db_fetch_helper_args *data)
*/
static int _ruby_ibm_db_fetch_row_helper( ibm_db_fetch_helper_args *data) {
  stmt_handle *stmt_res  = data->stmt_res;
  SQLLEN      row_number = 0;

  VALUE ret_val  =  Qnil;

  int   rc;

  fetch_data_args *fetch_args = NULL;

  if (!NIL_P( data->row_number )) {
    row_number = NUM2LONG( data->row_number );
  }

  /* get column header info*/
  if ( stmt_res->column_info == NULL ) {
    if (_ruby_ibm_db_get_result_set_info(stmt_res)<0) {
      if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: "),
                           _ruby_ibm_db_export_sqlwchar_to_utf8_rstr( stmt_res->ruby_stmt_err_msg,
                                     stmt_res->ruby_stmt_err_msg_len)
                         );
#else
        *(data->error) = rb_str_cat2(rb_str_new2("Column information cannot be retrieved: "), stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: <error message could not be retrieved>");
#else
        *(data->error) = rb_str_new2("Column information cannot be retrieved: <error message could not be retrieved>");
#endif
      }
	  data->return_value = Qnil;
      return Qnil;
    }
  } 

  fetch_args = ALLOC( fetch_data_args );
  memset(fetch_args,'\0',sizeof(struct _ibm_db_fetch_data_struct));

  fetch_args->stmt_res = stmt_res;

  /*check if row_number is present*/
  if (data->arg_count == 2 && row_number > 0) {

#ifndef PASE /* i5/OS problem with SQL_FETCH_ABSOLUTE */
    fetch_args->fetchOrientation   =  SQL_FETCH_ABSOLUTE;
    fetch_args->fetchOffset        =  row_number;

    rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );
#else /*PASE */
    fetch_args->fetchOrientation   =  SQL_FETCH_FIRST;
    fetch_args->fetchOffset        =  row_number;

    rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );

    if (row_number>1 && (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO)) {
      fetch_args->fetchOrientation =  SQL_FETCH_RELATIVE;
      fetch_args->fetchOffset      =  row_number - 1;

      rc = _ruby_ibm_db_SQLFetchScroll_helper( fetch_args );
    }
#endif /*PASE*/
  } else if (data->arg_count == 2 && row_number < 0) {
#ifdef UNICODE_SUPPORT_VERSION
    *(data->error) = _ruby_ibm_db_export_char_to_utf8_rstr("Requested row number must be a positive value");
#else
    *(data->error) = rb_str_new2("Requested row number must be a positive value");
#endif
    data->return_value = Qnil;
    return Qnil;
  } else {
      /*row_number is NULL or 0; just fetch next row*/
    rc = _ruby_ibm_db_SQLFetch_helper( fetch_args );
  }

  /*Free Memory Allocated*/
  if ( fetch_args != NULL ) {
    ruby_xfree( fetch_args );
    fetch_args = NULL;
  }

  if ( ret_val == Qnil ) {
    if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) {
      ret_val = Qtrue;
    } else {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 0 );
      ret_val = Qfalse;
    }
  }
  data->return_value = ret_val;
  return ret_val;
}
/*  */

/*
 * IBM_DB.fetch_row --  Sets the result set pointer to the next row or requested row
 * 
 * ===Description
 * bool IBM_DB.fetch_row ( resource stmt [, int row_number] )
 * 
 * Use IBM_DB.fetch_row() to iterate through a result set, or to point to a specific row in a result set
 * if you requested a scrollable cursor.
 * 
 * To retrieve individual fields from the result set, call the IBM_DB.result() function. Rather than calling
 * IBM_DB.fetch_row() and IBM_DB.result(), most applications will call one of IBM_DB.fetch_assoc(),
 * IBM_DB.fetch_both(), or IBM_DB.fetch_array() to advance the result set pointer and return a complete
 * row as an array.
 * 
 * ===Parameters
 * stmt
 *     A valid stmt resource. 
 * 
 * row_number
 *     With scrollable cursors, you can request a specific row number in the result set. Row numbering
 *     is 1-indexed. 
 * 
 * ===Return Values
 * 
 * Returns TRUE if the requested row exists in the result set. Returns FALSE if the requested row
 * does not exist in the result set. 
 */
VALUE ibm_db_fetch_row(int argc, VALUE *argv, VALUE self)
{
  VALUE row_number       =  Qnil;
  VALUE stmt             =  Qnil;
  VALUE ret_val          =  Qnil;

  VALUE        error     =  Qnil;
  stmt_handle *stmt_res  =  NULL;

  ibm_db_fetch_helper_args *helper_args = NULL;

  rb_scan_args(argc, argv, "11", &stmt, &row_number);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource specified");
    return Qfalse;
  }

  helper_args = ALLOC( ibm_db_fetch_helper_args );
  memset(helper_args,'\0',sizeof(struct _ibm_db_fetch_helper_struct));

  helper_args->stmt_res    =  stmt_res;
  helper_args->row_number  =  row_number;
  helper_args->arg_count   =  argc;
  helper_args->error       =  &error;

  #ifdef UNICODE_SUPPORT_VERSION    
	ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_fetch_row_helper, helper_args,
                        (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	ret_val = helper_args->return_value;
  #else
    ret_val = _ruby_ibm_db_fetch_row_helper( helper_args );
  #endif

  /*Free Memory Allocated*/
  if ( helper_args != NULL) {
    ruby_xfree( helper_args );
    helper_args = NULL;
  }

  if( error != Qnil && ret_val == Qnil ) {
    rb_throw( RSTRING_PTR(error),Qnil );
  }

  return ret_val;
}

/* */
/*
 *IBM_DB.resultCols --  Returns an array of column names in a result set
 *
 * ===Description
 * array IBM_DB.resultCols ( resource stmt )
 *
 * Returns an array of column names in a result set.
 *
 * ===Parameters
 * stmt
 *     A valid stmt resource containing a result set.
 *
 * ===Return Values
 *
 * Returns an array of column names in the result set. Raises exception on Error.
 * 
 */
VALUE ibm_db_result_cols(int argc, VALUE *argv, VALUE self) {
  VALUE stmt             =  Qnil;
  VALUE ret_val          =  Qnil;

  VALUE  error           =  Qnil;
  VALUE  colName         =  Qnil;
  VALUE  return_value    =  Qnil;

  stmt_handle *stmt_res  =  NULL;

  int index              = 0;

  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource specified");
    return Qnil;
  }

  if ( stmt_res->column_info == NULL ) {
    if (_ruby_ibm_db_get_result_set_info(stmt_res)<0) {
      if( stmt_res != NULL && stmt_res->ruby_stmt_err_msg != NULL ) {
#ifdef UNICODE_SUPPORT_VERSION
        error = rb_str_concat( _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: "),
                           _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->ruby_stmt_err_msg,
                                     stmt_res->ruby_stmt_err_msg_len)
                         );
#else
        error = rb_str_cat2(rb_str_new2("Column information cannot be retrieved: "), stmt_res->ruby_stmt_err_msg );
#endif
      } else {
#ifdef UNICODE_SUPPORT_VERSION
        error = _ruby_ibm_db_export_char_to_utf8_rstr("Column information cannot be retrieved: <error message could not be retrieved>");
#else
        error = rb_str_new2("Column information cannot be retrieved: <error message could not be retrieved>");
#endif
      }
      rb_throw( RSTRING_PTR(error), Qnil );
    }
  }

  return_value = rb_ary_new();

  for (index=0; index<stmt_res->num_columns; index++) {
        switch(stmt_res->s_case_mode) {
      case CASE_LOWER:
#ifdef UNICODE_SUPPORT_VERSION
        strtolower((char*)stmt_res->column_info[index].name, stmt_res->column_info[index].name_length * sizeof(SQLWCHAR));
#else
        strtolower((char*)stmt_res->column_info[index].name, strlen((char*)stmt_res->column_info[index].name));
#endif
        break;
      case CASE_UPPER:
#ifdef UNICODE_SUPPORT_VERSION
        strtoupper((char*)stmt_res->column_info[index].name, stmt_res->column_info[index].name_length * sizeof(SQLWCHAR) );
#else
        strtoupper((char*)stmt_res->column_info[index].name, strlen((char*)stmt_res->column_info[index].name));
#endif
        break;
      case CASE_NATURAL:
      default:
        break;
    }
#ifdef UNICODE_SUPPORT_VERSION
    colName = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(stmt_res->column_info[index].name, stmt_res->column_info[index].name_length * sizeof(SQLWCHAR) );
#else
    colName = rb_str_new2((char*)stmt_res->column_info[index].name);
#endif

    rb_ary_store(return_value, index, colName);
  }

  return return_value;
}
/*  */

/*
 * IBM_DB.fetch_assoc --  Returns an array, indexed by column name, representing a row in a result set
 * 
 * ===Description
 * array IBM_DB.fetch_assoc ( resource stmt [, int row_number] )
 * 
 * Returns an array, indexed by column name, representing a row in a result set.
 * 
 * ===Parameters
 * stmt
 *     A valid stmt resource containing a result set. 
 * 
 * row_number
 * 
 *     Requests a specific 1-indexed row from the result set. Passing this parameter results in a
 *     Ruby warning if the result set uses a forward-only cursor. 
 * 
 * ===Return Values
 * 
 * Returns an associative array with column values indexed by the column name representing the next
 * or requested row in the result set. Returns FALSE if there are no rows left in the result set,
 * or if the row requested by row_number does not exist in the result set.
 */
VALUE ibm_db_fetch_assoc(int argc, VALUE *argv, VALUE self) {
  VALUE row_number       =  Qnil;
  VALUE stmt             =  Qnil;
  VALUE ret_val          =  Qnil;

  VALUE  error           =  Qnil;

  stmt_handle *stmt_res  =  NULL;

  ibm_db_fetch_helper_args *helper_args = NULL;

  rb_scan_args(argc, argv, "11", &stmt, &row_number);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource specified");
    return Qfalse;
  }

  helper_args = ALLOC( ibm_db_fetch_helper_args );
  memset(helper_args,'\0',sizeof(struct _ibm_db_fetch_helper_struct));

  helper_args->stmt_res   =  stmt_res;
  helper_args->row_number =  row_number;
  helper_args->arg_count  =  argc;
  helper_args->error      =  &error;
  helper_args->funcType   =  FETCH_ASSOC;

  #ifdef UNICODE_SUPPORT_VERSION    
	ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_bind_fetch_helper, helper_args,
                        (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	ret_val = helper_args->return_value;
						
  #else
    ret_val = _ruby_ibm_db_bind_fetch_helper( helper_args );
  #endif
   
  /*Free Memory Allocated*/
  if ( helper_args != NULL) {
    ruby_xfree( helper_args );
    helper_args = NULL;
  }

  if( error != Qnil && ret_val == Qnil ) {
    rb_throw( RSTRING_PTR(error), Qnil );
  }

  return ret_val;
}
/*  */

/*
 * IBM_DB.fetch_object --  Returns an object with properties representing columns in the fetched row
 * 
 * ===Description
 * object IBM_DB.fetch_object ( resource stmt [, int row_number] )
 * 
 * Returns an object in which each property represents a column returned in the row fetched from a result set.
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid stmt resource containing a result set. 
 * 
 * row_number
 *     Requests a specific 1-indexed row from the result set. Passing this parameter results in a
 *     Ruby warning if the result set uses a forward-only cursor. 
 * 
 * ===Return Values
 * 
 * Returns an object representing a single row in the result set. The properties of the object map
 * to the names of the columns in the result set.
 * 
 * The IBM DB2, Cloudscape, and Apache Derby database servers typically fold column names to upper-case,
 * so the object properties will reflect that case.
 * 
 * If your SELECT statement calls a scalar function to modify the value of a column, the database servers
 * return the column number as the name of the column in the result set. If you prefer a more
 * descriptive column name and object property, you can use the AS clause to assign a name
 * to the column in the result set.
 * 
 * Returns FALSE if no row was retrieved. 
 */
VALUE ibm_db_fetch_object(int argc, VALUE *argv, VALUE self)
{
  VALUE     row_number   =  Qnil;
  VALUE     stmt         =  Qnil;
  VALUE     ret_val      =  Qnil;

  VALUE     error        =  Qnil;

  stmt_handle *stmt_res  =  NULL;

  ibm_db_fetch_helper_args *helper_args = NULL;

  row_hash_struct *row_res;

  rb_scan_args(argc, argv, "11", &stmt, &row_number);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource specified");
    return Qfalse;
  }

  row_res     = ALLOC(row_hash_struct);

  helper_args = ALLOC( ibm_db_fetch_helper_args );
  memset(helper_args,'\0',sizeof(struct _ibm_db_fetch_helper_struct));

  helper_args->stmt_res   =  stmt_res;
  helper_args->row_number =  row_number;
  helper_args->arg_count  =  argc;
  helper_args->error      =  &error;
  helper_args->funcType   =  FETCH_ASSOC;

  #ifdef UNICODE_SUPPORT_VERSION    
	ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_bind_fetch_helper, helper_args,
                              (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	row_res->hash = helper_args->return_value;
  #else
    row_res->hash = _ruby_ibm_db_bind_fetch_helper( helper_args );
  #endif

  /*Free Memory Allocated*/
  if ( helper_args != NULL) {
    ruby_xfree( helper_args );
    helper_args = NULL;
  }

  if( error != Qnil && ret_val == Qnil ) {
    rb_throw( RSTRING_PTR(error), Qnil );
  }

  if (RTEST(row_res->hash)) {
    return Data_Wrap_Struct(le_row_struct,
        _ruby_ibm_db_mark_row_struct, _ruby_ibm_db_free_row_struct,
        row_res);
  } else {
    ruby_xfree( row_res );
    row_res = NULL;
    return Qfalse;
  }  
}
/*  */

/*
 * IBM_DB.fetch_array --  Returns an array, indexed by column position, representing a row in a result set
 * 
 * ===Description
 * 
 * array IBM_DB.fetch_array ( resource stmt [, int row_number] )
 *
 * Returns an array, indexed by column position, representing a row in a result set. The columns are 0-indexed.
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid stmt resource containing a result set. 
 * 
 * row_number
 *     Requests a specific 1-indexed row from the result set. Passing this parameter results in a
 *     Ruby warning if the result set uses a forward-only cursor. 
 * 
 * ===Return Values
 * 
 * Returns a 0-indexed array with column values indexed by the column position representing the next
 * or requested row in the result set. Returns FALSE if there are no rows left in the result set,
 * or if the row requested by row_number does not exist in the result set. 
 */
VALUE ibm_db_fetch_array(int argc, VALUE *argv, VALUE self)
{
  VALUE row_number       =  Qnil;
  VALUE stmt             =  Qnil;
  VALUE ret_val          =  Qnil;

  VALUE        error     =  Qnil;
  stmt_handle *stmt_res  =  NULL;

  ibm_db_fetch_helper_args *helper_args = NULL;

  rb_scan_args(argc, argv, "11", &stmt, &row_number);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource specified");
    return Qfalse;
  }

  helper_args = ALLOC( ibm_db_fetch_helper_args );
  memset(helper_args,'\0',sizeof(struct _ibm_db_fetch_helper_struct));

  helper_args->stmt_res    =  stmt_res;
  helper_args->row_number  =  row_number;
  helper_args->arg_count   =  argc;
  helper_args->error       =  &error;
  helper_args->funcType    =  FETCH_INDEX;

  #ifdef UNICODE_SUPPORT_VERSION    
	ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_bind_fetch_helper, helper_args,
                        (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
    ret_val = helper_args->return_value;
						
  #else
    ret_val = _ruby_ibm_db_bind_fetch_helper( helper_args );
  #endif

  /*Free Memory Allocated*/
  if ( helper_args != NULL) {
    ruby_xfree( helper_args );
    helper_args = NULL;
  }

  if( error != Qnil && ret_val == Qnil ) {
    rb_throw( RSTRING_PTR(error), Qnil );
  }

  return ret_val;
}
/*  */

/*
 * IBM_DB.fetch_both --  Returns an array, indexed by both column name and position, representing a row
 * in a result set
 * 
 * ===Description
 * array IBM_DB.fetch_both ( resource stmt [, int row_number] )
 * 
 * Returns an array, indexed by both column name and position, representing a row in a result set.
 * Note that the row returned by IBM_DB.fetch_both() requires more memory than the single-indexed
 * arrays returned by IBM_DB.fetch_assoc() or IBM_DB.fetch_array().
 * 
 * ===Parameters
 * 
 * stmt
 *     A valid stmt resource containing a result set. 
 * 
 * row_number
 *     Requests a specific 1-indexed row from the result set. Passing this parameter results in a
 *     Ruby warning if the result set uses a forward-only cursor. 
 * 
 * ===Return Values
 * 
 * Returns an associative array with column values indexed by both the column name and 0-indexed column number.
 * The array represents the next or requested row in the result set. Returns FALSE if there are no rows
 * left in the result set, or if the row requested by row_number does not exist in the result set.
 */
VALUE ibm_db_fetch_both(int argc, VALUE *argv, VALUE self)
{
  VALUE row_number       =  Qnil;
  VALUE stmt             =  Qnil;
  VALUE ret_val          =  Qnil;

  VALUE        error     =  Qnil;
  stmt_handle *stmt_res  =  NULL;

  ibm_db_fetch_helper_args *helper_args = NULL;

  rb_scan_args(argc, argv, "11", &stmt, &row_number);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);
  } else {
    rb_warn("Invalid statement resource specified");
    return Qfalse;
  }

  helper_args = ALLOC( ibm_db_fetch_helper_args );
  memset(helper_args,'\0',sizeof(struct _ibm_db_fetch_helper_struct));

  helper_args->stmt_res    =  stmt_res;
  helper_args->row_number  =  row_number;
  helper_args->arg_count   =  argc;
  helper_args->error       =  &error;
  helper_args->funcType    =  FETCH_BOTH;

  #ifdef UNICODE_SUPPORT_VERSION    
	 ibm_Ruby_Thread_Call ( (void *)_ruby_ibm_db_bind_fetch_helper, helper_args,
                        (void *)_ruby_ibm_db_Statement_level_UBF, stmt_res );
	ret_val = helper_args->return_value;
  #else
    ret_val = _ruby_ibm_db_bind_fetch_helper( helper_args );
  #endif

  /*Free Memory Allocated*/
  if ( helper_args != NULL) {
    ruby_xfree( helper_args );
    helper_args = NULL;
  }

  if( error != Qnil && ret_val == Qnil ) {
    rb_throw( RSTRING_PTR(error), Qnil );
  }

  return ret_val;
}
/*  */

/*
 * IBM_DB.set_option --  Sets the specified option in the resource.
 * 
 * ===Description
 * bool IBM_DB.set_option ( resource resc, array options, int type )
 * 
 * Sets options for a connection or statement resource. You cannot set options for result set resources.
 * 
 * ===Parameters
 * 
 * resc
 *     A valid connection or statement resource.
 * 
 * options
 *     The options to be set
 *
 * type
 *     A field that specifies the resource type (1 = Connection, NON-1 = Statement)
 * 
 * ===Return Values
 * 
 * Returns TRUE on success or FALSE on failure
 */
VALUE ibm_db_set_option(int argc, VALUE *argv, VALUE self)
{
  VALUE conn_or_stmt = Qnil;
  VALUE r_options;
  VALUE r_type;

  stmt_handle *stmt_res = NULL;
  conn_handle *conn_res;

  int  rc   =  0;
  long type =  0;

  VALUE error = Qnil;

  rb_scan_args(argc, argv, "3", &conn_or_stmt, &r_options, &r_type);

  if (!NIL_P(r_type)) type = NUM2LONG(r_type);

  if (!NIL_P(conn_or_stmt)) {
    if ( type == 1 ) {
      Data_Get_Struct(conn_or_stmt, conn_handle, conn_res);

      if ( !NIL_P(r_options) ) {
        rc = _ruby_ibm_db_parse_options( r_options, SQL_HANDLE_DBC, conn_res, &error );
        if (rc == SQL_ERROR) {
          rb_warn( RSTRING_PTR(error) );
          return Qfalse;
        }
      }
    } else {
      Data_Get_Struct( conn_or_stmt, stmt_handle, stmt_res );

      if ( !NIL_P(r_options) ) {
        rc = _ruby_ibm_db_parse_options( r_options, SQL_HANDLE_STMT, stmt_res, &error );
        if (rc == SQL_ERROR) {
          rb_warn( RSTRING_PTR(error) );
          return Qfalse;
        }
      }
    }

    return Qtrue;
  } else {
    return Qfalse;
  }
}
/*
   Retrieves the server information by calling the SQLGetInfo_helper function and wraps it up into server_info object
*/
static VALUE ibm_db_server_info_helper( get_info_args *getInfo_args ) {	
  conn_handle *conn_res = NULL;

  int         rc          =  0;
  SQLSMALLINT out_length  =  0;

#ifndef UNICODE_SUPPORT_VERSION
  char buffer11[11];
  char buffer255[255];
  char buffer3k[3072]; /*Informix server returns SQL_KEYWORDS data, which requires 2608*/
#else
  SQLWCHAR buffer11[11];
  SQLWCHAR buffer255[255];
  SQLWCHAR buffer3k[3072]; /*Informix server returns SQL_KEYWORDS data, which requires 2608*/
#endif

  SQLSMALLINT bufferint16;
  SQLUINTEGER bufferint32;
  SQLINTEGER  bitmask;

  VALUE return_value = rb_funcall(le_server_info, id_new, 0);

  conn_res  =  getInfo_args->conn_res;

  /* DBMS_NAME */
  getInfo_args->infoType     =  SQL_DBMS_NAME;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  getInfo_args->out_length   =  &out_length;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {

#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@DBMS_NAME", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@DBMS_NAME", rb_str_new2(buffer255));
#endif
  }

  /* DBMS_VER */
  getInfo_args->infoType     =  SQL_DBMS_VER;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer11;
  getInfo_args->buff_length  =  sizeof( buffer11 );
  out_length                 =  0;

  memset(buffer11, '\0', sizeof(buffer11));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );
  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@DBMS_VER", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer11, out_length));
#else
    rb_iv_set(return_value, "@DBMS_VER", rb_str_new2(buffer11));
#endif
  }
#ifndef PASE    /* i5/OS DB_CODEPAGE handled natively */
  /* DB_CODEPAGE */
  bufferint32 = 0;

  getInfo_args->infoType     =  SQL_DATABASE_CODEPAGE;
  getInfo_args->infoValue    =  &bufferint32;
  getInfo_args->buff_length  =  sizeof( bufferint32 );
  out_length                 =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@DB_CODEPAGE", INT2NUM(bufferint32));
  }
#endif /* PASE */

  /* DB_NAME */
  getInfo_args->infoType     =  SQL_DATABASE_NAME;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  out_length                 =  0;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
   rb_iv_set(return_value, "@DB_NAME", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@DB_NAME", rb_str_new2(buffer255));
#endif
  }

#ifndef PASE    /* i5/OS INST_NAME handled natively */
  /* INST_NAME */
  getInfo_args->infoType     =  SQL_SERVER_NAME;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  out_length                 =  0;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@INST_NAME", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@INST_NAME", rb_str_new2(buffer255));
#endif
  }

  /* SPECIAL_CHARS */
  getInfo_args->infoType     =  SQL_SPECIAL_CHARACTERS;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  out_length                 =  0;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@SPECIAL_CHARS", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@SPECIAL_CHARS", rb_str_new2(buffer255));
#endif
  }
#endif /* PASE */

  /* KEYWORDS */
  getInfo_args->infoType     =  SQL_KEYWORDS;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer3k;
  getInfo_args->buff_length  =  sizeof( buffer3k );
  out_length                 =  0;

  memset(buffer3k, '\0', sizeof(buffer3k));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    VALUE keywordsStr, keywordsArray;
#ifdef UNICODE_SUPPORT_VERSION
    keywordsStr   =  _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer3k, out_length);
    keywordsArray =  rb_str_split(keywordsStr, RSTRING_PTR(_ruby_ibm_db_export_char_to_utf8_rstr(",")) );
#else
    keywordsStr   = rb_str_new2( buffer3k );
    keywordsArray = rb_str_split(keywordsStr, ",");
#endif
    rb_iv_set(return_value, "@KEYWORDS", keywordsArray);
  }

  /* DFT_ISOLATION */
  getInfo_args->infoType     =  SQL_DEFAULT_TXN_ISOLATION;
  getInfo_args->infoValue    =  &bitmask;
  getInfo_args->buff_length  =  sizeof( bitmask );
  out_length                 =  0;
  bitmask                    =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    VALUE dft_isolation = Qnil;
    if( bitmask & SQL_TXN_READ_UNCOMMITTED ) {
#ifdef UNICODE_SUPPORT_VERSION
     dft_isolation = _ruby_ibm_db_export_char_to_utf8_rstr("UR");
#else
      dft_isolation = rb_str_new2("UR");
#endif
    }
    if( bitmask & SQL_TXN_READ_COMMITTED ) {
#ifdef UNICODE_SUPPORT_VERSION
      dft_isolation = _ruby_ibm_db_export_char_to_utf8_rstr("CS");
#else
      dft_isolation = rb_str_new2("CS");
#endif
    }
    if( bitmask & SQL_TXN_REPEATABLE_READ ) {
#ifdef UNICODE_SUPPORT_VERSION
      dft_isolation = _ruby_ibm_db_export_char_to_utf8_rstr("RS");
#else
      dft_isolation = rb_str_new2("RS");
#endif
    }
    if( bitmask & SQL_TXN_SERIALIZABLE ) {
#ifdef UNICODE_SUPPORT_VERSION
      dft_isolation = _ruby_ibm_db_export_char_to_utf8_rstr("RR");
#else
      dft_isolation = rb_str_new2("RR");
#endif
    }
    if( bitmask & SQL_TXN_NOCOMMIT ) {
#ifdef UNICODE_SUPPORT_VERSION
      dft_isolation = _ruby_ibm_db_export_char_to_utf8_rstr("NC");
#else
      dft_isolation = rb_str_new2("NC");
#endif
    }
    rb_iv_set(return_value, "@DFT_ISOLATION", dft_isolation);
  }
#ifndef PASE    /* i5/OS ISOLATION_OPTION handled natively */
  /* ISOLATION_OPTION */
  getInfo_args->infoType     =  SQL_TXN_ISOLATION_OPTION;
  getInfo_args->infoValue    =  &bitmask;
  getInfo_args->buff_length  =  sizeof( bitmask );
  out_length                 =  0;

  bitmask = 0;
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );
  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    VALUE array;

    array = rb_ary_new();
    if( bitmask & SQL_TXN_READ_UNCOMMITTED ) {
#ifdef UNICODE_SUPPORT_VERSION
     rb_ary_push(array, _ruby_ibm_db_export_char_to_utf8_rstr("UR"));
#else
      rb_ary_push(array, rb_str_new2("UR"));
#endif
    }
    if( bitmask & SQL_TXN_READ_COMMITTED ) {
#ifdef UNICODE_SUPPORT_VERSION
      rb_ary_push(array, _ruby_ibm_db_export_char_to_utf8_rstr("CS"));
#else
      rb_ary_push(array, rb_str_new2("CS"));
#endif
    }
    if( bitmask & SQL_TXN_REPEATABLE_READ ) {
#ifdef UNICODE_SUPPORT_VERSION
      rb_ary_push(array, _ruby_ibm_db_export_char_to_utf8_rstr("RS"));
#else
      rb_ary_push(array, rb_str_new2("RS"));
#endif
    }
    if( bitmask & SQL_TXN_SERIALIZABLE ) {
#ifdef UNICODE_SUPPORT_VERSION
      rb_ary_push(array, _ruby_ibm_db_export_char_to_utf8_rstr("RR"));
#else
      rb_ary_push(array, rb_str_new2("RR"));
#endif
    }
    if( bitmask & SQL_TXN_NOCOMMIT ) {
#ifdef UNICODE_SUPPORT_VERSION
      rb_ary_push(array, _ruby_ibm_db_export_char_to_utf8_rstr("NC"));
#else
      rb_ary_push(array, rb_str_new2("NC"));
#endif
    }
    rb_iv_set(return_value, "@ISOLATION_OPTION", array);
  }
#endif /* PASE */

  /* SQL_CONFORMANCE */
  getInfo_args->infoType     =  SQL_ODBC_SQL_CONFORMANCE;
  getInfo_args->infoValue    =  &bufferint32;
  getInfo_args->buff_length  =  sizeof( bufferint32 );
  out_length                 =  0;

  bufferint32 = 0;
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );
  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    VALUE conformance = Qnil;
    switch (bufferint32) {
      case SQL_SC_SQL92_ENTRY:
#ifdef UNICODE_SUPPORT_VERSION
        conformance = _ruby_ibm_db_export_char_to_utf8_rstr("ENTRY");
#else
        conformance = rb_str_new2("ENTRY");
#endif
        break;
      case SQL_SC_FIPS127_2_TRANSITIONAL:
#ifdef UNICODE_SUPPORT_VERSION
        conformance = _ruby_ibm_db_export_char_to_utf8_rstr("FIPS127");
#else
        conformance = rb_str_new2("FIPS127");
#endif
        break;
      case SQL_SC_SQL92_FULL:
#ifdef UNICODE_SUPPORT_VERSION
        conformance = _ruby_ibm_db_export_char_to_utf8_rstr("FULL");
#else
        conformance = rb_str_new2("FULL");
#endif
        break;
      case SQL_SC_SQL92_INTERMEDIATE:
#ifdef UNICODE_SUPPORT_VERSION
        conformance = _ruby_ibm_db_export_char_to_utf8_rstr("INTERMEDIATE");
#else
        conformance = rb_str_new2("INTERMEDIATE");
#endif
        break;
      default:
        break;
    }
    rb_iv_set(return_value, "@SQL_CONFORMANCE", conformance);
  }

  /* PROCEDURES */
  getInfo_args->infoType     =  SQL_PROCEDURES;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer11;
  getInfo_args->buff_length  =  sizeof( buffer11 );
  out_length                 =  0;

  memset(buffer11, '\0', sizeof(buffer11));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );
  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    if( rb_str_equal(_ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer11, out_length), _ruby_ibm_db_export_char_to_utf8_rstr("Y")) ) {
#else
     if( strcmp((char *)buffer11, "Y") == 0 ) {
#endif
      rb_iv_set(return_value, "@PROCEDURES", Qtrue);
    } else {
      rb_iv_set(return_value, "@PROCEDURES", Qfalse);
    }
  }
  /* IDENTIFIER_QUOTE_CHAR */
  getInfo_args->infoType     =  SQL_IDENTIFIER_QUOTE_CHAR;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer11;
  getInfo_args->buff_length  =  sizeof( buffer11 );
  out_length                 =  0;

  memset(buffer11, '\0', sizeof(buffer11));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@IDENTIFIER_QUOTE_CHAR", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer11, out_length));
#else
    rb_iv_set(return_value, "@IDENTIFIER_QUOTE_CHAR", rb_str_new2(buffer11));
#endif
  }

  /* LIKE_ESCAPE_CLAUSE */
  getInfo_args->infoType     =  SQL_LIKE_ESCAPE_CLAUSE;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer11;
  getInfo_args->buff_length  =  sizeof( buffer11 );
  out_length                 =  0;

  memset(buffer11, '\0', sizeof(buffer11));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    if( rb_str_equal(_ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer11, out_length), _ruby_ibm_db_export_char_to_utf8_rstr("Y")) ) {
#else
    if( strcmp(buffer11, "Y") == 0 ) {
#endif
      rb_iv_set(return_value, "@LIKE_ESCAPE_CLAUSE", Qtrue);
    } else {
      rb_iv_set(return_value, "@LIKE_ESCAPE_CLAUSE", Qfalse);
    }
  }

  /* MAX_COL_NAME_LEN */
  getInfo_args->infoType     =  SQL_MAX_COLUMN_NAME_LEN;
  getInfo_args->infoValue    =  &bufferint16;
  getInfo_args->buff_length  =  sizeof( bufferint16 );
  out_length                 =  0;
  bufferint16                =  0;
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );
  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_COL_NAME_LEN", INT2NUM(bufferint16));
  }

  /* MAX_ROW_SIZE */
  getInfo_args->infoType     =  SQL_MAX_ROW_SIZE;
  getInfo_args->infoValue    =  &bufferint32;
  getInfo_args->buff_length  =  sizeof( bufferint32 );
  out_length                 =  0;
  bufferint32                =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_ROW_SIZE", INT2NUM(bufferint32));
  }
#ifndef PASE    /* i5/OS MAX_IDENTIFIER_LEN handled natively */
  /* MAX_IDENTIFIER_LEN */
  getInfo_args->infoType     =  SQL_MAX_IDENTIFIER_LEN;
  getInfo_args->infoValue    =  &bufferint16;
  getInfo_args->buff_length  =  sizeof( bufferint16 );
  out_length                 =  0;
  bufferint16                =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_IDENTIFIER_LEN", INT2NUM(bufferint16));
  }

  /* MAX_INDEX_SIZE */
  getInfo_args->infoType     =  SQL_MAX_INDEX_SIZE;
  getInfo_args->infoValue    =  &bufferint32;
  getInfo_args->buff_length  =  sizeof( bufferint32 );
  out_length                 =  0;
  bufferint32                =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_INDEX_SIZE", INT2NUM(bufferint32));
  }

  /* MAX_PROC_NAME_LEN */
  getInfo_args->infoType     =  SQL_MAX_PROCEDURE_NAME_LEN;
  getInfo_args->infoValue    =  &bufferint16;
  getInfo_args->buff_length  =  sizeof( bufferint16 );
  out_length                 =  0;

  bufferint16 = 0;
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_PROC_NAME_LEN", INT2NUM(bufferint16));
  }
#endif /* PASE */

  /* MAX_SCHEMA_NAME_LEN */
  getInfo_args->infoType     =  SQL_MAX_SCHEMA_NAME_LEN;
  getInfo_args->infoValue    =  &bufferint16;
  getInfo_args->buff_length  =  sizeof( bufferint16 );
  out_length                 =  0;
  bufferint16                =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_SCHEMA_NAME_LEN", INT2NUM(bufferint16));
  }

  /* MAX_STATEMENT_LEN */
  getInfo_args->infoType     =  SQL_MAX_STATEMENT_LEN;
  getInfo_args->infoValue    =  &bufferint32;
  getInfo_args->buff_length  =  sizeof( bufferint32 );
  out_length                 =  0;
  bufferint32                =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_STATEMENT_LEN", INT2NUM(bufferint32));
  }

  /* MAX_TABLE_NAME_LEN */
  getInfo_args->infoType     =  SQL_MAX_TABLE_NAME_LEN;
  getInfo_args->infoValue    =  &bufferint16;
  getInfo_args->buff_length  =  sizeof( bufferint16 );
  out_length                 =  0;
  bufferint16                =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@MAX_TABLE_NAME_LEN", INT2NUM(bufferint16));
  }

  /* NON_NULLABLE_COLUMNS */
  getInfo_args->infoType     =  SQL_NON_NULLABLE_COLUMNS;
  getInfo_args->infoValue    =  &bufferint16;
  getInfo_args->buff_length  =  sizeof( bufferint16 );
  out_length                 =  0;
  bufferint16                =  0;

  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    VALUE rv = Qnil;
    switch (bufferint16) {
      case SQL_NNC_NON_NULL:
        rv = Qtrue;
        break;
      case SQL_NNC_NULL:
        rv = Qfalse;
        break;
      default:
        break;
    }
    rb_iv_set(return_value, "@NON_NULLABLE_COLUMNS", rv);
  }

  getInfo_args->return_value=return_value;
  
  return return_value;
}
/*  */

/*
 * IBM_DB.server_info -- Returns an object with properties that describe the DB2 database server
 * 
 * ===Description
 * object IBM_DB.server_info ( resource connection )
 * 
 * This function returns a read-only object with information about the IBM DB2, Cloudscape, or Apache Derby database server.
 * The following table lists the database server properties:
 * 
 * ===Table 1. Database server properties
 * <b>Property name</b>:: <b>Description (Return type)</b>
 * DBMS_NAME:: The name of the database server to which you are connected. For DB2 servers this is a combination
 *             of DB2 followed by the operating system on which the database server is running. (string)
 * DBMS_VER:: The version of the database server, in the form of a string "MM.mm.uuuu" where MM is the major version,
 *            mm is the minor version, and uuuu is the update. For example, "08.02.0001" represents major version 8,
 *            minor version 2, update 1. (string)
 * DB_CODEPAGE:: The code page of the database to which you are connected. (int)
 * DB_NAME:: The name of the database to which you are connected. (string)
 * DFT_ISOLATION:: The default transaction isolation level supported by the server: (string)
 * 
 *                 UR:: Uncommitted read: changes are immediately visible by all concurrent transactions. 
 * 
 *                 CS:: Cursor stability: a row read by one transaction can be altered and committed by a second concurrent transaction. 
 * 
 *                 RS:: Read stability: a transaction can add or remove rows matching a search condition or a pending transaction. 
 * 
 *                 RR:: Repeatable read: data affected by pending transaction is not available to other transactions. 
 * 
 *                 NC:: No commit: any changes are visible at the end of a successful operation. Explicit commits and rollbacks are not allowed. 
 * 
 * IDENTIFIER_QUOTE_CHAR:: The character used to delimit an identifier. (string)
 * INST_NAME:: The instance on the database server that contains the database. (string)
 * ISOLATION_OPTION:: An array of the isolation options supported by the database server. The isolation options are described
 *                    in the DFT_ISOLATION property. (array)
 * KEYWORDS:: An array of the keywords reserved by the database server. (array)
 * LIKE_ESCAPE_CLAUSE:: TRUE if the database server supports the use of % and _ wildcard characters. FALSE if the database server
 *                      does not support these wildcard characters. (bool)
 * MAX_COL_NAME_LEN:: Maximum length of a column name supported by the database server, expressed in bytes. (int)
 * MAX_IDENTIFIER_LEN:: Maximum length of an SQL identifier supported by the database server, expressed in characters. (int)
 * MAX_INDEX_SIZE:: Maximum size of columns combined in an index supported by the database server, expressed in bytes. (int)
 * MAX_PROC_NAME_LEN:: Maximum length of a procedure name supported by the database server, expressed in bytes. (int)
 * MAX_ROW_SIZE:: Maximum length of a row in a base table supported by the database server, expressed in bytes. (int)
 * MAX_SCHEMA_NAME_LEN:: Maximum length of a schema name supported by the database server, expressed in bytes. (int)
 * MAX_STATEMENT_LEN:: Maximum length of an SQL statement supported by the database server, expressed in bytes. (int)
 * MAX_TABLE_NAME_LEN:: Maximum length of a table name supported by the database server, expressed in bytes. (bool)
 * NON_NULLABLE_COLUMNS:: TRUE if the database server supports columns that can be defined as NOT NULL, FALSE if the database
 *                        server does not support columns defined as NOT NULL. (bool)
 * PROCEDURES:: TRUE if the database server supports the use of the CALL statement to call stored procedures, FALSE if the
 *              database server does not support the CALL statement. (bool)
 * SPECIAL_CHARS:: A string containing all of the characters other than a-Z, 0-9, and underscore that can be used in an
 *                 identifier name. (string)
 * SQL_CONFORMANCE:: The level of conformance to the ANSI/ISO SQL-92 specification offered by the database server: (string)
 * 
 *                   ENTRY:: Entry-level SQL-92 compliance. 
 * 
 *                   FIPS127:: FIPS-127-2 transitional compliance. 
 * 
 *                   FULL:: Full level SQL-92 compliance. 
 * 
 *                   INTERMEDIATE:: Intermediate level SQL-92 compliance. 
 * 
 * ===Parameters
 * 
 * connection
 *     Specifies an active DB2 client connection. 
 * 
 * ===Return Values
 * 
 * Returns an object on a successful call. Returns FALSE on failure. 
 */
VALUE ibm_db_server_info(int argc, VALUE *argv, VALUE self)
{
  VALUE       connection  =  Qnil;
  conn_handle *conn_res   =  NULL;

  VALUE         return_value   =  Qnil;
  get_info_args *getInfo_args  =  NULL;

  rb_scan_args(argc, argv, "1", &connection);
  
  
  if(NIL_P(&connection))
	{
	}
	if(&connection == NULL)
	{
	}

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);
	
    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }
    getInfo_args = ALLOC( get_info_args );
    memset(getInfo_args,'\0',sizeof(struct _ibm_db_get_info_struct));
	
    getInfo_args->conn_res     =  conn_res;
    getInfo_args->out_length   =  NULL;
    getInfo_args->infoType     =  0;
    getInfo_args->infoValue    =  NULL;
    getInfo_args->buff_length  =  0;
    #ifdef UNICODE_SUPPORT_VERSION
	  ibm_Ruby_Thread_Call ( (void *)ibm_db_server_info_helper, getInfo_args,
                                 (void *)_ruby_ibm_db_Connection_level_UBF, NULL);
	  return_value  = getInfo_args->return_value;
    #else
      return_value = ibm_db_server_info_helper( getInfo_args );
    #endif

    /* Free Any memory Allocated*/
    if( getInfo_args != NULL ) {
      ruby_xfree( getInfo_args );
      getInfo_args = NULL;
    }

    return return_value;
  }
  return Qnil;
}
/*  
   Retrieves the client information by calling the SQLGetInfo_helper function and wraps it up into client_info object
*/
static VALUE ibm_db_client_info_helper( get_info_args *getInfo_args) {
  conn_handle *conn_res = NULL;

  int          rc          =  0;
  SQLSMALLINT  out_length  =  0;

#ifndef UNICODE_SUPPORT_VERSION
  char         buffer255[255];
#else
  SQLWCHAR buffer255[255];
#endif

  SQLSMALLINT  bufferint16;
  SQLUINTEGER  bufferint32;

  VALUE return_value = rb_funcall(le_client_info, id_new, 0);

  conn_res =  getInfo_args->conn_res;

  /* DRIVER_NAME */
  getInfo_args->infoType     =  SQL_DRIVER_NAME;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  getInfo_args->out_length   =  &out_length;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@DRIVER_NAME", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@DRIVER_NAME", rb_str_new2(buffer255));
#endif
  }

  /* DRIVER_VER */
  getInfo_args->infoType     =  SQL_DRIVER_VER;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  out_length                 =  0;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@DRIVER_VER", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@DRIVER_VER", rb_str_new2(buffer255));
#endif
  }

  /* DATA_SOURCE_NAME */
  getInfo_args->infoType     =  SQL_DATA_SOURCE_NAME;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  out_length                 =  0;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@DATA_SOURCE_NAME", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@DATA_SOURCE_NAME", rb_str_new2(buffer255));
#endif
  }

  /* DRIVER_ODBC_VER */
  getInfo_args->infoType     =  SQL_DRIVER_ODBC_VER;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  out_length                  =  0;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@DRIVER_ODBC_VER", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@DRIVER_ODBC_VER", rb_str_new2(buffer255));
#endif
  }

#ifndef PASE    /* i5/OS ODBC_VER handled natively */
  /* ODBC_VER */
  getInfo_args->infoType     =  SQL_ODBC_VER;
  getInfo_args->infoValue    =  (SQLPOINTER)buffer255;
  getInfo_args->buff_length  =  sizeof( buffer255 );
  out_length                 =  0;

  memset(buffer255, '\0', sizeof(buffer255));
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
#ifdef UNICODE_SUPPORT_VERSION
    rb_iv_set(return_value, "@ODBC_VER", _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(buffer255, out_length));
#else
    rb_iv_set(return_value, "@ODBC_VER", rb_str_new2(buffer255));
#endif
  }
#endif /* PASE */

  /* ODBC_SQL_CONFORMANCE */
  getInfo_args->infoType     =  SQL_ODBC_SQL_CONFORMANCE;
  getInfo_args->infoValue    =  &bufferint16;
  getInfo_args->buff_length  =  sizeof( bufferint16 );
  out_length                 =  0;

  bufferint16 = 0;
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    VALUE conformance = Qnil;
    switch (bufferint16) {
      case SQL_OSC_MINIMUM:
#ifdef UNICODE_SUPPORT_VERSION
       conformance = _ruby_ibm_db_export_char_to_utf8_rstr("MINIMUM");
#else
       conformance = rb_str_new2("MINIMUM");
#endif
        break;
      case SQL_OSC_CORE:
#ifdef UNICODE_SUPPORT_VERSION
       conformance = _ruby_ibm_db_export_char_to_utf8_rstr("CORE");
#else
       conformance = rb_str_new2("CORE");
#endif
        break;
      case SQL_OSC_EXTENDED:
#ifdef UNICODE_SUPPORT_VERSION
       conformance = _ruby_ibm_db_export_char_to_utf8_rstr("EXTENDED");
#else
       conformance = rb_str_new2("EXTENDED");
#endif
        break;
      default:
        break;
    }
    rb_iv_set(return_value, "@ODBC_SQL_CONFORMANCE", conformance);
  }

#ifndef PASE    /* i5/OS APPL_CODEPAGE handled natively */
  /* APPL_CODEPAGE */
  getInfo_args->infoType     =  SQL_APPLICATION_CODEPAGE;
  getInfo_args->infoValue    =  &bufferint32;
  getInfo_args->buff_length  =  sizeof( bufferint32 );
  out_length                 =  0;

  bufferint32 = 0;
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@APPL_CODEPAGE", INT2NUM(bufferint32));
  }

  /* CONN_CODEPAGE */
  getInfo_args->infoType     =  SQL_APPLICATION_CODEPAGE;
  getInfo_args->infoValue    =  &bufferint32;
  getInfo_args->buff_length  =  sizeof( bufferint32 );
  out_length                 =  0;

  bufferint32 = 0;
  rc = _ruby_ibm_db_SQLGetInfo_helper( getInfo_args );

  if ( rc == SQL_ERROR ) {
    _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 0 );
	getInfo_args->return_value = Qfalse;
    return Qfalse;
  } else {
    rb_iv_set(return_value, "@CONN_CODEPAGE", INT2NUM(bufferint32));
  }
#endif /* PASE */

  getInfo_args->return_value = return_value;
  return return_value;
}
/*  */

/*
 * IBM_DB.client_info -- Returns an object with properties that describe the DB2 database client
 * 
 * ===Description
 * object IBM_DB.client_info ( resource connection )
 * 
 * This function returns a read-only object with information about the DB2 database client. The following table lists the DB2 client properties:
 * 
 * ====Table 1. DB2 client properties
 *
 * <b>Property name</b>:: <b>Description (Return type)</b>
 *
 * APPL_CODEPAGE:: The application code page. (int)
 *
 * CONN_CODEPAGE:: The code page for the current connection. (int)
 *
 * DATA_SOURCE_NAME:: The data source name (DSN) used to create the current connection to the database. (string)
 *
 * DRIVER_NAME:: The name of the library that implements the DB2 Call Level Interface (CLI) specification. (string)
 *
 * DRIVER_ODBC_VER:: The version of ODBC that the DB2 client supports. This returns a string "MM.mm" where MM is the major version and mm is the minor version. The DB2 client always returns "03.51". (string)
 *
 * DRIVER_VER:: The version of the client, in the form of a string "MM.mm.uuuu" where MM is the major version, mm is the minor version, and uuuu is the update. For example, "08.02.0001" represents major version 8, minor version 2, update 1. (string)
 *
 * ODBC_SQL_CONFORMANCE:: There are three levels of ODBC SQL grammar supported by the client: MINIMAL (Supports the minimum ODBC SQL grammar), CORE (Supports the core ODBC SQL grammar), EXTENDED (Supports extended ODBC SQL grammar). (string)
 *
 * ODBC_VER:: The version of ODBC that the ODBC driver manager supports. This returns a string "MM.mm.rrrr" where MM is the major version, mm is the minor version, and rrrr is the release. The DB2 client always returns "03.01.0000". (string)
 *
 * ===Parameters
 * 
 * connection
 * 
 *    Specifies an active DB2 client connection. 
 *
 * ===Return Values
 * 
 * Returns an object on a successful call. Returns FALSE on failure. 
 */
VALUE ibm_db_client_info(int argc, VALUE *argv, VALUE self)
{
  VALUE connection = Qnil;
  conn_handle *conn_res;

  get_info_args *getInfo_args = NULL;

  VALUE return_value = Qnil;

  rb_scan_args(argc, argv, "1", &connection);

  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);

    if (!conn_res || !conn_res->handle_active) {
      rb_warn("Connection is not active");
      return Qfalse;
    }

    getInfo_args = ALLOC( get_info_args );
    memset(getInfo_args,'\0',sizeof(struct _ibm_db_get_info_struct));

    getInfo_args->conn_res     =  conn_res;
    getInfo_args->out_length   =  NULL;
    getInfo_args->infoType     =  0;
    getInfo_args->infoValue    =  NULL;
    getInfo_args->buff_length  =  0;

    #ifdef UNICODE_SUPPORT_VERSION      
	  ibm_Ruby_Thread_Call ( (void *)ibm_db_client_info_helper, getInfo_args,
                               (void *)_ruby_ibm_db_Connection_level_UBF, NULL);
	  return_value = getInfo_args->return_value;
							   
    #else
      return_value = ibm_db_client_info_helper( getInfo_args );
    #endif

    /*Free Any memory Alllocated*/
    if( getInfo_args != NULL ) {
      ruby_xfree( getInfo_args );
      getInfo_args = NULL;
    }

    return return_value;
  }

  return Qnil;
}
/*  */

/* 
 * IBM_DB.active --  Checks if the specified connection resource is active
 * 
 * ===Description
 * object IBM_DB.active(resource connection)
 * 
 * Returns true if the given connection resource is active
 * 
 * ===Parameters
 * connection
 *     The connection resource to be validated.
 * 
 * ===Return Values
 * 
 * Returns true if the given connection resource is active, otherwise it will return false
 */
VALUE ibm_db_active(int argc, VALUE *argv, VALUE self)
{
  VALUE connection = Qnil;
  int rc;
  conn_handle *conn_res;
  SQLINTEGER  conn_alive;

  get_handle_attr_args  *get_handleAttr_args = NULL;

  conn_alive = 0;

  rb_scan_args(argc, argv, "1", &connection);
  if (!NIL_P(connection)) {
    Data_Get_Struct(connection, conn_handle, conn_res);
#ifndef PASE
    get_handleAttr_args = ALLOC( get_handle_attr_args );
    memset(get_handleAttr_args,'\0',sizeof(struct _ibm_db_get_handle_attr_struct));

    get_handleAttr_args->handle       =  &( conn_res->hdbc );
    get_handleAttr_args->attribute    =  SQL_ATTR_PING_DB;
    get_handleAttr_args->valuePtr     =  (SQLPOINTER)&conn_alive;
    get_handleAttr_args->buff_length  =  0;
    get_handleAttr_args->out_length   =  NULL;

    rc = _ruby_ibm_db_SQLGetConnectAttr_helper( get_handleAttr_args );

    ruby_xfree( get_handleAttr_args );
    get_handleAttr_args = NULL;

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
    }
#endif /* PASE */
  }
  /*
  *  SQLGetConnectAttr with SQL_ATTR_PING_DB will return 0 on failure but will return
  *  the ping time on success.  We only want success or failure.
  */
  if (conn_alive == 0) {
    return Qfalse;
  } else {
    return Qtrue;
  }
}
/*  */

/*
 * IBM_DB.get_option --  Gets the specified option in the resource.
 *
 * ===Description
 * mixed IBM_DB.get_option ( resource resc, int options, int type )
 *
 * Returns a value, that is the current setting of a connection or statement attribute.
 *
 * ===Parameters
 *
 * resc
 *     A valid connection or statement resource containing a result set. 
 *
 * options
 *     The options to be retrieved
 *
 * type
 *     A field that specifies the resource type
 *
 *     IBM_DB::DB_STMT for Statement and IBM_DB::DB_CONN for Connection or 
 *     1 = Connection, non - 1 = Statement
 *
 * ===Return Values
 *
 * Returns the current setting of the resource attribute provided or
 * Returns FALSE on failure.
 */
VALUE ibm_db_get_option(int argc, VALUE *argv, VALUE self)
{
  VALUE conn_or_stmt        =  Qnil;
  VALUE option              =  Qnil;
  VALUE r_type              =  Qnil;
  VALUE ret_val             =  Qnil;

#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR   *value        =  NULL;
#else
  SQLCHAR    *value        =  NULL;
#endif

  SQLINTEGER  value_int     =  0;
  conn_handle *conn_res     =  NULL;
  stmt_handle *stmt_res     =  NULL;
  SQLINTEGER  op_integer    =  0;
  SQLINTEGER  out_length    =  0;

  long type = 0;
  int rc;

  get_handle_attr_args *get_handleAttr_args = NULL;

  rb_scan_args(argc, argv, "3", &conn_or_stmt, &option, &r_type);

  
  if (!NIL_P(r_type)) type = NUM2LONG(r_type);
  

  if (!NIL_P(conn_or_stmt)) {
    /* Checking to see if we are getting a connection option (1) or a statement option (non - 1) */
    if (type == 1) {
      Data_Get_Struct(conn_or_stmt, conn_handle, conn_res);
      /* Check to ensure the connection resource given is active */
      if (!conn_res || !conn_res->handle_active) {
        rb_warn("Connection is not active");
        return Qfalse;
      }
      /* Check that the option given is not null */
      if (!NIL_P(option)) {
        op_integer=(SQLINTEGER)FIX2INT(option);
        /* ACCTSTR_LEN is the largest possible length of the options to retrieve */
#ifdef UNICODE_SUPPORT_VERSION
        value = (SQLWCHAR *)ALLOC_N(SQLWCHAR, ACCTSTR_LEN + 1);
        memset(value,'\0', (ACCTSTR_LEN + 1)*sizeof(SQLWCHAR));
#else
        value = (SQLCHAR *)ALLOC_N(SQLCHAR, ACCTSTR_LEN + 1);
        memset(value,'\0', ACCTSTR_LEN + 1);
#endif
        get_handleAttr_args = ALLOC( get_handle_attr_args );
        memset(get_handleAttr_args,'\0',sizeof(struct _ibm_db_get_handle_attr_struct));

        get_handleAttr_args->handle      =  &( conn_res->hdbc );
        get_handleAttr_args->attribute   =  op_integer;
        get_handleAttr_args->valuePtr    =  (SQLPOINTER)value;
#ifdef UNICODE_SUPPORT_VERSION
        get_handleAttr_args->buff_length =  (ACCTSTR_LEN+1)*sizeof(SQLWCHAR);
#else
        get_handleAttr_args->buff_length =  (ACCTSTR_LEN+1);
#endif
        get_handleAttr_args->out_length  =  &out_length;
        rc = _ruby_ibm_db_SQLGetConnectAttr_helper( get_handleAttr_args );

        ruby_xfree( get_handleAttr_args );
        get_handleAttr_args = NULL;
        if (rc == SQL_ERROR) {
          _ruby_ibm_db_check_sql_errors( conn_res, DB_CONN, conn_res->hdbc, SQL_HANDLE_DBC, rc, 1, NULL, NULL, -1, 1, 1 );
          ret_val = Qfalse;
        } else {
#ifdef UNICODE_SUPPORT_VERSION
          ret_val = _ruby_ibm_db_export_sqlwchar_to_utf8_rstr(value, out_length);
#else
          ret_val = rb_str_new2((char *)value);
#endif
        }
        ruby_xfree( value );
        value = NULL;
        return ret_val;
      } else {
        rb_warn("No options specified");
        return Qfalse;
      }
    /* At this point we know we are to retreive a statement option */
    } else {
      Data_Get_Struct(conn_or_stmt, stmt_handle, stmt_res);
      /* Check that the option given is not null */
      if (!NIL_P(option)) {
        op_integer=(SQLINTEGER)FIX2INT(option);
        /* Checking that the option to get is the cursor type because that is what we support here */
        if (op_integer == SQL_ATTR_CURSOR_TYPE) {
          get_handleAttr_args = ALLOC( get_handle_attr_args );
          memset(get_handleAttr_args,'\0',sizeof(struct _ibm_db_get_handle_attr_struct));

          get_handleAttr_args->handle      =  &( stmt_res->hstmt );
          get_handleAttr_args->attribute   =  op_integer;
          get_handleAttr_args->valuePtr    =  &value_int;
          get_handleAttr_args->buff_length =  SQL_IS_INTEGER;
          get_handleAttr_args->out_length  =  NULL;
          rc = _ruby_ibm_db_SQLGetStmtAttr_helper( get_handleAttr_args );

          ruby_xfree( get_handleAttr_args );
          get_handleAttr_args = NULL;
          if (rc == SQL_ERROR) {
            _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
            return Qfalse;
          }
          return INT2NUM(value_int);
        } else {
          rb_warn("Invalid option specified");
          return Qfalse;
        }
      } else {
        rb_warn("No options specified");
        return Qfalse;
      }

    }
  } else {
    rb_warn("Supplied resource handle is invalid");
    return Qfalse;
  }  
}


/*
 * IBM_DB.get_last_serial_value --  Gets the last inserted serial value from IDS
 *
 * ===Description
 * string IBM_DB.get_last_serial_value ( resource stmt )
 *
 * Returns a string, that is the last inserted value for a serial column for IDS. 
 * The last inserted value could be auto-generated or entered explicitly by the user
 * This function is valid for IDS (Informix Dynamic Server only)
 *
 * ===Parameters
 *
 * stmt
 *     A valid statement resource.
 *
 * ===Return Values
 *
 * Returns a string representation of last inserted serial value on a successful call. 
 * Returns FALSE in case of failure.
 */
VALUE ibm_db_get_last_serial_value(int argc, VALUE *argv, VALUE self)
{
  VALUE   stmt    = Qnil;
  VALUE   ret_val = Qnil;

  char    *value = NULL;

  stmt_handle *stmt_res;

  int rc = 0;

  get_handle_attr_args *get_handleAttr_args = NULL;
  
  rb_scan_args(argc, argv, "1", &stmt);

  if (!NIL_P(stmt)) {
    Data_Get_Struct(stmt, stmt_handle, stmt_res);

    /* We allocate a buffer of size 31 as per recommendations from the CLI IDS team */
    value = (char *) ALLOC_N(char, 31);

    get_handleAttr_args = ALLOC( get_handle_attr_args );
    memset(get_handleAttr_args,'\0',sizeof(struct _ibm_db_get_handle_attr_struct));

    get_handleAttr_args->handle      =  &( stmt_res->hstmt );
    get_handleAttr_args->attribute   =  SQL_ATTR_GET_GENERATED_VALUE;
    get_handleAttr_args->valuePtr    =  (SQLPOINTER)value;
    get_handleAttr_args->buff_length =  31;
    get_handleAttr_args->out_length  =  NULL;

    rc = _ruby_ibm_db_SQLGetStmtAttr_helper( get_handleAttr_args );

    ruby_xfree( get_handleAttr_args );
    get_handleAttr_args = NULL;

    if ( rc == SQL_ERROR ) {
      _ruby_ibm_db_check_sql_errors( stmt_res, DB_STMT, (SQLHSTMT)stmt_res->hstmt, SQL_HANDLE_STMT, rc, 1, NULL, NULL, -1, 1, 1 );
      return Qfalse;
    }
    ret_val = INT2NUM(atoi( value ));
    ruby_xfree( value );
    value = NULL;

    return ret_val;
  }
  else {
    rb_warn("Supplied statement handle is invalid");
    return Qfalse;
  }
  
}


/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
