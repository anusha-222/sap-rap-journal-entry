@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDs view for header'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_FI_JE_HEADER as select from zfi_je_header
composition[0..*] of ZI_FI_JE_ITEM as _item
{
  key je_id as jeid,
  company_code as companycode,
  fiscal_year as fiscalyear,
  document_date as documentdate,
  posting_date as postingdate,
  document_type as documenttype,
  currency as currency,
  @Semantics.amount.currencyCode : 'currency'
  total_amount as totalamount,
  status as status,
  created_by as createdby,
  created_at as createdat,
  changed_by as changedby,
  @Semantics.systemDateTime.lastChangedAt: true
  changed_at as changedat,
  reversal_of_jeid as reversalofjeid,
  _item
}

