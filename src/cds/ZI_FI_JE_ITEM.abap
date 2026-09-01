@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Definition for Item table'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_FI_JE_ITEM as select from zfi_je_item
association to parent ZI_FI_JE_HEADER as _header
on $projection.jeid = _header.jeid 

{  
  key je_id as jeid,  
  key item_no as itemno, 
  gl_account as glaccount, 
  cost_center as costcenter, 
  profit_center as profitcenter, 
  debit_credit as debitcredit, 
  @Semantics.amount.currencyCode: 'currency'
  amount as amount,    
  currency as currency, 
  item_text as itemtext,
  _header  
}

