local players = {}

local families = {}

local myFamily = nil

local Events = require("Events")

--!SerializeField
local UIManager : GameObject = nil

local RoleUpdateRequest = Event.new("RoleUpdateRequest")

local CreateFamilyRequest = Event.new("CreateFamilyRequest")
local CreateFamilyResponse = Event.new("CreateFamilyResponse")

local InviteFamilyRequest = Event.new("InviteFamilyRequest")
local InviteFamilyEvent = Event.new("InviteFamilyEvent")

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
        print("Player Connected", player.name)

        UIManager:GetComponent("UI_Main"):enableChoicePanel()
    end)

    CreateFamilyResponse:Connect(function(familyOwner, familyInfo)
        if familyOwner ~= client.localPlayer then return end
        print("familyCreated", familyInfo.familyName)

        myFamily = familyInfo
    end)

    InviteFamilyEvent:Connect(function(FromPlayer, ToPlayer)
        if ToPlayer ~= client.localPlayer then return end
        
        print("Show invitation request on UI")
        print("Family request from player : ", FromPlayer.name)



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
        UIManager:GetComponent("UI_Main").AddInvitePopup(clickedPlayer)
    end

    function CreateFamilyFromClient(familyName)
        CreateFamilyRequest:FireServer(familyName)
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
            families[familyName] = {
                familyName = familyName,
                familyId = tostring(familyName) .. tostring(math.random(0, 1000)),
                familyMembers = {
                    familyOwner
                }
            }
            local familyInfo = families[familyName]
            CreateFamilyResponse:FireAllClients(familyOwner, familyInfo)
    end)

    InviteFamilyRequest:Connect(function(FromPlayer, ToPlayer)
        InviteFamilyEvent:FireAllClients(FromPlayer, ToPlayer)
    end)

end

function self:ServerAwake()
    trackPlayers()
    bindClientFiredRequestsOnServer()
end
