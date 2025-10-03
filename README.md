# ClickUpTracker
A simple app acting as a different interface for time tracking with ClickUp. Mostly coded using LLMs as a hobby project.

Idea:
This app is basically just an icon in the menu bar and some options when you click it. The icon shows if you are currently tracking time or not.

On click the following options are revealed:
- (readonly) Current tracked time
- Start / Pause tracking time
- Stop tracking time
  - On stop the user is asked to select a task from ClickUp to which the tracked time should be assigned.
  - Instead of tracking time automatically, it should only prefill the time tracked and require user confirmation.  Basically open the usual ClickUp time tracking dialog with the time already filled in where the user can still edit things and add comments.
- Settings
  - ClickUp API Key
  - Team ID
  - Notification freuqency (e.g. every 30min, every hour, every 2 hours)
- Quit 

If a tracking session is running, a notification is shown every X minutes (configurable in settings) to remind the user that time tracking is active. This is just to avoid forgetting to stop tracking time.

Long term I want to integrate hotkeys to start/pause/stop tracking time without having to click the icon in the menu bar. These should also be configurable in the settings.