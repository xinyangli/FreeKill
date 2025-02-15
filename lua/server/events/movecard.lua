GameEvent.functions[GameEvent.MoveCards] = function(self)
  local args = self.data
  local self = self.room
  ---@type CardsMoveStruct[]
  local cardsMoveStructs = {}
  local infoCheck = function(info)
    assert(table.contains({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge, Card.PlayerSpecial, Card.Processing, Card.DrawPile, Card.DiscardPile, Card.Void }, info.toArea))
    assert(info.toArea ~= Card.PlayerSpecial or type(info.specialName) == "string")
    assert(type(info.moveReason) == "number")
  end

  for _, cardsMoveInfo in ipairs(args) do
    if #cardsMoveInfo.ids > 0 then
      infoCheck(cardsMoveInfo)

      ---@type MoveInfo[]
      local infos = {}
      for _, id in ipairs(cardsMoveInfo.ids) do
        table.insert(infos, {
          cardId = id,
          fromArea = self:getCardArea(id),
          fromSpecialName = cardsMoveInfo.from and self:getPlayerById(cardsMoveInfo.from):getPileNameOfId(id),
        })
      end

      ---@type CardsMoveStruct
      local cardsMoveStruct = {
        moveInfo = infos,
        from = cardsMoveInfo.from,
        to = cardsMoveInfo.to,
        toArea = cardsMoveInfo.toArea,
        moveReason = cardsMoveInfo.moveReason,
        proposer = cardsMoveInfo.proposer,
        skillName = cardsMoveInfo.skillName,
        moveVisible = cardsMoveInfo.moveVisible,
        specialName = cardsMoveInfo.specialName,
        specialVisible = cardsMoveInfo.specialVisible,
      }

      table.insert(cardsMoveStructs, cardsMoveStruct)
    end
  end

  if #cardsMoveStructs < 1 then
    return false
  end

  if self.logic:trigger(fk.BeforeCardsMove, nil, cardsMoveStructs) then
    self.logic:breakEvent(false)
  end

  self:notifyMoveCards(nil, cardsMoveStructs)

  for _, data in ipairs(cardsMoveStructs) do
    if #data.moveInfo > 0 then
      infoCheck(data)

      ---@param info MoveInfo
      for _, info in ipairs(data.moveInfo) do
        local realFromArea = self:getCardArea(info.cardId)
        local playerAreas = { Player.Hand, Player.Equip, Player.Judge, Player.Special }

        if table.contains(playerAreas, realFromArea) and data.from then
          self:getPlayerById(data.from):removeCards(realFromArea, { info.cardId }, info.fromSpecialName)
        elseif realFromArea ~= Card.Unknown then
          local fromAreaIds = {}
          if realFromArea == Card.Processing then
            fromAreaIds = self.processing_area
          elseif realFromArea == Card.DrawPile then
            fromAreaIds = self.draw_pile
          elseif realFromArea == Card.DiscardPile then
            fromAreaIds = self.discard_pile
          elseif realFromArea == Card.Void then
            fromAreaIds = self.void
          end

          table.removeOne(fromAreaIds, info.cardId)
        end

        if table.contains(playerAreas, data.toArea) and data.to then
          self:getPlayerById(data.to):addCards(data.toArea, { info.cardId }, data.specialName)
        else
          local toAreaIds = {}
          if data.toArea == Card.Processing then
            toAreaIds = self.processing_area
          elseif data.toArea == Card.DrawPile then
            toAreaIds = self.draw_pile
          elseif data.toArea == Card.DiscardPile then
            toAreaIds = self.discard_pile
          elseif data.toArea == Card.Void then
            toAreaIds = self.void
          end

          table.insert(toAreaIds, toAreaIds == Card.DrawPile and 1 or #toAreaIds + 1, info.cardId)
        end
        self:setCardArea(info.cardId, data.toArea, data.to)
        Fk:filterCard(info.cardId, self:getPlayerById(data.to))

        local currentCard = Fk:getCardById(info.cardId)
        if
          data.toArea == Player.Equip and
          currentCard.type == Card.TypeEquip and
          data.to ~= nil and
          self:getPlayerById(data.to):isAlive() and
          currentCard.equip_skill
        then
          currentCard:onInstall(self, self:getPlayerById(data.to))
        elseif realFromArea == Player.Equip and currentCard.type == Card.TypeEquip and data.from ~= nil and currentCard.equip_skill then
          currentCard:onUninstall(self, self:getPlayerById(data.from))
        end
      end
    end
  end

  self.logic:trigger(fk.AfterCardsMove, nil, cardsMoveStructs)
  return true
end
