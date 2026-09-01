@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: 'Definition for Item table'
}
@AccessControl.authorizationCheck: #MANDATORY
define view entity ZC_FI_JE_ITEM
  as projection on ZI_FI_JE_ITEM
  association [1..1] to ZI_FI_JE_ITEM as _BaseEntity on $projection.JEID = _BaseEntity.JEID and $projection.ITEMNO = _BaseEntity.ITEMNO
{
  key jeid,
  key itemno,
  glaccount,
  costcenter,
  profitcenter,
  debitcredit,
  @Semantics: {
    Amount.Currencycode: 'currency'
  }
  amount,
  @Semantics.currencyCode: true
  currency,
  itemtext,
  _header : redirected to parent ZC_FI_JE_HEADER,
  _BaseEntity
}

