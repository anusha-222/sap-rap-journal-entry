@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: 'CDs view for header'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_FI_JE_HEADER
  provider contract transactional_query
  as projection on ZI_FI_JE_HEADER
  association [1..1] to ZI_FI_JE_HEADER as _BaseEntity on $projection.jeid = _BaseEntity.jeid
{
  key jeid,
  companycode,
  fiscalyear,
  documentdate,
  postingdate,
  documenttype,
  @Semantics.currencyCode: true
  currency,
  @Semantics: {
    amount.currencyCode: 'currency'
  }
  totalamount,
  status,
  createdby,
  createdat,
  changedby,
  changedat,
  reversalofjeid,
  _item : redirected to composition child ZC_FI_JE_ITEM,
  _BaseEntity
}

