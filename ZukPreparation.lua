local API = require("api")

local Logger = require("zukME-main.ZukLogger")

local auras = require("auras")


local ALTAR_OF_WAR_ID = 114748

local BANK_CHEST_ID = 114750

local BOSS_PORTAL_ID = 122070

local DEATH_NPC_ID = 27299

local COLOSSEUM_ENTRANCE_ID = 120046


local COMBAT_START_INTERFACE_ID = 1671


local COMBAT_INITIATOR_NPC_ID = 28525

local npcdeath = false






local State = {

    isPlayerDead = false,

    isInWarsRetreat = false,

    isRestoringPrayer = false,

    isBanking = false,

    isMaxAdrenaline = false,

    isPortalUsed = false,


}



function State:Reset()

    self.isInWarsRetreat = false

    self.isRestoringPrayer = false

    self.isBanking = false

    self.isMaxAdrenaline = false

    self.isPortalUsed = false

    Logger:Info("Estado do script resetado.")

end



local zukPreparation = {}



zukPreparation.summoningPouches = {
    "Blood nihil pouch", "Ice nihil pouch", "Shadow nihil pouch", "Smoke nihil pouch",
    "Binding contract (ripper demon)", "Binding contract (kal'gerion demon)",
    "Binding contract (blood reaver)", "Binding contract (hellhound)", "Holy scarab pouch"
}

zukPreparation.foodItems = {
    "Lobster", "Swordfish", "Desert sole", "Catfish", "Monkfish", "Beltfish",
    "Ghostly sole", "Cooked eeligator", "Shark", "Sea turtle", "Great white shark",
    "Cavefish", "Manta ray", "Rocktail", "Tiger shark", "Sailfish",
    "Potato with cheese", "Tuna potato", "Baron shark", "Juju gumbo",
    "Great maki", "Great gunkan", "Rocktail soup", "Sailfish soup",
    "Fury shark", "Primal feast"
}

zukPreparation.emergencyFoodItems = {
    "Green blubber jellyfish", "Blue blubber jellyfish",
    "2/3 green blubber jellyfish", "2/3 blue blubber jellyfish",
    "1/3 green blubber jellyfish", "1/3 blue blubber jellyfish",
}

zukPreparation.emergencyDrinkItems = {
    "Guthix rest (4)", "Guthix rest (3)", "Guthix rest (2)", "Guthix rest (1)",
    "Guthix rest flask (6)", "Guthix rest flask (5)", "Guthix rest flask (4)", "Guthix rest flask (3)", "Guthix rest flask (2)", "Guthix rest flask (1)",
    "Saradomin brew (4)", "Saradomin brew (3)", "Saradomin brew (2)", "Saradomin brew (1)",
    "Saradomin brew flask (6)", "Saradomin brew flask (5)", "Saradomin brew flask (4)", "Saradomin brew flask (3)", "Saradomin brew flask (2)", "Saradomin brew flask (1)",
    "Super Guthix rest (4)", "Super Guthix rest (3)", "Super Guthix rest (2)", "Super Guthix rest (1)",
    "Super Guthix rest flask (6)", "Super Guthix rest flask (5)", "Super Guthix rest flask (4)", "Super Guthix rest flask (3)", "Super Guthix rest flask (2)", "Super Guthix rest flask (1)",
    "Super Saradomin brew (4)", "Super Saradomin brew (3)", "Super Saradomin brew (2)", "Super Saradomin brew (1)",
    "Super Saradomin brew flask (6)", "Super Saradomin brew flask (5)", "Super Saradomin brew flask (4)", "Super Saradomin brew flask (3)", "Super Saradomin brew flask (2)", "Super Saradomin brew flask (1)"
}

zukPreparation.totalDeaths = 0

function zukPreparation:WhichFamiliar()
    local familiar = ""
    local foundFamiliar = false
    for i = 1, #zukPreparation.summoningPouches do
        foundFamiliar = Inventory:Contains(zukPreparation.summoningPouches[i])
        if foundFamiliar then
            familiar = zukPreparation.summoningPouches[i]
            break
        end
    end
    return familiar
end

function zukPreparation:SummonFamiliar()
    if not Familiars:HasFamiliar() and Inventory:ContainsAny(zukPreparation.summoningPouches) then
        Logger:Info("Summoning familiar " .. self:WhichFamiliar())
        Inventory:DoAction(self:WhichFamiliar(), 1, API.OFF_ACT_GeneralInterface_route)
        State.isFamiliarSummoned = true
        API.RandomSleep()
    else
        Logger:Debug("familiar is summoned or pouch in inventory")
    end
end




function zukPreparation:IsDialogInterfacePresent()

    Logger:Info("DEBUG: Checking if dialog interface is present using API.Check_Dialog_Open().")

    local isPresent = API.Check_Dialog_Open()

    if isPresent then

        Logger:Debug("Dialog interface is present.")

    else

        Logger:Debug("Dialog interface is NOT present.")

    end

    return isPresent

end



function zukPreparation:IsCombatStartInterfacePresent()

    Logger:Info("DEBUG: Checking if combat start interface is present using API.Compare2874Status().")

    local isPresent = API.Compare2874Status(COMBAT_START_INTERFACE_ID, false)

    if isPresent then

        Logger:Debug("Combat start interface (ID: " .. COMBAT_START_INTERFACE_ID .. ") is present via Compare2874Status.")

    else

        Logger:Debug("Combat start interface (ID: " .. COMBAT_START_INTERFACE_ID .. ") is NOT present via Compare2874Status.")

    end

    return isPresent

end

function zukPreparation:SleepTickRandom(sleepticks)
    API.Sleep_tick(sleepticks)
    API.RandomSleep2(1, 120, 0)
end

function zukPreparation:WarsTeleport()
    API.DoAction_Ability("War's Retreat", 1, API.OFF_ACT_GeneralInterface_route, false)
    self:SleepTickRandom(10)
    Logger:Info("Teleported to War's Retreat")
end


function zukPreparation:CheckStartLocation()

    if not (API.Dist_FLP(FFPOINT.new(3299, 10131, 0)) < 30) then

        Logger:Info("Teleporting to War's Retreat")

        zukPreparation:WarsTeleport()

        API.RandomSleep()

    else

        Logger:Info("Already in War's Retreat")

        State.isInWarsRetreat = true

        API.RandomSleep() -- Substituído de Utils:SleepTickRandom(2)

    end

end



function zukPreparation:HandlePrayerRestore()

    if API.GetPrayPrecent() < 100 or API.GetSummoningPoints_() < 60 then

        Logger:Info("Restoring prayer and summoning at Altar of War")

        API.DoAction_Object1(0x3d, API.OFF_ACT_GeneralObject_route0, { ALTAR_OF_WAR_ID }, 50)

        while API.GetPrayPrecent() < 90 do
            API.RandomSleep2(500, 500, 500)
        end

    end

    State.isRestoringPrayer = true

end



function zukPreparation:HandleBanking()

    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { BANK_CHEST_ID }, 50)

    while not Inventory:Contains(15332) do
        zukPreparation:HandleDeathNPC()
        API.RandomSleep2(1200, 700, 800)
    end

    Logger:Info("Loading preset")

    State.isBanking = true

end


function zukPreparation:HandleAdrenalineCrystal()

    while not State.isMaxAdrenaline and API.Read_LoopyLoop() do
        zukPreparation:HandleDeathNPC()

        if API.GetAddreline_() ~= 100 then

            Logger:Info("Charging adrenaline...")

            Interact:Object("Adrenaline crystal", "Channel", 60)

            API.RandomSleep2(2000,500,500)

            while API.ReadPlayerMovin() do
                API.RandomSleep2(500, 500, 500)
            end

            API.RandomSleep() -- Substituído de Utils:SleepTickRandom(1)

        else

            State.isMaxAdrenaline = true

            Logger:Info("Adrenaline fully charged.")

        end

        API.RandomSleep() -- Substituído de Utils:SleepTickRandom(1)

    end

end

function zukPreparation:GoThroughPortal()

    Logger:Info("Going through boss portal")

-- Substituído de Utils:SleepTickRandom(5) para um sleep em milissegundos com mais controle

    -- (500ms fixos, +até 1000ms aleatórios, +até 2000ms aleatórios raros)

    local colosseum = API.GetAllObjArray1({ 28525 }, 10, { 1 })
    local entreiportal = false
    if #colosseum > 0 then
        entreiportal = true
    end

    while entreiportal==false and API.Read_LoopyLoop() do
        colosseum = API.GetAllObjArray1({ 28525 }, 10, { 1 })
        zukPreparation:HandleDeathNPC()

        if #colosseum > 0 then
            entreiportal = true
        end

        API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { BOSS_PORTAL_ID }, 50)

        API.RandomSleep2(1000, 1500, 2000)

        Logger:Info("At Colosseum entrance")

    end


end

local function getBuff(buffId)
    local buff = API.Buffbar_GetIDstatus(buffId, false)
    return { found = buff.found, remaining = (buff.found and API.Bbar_ConvToSeconds(buff)) or 0 }
end

function zukPreparation:FullPreparationCycle()

    Logger:Info("Iniciando ciclo de preparação completo.")
    API.RandomSleep2(1000,500,600) -- Substituído de Utils:SleepTickRandom(2)


    if not Equipment:Contains(55484) then
        zukPreparation:HandleDeathNPC()
        if not Equipment:Contains(55484) then
            return false
        end
    end
    if Equipment:Contains(55484) then
        self:CheckStartLocation()
        API.RandomSleep() -- Substituído de Utils:SleepTickRandom(2)
        self:HandleBanking()
        API.RandomSleep() -- Substituído de Utils:SleepTickRandom(2)
        Logger:Info("to armado vamo pra cima")
    else
        return false
    end

    if not auras:isAuraActive() then
        auras:activateAura("equilibrium")
    end

        self:HandlePrayerRestore()
        API.RandomSleep()
        zukPreparation:FireBuff()
        API.RandomSleep()
        self:SummonFamiliar()
        API.RandomSleep()
        self:HandleAdrenalineCrystal()
        API.RandomSleep() -- Substituído de Utils:SleepTickRandom(2)
        self:GoThroughPortal()
        API.RandomSleep() -- Substituído de Utils:SleepTickRandom(2)
        while API.ReadPlayerMovin() do
        API.RandomSleep2(500, 500, 500)
        end

    while not API.GetAllObjArrayFirst({ 28525 }, 40, { 1 }) do
        API.RandomSleep2(500, 500, 500)
        zukPreparation:HandleDeathNPC()
    end
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, { COMBAT_INITIATOR_NPC_ID }, 50)

        API.RandomSleep2(2000, 2000, 1500)




        while self:IsDialogInterfacePresent() do
            zukPreparation:HandleDeathNPC()

            Logger:Info("Dialog interface is present. Clicking 'Yes' option.")

            local success, err = pcall(function()

                API.DoAction_Interface(0xffffffff,0xffffffff,0,1188,8,-1,API.OFF_ACT_GeneralInterface_Choose_option)
            end)

            if not success then

                Logger:Error("Error clicking 'Yes' option: " .. tostring(err))

            end

            API.RandomSleep() -- Substituído de Utils:SleepTickRandom(2)


        end


        API.RandomSleep2(1000, 1000, 2000)
        API.RandomSleep() -- Substituído de Utils:SleepTickRandom(3)

        API.DoAction_Interface(0x24, 0xffffffff, 1, 1591, 60, -1, API.OFF_ACT_GeneralInterface_route)

        Logger:Info("Cliquei em iniciar.")

        API.RandomSleep2(1000, 1000, 2000) -- Mais tempo para o carregamento da luta, randomizado

        npcdeath = false

        Logger:Info("Ciclo de preparação completo finalizado.")

    end



function zukPreparation:ReclaimItemsAtGrave()
    API.RandomSleep2(2500,1000,1000)
    if API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route3,{ DEATH_NPC_ID },50) and State.isPlayerDead then
        API.RandomSleep2(1000, 1000, 1500)
        API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route3,{ 27299 },9)
        API.RandomSleep2(1000, 1000, 1500) -- Substituído de Utils:SleepTickRandom(5)

        if API.DoAction_Interface(0xffffffff,0xffffffff,1,1626,47,-1,API.OFF_ACT_GeneralInterface_route) then
            API.RandomSleep2(2000, 1000, 1500)
        end


        if API.DoAction_Interface(0xffffffff,0xffffffff,0,1626,72,-1,API.OFF_ACT_GeneralInterface_Choose_option) then

            API.RandomSleep2(1500, 1000, 1500) -- Substituído de Utils:SleepTickRandom(5)

            Logger:Info("Items reclaimed from grave")

            State.isPlayerDead = false

        end
        return true
    else
        return false
    end

end

function zukPreparation:CheckPlayerDeath()
    zukPreparation:VerificarNpcDeath()
    if API.HasDeathItemsReclaim() and not State.isPlayerDead or npcdeath == true and not State.isPlayerDead then
        State.isPlayerDead = true
        zukPreparation.totalDeaths = zukPreparation.totalDeaths + 1
        Logger:Warn("Player died!")
        zukPreparation:HandleDeathNPC()
        return true
    else
        return false
    end
end

function zukPreparation:VerificarNpcDeath()

    if API.IsInDeathOffice() then
        npcdeath = true
    else
        npcdeath = false
    end
end

function zukPreparation:HandleDeathNPC()
    zukPreparation:CheckPlayerDeath()
    if State.isPlayerDead then
        zukPreparation:ReclaimItemsAtGrave()  -- Chama a função de resgate de itens que já deve estar aqui
            API.RandomSleep2(1000, 500, 200) -- Pequeno sleep após a ação
            if not Equipment:Contains(55484) then
                API.logInfo("Deu algo errado man.")
                zukPreparation:ReclaimItemsAtGrave()
                if Equipment:Contains(55484) then
                    zukPreparation:FullPreparationCycle()
                    return true
                else
                    API.Write_LoopyLoop(false)
                    return false
                end
            end
            if not State.isPlayerDead then
                zukPreparation:FullPreparationCycle()
            end
        else
            return false
        end

end

function zukPreparation:FireBuff()
    while not getBuff(10931).found do
        Interact:Object("Campfire","Warm hands",15)
        API.RandomSleep2(5000,500,400)
        print("tentei por fogo na bomba")
    end
end

return zukPreparation