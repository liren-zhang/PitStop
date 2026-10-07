# PitStop

A bicycle maintenance assistant for amateur road cyclists.

## Problem

Amateur cyclists often miss scheduled component checks — chain wear,
brake pad thickness, battery charge — which leads to premature wear of
expensive drivetrain parts, safety risks on the road, and last-minute
trips to a bike shop.

PitStop keeps track of when each component needs attention and tells the
rider what to check, what the standard is, and what to do next.

## Domain Context

The app speaks the vocabulary of bicycle maintenance:

- **Components**: chain, cassette, chainring, brake pads, brake rotor,
  tyre, gear cable, brake cable, battery, bottom bracket, hub bearing.
- **Interval tracking**: each component has both a distance interval
  (kilometres ridden since installation) and a time interval (days since
  installation). Whichever is reached first triggers a reminder.
- **Inspection results**: `pass`, `observe`, `actionNeeded`,
  `professional` — the same four-level scale used in professional
  workshop reports.
- **Service levels**: `diySimple`, `diyWithTools`, `shopRecommended`,
  `shopRequired`. Classification depends on the rider's own assessment
  of difficulty, tools, consumables, time, and safety.

## Architecture Summary

The project follows the layered MVVM + Use Case pattern required by the
subject.

Views (SwiftUI)
↓
ViewModels (@ObservableObject)
↓
Use Cases (business rules)
↓
Repositories (protocol + Core Data)
↓
Core Data / App Group shared container


### Domain models (`Models/`)
- `Bicycle`, `BikeComponent`, `InspectionRecord`, `MaintenanceTask`
- `ServiceLevel`, `InspectionResult`, `DomainError`

### Use cases (`UseCases/`)
- `LogInspectionUseCase` — records inspection results, decides the
  interval reset
- `AssessServiceOptionUseCase` — decides whether a job is DIY or
  shop-level
- `ScheduleMaintenanceUseCase` — computes service status and schedules
  reminders

### Repositories (`Repositories/`)
- `BikeRepository` — protocol
- `CoreDataBikeRepository` — concrete implementation

## Extensions

Two iOS system extensions are integrated, each serving a real user need.

### 1. Widget (`PitStopWidget`)

**User need**: A rider checks the bike before leaving home. Instead of
opening the app, a Lock Screen / Home Screen widget shows how many
components need attention, and which bike is most urgent.

**Families**: `systemSmall` and `systemMedium`.

**Data flow**: The main app writes a lightweight JSON snapshot into the
App Group container each time the garage data changes. The widget reads
that snapshot in its `TimelineProvider`.

### 2. Notification Content Extension (`PitStopNotification`)

**User need**: When a scheduled check comes due, a plain notification is
not enough — the rider needs to see the standard and the recommended
action without opening the app. The custom notification view shows the
component name, the reading standard, and the recommended action, all
rendered in SwiftUI via a `UIHostingController`.

**Category**: `PITSTOP_MAINTENANCE_DUE`

## Database Choice

**Core Data**, not CloudKit.

Reasons:
- All data is private and local to a single device.
- The app reads and writes frequently (every check, every ride).
- Predicate queries are needed (for example, "find all components whose
  service interval has passed").
- Core Data stores its SQLite file inside the App Group container so the
  widget can access it if needed.

**Schema**: four related entities — `CDBicycle`,
`CDBikeComponent`, `CDInspectionRecord`, `CDMaintenanceTask` — linked by
`bicycleId` and `componentId`.

## App Group

Identifier: `group.com.liren.PitStop`

Shared between the main app, the widget, and the notification extension.

## Setup Instructions

1. Clone the repository: