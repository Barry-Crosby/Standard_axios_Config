dofile("\\_Axios_Config\\Common\\Baseconfig.lua")

mailboxReader {
	-- The log level can be DEBUG, INFO, WARN, ERROR, FATAL in decreasing verbosity (default is INFO).
	loglevel = INFO,
	nteventlog = ERROR,

	-- Log serious errors (connection failures and assyst new event or update event failures) to email.
	emaillog = {
		server = strSMTPServer,
		sender = "assyst MailboxReader Admin@anycorp.com",
		recipients = "Administrator@anycorp.com",
		header = {
			from = "assyst Mailbox Reader <Administrator@anycorp.com>",
			to = "Administrator <Administrator@anycorp.com>",
			subject = "assyst Mailbox Reader %level",
		},
		body = "assyst Mailbox Reader %level (%date):\n\n%message\n",
	},

	-- Uncomment the following line if the Mailbox Reader should stop on a serious error.
	-- stop_on_error = true,

	-- The number of seconds to sleep, when no new messages have been found (default is 60).
	sleep_seconds = 60,
}


assyst {
	dbtype = strassystDBType,
	interface = strDBInterface,

	server = strassystDBServer,
	name = strassystDBName,
	user = strassystUserMBR,
	password = strassystPWMBR,
	
	acli = straclipath,
}


-- First Mailbox (POP3).
mailbox {
	server = strPOPServer,
	protocol = "pop",
	user = strassystUserMBR,
	password = strassystPWMBR,

	-- Use these values when logging the incidents in assyst.
	EVENTIMPPROFILE = "MBOX READER",
	ACTIONIMPPROFILE = "GENERAL ACTION",
	AFFECTED = "ZZ MAILBOX READER",  -- Used if no contact user with "From:" email addr is found.
	ACTIONEDBY = strassystUserMBR,  -- Add email updates using this assyst User.
	UPDATE_ACTION = "MBR EMAIL UPD",  -- Add email updates using this Action Type.
	ATTACHMENT_ACTION = "MBR ATTACH",  -- Add email attachments using this Action Type.

	ignore_mail_date = true, -- Use date and time of Mailbox Reader instead of the email date
	any_mail_user = true, -- Allow multi user matches from email addreses

--	forward = {  -- Forward copies of processed emails.
--		server = "smtp.server",
--		to = "processed@anycorp.local",
--	},

	reference_pattern = {  -- The $REF marks the assyst reference number.
		"(ref. $REF)",
		"#$REF",
	},

	update_pattern = {
		["Comment"] = "MBR EMAIL UPD",
		["Assessment Complete"] = {
			UPDATE_ACTION = "MBR EMAIL UPD",  -- Add email updates using this Action Type.
			ACTIONIMPPROFILE = "MBOX READER",
			description_template = "template/default.txt",
		},
		["Denied"] = {
			UPDATE_ACTION = "NOT AUTHORIZED",  -- Add email updates using this Action Type.
			ACTIONIMPPROFILE = "MBOX READER",
			description_template = "template/default.txt",
		},
		["Approved"] = {
			UPDATE_ACTION = "AUTHORIZED",  -- Add email updates using this Action Type.
			ACTIONIMPPROFILE = "MBOX READER",
			description_template = "template/default.txt",
		},
		["Reopen request"] = {
			open = {
				UPDATE_ACTION = "ADD INFO",  
				ACTIONIMPPROFILE = "MBOX READER",
				description_template = "template/default.txt",
			},
			pending = {
				UPDATE_ACTION = "MBR REOPEN REQ",  
				ACTIONIMPPROFILE = "MBOX READER",
				description_template = "template/default.txt",
			},
			closed = {
				UPDATE_ACTION = "MBR REOPEN REQ",  
				ACTIONIMPPROFILE = "MBOX READER",
				description_template = "template/default.txt",
			},
		},
	},

	-- Only process attachments less than 500K bytes, and
	-- exclude all audio and video attachments, as well as Adobe Flash apps, and
	-- don't process any "logo.gif" files.
	attachment = {
		max_size_bytes = 500000,
		mime_type = {
			exclude = { "AUDIO", "VIDEO", "APPLICATION/X-SHOCKWAVE-FLASH", },
		},
		filename = {
			exclude = { "logo.gif", "image001.gif", },
		},
	},
}


-- As many mailbox definitions as necessary may be added here ...

