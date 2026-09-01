CLASS lhc_ZI_FI_JE_HEADER DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    "------------------------------------------------------------
    " Authorization Methods
    "------------------------------------------------------------

    METHODS get_instance_authorizations
      FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations
      FOR journalentry
      RESULT result.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations
      FOR journalentry
      RESULT result.


    "------------------------------------------------------------
    " Instance Feature Control
    " Controls which actions are enabled/disabled based on
    " document status and other business conditions.
    "------------------------------------------------------------

    METHODS get_instance_features
      FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features
      FOR journalentry
      RESULT result.


    "------------------------------------------------------------
    " Validation Methods
    "------------------------------------------------------------

    METHODS validateheader
      FOR VALIDATE ON SAVE
      keys FOR journalentry~validateheader.

    METHODS validatebalance
      FOR VALIDATE ON SAVE
      keys FOR journalentry~validatebalance.

    METHODS validatelineitems
      FOR VALIDATE ON SAVE
      keys FOR journalentry~validatelineitems.


    "------------------------------------------------------------
    " Determination Methods
    "------------------------------------------------------------

    METHODS determinefiscalyear
      FOR DETERMINE ON MODIFY
      keys FOR journalentry~determinefiscalyear.

    METHODS determinestatus
      FOR DETERMINE ON MODIFY
      keys FOR journalentry~determinestatus.

    METHODS determinecreatedby
      FOR DETERMINE ON MODIFY
      keys FOR journalentry~determinecreatedby.


    "------------------------------------------------------------
    " Action Methods
    "------------------------------------------------------------

    METHODS submit
      FOR MODIFY
      keys FOR ACTION journalentry~submit.

    METHODS approve
      FOR MODIFY
      keys FOR ACTION journalentry~approve.

    METHODS post
      FOR MODIFY
      keys FOR ACTION journalentry~post.

    METHODS reverse
      FOR MODIFY
      keys FOR ACTION journalentry~reverse.


    "------------------------------------------------------------
    " Early Numbering
    "------------------------------------------------------------

    METHODS earlynumbering_create
      FOR NUMBERING
      entities FOR CREATE journalentry.

    METHODS earlynumbering_cba_item
      FOR NUMBERING
      entities FOR CREATE journalentry\_item.

ENDCLASS.

CLASS lhc_ZI_FI_JE_HEADER IMPLEMENTATION.


  "================================================================
  " INSTANCE AUTHORIZATIONS
  "================================================================
  " Controls whether the current user is authorized to:
  " - Update the journal entry
  " - Submit
  " - Approve
  " - Post
  " - Reverse
  "
  " Feature control and authorization are separate concepts:
  " Feature control determines whether the button is enabled.
  " Authorization determines whether the user is allowed to
  " execute the operation.
  "================================================================

  METHOD get_instance_authorizations.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS ( createdby status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<header>).

      APPEND VALUE #(

        %tky = <header>-%tky

        "----------------------------------------------------------
        " Update is allowed only for own draft documents
        "----------------------------------------------------------
        %update = COND #(
          WHEN <header>-status = 'D'
           AND <header>-createdby = sy-uname
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )


        "----------------------------------------------------------
        " Submit is allowed only for own draft documents
        "----------------------------------------------------------
        %action-submit = COND #(
          WHEN <header>-status = 'D'
           AND <header>-createdby = sy-uname
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )


        "----------------------------------------------------------
        " Approve is allowed for submitted documents
        "----------------------------------------------------------
        %action-approve = COND #(
          WHEN <header>-status = 'S'
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )


        "----------------------------------------------------------
        " Post is allowed for approved documents
        "----------------------------------------------------------
        %action-post = COND #(
          WHEN <header>-status = 'A'
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )


        "----------------------------------------------------------
        " Reverse is allowed only for posted documents
        "----------------------------------------------------------
        %action-reverse = COND #(
          WHEN <header>-status = 'P'
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized )

      ) TO result.

    ENDLOOP.

  ENDMETHOD.



  "================================================================
  " GLOBAL AUTHORIZATIONS
  "================================================================

  METHOD get_global_authorizations.

    "No global authorization logic is currently required.

  ENDMETHOD.



  "================================================================
  " HEADER VALIDATION
  "================================================================
  " Validates mandatory header fields and basic date rules.
  " Also validates mandatory fields of the associated line items.
  "================================================================

  METHOD validateheader.

    "--------------------------------------------------------------
    " Read header data
    "--------------------------------------------------------------

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS ( documentdate postingdate documenttype )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).


    "--------------------------------------------------------------
    " Validate header fields
    "--------------------------------------------------------------

    LOOP AT lt_header INTO DATA(ls_header).

      "Document Date is mandatory
      IF ls_header-documentdate IS INITIAL.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Document Date is required'
          )
        ) TO reported-journalentry.

      ENDIF.


      "Posting Date is mandatory
      IF ls_header-postingdate IS INITIAL.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Posting Date is required'
          )
        ) TO reported-journalentry.

      ENDIF.


      "Document Type is mandatory
      IF ls_header-documenttype IS INITIAL.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Document Type is required'
          )
        ) TO reported-journalentry.

      ENDIF.


      "Document Date cannot be in the future
      IF ls_header-documentdate > sy-datum.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Document Date cannot be posted in the future'
          )
        ) TO reported-journalentry.

      ENDIF.

    ENDLOOP.


    "--------------------------------------------------------------
    " Read associated line items
    "--------------------------------------------------------------

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      BY \_item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).


    "--------------------------------------------------------------
    " Validate line items
    "--------------------------------------------------------------

    LOOP AT lt_items INTO DATA(ls_item).

      "G/L Account is mandatory
      IF ls_item-glaccount IS INITIAL.

        APPEND VALUE #(
          %tky = ls_item-%tky
        ) TO failed-journalitem.

        APPEND VALUE #(
          %tky = ls_item-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'G/L Account is required'
          )
        ) TO reported-journalitem.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.



  "================================================================
  " BALANCE VALIDATION
  "================================================================
  " Ensures:
  " 1. Total debit = total credit
  " 2. Every line-item amount is greater than zero
  "================================================================

  METHOD validatebalance.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      BY \_item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).


    DATA(lv_credit) = CONV decfloat34( 0 ).
    DATA(lv_debit)  = CONV decfloat34( 0 ).


    LOOP AT lt_items INTO DATA(ls_item).

      "------------------------------------------------------------
      " Calculate total debit and credit
      "------------------------------------------------------------

      IF ls_item-debitcredit = 'D'.

        lv_debit += ls_item-amount.

      ELSEIF ls_item-debitcredit = 'C'.

        lv_credit += ls_item-amount.

      ENDIF.


      "------------------------------------------------------------
      " Amount must be greater than zero
      " This check must be inside the loop so every item is
      " validated.
      "------------------------------------------------------------

      IF ls_item-amount <= 0.

        APPEND VALUE #(
          %tky = ls_item-%tky
        ) TO failed-journalitem.

        APPEND VALUE #(
          %tky = ls_item-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Amount must be greater than zero'
          )
        ) TO reported-journalitem.

      ENDIF.

    ENDLOOP.


    "--------------------------------------------------------------
    " Debit and credit must be equal
    "--------------------------------------------------------------

    IF lv_credit <> lv_debit.

      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
      ) TO failed-journalentry.

      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Credit and Debit amounts do not match'
        )
      ) TO reported-journalentry.

    ENDIF.

  ENDMETHOD.



  "================================================================
  " LINE ITEM COUNT VALIDATION
  "================================================================
  " A journal entry must contain at least two line items.
  "================================================================

  METHOD validatelineitems.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      BY \_item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).


    DATA(lv_count) = lines( lt_items ).


    IF lv_count < 2.

      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
      ) TO failed-journalentry.

      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'At least 2 line items is required'
        )
      ) TO reported-journalentry.

    ENDIF.

  ENDMETHOD.



  "================================================================
  " DETERMINE FISCAL YEAR
  "================================================================
  " Fiscal year is derived from the posting date.
  "================================================================

  METHOD determinefiscalyear.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS ( postingdate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).


    MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      UPDATE FIELDS ( fiscalyear )
      WITH VALUE #(
        FOR ls_header IN lt_header
        WHERE ( postingdate IS NOT INITIAL )
        (
          %tky       = ls_header-%tky
          fiscalyear = ls_header-postingdate+0(4)
        )
      ).

  ENDMETHOD.



  "================================================================
  " DETERMINE INITIAL STATUS
  "================================================================
  " Every newly created journal entry starts in Draft status.
  " Status:
  " D = Draft
  " S = Submitted
  " A = Approved
  " P = Posted
  "================================================================

  METHOD determinestatus.

    MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      UPDATE FIELDS ( status )
      WITH VALUE #(
        FOR key IN keys
        (
          %tky   = key-%tky
          status = 'D'
        )
      ).

  ENDMETHOD.


  "================================================================
  " SUBMIT ACTION
  "================================================================
  " Draft -> Submitted
  "================================================================

  METHOD submit.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).


    LOOP AT lt_header INTO DATA(ls_header).

      "Only draft documents can be submitted
      IF ls_header-status <> 'D'.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Only draft Journal Entry can be submitted'
          )
        ) TO reported-journalentry.

        CONTINUE.

      ENDIF.


      "Change status from Draft to Submitted
      MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE
        ENTITY journalentry
        UPDATE FIELDS ( status )
        WITH VALUE #(
          (
            %tky   = ls_header-%tky
            status = 'S'
          )
        ).

    ENDLOOP.

  ENDMETHOD.



  "================================================================
  " APPROVE ACTION
  "================================================================
  " Submitted -> Approved
  "================================================================

  METHOD approve.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).


    LOOP AT lt_header INTO DATA(ls_header).

      "Only submitted documents can be approved
      IF ls_header-status <> 'S'.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Only submitted Journal Entry can be approved'
          )
        ) TO reported-journalentry.

        CONTINUE.

      ENDIF.


      "Change status from Submitted to Approved
      MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE
        ENTITY journalentry
        UPDATE FIELDS ( status )
        WITH VALUE #(
          (
            %tky   = ls_header-%tky
            status = 'A'
          )
        ).

    ENDLOOP.

  ENDMETHOD.



  "================================================================
  " POST ACTION
  "================================================================
  " Approved -> Posted
  "================================================================

  METHOD post.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).


    LOOP AT lt_header INTO DATA(ls_header).

      "Only approved documents can be posted
      IF ls_header-status <> 'A'.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Only approved Journal Entry can be posted'
          )
        ) TO reported-journalentry.

        CONTINUE.

      ENDIF.


      "Change status from Approved to Posted
      MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE
        ENTITY journalentry
        UPDATE FIELDS ( status )
        WITH VALUE #(
          (
            %tky   = ls_header-%tky
            status = 'P'
          )
        ).

    ENDLOOP.

  ENDMETHOD.



  "================================================================
  " EARLY NUMBERING - JOURNAL ENTRY HEADER
  "================================================================
  " Generates a unique JE ID by checking both:
  " 1. Active table
  " 2. Draft table
  "
  " This prevents the same number from being assigned to an
  " active document and a draft document.
  "================================================================

  METHOD earlynumbering_create.

    DATA lv_max_active TYPE zfi_je_header-je_id.
    DATA lv_max_draft  TYPE zfi_je_header-je_id.
    DATA lv_max_field  TYPE zfi_je_header-je_id.
    DATA lv_next_field TYPE i.


    "--------------------------------------------------------------
    " Get highest JE ID from active table
    "--------------------------------------------------------------

    SELECT MAX( je_id )
      FROM zfi_je_header
      INTO @lv_max_active.


    "--------------------------------------------------------------
    " Get highest JE ID from draft table
    "--------------------------------------------------------------

    SELECT MAX( jeid )
      FROM zfi_je_header_d
      INTO @lv_max_draft.


    "--------------------------------------------------------------
    " Determine highest existing JE ID
    "--------------------------------------------------------------

    IF lv_max_active >= lv_max_draft.

      lv_max_field = lv_max_active.

    ELSE.

      lv_max_field = lv_max_draft.

    ENDIF.


    "--------------------------------------------------------------
    " Determine next JE ID
    "--------------------------------------------------------------

    IF lv_max_field IS INITIAL.

      lv_next_field = 1.

    ELSE.

      lv_next_field = CONV i( lv_max_field ) + 1.

    ENDIF.


    "--------------------------------------------------------------
    " Number all incoming instances
    "--------------------------------------------------------------

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_header>).

      IF <fs_header>-jeid IS INITIAL.

        "New instance - assign the next available JE ID
        APPEND VALUE #(
          %cid      = <fs_header>-%cid
          %is_draft = <fs_header>-%is_draft
          jeid      = lv_next_field
        ) TO mapped-journalentry.

        lv_next_field += 1.

      ELSE.

        "Existing instance - return the existing JE ID
        APPEND VALUE #(
          %cid      = <fs_header>-%cid
          %is_draft = <fs_header>-%is_draft
          jeid      = <fs_header>-jeid
        ) TO mapped-journalentry.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.



  "================================================================
  " EARLY NUMBERING - JOURNAL ENTRY ITEMS
  "================================================================
  " Generates sequential item numbers for each journal entry.
  "================================================================

  METHOD earlynumbering_cba_item.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<header>).

      DATA(lv_jeid) = <header>-jeid.


      "------------------------------------------------------------
      " Read existing items from the RAP transactional buffer
      "------------------------------------------------------------

      READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
        ENTITY journalentry
        BY \_item
        ALL FIELDS
        WITH VALUE #(
          (
            %tky = <header>-%tky
          )
        )
        RESULT DATA(lt_existing_items).


      DATA(lv_max_item) = 0.


      "------------------------------------------------------------
      " Find highest existing item number
      "------------------------------------------------------------

      LOOP AT lt_existing_items ASSIGNING FIELD-SYMBOL(<existing_item>).

        IF <existing_item>-itemno > lv_max_item.

          lv_max_item = <existing_item>-itemno.

        ENDIF.

      ENDLOOP.


      DATA(lv_next_item) = lv_max_item + 1.


      "------------------------------------------------------------
      " Assign item numbers to newly created items
      "------------------------------------------------------------

      LOOP AT <header>-%target ASSIGNING FIELD-SYMBOL(<item>).

        APPEND VALUE #(
          %cid      = <item>-%cid
          %is_draft = <item>-%is_draft
          jeid      = lv_jeid
          itemno    = lv_next_item
        ) TO mapped-journalitem.

        lv_next_item += 1.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.



  "================================================================
  " INSTANCE FEATURES
  "================================================================
  " Controls which action buttons are enabled in the UI.
  "
  " Workflow:
  "
  " Draft     -> Submit
  " Submitted -> Approve
  " Approved  -> Post
  " Posted    -> Reverse
  "
  " Actions are disabled while working on a draft.
  "================================================================

  METHOD get_instance_features.

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS ( status reversalofjeid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).


    "--------------------------------------------------------------
    " Find existing reversal documents in active table
    "--------------------------------------------------------------

    IF lt_header IS NOT INITIAL.

      SELECT reversal_of_jeid
        FROM zfi_je_header
        FOR ALL ENTRIES IN @lt_header
        WHERE reversal_of_jeid = @lt_header-jeid
        INTO TABLE @DATA(lt_existing_reversals_active).


      "------------------------------------------------------------
      " Find existing reversal documents in draft table
      "------------------------------------------------------------

      SELECT reversalofjeid
        FROM zfi_je_header_d
        FOR ALL ENTRIES IN @lt_header
        WHERE reversalofjeid = @lt_header-jeid
        INTO TABLE @DATA(lt_existing_reversals_draft).

    ENDIF.


    "--------------------------------------------------------------
    " Combine active and draft reversals
    "--------------------------------------------------------------

    APPEND LINES OF lt_existing_reversals_draft
      TO lt_existing_reversals_active.

    DATA(lt_existing_reversals) = lt_existing_reversals_active.


    "--------------------------------------------------------------
    " Determine enabled/disabled state of each action
    "--------------------------------------------------------------

    result = VALUE #(

      FOR ls_header IN lt_header

      (

        %tky = ls_header-%tky


        "----------------------------------------------------------
        " SUBMIT
        " Enabled only for active draft documents
        "----------------------------------------------------------

        %features-%action-submit =
          COND #(
            WHEN ls_header-%is_draft = if_abap_behv=>mk-off
             AND ls_header-status = 'D'
            THEN if_abap_behv=>fc-o-enabled
            ELSE if_abap_behv=>fc-o-disabled )


        "----------------------------------------------------------
        " APPROVE
        " Enabled only for submitted active documents
        "----------------------------------------------------------

        %features-%action-approve =
          COND #(
            WHEN ls_header-%is_draft = if_abap_behv=>mk-off
             AND ls_header-status = 'S'
            THEN if_abap_behv=>fc-o-enabled
            ELSE if_abap_behv=>fc-o-disabled )


        "----------------------------------------------------------
        " POST
        " Enabled only for approved active documents
        "----------------------------------------------------------

        %features-%action-post =
          COND #(
            WHEN ls_header-%is_draft = if_abap_behv=>mk-off
             AND ls_header-status = 'A'
            THEN if_abap_behv=>fc-o-enabled
            ELSE if_abap_behv=>fc-o-disabled )


        "----------------------------------------------------------
        " REVERSE
        "
        " Conditions:
        " 1. Document must not be a draft
        " 2. Document must be posted
        " 3. Document must not itself be a reversal document
        " 4. No reversal document must already exist
        "----------------------------------------------------------

        %features-%action-reverse =
          COND #(
            WHEN ls_header-%is_draft = if_abap_behv=>mk-off
             AND ls_header-status = 'P'
             AND ls_header-reversalofjeid = '0000000000'
             AND NOT line_exists(
                   lt_existing_reversals[
                     reversal_of_jeid = ls_header-jeid
                   ]
                 )
            THEN if_abap_behv=>fc-o-enabled
            ELSE if_abap_behv=>fc-o-disabled )

      )

    ).

  ENDMETHOD.



  "================================================================
  " DETERMINE CREATED BY
  "================================================================

  METHOD determinecreatedby.

    MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      UPDATE FIELDS ( createdby )
      WITH VALUE #(
        FOR key IN keys
        (
          %tky     = key-%tky
          createdby = sy-uname
        )
      ).

  ENDMETHOD.



  "================================================================
  " REVERSE ACTION
  "================================================================
  " Creates a reversal journal entry for a posted journal entry.
  "
  " The reversal document:
  " - Gets a new JE ID
  " - Copies the header information
  " - Copies all line items
  " - Reverses Debit/Credit
  " - Stores the original JE ID in REVERSAL_OF_JEID
  "
  " The original JE is also updated with the newly created
  " reversal JE ID.
  "================================================================

  METHOD reverse.

    "--------------------------------------------------------------
    " 1. Read original journal entry
    "--------------------------------------------------------------

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      FIELDS (
        jeid
        companycode
        fiscalyear
        documentdate
        postingdate
        documenttype
        currency
        status
        reversalofjeid
      )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).


    "--------------------------------------------------------------
    " 2. Read original journal entry items
    "--------------------------------------------------------------

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE
      ENTITY journalentry
      BY \_item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).


    "--------------------------------------------------------------
    " 3. Process each selected journal entry
    "--------------------------------------------------------------

    LOOP AT lt_header INTO DATA(ls_header).


      "------------------------------------------------------------
      " Only posted JEs can be reversed
      "------------------------------------------------------------

      IF ls_header-status <> 'P'.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Only posted Journal Entries can be reversed'
          )
        ) TO reported-journalentry.

        CONTINUE.

      ENDIF.


      "------------------------------------------------------------
      " A reversal document cannot itself be reversed
      "------------------------------------------------------------

      IF ls_header-reversalofjeid <> '0000000000'.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'A reversal entry cannot be reversed'
          )
        ) TO reported-journalentry.

        CONTINUE.

      ENDIF.


      "------------------------------------------------------------
      " Check whether a reversal already exists
      "------------------------------------------------------------

      SELECT SINGLE je_id
        FROM zfi_je_header
        WHERE reversal_of_jeid = @ls_header-jeid
        INTO @DATA(lv_existing_reversal).


      IF lv_existing_reversal IS NOT INITIAL.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = |Journal Entry { ls_header-jeid } has already been reversed|
          )
        ) TO reported-journalentry.

        CONTINUE.

      ENDIF.


      "------------------------------------------------------------
      " 4. Create reversal journal entry header
      "------------------------------------------------------------

      DATA(lv_cid) = |REV_{ ls_header-jeid }|.


      MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE

        ENTITY journalentry

        CREATE

        FIELDS (
          companycode
          documentdate
          postingdate
          documenttype
          currency
          status
          reversalofjeid
        )

        WITH VALUE #(
          (
            %cid          = lv_cid
            companycode   = ls_header-companycode
            documentdate  = sy-datum
            postingdate   = sy-datum
            documenttype  = ls_header-documenttype
            currency      = ls_header-currency
            status        = 'D'
            reversalofjeid = ls_header-jeid
          )
        )


        "----------------------------------------------------------
        " 5. Create reversal line items
        "----------------------------------------------------------

        ENTITY journalentry

        CREATE BY \_item

        FIELDS (
          glaccount
          costcenter
          profitcenter
          debitcredit
          amount
          currency
          itemtext
        )

        WITH VALUE #(
          (
            %cid_ref = lv_cid

            %target = VALUE #(

              FOR ls_item IN lt_items

              WHERE ( jeid = ls_header-jeid )

              (
                %cid = |REV_{ ls_header-jeid }_{ ls_item-itemno }|

                glaccount   = ls_item-glaccount
                costcenter  = ls_item-costcenter
                profitcenter = ls_item-profitcenter

                "Reverse Debit/Credit
                debitcredit = COND #(
                  WHEN ls_item-debitcredit = 'D'
                  THEN 'C'

                  WHEN ls_item-debitcredit = 'C'
                  THEN 'D'

                  ELSE ls_item-debitcredit
                )

                amount   = ls_item-amount
                currency = ls_item-currency

                itemtext = |Reversal of JE { ls_header-jeid }|
              )

            )

          )
        )

        MAPPED mapped
        FAILED failed
        REPORTED reported.


      "------------------------------------------------------------
      " 6. Check whether reversal creation failed
      "------------------------------------------------------------

      IF failed-journalentry IS NOT INITIAL
         OR failed-journalitem IS NOT INITIAL.

        APPEND VALUE #(
          %tky = ls_header-%tky
        ) TO failed-journalentry.

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Reversal Journal Entry could not be created'
          )
        ) TO reported-journalentry.

        CONTINUE.

      ENDIF.


      "------------------------------------------------------------
      " 7. Get the JE ID assigned to the newly created reversal
      "------------------------------------------------------------

      READ TABLE mapped-journalentry
        ASSIGNING FIELD-SYMBOL(<mapped_reversal>)
        WITH KEY %cid = lv_cid.


      IF sy-subrc = 0.

        DATA(lv_reversal_jeid) = <mapped_reversal>-jeid.


        "----------------------------------------------------------
        " 8. Update original JE with reversal JE ID
        "
        " Example:
        " Original JE 9
        " Reversal JE 12
        "
        " Original JE:
        " REVERSAL_OF_JEID = 0000000012
        "
        " Reversal JE:
        " REVERSAL_OF_JEID = 0000000009
        "----------------------------------------------------------

        MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE
          ENTITY journalentry
          UPDATE FIELDS ( reversalofjeid )
          WITH VALUE #(
            (
              %tky = ls_header-%tky
              reversalofjeid = lv_reversal_jeid
            )
          ).


        "----------------------------------------------------------
        " 9. Success message
        "----------------------------------------------------------

        APPEND VALUE #(
          %tky = ls_header-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-success
            text = |Reversal Entry { lv_reversal_jeid } created successfully|
          )
        ) TO reported-journalentry.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

"============================================================
" 4. ITEM HANDLER DEFINITION
"============================================================

CLASS lhc_ZI_FI_JE_ITEM DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS determinetotalamount
      FOR DETERMINE ON MODIFY
      keys FOR journalitem~determinetotalamount.

ENDCLASS.

"============================================================
" 5. ITEM HANDLER IMPLEMENTATION
"============================================================

CLASS lhc_ZI_FI_JE_ITEM IMPLEMENTATION.

  METHOD determinetotalamount.

    "--------------------------------------------------------
    " Get the header belonging to the changed line item
    "--------------------------------------------------------

    READ ENTITIES OF zi_fi_je_header IN LOCAL MODE

      ENTITY journalitem

      BY \_header

      FIELDS ( jeid )

      WITH CORRESPONDING #( keys )

      RESULT DATA(lt_headers).


    "--------------------------------------------------------
    " Process each affected Journal Entry
    "--------------------------------------------------------

    LOOP AT lt_headers INTO DATA(ls_header).


      "------------------------------------------------------
      " Read all line items belonging to this Journal Entry
      "------------------------------------------------------

      READ ENTITIES OF zi_fi_je_header IN LOCAL MODE

        ENTITY journalentry

        BY \_item

        ALL FIELDS

        WITH VALUE #(
          (
            %tky = ls_header-%tky
          )
        )

        RESULT DATA(lt_items).


      "------------------------------------------------------
      " Calculate total amount
      "------------------------------------------------------

      DATA(lv_total_amount) = CONV decfloat34( 0 ).

      LOOP AT lt_items INTO DATA(ls_item).

        lv_total_amount = lv_total_amount + ls_item-amount.

      ENDLOOP.


      "------------------------------------------------------
      " Update header total amount
      "------------------------------------------------------

      MODIFY ENTITIES OF zi_fi_je_header IN LOCAL MODE

        ENTITY journalentry

        UPDATE FIELDS ( totalamount )

        WITH VALUE #(
          (
            %tky        = ls_header-%tky
            totalamount = lv_total_amount
          )
        ).


    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

