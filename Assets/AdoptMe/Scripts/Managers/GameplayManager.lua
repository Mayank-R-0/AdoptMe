local players = {}

local families = {}

local myFamily = nil

local Events = require("Events")

--!SerializeField
local UIManager : GameObject = nil

local currentPlayerClicked = nil

local CurrentInvitation = nil

local RoleUpdateRequest = Event.new("RoleUpdateRequest")

local CreateFamilyRequest = Event.new("CreateFamilyRequest")
local CreateFamilyResponse = Event.new("CreateFamilyResponse")

local InviteFamilyRequest = Event.new("InviteFamilyRequest")
local InviteFamilyEvent = Event.new("InviteFamilyEvent")

local AcceptInviteRequest = Event.new("AcceptInviteRequest")
local AcceptInviteEvent = Event.new("AcceptInviteEvent")

local LeaveFamilyRequest = Event.new("LeaveFamiyRequest")
local LeaveFamilyEvent = Event.new("LeaveFamiyEvent")



function printMessage(position, messageOwner, message)
    print(position .. " : " .. messageOwner .. " : " .. message)
end

function trackPlayers(characterCallback)
    
    scene.PlayerJoined:Connect(function(scene, player)
        
        players[player] = {
            player = player,
            role = IntValue.new("role" .. tostring(player.id), -1)
        }

        player.CharacterChanged:Connect(function(player, character)
            local playerInfo = players[player]
            if(character == nil) then
                return
            end

            if characterCallback then
                characterCallback(playerInfo)
            end
        end)

    end)

    scene.PlayerLeft:Connect(function(scene, player)
    
        players[player] = nil

    end)

end

function bindServerFiredEventsOnClient()
    
    Events.getEvent("ClientConnectionEvent"):Connect(function(player)
        if(player ~= client.localPlayer) then return end
        printMessage("Client", player.name, "Player Connected" .. player.name)

        UIManager:GetComponent("UI_Main"):enableChoicePanel()
    end)

    CreateFamilyResponse:Connect(function(familyOwner, familyInfo)
        if familyOwner ~= client.localPlayer then return end
        printMessage("Client", familyOwner.name, "familyCreated " .. familyInfo.familyName)

        myFamily = familyInfo
        printMessage("Client", familyOwner.name, "family name : " .. myFamily.familyName)
        --UIManager:GetComponent("UI_Main").SetLeaveStateOpen(myFamily.familyName)
    end)

    InviteFamilyEvent:Connect(function(FromPlayer, ToPlayer, familyName)
        if ToPlayer ~= client.localPlayer then return end
        
        printMessage("Client", ToPlayer.name, "Show invitation request on UI")
        printMessage("Client", ToPlayer.name, "Family request from player : " .. FromPlayer.name .. " - " .. familyName)


        --UIManager:GetComponent("UI_Main").SetAcceptInviteStateOpen(FromPlayer.name, familyName)

        CurrentInvitation = {
            fromPlayer = FromPlayer,
            familyName = familyName
        }

    end)

    AcceptInviteEvent:Connect(function(familyInfo) 
        if familyInfo.familyMembers[client.localPlayer.name] == nil then return end

        myFamily = familyInfo

        --UIManager:GetComponent("UI_Main").SetLeaveStateOpen(myFamily.familyName)

        for k, v in myFamily.familyMembers do
            printMessage("Client", client.localPlayer.name, "family member Accept " .. v.name)
        end
            
    end)

    LeaveFamilyEvent:Connect(function(FamilyMember, familyinfo)
    

        if myFamily == nil then return end
        --printMessage("Client", client.localPlayer.name, "Memeber name" .. FamilyMember.name .. " family info " .. familyinfo.familyName)


        if(familyinfo.familyMembers[client.localPlayer.name] == nil) then
            if(familyinfo.familyName == myFamily.familyName) then
                printMessage("Client", client.localPlayer.name, "Leaving Family")
                myFamily = nil
                --UIManager:GetComponent("UI_Main").SetCreateFamilyStateOpen()
            end
        elseif(familyinfo.familyName == myFamily.familyName) then
            myFamily = familyinfo
        end


        for k, v in familyinfo.familyMembers do
            printMessage("Client", client.localPlayer.name, v.name)
        end
    end)

end

function self:ClientAwake()
    bindServerFiredEventsOnClient()

    function OnCharacterInstantiate(playerinfo)
        local player = playerinfo.player
        local character = player.character

        playerinfo.role.Changed:Connect(function(newVal, oldVal)
            local newScale = nil
            if (newVal == 0) then
                newScale = 1.5
            elseif (newVal == 1) then
                newScale = 1
            end
            character.renderScale = Vector3.new(newScale, newScale, 1)
        end)
    end

    function ChangeRole(role)

        RoleUpdateRequest:FireServer(role)

    end

    function CharacterClicked(clickedPlayer)
        currentPlayerClicked = clickedPlayer

        if(myFamily ~= nil) then
            if (myFamily.familyMembers[currentPlayerClicked.name] == nil) then
                --UIManager:GetComponent("UI_Main").SetInviteStateOpen(currentPlayerClicked.name)
            else 
                --UIManager:GetComponent("UI_Main").ShowMessage("Already in family")
            end
        end

        --UIManager:GetComponent("UI_Main").AddInvitePopup(clickedPlayer)
    end

    function CreateFamilyFromClient(familyName)
        CreateFamilyRequest:FireServer(familyName)
    end

    function InviteFamilyFromClient(familyName)
        InviteFamilyRequest:FireServer(currentPlayerClicked, myFamily.familyName)
    end

    function AcceptInviteFromClient()
        if (myFamily ~= nil) then
            local  message = "You are already in family " .. "'" .. myFamily.familyName .. "'" .. " You will be leaving and joining " .. CurrentInvitation.familyName
            --[[UIManager:GetComponent("UI_Main").ShowConfirmationMessage(message, 
                function() 
                    LeaveFamilyFromClient()
                    AcceptInviteRequest:FireServer(CurrentInvitation.fromPlayer, CurrentInvitation.familyName) end,
                function() UIManager:GetComponent("UI_Main").ShowMessage("Invite Cancelled") end
            )]]
        else
            AcceptInviteRequest:FireServer(CurrentInvitation.fromPlayer, CurrentInvitation.familyName)
        end
    end

    function LeaveFamilyFromClient()
        LeaveFamilyRequest:FireServer(myFamily.familyName)
    end

    trackPlayers(OnCharacterInstantiate)
    Events.getEvent("ClientConnectionRequest"):FireServer()
end


function bindClientFiredRequestsOnServer()

    Events.getEvent("ClientConnectionRequest"):Connect(function(player)
        Events.getEvent("ClientConnectionEvent"):FireAllClients(player)
    end) 
    
    RoleUpdateRequest:Connect(function(player, role)

        local playerInfo = players[player]
        playerInfo.role.value = role

    end)

    CreateFamilyRequest:Connect(function(familyOwner, familyName)
        printMessage("Server", familyOwner.name, familyOwner.name .. " - " .. familyName)
        families[familyName] = {
            familyName = familyName,
            familyId = tostring(familyName) .. tostring(math.random(0, 1000)),
            familyMembers = {
                [familyOwner.name] = familyOwner
            }
        }
        local familyInfo = families[familyName]
        CreateFamilyResponse:FireAllClients(familyOwner, familyInfo)
    end)

    InviteFamilyRequest:Connect(function(FromPlayer, ToPlayer, familyName)
        InviteFamilyEvent:FireAllClients(FromPlayer, ToPlayer, familyName)
    end)

    AcceptInviteRequest:Connect(function(AcceptingPlayer, FamilyOwner, familyName)

        printMessage("Server", AcceptingPlayer.name, AcceptingPlayer.name .. " - " .. FamilyOwner.name .. " - " .. familyName)

        if(families[familyName]) then
            families[familyName].familyMembers[AcceptingPlayer.name] = AcceptingPlayer
        end

        AcceptInviteEvent:FireAllClients(families[familyName])
        
        for k, v in pairs(families[familyName].familyMembers) do
            printMessage("Server", AcceptingPlayer.name, "Pring........." .. v.name)
        end
    end)

    LeaveFamilyRequest:Connect(function(FamilyMember, familyName)
        printMessage("Server", FamilyMember.name, "Leave family requested by " .. FamilyMember.name .. "From Family " .. familyName) 
        families[familyName].familyMembers[FamilyMember.name] = nil
        -- if(#families[familyName].familyMembers <= 0) then
        --     families[familyName] = nil
        -- end

        local familyinfo = families[familyName]

        LeaveFamilyEvent:FireAllClients(FamilyMember, familyinfo)

    end)

end

function self:ServerAwake()
    trackPlayers()
    bindClientFiredRequestsOnServer()
end
