# sap-rap-journal-entry
SAP RAP-based Journal Entry Management Application

A custom SAP Fiori application built using the **ABAP RESTful Application Programming Model (RAP)** for creating, validating, approving, posting, and reversing Journal Entries.



## 📌 Project Overview

This project implements a Journal Entry Management application using SAP RAP.

The application allows users to:

- Create Journal Entries
- Maintain Journal Entry line items
- Automatically determine Fiscal Year
- Automatically determine Created By
- Automatically calculate Total Amount
- Validate Journal Entry header data
- Validate line items
- Validate Debit/Credit balance
- Submit Journal Entries
- Approve Journal Entries
- Post Journal Entries
- Reverse posted Journal Entries
- Prevent invalid status transitions
- Control action availability dynamically
- Handle draft documents using RAP Draft
- Automatically generate Journal Entry IDs and Item Numbers

The application follows a controlled business process:

**Draft → Submitted → Approved → Posted → Reversed**



# 🏗️ Technology Stack

| Technology | Usage |
|||
| SAP ABAP | Backend development |
| ABAP RAP | Business object implementation |
| CDS View Entities | Data modeling |
| Behavior Definition | Business logic definition |
| Behavior Pool | RAP implementation |
| EML | Entity manipulation and transactional operations |
| SAP Fiori | User interface |
| OData | Service exposure |
| Draft | Draft document handling |
| SAP HANA | Persistence |



# 🧩 Application Architecture

The application follows the RAP architecture:
SAP Fiori UI
     |
     ↓
OData Service
     |
     ↓
Projection CDS View
     |
     ↓
Projection Behavior
     |
     ↓
Interface CDS View
     |
     ↓
Interface Behavior Definition
     |
     ↓
Behavior Pool
     |
     ↓
Persistent Database Tables


# 📊 Data Model

The application contains two main entities.

## Journal Entry Header

Persistent table:
ZFI_JE_HEADER


Draft table:
ZFI_JE_HEADER_D


The header contains information such as:

* Journal Entry ID
* Company Code
* Fiscal Year
* Document Date
* Posting Date
* Document Type
* Currency
* Total Amount
* Status
* Created By
* Created At
* Changed By
* Changed At
* Reversal Journal Entry ID



## Journal Entry Item

Persistent table:
ZFI_JE_ITEM


Draft table:
ZFI_JE_ITEM_D


The line item contains:

* Journal Entry ID
* Item Number
* G/L Account
* Cost Center
* Profit Center
* Debit/Credit Indicator
* Amount
* Currency
* Item Text



# 🔗 Entity Relationship

The Journal Entry Header has a composition relationship with Journal Entry Items.
ZI_FI_JE_HEADER
       |
       | 1
       |
       | composition
       |
       | 0..*
       ↓
ZI_FI_JE_ITEM

The Journal Entry Header acts as the composition root.



# 🗂️ CDS Data Model

## Header CDS View
ZI_FI_JE_HEADER

The root CDS view is based on:
ZFI_JE_HEADER

and exposes the Journal Entry Header as the RAP business object root entity.

The header contains a composition to:
ZI_FI_JE_ITEM



## Item CDS View
ZI_FI_JE_ITEM


The item CDS view represents the individual Journal Entry line items.



# ⚙️ RAP Behavior

The application uses a **managed RAP implementation with draft support**.

The Header behavior contains:

* Create
* Update
* Delete
* Draft handling
* Validations
* Determinations
* Actions
* Instance authorization
* Instance feature control
* Early numbering
* Side effects



# 📝 Draft Handling

The application uses RAP Draft functionality.

Users can create and modify a Journal Entry as a draft before it is activated.

Draft functionality includes:

* Edit
* Activate
* Discard
* Resume
* Prepare

The application prevents business-process actions from being executed while the Journal Entry is still a draft.

The Submit, Approve, Post, and Reverse actions are controlled through instance feature control.



# 🔢 Early Numbering

The application implements early numbering for Journal Entries.

The next Journal Entry ID is determined using the highest existing ID from:
ZFI_JE_HEADER


and:
ZFI_JE_HEADER_D


The next available number is then assigned to the newly created Journal Entry.

This ensures that IDs are considered across both active and draft records.

Journal Entry items are also numbered automatically within their respective Journal Entry.



# 🔄 Journal Entry Status Flow

The application implements a controlled status flow.

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
Reversal Journal Entry


Each action is allowed only when the Journal Entry is in the appropriate status.



# 🚦 Submit

A Journal Entry can be submitted only when its status is:
D - Draft


After successful submission:

D → S


The Submit action becomes unavailable and Approve becomes available.



# ✅ Approve

A Journal Entry can be approved only when its status is:


S - Submitted


After successful approval:


S → A


The Approve action becomes unavailable and Post becomes available.



# 📌 Post

A Journal Entry can be posted only when its status is:


A - Approved


After successful posting:


A → P


The Post action becomes unavailable and Reverse becomes available.



# 🔁 Reverse

Only a posted Journal Entry can be reversed.

A reversal creates a new Journal Entry containing:

* The original header information
* Current document/posting date
* The original document type
* The original currency
* Reversed debit/credit values
* Original amounts
* Original G/L accounts
* Original cost/profit center information
* Reversal reference to the original Journal Entry

The reversal Journal Entry stores the original Journal Entry ID in:


REVERSAL_OF_JEID




# 🛑 Reversal Protection

The application prevents:

* Reversing a non-posted Journal Entry
* Reversing a reversal Journal Entry
* Reversing the same Journal Entry more than once

The Reverse action is dynamically disabled when a reversal already exists.



# 🧮 Total Amount Determination

The Journal Entry header contains a Total Amount field.

The total is calculated from the amounts maintained in the Journal Entry line items.


Journal Entry Items
        ↓
Item Amounts
        ↓
Header Total Amount


The determination is implemented using RAP EML and reads the related Journal Entry items before updating the header total amount.



# 📅 Fiscal Year Determination

The Fiscal Year is automatically determined from the Posting Date.

For example:


Posting Date: 2026-08-31
        ↓
Fiscal Year: 2026


This is implemented as a RAP determination.



# 👤 Created By Determination

The Created By field is automatically populated using the current SAP user.


SY-UNAME
    ↓
Created By


This avoids requiring the user to manually enter the creator information.



# ✔️ Validations

The application implements RAP validations to ensure that invalid Journal Entries cannot be saved.

## Header Validation

The following validations are performed:

### Document Date

Document Date is mandatory.


Document Date cannot be initial.


Document Date cannot be in the future.



### Posting Date

Posting Date is mandatory.



### Document Type

Document Type is mandatory.



## Line Item Validation

G/L Account is mandatory for every Journal Entry item.



## Minimum Line Items

A Journal Entry must contain at least two line items.


Minimum line items = 2




## Debit/Credit Validation

The total Debit amount must equal the total Credit amount.


Total Debit = Total Credit


If the amounts do not match, the Journal Entry cannot proceed.



## Amount Validation

Line item amount must be greater than zero.


Amount > 0




# 🔐 Authorization

The application uses RAP authorization concepts including:

* Instance authorization
* Global authorization
* Authorization based on document status
* Authorization based on the document creator

For example, draft update/submit operations can be restricted based on:


Created By
+
Current User
+
Document Status




# 🎛️ Dynamic Feature Control

The application dynamically controls whether actions are enabled or disabled.

| Status    | Submit   | Approve  | Post     | Reverse  |
|  | -- | -- | -- | -- |
| Draft     | Disabled | Disabled | Disabled | Disabled |
| Submitted | Disabled | Enabled  | Disabled | Disabled |
| Approved  | Disabled | Disabled | Enabled  | Disabled |
| Posted    | Disabled | Disabled | Disabled | Enabled  |
| Reversal  | Disabled | Disabled | Disabled | Disabled |

Draft records are prevented from executing the business-process actions.

The Reverse action is additionally controlled based on whether the Journal Entry has already been reversed.



# 🔄 Side Effects

RAP side effects are implemented for the status and reversal-related actions.

The side effects ensure that changes to the business object are reflected in the UI, including:

* Status changes
* Action permissions
* Submit availability
* Approve availability
* Post availability
* Reverse availability
* Reversal information

This allows the UI to update action availability without requiring unnecessary manual refreshes.



# 🧠 EML Usage

Entity Manipulation Language (EML) is used extensively in the behavior implementation.

Examples include:

abap
READ ENTITIES


for reading RAP entities and:

abap
MODIFY ENTITIES


for modifying RAP entities.

EML is used for:

* Reading Header data
* Reading associated Item data
* Updating status
* Creating reversal Journal Entries
* Creating reversal line items
* Updating calculated values



# 📁 Main RAP Objects

The project contains the following main RAP objects.

## CDS Views


ZI_FI_JE_HEADER
ZI_FI_JE_ITEM


Projection views:


ZC_FI_JE_HEADER
ZC_FI_JE_ITEM




## Behavior Definitions

Interface behavior:


ZI_FI_JE_HEADER
ZI_FI_JE_ITEM


Projection behavior:


ZC_FI_JE_HEADER
ZC_FI_JE_ITEM




## Behavior Pool

Main behavior pool:


ZBP_I_FI_JE_HEADER


The behavior pool contains the implementation of:

* Validations
* Determinations
* Actions
* Feature control
* Authorization
* Early numbering
* Reversal processing



# 🖥️ Fiori Application

The RAP business object is exposed through an OData service and consumed by a SAP Fiori application.

The application provides a user interface for:

* Creating Journal Entries
* Entering Header information
* Adding line items
* Saving drafts
* Submitting documents
* Approving documents
* Posting documents
* Reversing posted documents

The UI dynamically reflects the current Journal Entry status and available actions.



# 🧪 Business Process Example

A typical Journal Entry processing scenario is:

### Step 1 — Create

User creates a new Journal Entry.


Status = Draft


A Journal Entry ID is automatically assigned.



### Step 2 — Add Items

User enters the Journal Entry line items.

Example:


Item 1 → Debit  10,000
Item 2 → Credit 10,000


The Journal Entry is balanced.



### Step 3 — Submit

User submits the Journal Entry.


Draft → Submitted




### Step 4 — Approve

The submitted Journal Entry is approved.


Submitted → Approved




### Step 5 — Post

The approved Journal Entry is posted.


Approved → Posted




### Step 6 — Reverse

The posted Journal Entry can be reversed.

A new reversal Journal Entry is generated with opposite Debit/Credit indicators.


Original JE
     ↓
Reverse
     ↓
New Reversal JE




# 🎯 Key RAP Concepts Demonstrated

This project demonstrates practical implementation of:

* Managed RAP
* Draft-enabled RAP
* CDS View Entities
* Root View Entity
* Composition
* Projection Views
* Behavior Definitions
* Behavior Pool
* EML
* Determinations
* Validations
* Actions
* Instance Feature Control
* Instance Authorization
* Early Numbering
* Side Effects
* Draft Actions
* Transactional Buffer
* Parent/Child Entity Processing
* RAP Error Handling
* RAP Message Handling



# 💡 Key Technical Highlights

Some of the important implementation aspects of this project are:

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




### 2. Automatic Reversal Creation

The Reverse action creates an independent reversal Journal Entry instead of simply changing the status of the original document.



### 3. Reversal Reference

The reversal document maintains a reference to the original document using:


REVERSAL_OF_JEID




### 4. Duplicate Reversal Prevention

The system checks whether the original Journal Entry already has a reversal before allowing another reversal.



### 5. Draft-Aware Numbering

Journal Entry numbering considers both active and draft records.



### 6. Dynamic UI Actions

Action availability is determined from the current document status.

This prevents users from performing invalid operations through the UI.



# 📚 Learning Outcomes

This project was developed to gain practical experience in SAP RAP and demonstrates how a business process can be implemented using modern ABAP development techniques.

The project provides hands-on implementation experience with:

* RAP Business Objects
* Draft Handling
* Transactional Processing
* EML
* CDS Modeling
* Business Validations
* Determinations
* Actions
* Authorizations
* Feature Control
* Side Effects
* Fiori Integration



# 🚀 Future Enhancements

Possible future enhancements include:

* Integration with SAP FI posting APIs
* Company Code and G/L Account validations against standard SAP master data
* Posting to an actual SAP accounting document
* Additional approval levels
* Attachment functionality
* Search and filter enhancements
* Application logging
* Error monitoring
* Role-based authorization refinement
* Audit trail for status changes
* Additional reporting capabilities



# 👩‍💻 Project Type

**SAP RAP / ABAP Cloud / SAP Fiori Business Application**

This project is intended as a practical demonstration of implementing a transactional business application using the SAP ABAP RESTful Application Programming Model.

