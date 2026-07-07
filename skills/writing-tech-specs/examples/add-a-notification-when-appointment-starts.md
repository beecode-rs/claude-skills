# [tech-spec] Add a notification when appointment starts

* 1 [Model](#Model)
  * 1.1 [node-core](#node-core)
    * 1.1.1 [Appointment](#Appointment)
* 2 [Flow](#Flow)
  * 2.1 [Backend](#Backend)
    * 2.1.1 [node-core](#node-core.1)
    * 2.1.2 [node-message](#node-message)
* 3 [Happy path](#Happy-path)

# Model

## node-core

### Appointment

advisorFirstJoinedAt → advisorFirstJoinedAt

```puml
@startuml

class Appointment {
  patientFirstJoinedAt?: number 
  advisorFirstJoinedAt?: number 
} 

@enduml
```

# Flow

## Backend

### node-core

Patient is fetching a token for video access

```puml
@startuml
actor patient
participant "node-core" as nodeCore
database "core-db" as coreDb

patient -> nodeCore: GET /appointments/:id/join-video
activate nodeCore
nodeCore -> nodeCore: Generate token for video call access
nodeCore --> coreDb: Update appointment.patientFirstJoinedAt\n with the current time if not set
nodeCore -> patient: Return token
deactivate nodeCore
@enduml
```

Advisor is fetching a token for video access. (startNotifiedAt → advisorFirstJoinedAt)

```puml
@startuml
actor advisor
participant "node-core" as nodeCore
database "core-db" as coreDb
control sns

advisor -> nodeCore: GET /appointments/:id/join-video
activate nodeCore
nodeCore -> nodeCore: Generate token for video call access
nodeCore --> coreDb: Check if appointment.patientFirstJoinedAt\nappointment.advisorFirstJoinedAt or has value
alt patientFirstJoinedAt or advisorFirstJoinedAt exists case
  nodeCore --> nodeCore: do nothing
else patientFirstJoinedAt and advisorFirstJoinedAt does not exist case
  nodeCore --> coreDb: Update appointment.advisorFirstJoinedAt\n with the current time if not set
  nodeCore -> sns: Trigger sns message\n that appointment started
end
nodeCore -> advisor: Return token
deactivate nodeCore
@enduml
```

### node-message

Generate a chat message for the patient to remind him that the appointment is starting.

```puml
@startuml
control "message-q" as messageQ
participant "node-message" as nodeMessage
database "message-db" as messageDb

messageQ -> nodeMessage: receive message "Appointment started"
nodeMessage -> messageDb: generate chat message for\n patient that belongs to appointment
@enduml
```

# Happy path

If an Advisor joins the call before the patient, the patient should receive a chat message that the appointment is about to start or already started (depending on the moment when the advisor joins the call)

If the patient joins the call before the Advisor, no message about starting the appointment is sent.