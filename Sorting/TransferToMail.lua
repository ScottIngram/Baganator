function Baganator.Sorting.TransferToMail(toMove)
  SetSendMailShowing(true)

  local missing = false
  local attachmentIndex = 1

  -- Move items if possible
  for _, item in ipairs(toMove) do
    while select(2, GetSendMailItem(attachmentIndex)) do
      attachmentIndex = attachmentIndex + 1
    end
    if attachmentIndex > ATTACHMENTS_MAX_SEND then
      break
    end
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if not C_Item.DoesItemExist(location) then
      missing = true
    elseif not C_Item.IsLocked(location) then
      C_Container.UseContainerItem(item.bagID, item.slotID)
    end
  end

  if missing then
    return Baganator.Constants.SortStatus.WaitingMove
  else
    return Baganator.Constants.SortStatus.Complete
  end
end