--use PracticeManagement_TaxAid
--go

--select * from [User]
--where Username in ('UK\Kcorbett', 'UK\pboyd1', 'UK\Rmills1', 'UK\gjohnston1', 'UK\akhan46', 'UK\jmoore8', 'UK\Jmcateer', 'UK\briandonnelly2', 'UK\Agray3', 'UK\jmcinally')




--begin transaction


--update PracticeManagement_TaxAid..[User]
--set CanViewAllClients = 1
--where Username in ('UK\Kcorbett', 'UK\pboyd1', 'UK\Rmills1', 'UK\gjohnston1', 'UK\akhan46', 'UK\jmoore8', 'UK\Jmcateer', 'UK\briandonnelly2', 'UK\Agray3', 'UK\jmcinally')


--rollback 
----commit