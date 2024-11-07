use [TaxywinCOE]
go

select 

gu.UserId,
gu.GroupId,
u.strFullName,
u.strUserRoleName


from groupuser gu

left join [User] u on u.userid = gu.UserId

where u.bActive = '1'

order by gu.UserId
