UPDATE [TaxywinXXX].[dbo].[User]
  SET [vbPassword]=NULL,
  [vbSalt]=NULL,
  [vbPasswordHash]=NULL,
  [nSalt]=4076
  WHERE [UserId]='AdminTaxy' 
