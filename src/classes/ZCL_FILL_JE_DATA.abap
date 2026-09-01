CLASS zcl_fill_je_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_fill_je_data IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA(lv_timestamp) = utclong_current( ).
    DATA lt_header type table of zfi_je_header.
    DATA lt_item type table of zfi_je_item.

    lt_header = value #(
    (
        client        = sy-mandt
        je_id         = '0000000001'
        company_code  = '1000'
        fiscal_year   = '2026'
        document_date = '20260824'
        posting_date   = '20260826'
        document_type = 'SA'
        currency      = 'INR'
        total_amount  = '15000.00'
        status        = 'N'
        created_by    = 'TEST_USER'
        created_at    = lv_timestamp
        changed_by    = 'TEST_USER'
        changed_at    = lv_timestamp
      )
      (
        client        = sy-mandt
        je_id         = '0000000002'
        company_code  = '2000'
        fiscal_year   = '2026'
        document_date = '20260824'
        posting_date   = '20260826'
        document_type = 'SA'
        currency      = 'INR'
        total_amount  = '10000.00'
        status        = 'N'
        created_by    = 'TEST_USER1'
        created_at    = lv_timestamp
        changed_by    = 'TEST_USER1'
        changed_at    = lv_timestamp
      )
     ).

     lt_item = VALUE #(
      (
        client        = sy-mandt
        je_id         = '0000000001'
        item_no       = '001'
        gl_account    = '400000'
        cost_center   = 'CC1000'
        profit_center = 'PC1000'
        debit_credit  = 'D'
        amount        = '10000.00'
        currency      = 'INR'
        item_text     = 'Test debit posting'
      )

      (
        client        = sy-mandt
        je_id         = '0000000001'
        item_no       = '002'
        gl_account    = '500000'
        cost_center   = 'CC1000'
        profit_center = 'PC1000'
        debit_credit  = 'C'
        amount        = '5000.00'
        currency      = 'INR'
        item_text     = 'Test credit posting'
      )
      (
        client        = sy-mandt
        je_id         = '0000000002'
        item_no       = '001'
        gl_account    = '600000'
        cost_center   = 'CC2000'
        profit_center = 'PC2000'
        debit_credit  = 'D'
        amount        = '7000.00'
        currency      = 'INR'
        item_text     = 'Test debit posting 1'
      )

      (
        client        = sy-mandt
        je_id         = '0000000002'
        item_no       = '002'
        gl_account    = '700000'
        cost_center   = 'CC2000'
        profit_center = 'PC2000'
        debit_credit  = 'C'
        amount        = '3000.00'
        currency      = 'INR'
        item_text     = 'Test credit posting 1'
      )
    ).

    insert zfi_je_header from table @lt_header.
     out->write( |Header records inserted: { sy-dbcnt }| ).
    insert zfi_je_item from table @lt_item.
      out->write( |item records inserted: { sy-dbcnt }| ).
  ENDMETHOD.

ENDCLASS.
