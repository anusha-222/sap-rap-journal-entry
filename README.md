# SAP RAP Journal Entry Management Application

A custom SAP Fiori business application built using the **ABAP RESTful Application Programming Model (RAP)** for creating, validating, submitting, approving, posting, and reversing Journal Entries.

## Project Overview

This project demonstrates the implementation of a transactional Journal Entry Management application using SAP RAP.

The application allows users to:

- Create Journal Entries
- Maintain Journal Entry line items
- Automatically determine Fiscal Year
- Automatically determine Created By
- Calculate Header Total Amount from line items
- Validate Journal Entry header data
- Validate Journal Entry line items
- Validate Debit/Credit balance
- Submit Journal Entries
- Approve Journal Entries
- Post Journal Entries
- Reverse posted Journal Entries
- Prevent invalid status transitions
- Dynamically control action availability
- Handle draft documents using RAP Draft
- Automatically generate Journal Entry IDs and Item Numbers

The business process follows:

**Draft → Submitted → Approved → Posted → Reversal Document**

## Technology Stack

 Technology                                           Usage 

 SAP ABAP                                             Backend development 
 ABAP RESTful Application Programming Model (RAP)     Business object implementation 
 CDS View Entities                                    Data modeling 
 Behavior Definitions                                 Business logic and transaction definition 
 Behavior Pool                                        Implementation of validations, determinations, and actions 
 Entity Manipulation Language (EML)                   Transactional entity operations 
 SAP Fiori                                            User interface 
 OData                                                Service exposure 
 RAP Draft                                            Draft document handling 
 SAP HANA                                             Persistence 

## Application Architecture

SAP Fiori UI
      |
      ↓
OData Service
      |
      ↓
Projection CDS Views
      |
      ↓
Projection Behavior
      |
      ↓
Interface CDS Views
      |
      ↓
Interface Behavior
      |
      ↓
Behavior Pool
      |
      ↓
Persistent Database Tables


The Journal Entry Header is the **composition root** and contains Journal Entry Items as dependent child entities.

## Data Model

### Journal Entry Header

Persistent table:
ZFI_JE_HEADER

Draft table:
ZFI_JE_HEADER_D

The header contains:
- Journal Entry ID
- Company Code
- Fiscal Year
- Document Date
- Posting Date
- Document Type
- Currency
- Total Amount
- Status
- Created By
- Created At
- Changed By
- Changed At
- Reversal Journal Entry ID

### Journal Entry Item
Persistent table:
ZFI_JE_ITEM

Draft table:
ZFI_JE_ITEM_D

The line item contains:
- Journal Entry ID
- Item Number
- G/L Account
- Cost Center
- Profit Center
- Debit/Credit Indicator
- Amount
- Currency
- Item Text

## Entity Relationship
ZI_FI_JE_HEADER
       |
       | 1
       |
       | composition
       |
       | 0..*
       ↓
ZI_FI_JE_ITEM

The Header acts as the composition root, while Items are dependent entities.

## CDS Data Model
### Interface CDS Views
Header:
ZI_FI_JE_HEADER

The root view entity is based on `ZFI_JE_HEADER` and exposes the Journal Entry Header as the RAP business object root entity.

The Header contains a composition to:
ZI_FI_JE_ITEM

Item:
ZI_FI_JE_ITEM

The item view represents individual Journal Entry line items.

### Projection CDS Views
ZC_FI_JE_HEADER
ZC_FI_JE_ITEM


The projection layer exposes the business object for consumption by the Fiori application.
## RAP Behavior

The application uses a **managed RAP implementation with draft support**.

The Header behavior implements:
- Create
- Update
- Delete
- Draft handling
- Validations
- Determinations
- Actions
- Instance authorization
- Instance feature control
- Early numbering
- Side effects

The Item behavior is dependent on the Header and supports the required child-entity operations.

## Draft Handling
The application uses RAP Draft functionality so that Journal Entries can be created and edited before activation.

Draft capabilities include:

- Edit
- Activate
- Discard
- Resume
- Prepare

Business-process actions are prevented while the document is still a draft.

Therefore:

- Submit is disabled for draft instances
- Approve is disabled for draft instances
- Post is disabled for draft instances
- Reverse is disabled for draft instances

Action availability is controlled dynamically using instance feature control.

## Early Numbering
The application implements early numbering for Journal Entries.
The next Journal Entry ID is determined using the highest existing ID from both:
ZFI_JE_HEADER
ZFI_JE_HEADER_D


The next available number is assigned to a newly created Journal Entry.

Journal Entry Items are also numbered automatically within their respective Journal Entry.

## Journal Entry Status Flow
Draft (D)
   |
   | Submit
   ↓
Submitted (S)
   |
   | Approve
   ↓
Approved (A)
   |
   | Post
   ↓
Posted (P)
   |
   | Reverse
   ↓
New Reversal Journal Entry


Each action validates the current status before performing the transition.

## Submit
A Journal Entry can be submitted only when:

Status = D (Draft)

After successful submission:

D → S

The Submit action becomes unavailable and Approve becomes available.

## Approve
A Journal Entry can be approved only when:

Status = S (Submitted)

After successful approval:

S → A

The Approve action becomes unavailable and Post becomes available.

## Post

A Journal Entry can be posted only when:

Status = A (Approved)

After successful posting:

A → P

The Post action becomes unavailable and Reverse becomes available.

## Reverse

Only a posted Journal Entry can be reversed.

The Reverse action creates a **new Journal Entry** rather than changing the status of the original posted document.

The reversal document contains:
- Original company code
- Current document date
- Current posting date
- Original document type
- Original currency
- Original line-item G/L accounts
- Original cost center and profit center information
- Original amounts
- Opposite Debit/Credit indicators
- Reference to the original Journal Entry

The new reversal document stores the original Journal Entry ID in:
REVERSAL_OF_JEID

The original posted document remains unchanged.

## Reversal Protection

The application prevents:
- Reversing a non-posted Journal Entry
- Reversing a reversal Journal Entry
- Reversing the same Journal Entry more than once

The Reverse action is dynamically disabled when a reversal already exists.

## Total Amount Determination
The Header contains a Total Amount field.
The determination reads the related Journal Entry Items and calculates the Header total from the item amounts.
The implementation uses RAP EML to read the associated Items and update the Header.

## Fiscal Year Determination
Fiscal Year is automatically derived from the Posting Date.

Example:
Posting Date: 2026-08-31
       ↓
Fiscal Year: 2026


This logic is implemented as a RAP determination triggered by creation and changes to the Posting Date.

## Created By Determination
The Created By field is automatically populated using the current SAP user:

SY-UNAME
   ↓
Created By

## Validations
The application implements RAP validations to prevent invalid Journal Entries from being saved.

### Header Validation
- Document Date is mandatory.
- Document Date cannot be in the future.
- Posting Date is mandatory.
- Document Type is mandatory.

### Line Item Validation
Every Journal Entry Item must contain a G/L Account.

### Minimum Line Items
A Journal Entry must contain at least two line items.
Minimum line items = 2

### Debit/Credit Validation
The total Debit amount must equal the total Credit amount.

Total Debit = Total Credit

### Amount Validation
Each line item amount must be greater than zero.

Amount > 0

## Authorization
The application uses RAP authorization concepts including:
- Instance authorization
- Global authorization framework
- Status-based action authorization
- Creator-based update and submit authorization

Draft update and submit operations can be restricted using:
Created By
     +
Current User
     +
Document Status

## Dynamic Feature Control
Instance feature control dynamically determines whether actions are enabled or disabled.

 Status        Submit        Approve        Post        Reverse 

 Draft        Disabled       Disabled       Disabled    Disabled 
 Submitted    Disabled       Enabled        Disabled    Disabled 
 Approved     Disabled       Disabled       Enabled     Disabled 
 Posted       Disabled       Disabled       Disabled    Enabled 
 Reversal     Disabled       Disabled       Disabled    Disabled 

The Reverse action has an additional check to determine whether the current Journal Entry has already been reversed.

## Side Effects
RAP side effects are defined for the business-process actions.

They inform the UI that changes to status and reversal information can affect:
- Action availability
- Submit permission
- Approve permission
- Post permission
- Reverse permission
- Reversal information
This allows the Fiori UI to recalculate relevant instance features after an action.

## EML Usage
Entity Manipulation Language (EML) is used extensively in the behavior implementation.

Examples include:
abap
READ ENTITIES
and:
abap
MODIFY ENTITIES

EML is used for:
- Reading Header data
- Reading associated Item data
- Updating document status
- Creating reversal Journal Entries
- Creating reversal line items
- Updating calculated Header values
- Reading data from the transactional buffer

## Metadata Extensions
Metadata extensions are used to define UI-related annotations for the Fiori application.

The project contains custom metadata extensions for:
ZC_FI_JE_HEADER
ZC_FI_JE_ITEM

## Main RAP Objects
### Database Tables
ZFI_JE_HEADER
ZFI_JE_ITEM
ZFI_JE_HEADER_D
ZFI_JE_ITEM_D

### Interface CDS Views
ZI_FI_JE_HEADER
ZI_FI_JE_ITEM

### Projection CDS Views
ZC_FI_JE_HEADER
ZC_FI_JE_ITEM

### Behavior Definitions
Interface behavior:
ZI_FI_JE_HEADER

Projection behavior:
ZC_FI_JE_HEADER
The Item behavior is defined as the dependent child behavior of the Header.

### Behavior Pool
ZBP_I_FI_JE_HEADER

The behavior pool contains the implementation of:
- Validations
- Determinations
- Actions
- Feature control
- Authorization
- Early numbering
- Reversal processing

### Utility Class
ZCL_FILL_JE_DATA

A custom utility class used for Journal Entry test/support data.

## Fiori Application
The RAP business object is exposed through an OData service and consumed by a SAP Fiori application.

The application provides functionality for:
- Creating Journal Entries
- Entering Header information
- Adding line items
- Saving drafts
- Submitting documents
- Approving documents
- Posting documents
- Reversing posted documents

The UI dynamically reflects the current Journal Entry status and available actions.

## Business Process Example
A typical scenario is:

### Step 1 — Create
Status = Draft
A Journal Entry ID is automatically assigned.

### Step 2 — Add Items
Example:
Item 1 → Debit  10,000
Item 2 → Credit 10,000
The Journal Entry is balanced.

### Step 3 — Submit
Draft → Submitted

### Step 4 — Approve
Submitted → Approved

### Step 5 — Post
Approved → Posted

### Step 6 — Reverse
A new reversal Journal Entry is generated with opposite Debit/Credit indicators.

Original JE
     ↓
   Reverse
     ↓
New Reversal JE


## Key RAP Concepts Demonstrated
- Managed RAP
- Draft-enabled RAP
- CDS View Entities
- Root View Entity
- Composition
- Projection Views
- Behavior Definitions
- Behavior Pool
- Entity Manipulation Language (EML)
- Determinations
- Validations
- Actions
- Instance Feature Control
- Instance Authorization
- Early Numbering
- Side Effects
- Draft Actions
- Transactional Buffer
- Parent/Child Entity Processing
- RAP Error Handling
- RAP Message Handling
- Metadata Extensions

## Key Technical Highlights
### 1. Controlled Status Workflow
The Journal Entry cannot skip business-process stages.
Draft
  ↓
Submit
  ↓
Submitted
  ↓
Approve
  ↓
Approved
  ↓
Post
  ↓
Posted

Each action performs a server-side status check.

### 2. Automatic Reversal Creation
The Reverse action creates an independent reversal Journal Entry instead of modifying the original posted document.

### 3. Reversal Reference
The reversal document maintains a reference to the original document using:

REVERSAL_OF_JEID

### 4. Duplicate Reversal Prevention
The application checks whether a reversal already exists before allowing another reversal.

### 5. Draft-Aware Numbering
Journal Entry numbering considers both active and draft records.

### 6. Dynamic UI Actions
Action availability is determined from the current document status and reversal state.

### 7. RAP Transactional Processing
The implementation uses EML and RAP transactional processing for entity reads, updates, and reversal creation.

## Project Structure
sap-rap-journal-entry/
│
├── README.md
│
└── src/
    ├── tables/
    │   ├── ZFI_JE_HEADER
    │   ├── ZFI_JE_ITEM
    │   ├── ZFI_JE_HEADER_D
    │   └── ZFI_JE_ITEM_D
    │
    ├── cds/
    │   ├── ZI_FI_JE_HEADER
    │   ├── ZI_FI_JE_ITEM
    │   ├── ZC_FI_JE_HEADER
    │   └── ZC_FI_JE_ITEM
    │
    ├── metadata/
    │   ├── ZC_FI_JE_HEADER.ddlx
    │   └── ZC_FI_JE_ITEM.ddlx
    │
    ├── behavior/
    │   ├── ZI_FI_JE_HEADER.bdef
    │   └── ZC_FI_JE_HEADER.bdef
    │
    └── classes/
        ├── ZBP_I_FI_JE_HEADER.abap
        └── ZCL_FILL_JE_DATA.abap


## Learning Outcomes
This project provides practical experience in building a transactional business application using modern SAP ABAP development techniques.

Key areas practiced include:
- RAP Business Objects
- Managed RAP
- Draft Handling
- Transactional Processing
- EML
- CDS Modeling
- Composition
- Business Validations
- Determinations
- Actions
- Authorizations
- Feature Control
- Side Effects
- Early Numbering
- Fiori Integration
- Reversal processing
- RAP error and message handling

## Future Enhancements
Possible future enhancements include:
- Integration with SAP FI posting APIs
- Company Code validation against standard SAP master data
- G/L Account validation against standard SAP master data
- Posting to an actual SAP accounting document
- Additional approval levels
- Attachment functionality
- Search and filter enhancements
- Application logging
- Error monitoring
- More granular role-based authorization
- Audit trail for status changes
- Additional reporting capabilities

## Project Type
**SAP RAP / ABAP Cloud / SAP Fiori Business Application**

This project is a practical demonstration of designing and implementing a transactional business application using the SAP ABAP RESTful Application Programming Model.
