# [tech-spec] - Claim item locking

* 1 [Model](#Model)
  * 1.1 [node-core](#node-core)
* 2 [Flow](#Flow)
  * 2.1 [Backend](#Backend)
    * 2.1.1 [node-core: Claim item correct/incorrect flow](#node-core%3A-Claim-item-correct%2Fincorrect-flow)
    * 2.1.2 [node-core: Claim correct/incorrect flow](#node-core%3A-Claim-correct%2Fincorrect-flow)
* 3 [Happy path](#Happy-path)

# Model

## node-core

ReimbursementClaimItem

```puml
@startuml
class ReimbursementClaimItem {
  ...
  incorrectAt?: number[timestamp]
  incorrectById?: string[uuid]
  incorrectReason?: string
  correctAt?: number[timestamp]
  correctById?: string[uuid]
}
@enduml
```

# Flow

## Backend

### node-core: Claim item correct/incorrect flow

```puml
@startuml
(*) --> "Claim is Submitted for Review" #lightblue
if "Is Claim Item correct?" then
  --> [Yes] "Update correct fields"
  --> (*)
else
  --> [No] "Update incorrect fields, remove correct fields"
  --> "Claim is Returned to Patient" #lightblue
  --> "Patient updates the Claim Item"
  --> "Claim is Submitted for Review" #lightblue
@enduml
```

### node-core: Claim correct/incorrect flow

```puml
@startuml
(*) --> "Claim is Submitted for Review" #lightblue
--> "Advisor checks all Claim Items (that are not marked as correct)"
if "All Claim Items are marked as correct ?" then
  --> [Yes] "Advisor can mark Claim as Approved" #lightblue
  --> (*)
else
  if "All Claim Items are marked as correct or incorrect ?" then
    --> [No] "Advisor checks all Claim Items (that are not marked as correct)"
  else
    --> [Yes] "Advisor can mark Claim as Returned to Patient" #lightblue
    --> "Patient can correct Claim Items"
    --> "Claim is Submitted for Review" #lightblue
@enduml
```

# Happy path

TODO: Add details here