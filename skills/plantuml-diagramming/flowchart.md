# Flowchart

A lightweight, non-UML alternative to activity diagrams for simple process flows.

## When to Use Flowchart vs Activity Diagram

| Use Flowchart When                | Use Activity Diagram When              |
| --------------------------------- | -------------------------------------- |
| Simple linear process             | Complex business workflow              |
| Quick visualization needed        | Formal UML documentation required      |
| Non-technical audience            | Need swimlanes/partitions              |
| Basic decision points only        | Advanced constructs (fork, join, etc.) |

## Syntax

### Basic Elements

```puml
@startuml
start
:Step 1;
:Step 2;
stop
@enduml
```

### Nodes

* `start` / `stop` - begin/end of flow
* `:Action Label;` - process step
* `if (Condition?) then (Yes)` - decision

### Arrows

* `->` - connection between nodes
* `-[#red,dashed]->` - styled connection
* `-->` - longer connection

### Labels

* `node Label` - labeled node
* `:Action;` - action with text

## Example

```puml
@startuml
start
:Receive Order;
if (In Stock?) then (yes)
  :Process Payment;
  :Ship Order;
else (no)
  :Backorder;
  :Notify Customer;
endif
stop
@enduml
```

## Common Patterns

### Simple Decision

```puml
@startuml
start
:Check Input;
if (Valid?) then (yes)
  :Process;
else (no)
  :Show Error;
endif
stop
@enduml
```

### Multiple Conditions

```puml
@startuml
start
if (Status?) then (pending)
  :Queue Task;
elseif (processing) then
  :Continue;
elseif (complete) then
  :Archive;
else (error)
  :Handle Error;
endif
stop
@enduml
```

### While Loop

```puml
@startuml
start
while (More Items?) is (yes)
  :Process Item;
endwhile (no)
stop
@enduml
```

### Repeat Loop

```puml
@startuml
start
repeat
  :Try Operation;
repeat while (Success?) is (no)
->yes;
:Continue;
stop
@enduml
```

### Parallel Fork

```puml
@startuml
start
fork
  :Task A;
fork again
  :Task B;
end fork
stop
@enduml
```

### Labeled Connections

```puml
@startuml
start
:Step A;
->Next Step;
:Step B;
stop
note right: Note text
@enduml
```

### Partition/Swimlane

```puml
@startuml
|User|
start
:Submit Form;
|System|
:Validate;
if (Valid?) then (yes)
  :Save;
  |User|
  :Confirm;
else (no)
  |User|
  :Fix Errors;
endif
stop
@enduml
```

## Styling

### Colors

```puml
@startuml
#Aqua:Colored Action;
#Pink:Another Action;
stop
@enduml
```

### Arrow Styles

```puml
@startuml
:A -> B;
:B -[#red,dashed]-> C;
:C -[bold]-> D;
stop
@enduml
```

### Skinparam

```puml
skinparam activity {
  BackgroundColor #LightBlue
  BorderColor #Navy
  FontSize 14
}
```
