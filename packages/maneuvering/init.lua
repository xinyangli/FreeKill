local extension = Package:new("maneuvering", Package.CardPack)

local slash = Fk:cloneCard("slash")

local thunderSlashSkill = fk.CreateActiveSkill{
  name = "thunder__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  target_filter = slash.skill.targetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from

    room:damage({
      from = room:getPlayerById(from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1 + (effect.additionalDamage or 0),
      damageType = fk.ThunderDamage,
      skillName = self.name
    })
  end
}
local thunderSlash = fk.CreateBasicCard{
  name = "thunder__slash",
  skill = thunderSlashSkill,
}

extension:addCards{
  thunderSlash:clone(Card.Club, 5),
  thunderSlash:clone(Card.Club, 6),
  thunderSlash:clone(Card.Club, 7),
  thunderSlash:clone(Card.Club, 8),
  thunderSlash:clone(Card.Spade, 4),
  thunderSlash:clone(Card.Spade, 5),
  thunderSlash:clone(Card.Spade, 6),
  thunderSlash:clone(Card.Spade, 7),
  thunderSlash:clone(Card.Spade, 8),
}

local fireSlashSkill = fk.CreateActiveSkill{
  name = "fire__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  target_filter = slash.skill.targetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from

    room:damage({
      from = room:getPlayerById(from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1 + (effect.additionalDamage or 0),
      damageType = fk.FireDamage,
      skillName = self.name
    })
  end
}
local fireSlash = fk.CreateBasicCard{
  name = "fire__slash",
  skill = fireSlashSkill,
}

extension:addCards{
  fireSlash:clone(Card.Heart, 4),
  fireSlash:clone(Card.Heart, 7),
  fireSlash:clone(Card.Heart, 10),
  fireSlash:clone(Card.Diamond, 4),
  fireSlash:clone(Card.Diamond, 5),
}

local analepticSkill = fk.CreateActiveSkill{
  name = "analeptic_skill",
  max_turn_use_time = 1,
  can_use = function(self, player)
    return player:usedCardTimes("analeptic", Player.HistoryTurn) < self:getMaxUseTime(Self, Player.HistoryTurn)
  end,
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end

    if use.extra_data and use.extra_data.analepticRecover then
      use.extraUse = true
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if effect.extra_data and effect.extra_data.analepticRecover then
      room:recover({
        who = to,
        num = 1,
        recoverBy = room:getPlayerById(effect.from),
        card = effect.card,
      })
    else
      to.drank = to.drank + 1
      room:broadcastProperty(to, "drank")
    end
  end
}

local analepticEffect = fk.CreateTriggerSkill{
  name = "analeptic_effect",
  global = true,
  priority = 0, -- game rule
  refresh_events = { fk.PreCardUse, fk.EventPhaseStart },
  can_refresh = function(self, event, target, player, data)
    if target ~= player then
      return false
    end

    if event == fk.PreCardUse then
      return data.card.trueName == "slash" and player.drank > 0
    else
      return player.phase == Player.NotActive
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      data.additionalDamage = (data.additionalDamage or 0) + player.drank
      data.extra_data = data.extra_data or {}
      data.extra_data.drankBuff = player.drank
      player.drank = 0
      player.room:broadcastProperty(player, "drank")
    else
      for _, p in ipairs(player.room:getAlivePlayers(true)) do
        if p.drank > 0 then
          p.drank = 0
          p.room:broadcastProperty(player, "drank")
        end
      end
    end
  end,
}
Fk:addSkill(analepticEffect)

local analeptic = fk.CreateBasicCard{
  name = "analeptic",
  suit = Card.Spade,
  number = 3,
  skill = analepticSkill,
}

extension:addCards({
  analeptic,
  analeptic:clone(Card.Spade, 9),
  analeptic:clone(Card.Club, 3),
  analeptic:clone(Card.Club, 9),
  analeptic:clone(Card.Diamond, 9),
})

local ironChainEffect = fk.CreateTriggerSkill{
  name = "iron_chain_effect",
  global = true,
  priority = { [fk.BeforeHpChanged] = 10, [fk.DamageFinished] = 0 }, -- game rule
  refresh_events = { fk.BeforeHpChanged, fk.DamageFinished },
  can_refresh = function(self, event, target, player, data)
    if event == fk.BeforeHpChanged then
      return target == player and data.damageEvent and data.damageEvent.damageType ~= fk.NormalDamage and player.chained
    else
      return target == player and data.beginnerOfTheDamage and not data.chain
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BeforeHpChanged then
      data.damageEvent.beginnerOfTheDamage = true
      player:setChainState(false)
    else
      local targets = table.filter(room:getAlivePlayers(), function(p)
        return p.chained
      end)
      for _, p in ipairs(targets) do
        room:sendLog{
          type = "#ChainDamage",
          from = p.id
        }
        local dmg = table.simpleClone(data)
        dmg.to = p
        dmg.chain = true
        room:damage(dmg)
      end
    end
  end,
}
Fk:addSkill(ironChainEffect)

local recast = fk.CreateActiveSkill{
  name = "recast",
  target_num = 0,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, from)
    room:drawCards(from, #effect.cards, self.name)
  end
}
Fk:addSkill(recast)

local ironChainCardSkill = fk.CreateActiveSkill{
  name = "iron_chain_skill",
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function() return true end,
  on_effect = function(self, room, cardEffectEvent)
    local to = room:getPlayerById(cardEffectEvent.to)
    to:setChainState(not to.chained)
  end,
}

local ironChain = fk.CreateTrickCard{
  name = "iron_chain",
  skill = ironChainCardSkill,
  special_skills = { "recast" },
}
extension:addCards{
  ironChain:clone(Card.Spade, 11),
  ironChain:clone(Card.Spade, 12),
  ironChain:clone(Card.Club, 10),
  ironChain:clone(Card.Club, 11),
  ironChain:clone(Card.Club, 12),
  ironChain:clone(Card.Club, 13),
}

local fireAttackSkill = fk.CreateActiveSkill{
  name = "fire_attack_skill",
  target_num = 1,
  target_filter = function(self, to_select)
    return not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_effect = function(self, room, cardEffectEvent)
    local from = room:getPlayerById(cardEffectEvent.from)
    local to = room:getPlayerById(cardEffectEvent.to)
    if to:isKongcheng() then return end

    local showCard = room:askForCard(to, 1, 1, false, self.name, false)[1]
    to:showCards(showCard)

    showCard = Fk:getCardById(showCard)
    local cards = room:askForDiscard(from, 1, 1, false, self.name, true,
                                    ".|.|" .. showCard:getSuitString())
    if #cards > 0 then
      room:damage({
        from = from,
        to = to,
        card = cardEffectEvent.card,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name
      })
    end
  end,
}
local fireAttack = fk.CreateTrickCard{
  name = "fire_attack",
  skill = fireAttackSkill,
}
extension:addCards{
  fireAttack:clone(Card.Heart, 2),
  fireAttack:clone(Card.Heart, 3),
  fireAttack:clone(Card.Diamond, 12),
}

local supplyShortageSkill = fk.CreateActiveSkill{
  name = "supply_shortage_skill",
  distance_limit = 1,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local player = Fk:currentRoom():getPlayerById(to_select)
      if Self ~= player then
        return not player:hasDelayedTrick("supply_shortage") and
          Self:distanceTo(player) <= self:getDistanceLimit(Self)
      end
    end
    return false
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local judge = {
      who = to,
      reason = "supply_shortage",
      pattern = ".|.|spade,heart,diamond",
    }
    room:judge(judge)
    local result = judge.card
    if result.suit ~= Card.Club then
      to:skip(Player.Draw)
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile
    }
  end,
}
local supplyShortage = fk.CreateDelayedTrickCard{
  name = "supply_shortage",
  skill = supplyShortageSkill,
}
extension:addCards{
  supplyShortage:clone(Card.Spade, 10),
  supplyShortage:clone(Card.Club, 4),
}

local gudingSkill = fk.CreateTriggerSkill{
  name = "#guding_blade_skill",
  attached_equip = "guding_blade",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.to:isKongcheng() and data.card and data.card.trueName == "slash" and
      not data.chain
  end,
  on_use = function(_, _, _, _, data)
    data.damage = data.damage + 1
  end,
}
Fk:addSkill(gudingSkill)
local gudingBlade = fk.CreateWeapon{
  name = "guding_blade",
  suit = Card.Spade,
  number = 1,
  attack_range = 2,
  equip_skill = gudingSkill,
}

extension:addCard(gudingBlade)

local fanSkill = fk.CreateTriggerSkill{
  name = "#fan_skill",
  attached_equip = "fan",
  events = { fk.AfterCardUseDeclared },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.name == "slash"
  end,
  on_use = function(_, _, _, _, data)
    local fireSlash = Fk:cloneCard("fire__slash")
    fireSlash.skillName = "fan"
    fireSlash:addSubcard(data.card)
    data.card = fireSlash
  end,
}
Fk:addSkill(fanSkill)
local fan = fk.CreateWeapon{
  name = "fan",
  suit = Card.Diamond,
  number = 1,
  attack_range = 4,
  equip_skill = fanSkill,
}

extension:addCard(fan)

local vineSkill = fk.CreateTriggerSkill{
  name = "#vine_skill",
  attached_equip = "vine",
  mute = true,
  frequency = Skill.Compulsory,

  events = {fk.PreCardEffect, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      return target == player and player:hasSkill(self.name) and
        data.damageType == fk.FireDamage
    end
    local effect = data ---@type CardEffectEvent
    return player.id == effect.to and player:hasSkill(self.name) and
      (effect.card.name == "slash" or effect.card.name == "savage_assault" or
      effect.card.name == "archery_attack")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:broadcastPlaySound("./packages/maneuvering/audio/card/vineburn")
      room:setEmotion(player, "./packages/maneuvering/image/anim/vineburn")
      data.damage = data.damage + 1
    else
      room:broadcastPlaySound("./packages/maneuvering/audio/card/vine")
      room:setEmotion(player, "./packages/maneuvering/image/anim/vine")
      return true
    end
  end,
}
Fk:addSkill(vineSkill)
local vine = fk.CreateArmor{
  name = "vine",
  equip_skill = vineSkill,
}
extension:addCards{
  vine:clone(Card.Spade, 2),
  vine:clone(Card.Club, 2),
}

local silverLionSkill = fk.CreateTriggerSkill{
  name = "#silver_lion_skill",
  attached_equip = "silver_lion",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.damage > 1
  end,
  on_use = function(_, _, _, _, data)
    data.damage = 1
  end,
}
Fk:addSkill(silverLionSkill)
local silverLion = fk.CreateArmor{
  name = "silver_lion",
  suit = Card.Club,
  number = 1,
  equip_skill = silverLionSkill,
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    if player:isWounded() and self.equip_skill:isEffectable(player) then
      room:broadcastPlaySound("./packages/maneuvering/audio/card/silver_lion")
      room:setEmotion(player, "./packages/maneuvering/image/anim/silver_lion")
      room:recover{
        who = player,
        num = 1,
        skillName = self.name
      }
    end
  end,
}
extension:addCard(silverLion)

local huaLiu = fk.CreateDefensiveRide{
  name = "hualiu",
  suit = Card.Diamond,
  number = 13,
}

extension:addCards({
  huaLiu,
})

extension:addCards{
  Fk:cloneCard("jink", Card.Heart, 8),
  Fk:cloneCard("jink", Card.Heart, 9),
  Fk:cloneCard("jink", Card.Heart, 11),
  Fk:cloneCard("jink", Card.Heart, 12),
  Fk:cloneCard("jink", Card.Diamond, 6),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 10),
  Fk:cloneCard("jink", Card.Diamond, 11),

  Fk:cloneCard("peach", Card.Heart, 5),
  Fk:cloneCard("peach", Card.Heart, 6),
  Fk:cloneCard("peach", Card.Diamond, 2),
  Fk:cloneCard("peach", Card.Diamond, 3),

  Fk:cloneCard("nullification", Card.Heart, 1),
  Fk:cloneCard("nullification", Card.Heart, 13),
  Fk:cloneCard("nullification", Card.Spade, 13),
}

Fk:loadTranslationTable{
  ["maneuvering"] = "军争",

  ["thunder__slash"] = "雷杀",
  ["fire__slash"] = "火杀",
  ["analeptic"] = "酒",
  ["iron_chain"] = "铁锁连环",
  ["_normal_use"] = "正常使用",
  ["recast"] = "重铸",
  ["fire_attack"] = "火攻",
  ["supply_shortage"] = "兵粮寸断",
  ["guding_blade"] = "古锭刀",
  ["fan"] = "朱雀羽扇",
  ["#fan_skill"] = "朱雀羽扇",
  ["vine"] = "藤甲",
  ["silver_lion"] = "白银狮子",
  ["hualiu"] = "骅骝",
}

return extension
