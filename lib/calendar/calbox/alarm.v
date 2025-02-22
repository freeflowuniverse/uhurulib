module calbox

// Represents an alarm/reminder
@[heap]
pub struct Alarm {
pub mut:
	action      AlarmAction
	trigger     string     // When the alarm triggers (relative or absolute)
	repeat      ?int
	duration Duration
}

// Alarm action types
pub enum AlarmAction {
	audio   // Play a sound
	display // Display a message
	email   // Send an email
}

// String representation of alarm action
pub fn (a AlarmAction) str() string {
	return match a {
		.audio { 'AUDIO' }
		.display { 'DISPLAY' }
		.email { 'EMAIL' }
	}
}

// Parse alarm action from string
pub fn parse_alarm_action(s string) !AlarmAction {
	return match s {
		'AUDIO' { AlarmAction.audio }
		'DISPLAY' { AlarmAction.display }
		'EMAIL' { AlarmAction.email }
		else { error('Invalid alarm action: ${s}') }
	}
}
