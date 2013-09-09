-- AssignCheck.lua
--
--
------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- If the number of SVD assignments gets to the assignment trigger level set on the SVD form
-- an email will be sent to the Service Desk and assigned SVD manager.
--------------------------------------------------------------------------------------
if ((ASSIGN_TOTAL) >= 3) and (EVENT_TYPE == "i") and (ASSIGN_CHANGED_SVD) then

	recipient_name = { (strServiceDeskName or ""), (ASS_SVD_N or "") }
	recipient_email = { (strServiceDeskEmail or ""), (ASS_SVD_EMAIL or "") }

	email_subject = strEmailSubjectPrefix .. "$EVENT_TYPE_N #$EVENT_TYPE_U$EVENT_REF has been assigned to " .. ASSIGN_TOTAL .. " different Service Departments"
	template = "assign_count_check.html"
	SMEXT_send_email(recipient_name, recipient_email, email_subject, template)
	
	LOGGER:info("Event: " .. EVENT_TYPE_U .. EVENT_REF .. " assign count violation.   Assign count: " ..  ASSIGN_TOTAL)

end