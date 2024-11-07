--Get clientid

select clientid, firstnames, surname, refcode, * from client where surname='Turner'

select clientid, firstnames, surname, refcode, * from client where refcode='LS-60271171-ST'



--Find when & when person return unlocked


Select C.SURNAME, C.FIRSTNAMES, C.REFCODE, LFC.dtUnlocked, LFC.strUnlockedByUserID, LFC.strUnlockedComment 
From LockedFormContent 
as LFC
Join Client 
as C 
on C.CLIENTID=LFC.lClientID
Where LFC.dtUnlocked is not null
and
clientid = '125926418'
Order by LFC.dtUnlocked DESC


--Same as above for all returns of a particular year


Select c.clientid, C.SURNAME, C.FIRSTNAMES, C.REFCODE, LFC.dtUnlocked, LFC.strUnlockedByUserID, LFC.strUnlockedComment 
From LockedFormContent 
as LFC
Join Client 
as C 
on C.CLIENTID=LFC.lClientID
Where LFC.dtUnlocked is not null
and
clientid in
(
select clientid from taxform
where [year]=2018
and
clientid = '125926418'
)
Order by LFC.dtUnlocked


--Find occurences of when clients return printed for signature


select * from ReturnForSignature
where lclientid = '125926418'
and nYear = 2018

