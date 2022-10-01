# scripting
This repo will be used to hold all historical, current and future scripts built by the Tax App Operations Team. Scripts could be in the form of batch, PowerShell &amp; MS SQL.  However there is obviously scope to build on this as we encounter new technologies and scripts we may use for these.
*IMPORTANT* - NEVER hardcode any secret values into scripts you put here, this includes any form of client data. Variables should always be used where this information is required and can be fed to the script at runtime.
I'll send back for review, any pull requests for master that do not adhere to at least basic scripting principles such as documenting your code with comments, adding a header portion to indicate: Author, Date Written, SNow Ticket Number(if requested here) and a high level description of what the scrip os for, an explanation of any variables that need to be passed in, as well as a brief example.  I'd also request you not any aliases in place of full commands, these only come back to bite you at a later date.  Please also try to not mix languages, for exmple, if you need to run a SQL query from a PowerShell script you are building, build the query into a SQL script, this allows others in the future to simply use this instead of repeating work.
Hoping over time this can build to a valuable resource the team can use to pull useful packages of scripts for many purposes.
This will also allow us to track chnages to scripts over time for proper source control of these.
