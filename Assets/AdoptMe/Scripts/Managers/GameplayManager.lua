local players = {}

local Events = require("Events")

--!SerializeField
local UIManager : GameObject = nil

local RoleUpdateRequest = Event.new("RoleUpdateRequest")

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

end

function self:ServerAwake()
    trackPlayers()
    bindClientFiredRequestsOnServer()
end
