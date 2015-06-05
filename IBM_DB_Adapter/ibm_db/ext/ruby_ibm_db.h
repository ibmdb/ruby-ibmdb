/*
  +----------------------------------------------------------------------+
  |  Licensed Materials - Property of IBM                                |
  |                                                                      |
  | (C) Copyright IBM Corporation 2006 - 2015                            |
  +----------------------------------------------------------------------+
  | Authors: Sushant Koduru, Lynh Nguyen, Kanchana Padmanabhan,          |
  |          Dan Scott, Helmut Tessarek, Kellen Bombardier, Sam Ruby     |
  |          Ambrish Bhargava, Tarun Pasrija, Praveen Devarao, 			 |
  |          Arvind Gupta                                                |
  +----------------------------------------------------------------------+
*/

#ifndef RUBY_IBM_DB_H
#define RUBY_IBM_DB_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>

#ifndef SQL_XML
#define SQL_XML -370
#endif

/* Needed for Backward compatibility */
#ifndef SQL_DECFLOAT
#define SQL_DECFLOAT -360
#endif

/* needed for backward compatibility (SQL_ATTR_ROWCOUNT_PREFETCH not defined prior to DB2 9.5.0.3) */
#ifndef SQL_ATTR_ROWCOUNT_PREFETCH
#define SQL_ATTR_ROWCOUNT_PREFETCH 2592
#define SQL_ROWCOUNT_PREFETCH_OFF   0
#define SQL_ROWCOUNT_PREFETCH_ON    1
#endif

/* SQL_ATTR_USE_TRUSTED_CONTEXT,
 * SQL_ATTR_TRUSTED_CONTEXT_USERID and
 * SQL_ATTR_TRUSTED_CONTEXT_PASSWORD
 * not defined prior to DB2 v9 */
#ifndef SQL_ATTR_USE_TRUSTED_CONTEXT
#define SQL_ATTR_USE_TRUSTED_CONTEXT 2561
#define SQL_ATTR_TRUSTED_CONTEXT_USERID 2562
#define SQL_ATTR_TRUSTED_CONTEXT_PASSWORD 2563
#endif

#ifndef SQL_ATTR_REPLACE_QUOTED_LITERALS
#define SQL_ATTR_REPLACE_QUOTED_LITERALS 2586
#endif

/* CLI v9.1 FP3 and below has a SQL_ATTR_REPLACE_QUOTED_LITERALS value of 116
 * We need to support both the new and old values for compatibility with older
 * versions of CLI. CLI v9.1 FP4 and beyond changed this value to 2586
 */
#define SQL_ATTR_REPLACE_QUOTED_LITERALS_OLDVALUE 116

/* If using a DB2 CLI version which doesn't support this functionality, explicitly
 * define this. We will rely on DB2 CLI to throw an error when SQLGetStmtAttr is 
 * called.
 */
#ifndef SQL_ATTR_GET_GENERATED_VALUE 
#define SQL_ATTR_GET_GENERATED_VALUE 2578
#endif

#ifdef _WIN32
#define RUBY_IBM_DB_API __declspec(dllexport)
#else
#define RUBY_IBM_DB_API
#endif

/* strlen(" SQLCODE=") added in */
#define DB2_MAX_ERR_MSG_LEN (SQL_MAX_MESSAGE_LENGTH + SQL_SQLSTATE_SIZE + 10)

/*Used to find the type of resource and the error type required*/
#define DB_ERRMSG       1
#define DB_ERR_STATE    2

#define DB_CONN         1
#define DB_STMT         2

#define CONN_ERROR      1
#define STMT_ERROR      2

/*Used to decide if LITERAL REPLACEMENT should be turned on or not*/
#define SET_QUOTED_LITERAL_REPLACEMENT_ON  1
#define SET_QUOTED_LITERAL_REPLACEMENT_OFF 0

/* DB2 instance environment variable */
#define DB2_VAR_INSTANCE "DB2INSTANCE="

/******** Makes code compatible with the options used by the user */
#define BINARY 1
#define CONVERT 2
#define PASSTHRU 3
#define PARAM_FILE 11

#ifdef PASE
#define SQL_IS_INTEGER 0
#define SQL_BEST_ROWID 0
#define SQLLEN long
#define SQLFLOAT double
#endif

/*fetch*/
#define FETCH_INDEX 0x01
#define FETCH_ASSOC 0x02
#define FETCH_BOTH 0x03

/* Change column case */
#define ATTR_CASE 3271982
#define CASE_NATURAL 0
#define CASE_LOWER 1
#define CASE_UPPER 2

/* maximum sizes */
#define USERID_LEN 16
#define ACCTSTR_LEN 200
#define APPLNAME_LEN 32
#define WRKSTNNAME_LEN 18

/*
 * Enum for Decfloat Rounding Modes
 * */
enum
{
        ROUND_HALF_EVEN = 0,
        ROUND_HALF_UP,
        ROUND_DOWN,
        ROUND_CEILING,
        ROUND_FLOOR
}ROUNDING_MODE;

void Init_ibm_db();

/* Function Declarations */

VALUE ibm_db_connect(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_createDB(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_dropDB(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_createDBNX(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_commit(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_pconnect(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_autocommit(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_bind_param(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_close(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_columnprivileges(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_column_privileges(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_columns(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_foreignkeys(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_foreign_keys(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_primarykeys(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_primary_keys(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_procedure_columns(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_procedures(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_specialcolumns(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_special_columns(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_statistics(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_tableprivileges(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_table_privileges(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_tables(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_commit(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_exec(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_prepare(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_execute(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_conn_errormsg(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_stmt_errormsg(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_getErrormsg(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_getErrorstate(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_conn_error(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_stmt_error(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_next_result(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_num_fields(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_num_rows(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_result_cols(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_field_name(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_field_display_size(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_field_num(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_field_precision(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_field_scale(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_field_type(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_field_width(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_cursor_type(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_rollback(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_free_stmt(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_result(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_fetch_row(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_fetch_assoc(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_fetch_array(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_fetch_both(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_result_all(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_free_result(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_set_option(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_setoption(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_get_option(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_get_last_serial_value(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_getoption(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_fetch_object(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_server_info(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_client_info(int argc, VALUE *argv, VALUE self);
VALUE ibm_db_active(int argc, VALUE *argv, VALUE self);

/*
  Declare any global variables you may need between the BEGIN
  and END macros here:
*/
struct _ibm_db_globals {
  int  bin_mode;
#ifdef UNICODE_SUPPORT_VERSION
  SQLWCHAR  __ruby_conn_err_msg[DB2_MAX_ERR_MSG_LEN];
  SQLWCHAR  __ruby_stmt_err_msg[DB2_MAX_ERR_MSG_LEN];
  SQLWCHAR  __ruby_conn_err_state[SQL_SQLSTATE_SIZE + 1];
  SQLWCHAR  __ruby_stmt_err_state[SQL_SQLSTATE_SIZE + 1];
#else
  char      __ruby_conn_err_msg[DB2_MAX_ERR_MSG_LEN];
  char      __ruby_stmt_err_msg[DB2_MAX_ERR_MSG_LEN];
  char      __ruby_conn_err_state[SQL_SQLSTATE_SIZE + 1];
  char      __ruby_stmt_err_state[SQL_SQLSTATE_SIZE + 1];
#endif

#ifdef PASE /* i5/OS ease of use turn off commit */
  long i5_allow_commit;
#endif /* PASE */
};

/*
  TODO: make this threadsafe
*/

#define IBM_DB_G(v) (ibm_db_globals->v)

#endif  /* RUBY_IBM_DB_H */


/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 */
