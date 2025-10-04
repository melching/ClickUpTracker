# Troubleshooting Guide

Solutions to common issues with ClickUp Time Tracker.

## Quick Diagnostics

### Run with Logging

To see detailed output for debugging:

```bash
cd /path/to/ClickUpTracker
./run-with-logs.sh
```

Or directly:
```bash
./ClickUpTracker.app/Contents/MacOS/ClickUpTracker
```

This shows all API calls, responses, and errors in the terminal.

## Common Issues

### App Won't Start

**Symptoms:**
- App doesn't appear in menu bar
- No response when double-clicking
- Immediate crash

**Solutions:**

1. **Run from terminal to see error:**
   ```bash
   ./ClickUpTracker.app/Contents/MacOS/ClickUpTracker
   ```

2. **Check macOS version:**
   - Requires macOS 14.0 (Sonoma) or later
   - Check: Apple Menu → About This Mac

3. **Rebuild app bundle:**
   ```bash
   rm -rf ClickUpTracker.app
   ./create-app-bundle.sh
   open ClickUpTracker.app
   ```

4. **Check permissions:**
   - System Settings → Privacy & Security
   - Allow app if blocked

---

### Can't Find Tasks

**Symptoms:**
- Search returns no results
- "No tasks found" message
- Empty task list

**Solutions:**

1. **Verify credentials:**
   - Settings → Check API Key
   - Settings → Check Team ID
   - Make sure Team ID is correct workspace

2. **Refresh cache:**
   - Click 🔄 button in task selector
   - Wait for "X tasks cached" to appear
   - First load may take 30-60 seconds

3. **Check task access:**
   - Can you see the task in ClickUp web?
   - Are you a member of the workspace?
   - Does your API key have task access?

4. **Clear and reload cache:**
   - Settings → Clear Cache
   - Close and reopen task selector
   - Click 🔄 to reload

5. **Check API key permissions:**
   - Regenerate API key in ClickUp
   - Ensure "View tasks" permission
   - Update in app settings

---

### Time Entry Failed

**Symptoms:**
- "Failed to submit time entry" error
- Tracking stops but no time in ClickUp
- Error message with code

**Solutions:**

1. **Check internet connection:**
   - Verify you're online
   - Try accessing clickup.com

2. **Verify API permissions:**
   - API key must have "Time Tracking" permission
   - Regenerate key if unsure
   - Update in Settings

3. **Confirm task still exists:**
   - Task might have been deleted
   - Try opening task in ClickUp first (↗ button)
   - Search for different task

4. **Check Team ID:**
   - Must match workspace where task lives
   - Get from ClickUp URL
   - Update in Settings if wrong

5. **Review logs:**
   ```bash
   ./run-with-logs.sh
   # Track time, try to submit
   # Look for error messages
   ```

**Common Error Codes:**
- **401** - Invalid API key
- **403** - No permission for this action
- **404** - Task or team not found
- **429** - Rate limit exceeded (wait a bit)
- **500** - ClickUp server error (try again later)

---

### Billable Flag Not Working

**Symptoms:**
- Toggle billable ON but shows non-billable in ClickUp
- Billable checkbox unchecked after submission
- Billable status not matching what you selected

**Solutions:**

1. **Check workspace settings:**
   - ClickUp Workspace Settings
   - Time Tracking → Enable Billable Rates
   - Must be enabled workspace-wide

2. **Verify user permissions:**
   - Your role must allow billable time
   - Ask workspace admin if unsure
   - Owner/Admin roles typically can

3. **Confirm using new API:**
   - Check logs show `/team/{id}/time_entries`
   - NOT `/task/{id}/time`
   - Rebuild if using old version

4. **Test with logs:**
   ```bash
   ./run-with-logs.sh
   ```
   Look for:
   ```
   📤 API: Request body: {...,"billable":true}
   📥 API: Response: {...,"billable":true}
   ```

5. **Check ClickUp display:**
   - Time entry details in ClickUp
   - "Billable" checkbox location
   - May be in edit mode only

---

### Description Not Appearing

**Symptoms:**
- Entered description but it's not in ClickUp
- Description field blank in time entry
- Text disappears after submission

**Solutions:**

1. **Verify you entered text:**
   - Description field in task selector
   - Not just whitespace
   - At least 1 character

2. **Check ClickUp display:**
   - Click time entry in ClickUp
   - Look for "Description" or "Notes" field
   - May be in different location than expected

3. **Confirm new API usage:**
   - Logs should show `description` field
   - Using `/team/{id}/time_entries` endpoint
   - Rebuild if necessary

4. **Test with simple text:**
   - Enter just "test"
   - Submit time entry
   - Check if "test" appears

5. **Review request body:**
   ```bash
   ./run-with-logs.sh
   ```
   Should see:
   ```
   📤 API: Request body: {...,"description":"your text",...}
   ```

---

### Search is Slow

**Symptoms:**
- Long delay when typing
- Spinner shows for many seconds
- UI freezes during search

**Solutions:**

1. **Wait for initial cache load:**
   - First search loads all tasks
   - Can take 30-60 seconds
   - Only happens once per session

2. **Check cache status:**
   - Look for "X tasks cached"
   - Should show task count
   - Means cache is ready

3. **Enable auto-refresh:**
   - Settings → Auto-refresh cache
   - Loads tasks in background
   - Ready when you need to search

4. **Reduce workspace size:**
   - Many tasks = larger cache
   - Archive completed tasks in ClickUp
   - Keep workspace organized

5. **Check system resources:**
   - Activity Monitor → Check CPU/Memory
   - Close other heavy apps
   - Restart Mac if sluggish

---

### Notifications Not Working

**Symptoms:**
- No reminders while tracking
- Permission denied errors
- Silent tracking sessions

**Solutions:**

1. **Grant notification permission:**
   - System Settings → Notifications
   - Find ClickUpTracker
   - Allow notifications

2. **Check notification settings:**
   - App Settings → Notifications
   - Must be set to something other than "Never"
   - Try "Every 30 minutes"

3. **Enable Do Not Disturb exception:**
   - System Settings → Focus
   - Allow ClickUpTracker notifications
   - Even during Focus modes

4. **Restart notification service:**
   ```bash
   killall NotificationCenter
   ```
   Then reopen app

---

### Cache Out of Date

**Symptoms:**
- Deleted tasks still appear
- New tasks don't show up
- Task information is old

**Solutions:**

1. **Manual refresh:**
   - Click 🔄 in task selector
   - Wait for completion
   - Check "Updated: just now"

2. **Enable auto-refresh:**
   - Settings → Auto-refresh cache ON
   - Choose appropriate interval
   - 15 minutes is good default

3. **Clear cache:**
   - Settings → Clear Cache
   - Close task selector
   - Reopen and wait for reload

4. **Check last update time:**
   - Shows in task selector
   - "Updated: X minutes ago"
   - Click 🔄 if too old

---

### Time Validation Issues

**Symptoms:**
- Can't submit time entry
- Red duration text
- End time keeps changing

**Solutions:**

1. **Ensure end after start:**
   - End time must be later than start
   - Check AM/PM
   - Check date as well as time

2. **Don't fight auto-correction:**
   - App adjusts times to stay valid
   - Adjust start first, then end
   - Or vice versa

3. **Use reasonable times:**
   - Within last few days usually
   - Not in the future
   - Matches when you actually worked

4. **Check duration:**
   - Must be > 0
   - Shows in black if valid
   - Shows in red if invalid

---

### Can't Open Task in ClickUp

**Symptoms:**
- ↗ button doesn't work
- Browser opens to wrong page
- 404 error in browser

**Solutions:**

1. **Check task ID:**
   - Logs show task ID being used
   - Should match ClickUp URL format
   - Example: `86c5t46vm`

2. **Verify task exists:**
   - Might have been deleted
   - Check in ClickUp directly
   - Refresh cache if missing

3. **Check default browser:**
   - System Settings → Desktop & Dock
   - Default web browser
   - Make sure it's set

4. **Try task URL manually:**
   ```
   https://app.clickup.com/t/{task_id}
   ```
   Replace {task_id} with actual ID

---

## Error Messages

### "Invalid API Key"

**Meaning:** API key is missing or wrong
**Fix:**
1. Get new API key from ClickUp
2. Settings → Enter API Key
3. Click Done

### "Invalid Team ID"

**Meaning:** Team ID is missing or wrong
**Fix:**
1. Get Team ID from ClickUp URL
2. Settings → Enter Team ID
3. Click Done

### "Network Error"

**Meaning:** Can't reach ClickUp servers
**Fix:**
1. Check internet connection
2. Try opening clickup.com
3. Check firewall/VPN
4. Try again in a moment

### "HTTP 401 Unauthorized"

**Meaning:** API key is invalid or expired
**Fix:**
1. Regenerate API key in ClickUp
2. Update in app Settings
3. Ensure key has right permissions

### "HTTP 403 Forbidden"

**Meaning:** No permission for this action
**Fix:**
1. Check API key permissions
2. Verify task access in ClickUp
3. Ask workspace admin for help

### "HTTP 404 Not Found"

**Meaning:** Task or team doesn't exist
**Fix:**
1. Verify Team ID is correct
2. Check task exists in ClickUp
3. Refresh cache
4. Try different task

### "HTTP 429 Too Many Requests"

**Meaning:** Hit ClickUp API rate limit
**Fix:**
1. Wait 1 minute
2. Try again
3. Reduce auto-refresh frequency

### "HTTP 500 Server Error"

**Meaning:** ClickUp server issue
**Fix:**
1. Not your fault
2. Wait a few minutes
3. Try again
4. Check ClickUp status page

---

## Getting Debug Information

### Collect Logs

```bash
# Run with logging
./run-with-logs.sh > debug.log 2>&1

# Or save output
./ClickUpTracker.app/Contents/MacOS/ClickUpTracker 2>&1 | tee debug.log
```

### What to Include in Bug Reports

1. **macOS version:** System Settings → About
2. **App version:** Check README changelog
3. **Error message:** Full text from dialog or logs
4. **Steps to reproduce:** What you did before error
5. **Logs:** Relevant lines from terminal output
6. **Screenshots:** If UI issue

### Sensitive Information

**Remove before sharing:**
- API keys (replace with `***`)
- Team IDs (replace with `123`)
- Task IDs (replace with `abc`)
- Personal information in task names

### Log Examples

**Good Log (shows issue):**
```
📤 API: Request body: {"tid":"abc","billable":true,...}
📥 API: Response status: 200
📥 API: Response body: {"billable":false}
❌ Issue: Sent billable=true but received false
```

**Sanitized for sharing:**
```
📤 API: Request body: {"tid":"***","billable":true,...}
📥 API: Response status: 200  
📥 API: Response body: {"billable":false}
❌ Issue: Sent billable=true but received false
```

---

## Advanced Troubleshooting

### Reset Everything

```bash
# 1. Quit app completely
killall ClickUpTracker

# 2. Remove cache
rm -rf ~/Library/Application\ Support/ClickUpTracker/

# 3. Remove preferences (CAUTION: loses settings)
defaults delete com.yourcompany.ClickUpTracker

# 4. Rebuild app
cd /path/to/ClickUpTracker
rm -rf .build ClickUpTracker.app
swift build -c release
./create-app-bundle.sh

# 5. Start fresh
open ClickUpTracker.app
```

### Check File Permissions

```bash
# Cache directory
ls -la ~/Library/Application\ Support/ClickUpTracker/

# Should be writable by you
# If not, fix with:
chmod -R u+w ~/Library/Application\ Support/ClickUpTracker/
```

### Verify API Manually

```bash
# Test API key
curl -H "Authorization: YOUR_API_KEY" \
  https://api.clickup.com/api/v2/team

# Test task fetch
curl -H "Authorization: YOUR_API_KEY" \
  https://api.clickup.com/api/v2/team/TEAM_ID/task?page=0
```

---

## Still Having Issues?

1. **Check GitHub Issues:** See if others have same problem
2. **Create New Issue:** With logs and details
3. **Check ClickUp Status:** api.clickup.com status page
4. **Contact Support:** Through GitHub discussions

---

For more help, see:
- [User Guide](USER_GUIDE.md) - Complete usage instructions
- [Developer Guide](DEVELOPER_GUIDE.md) - Technical details
- [API Reference](API_REFERENCE.md) - API integration info
