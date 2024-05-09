--[[
	
	Copyright (c) 2024 Pocket Worlds

	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely.
	
--]] 

type PlayerInfo = {
	player : Player,
	emote : StringValue,
	lastFootStep : number
}

local footstepEvent = "footstep"
local footstepEventThreshold = 0.1

--!SerializeField
local movementIndicator : GameObject = nil

--!SerializeField
local longPressSound : AudioShader = nil

--!SerializeField
local footstepWalkSound : AudioShader = nil

--!SerializeField
local footstepRunSound : AudioShader = nil

local moveRequest = Event.new("MoveRequest")
local moveEvent = Event.new("MoveEvent")
local emoteRequest = Event.new("EmoteRequest")
local emoteEvent = Event.new("EmoteEvent")
local players = {}
local movementIndicatorInstance : GameObject? = nil;

options = {}

local gameplayManager = require("GameplayManager")

--[[
	
	Client
	
--]] 

if client then
    -- Whether or not the PlayerController is enabled
    options.enabled = true
    
    -- The mask to use for raycasting
    options.tapMask =
        bit32.bor(
            bit32.lshift(1, LayerMask.NameToLayer("Default")),
            bit32.lshift(1, LayerMask.NameToLayer("Character")),
            bit32.lshift(1, LayerMask.NameToLayer("Tappable")))
    
	options.characterLongPress = {
        height = 0.5,
        bounceDuration = 0.3
    }
end

local function PlayFootstepSound(playerInfo : PlayerInfo)
	local c = playerInfo.player.character
	if not c then
		return
	end

	if playerInfo.lastFootStep + footstepEventThreshold > Time.time then
		return
	end

	playerInfo.lastFootStep = Time.time

	if c.state == CharacterState.Walking and footstepWalkSound then
		footstepWalkSound:Play(1,1)
	elseif c.state == CharacterState.Running and footstepRunSound then
		footstepRunSound:Play(1,1)
	end
end

--- Track all created players instances in the players table
-- @param game Client or server
local function TrackPlayers(playerJoinedCallback, characterChangedCallback)
	scene.PlayerJoined:Connect(function(scene, player)
		local playerInfo = {
			player = player,
			emote = StringValue.new("emote" .. tostring(player.id), ""),
			lastFootStep = Time.time
		} :: PlayerInfo
		
		players[player] = playerInfo

		if playerJoinedCallback then
			playerJoinedCallback(playerInfo)
		end

		if characterChangedCallback then
			player.CharacterChanged:Connect(characterChangedCallback)
		end
	end)
	
	scene.PlayerLeft:Connect(function(player)
		players[player] = nil
	end)
end

--- Show the movement indicator (Client)
-- @param point Position to show the indicator at
local function ShowMovementIndicator(point)
	-- Create the movement indicator if we have not created it yet
	if not movementIndicatorInstance and movementIndicator then
		movementIndicatorInstance = Object.Instantiate(movementIndicator) :: GameObject?
		movementIndicatorInstance:SetActive(false)
	end
	
	if movementIndicatorInstance then
		movementIndicatorInstance.transform.position = point
		movementIndicatorInstance:SetActive(true)
	end
end

--- Hide the movement indicator (Client)
local function HideMovementIndicator()
	if movementIndicatorInstance then
		movementIndicatorInstance:SetActive(false)
	end
end

--- Move a character to a given point using path finding
-- @param character Character to move
-- @param point World position to move the character to
-- @param areaMask Pathfinding area mask to use to move the character
-- @param distance Optional distance away from the point that character should move
-- @param callback Callback to call when the move is finished
-- @return True if a path was found and the character is moving
local function MoveTo(
	character : Character,
	point : Vector3,
	areaMask : number,
	distance : number,
	callback :(character: Character, completed : boolean) -> ()) : boolean

	if not character then return false end
	if not character.player or not character.player.isLocal then
		error("MoveTo should only be called on the local player's character")
		return false
	end

	local moved = false

	if distance > 0 then
		moved = character:MoveWithinRangeOf(point, distance, -1, callback)
	else
		moved = character:MoveTo(point, -1, callback)
	end

	if (moved) then
		if character.state ~= CharacterState.Idle then
			ShowMovementIndicator(character.destination)
		end

		moveRequest:FireServer(character.destination)
	end

	return moved
end

function self:ClientAwake()
	local longPressCharacter : Character? = nil;
	local longPressTween : Tween? = nil;

	-- Listen for an emote being selected in the UI and request the emote from the server
	UI.EmoteSelected:Connect(function(emote, loop)
		emoteRequest:FireServer(emote, loop)
	end)

	-- Listen for a one time emote to play on any character
	emoteEvent:Connect(function(player, emote)
		if player.character and emote and emote ~= "" then
			player.character:PlayEmote(emote, false)
		end
	end)

	function RayCast(position)
		local camera = scene.mainCamera
		if not camera or not camera.isActiveAndEnabled then
			return false
		end

		-- Create a ray from the screen position
		local ray = camera:ScreenPointToRay(Vector3.new(position.x, position.y, 0))

		-- Cast a ray from the camera into the world
		return Physics.Raycast(ray, 1000, options.tapMask)
	end

	Input.LongPressBegan:Connect(function(evt)
		-- Cast a ray from the camera into the world
		local success, hit = RayCast(evt.position)
		if (not success or not hit.collider) then
			return
		end

		local character = hit.collider.gameObject:GetComponentInParent(Character)
		if not character or not character.player then
			return
		end

		longPressCharacter = character

		if longPressTween then
			longPressTween:Stop(false)
			longPressTween = nil
		end
	end)

	Input.LongPressContinue:Connect(function(evt)
		if longPressCharacter then
			local height = Easing.Sine(evt.progress) * options.characterLongPress.height
			longPressCharacter.renderPosition = Vector3.new(0,height, 0)
		end
	end)
	
	Input.LongPressEnded:Connect(function(evt)
		if not longPressCharacter then
			return
		end

		local character = longPressCharacter
		longPressCharacter = nil

		-- always return back to start
		longPressTween = character:TweenRenderPositionTo(Vector3.zero)
			:EaseOutBounce(1, 3)
			:Duration(options.characterLongPress.bounceDuration * evt.progress)
			:Play()

		if not evt.cancelled then
			if longPressSound then
				longPressSound:Play(1,1)
			end
			UI:OpenMiniProfile(character.player)
		end
	end)

	local function FailedMove(character : Character)
		if not character then
			return
		end

		if not character.player or not character.player.isLocal then
			error("FailedMove must only be called for the local player's character")
			return;
		end

		MoveTo(character, character.transform.position, -1, 0, function() end)
		character:PlayEmote("emote-no", false)
	end

	Input.Tapped:Connect(function(tap)
		if (not options.enabled) then
			return
		end

		local character = client.localPlayer.character
		if (not character) then
			return
		end

		-- Cast a ray from the camera into the world
		local success, hit = RayCast(tap.position)		
		if (not success) then
			return
		end

		-- Check for a tap handler in the hierarchy
		if (hit.collider) then
			local handler = hit.collider.gameObject:GetComponentInParent(TapHandler) :: TapHandler?
			if handler then
				-- Ensure the handler is actually enabled.
				if not handler.enabled then
					return
				end

				if not handler.moveTo or Vector3.Distance(handler.transform.position, character.transform.position) <= handler.distance then
					handler:Perform()
				elseif handler.moveTo then
					MoveTo(character, handler.transform.position, -1, handler.distance, function(character, completed)
						-- Ensure we got to our destination before performing the action
						if completed then
							handler:Perform()
						end
					end)
				end

				return
			end

			-- Characters should block taps
			if hit.collider.gameObject:GetComponentInParent(Character) then
                --print("Clicked Player", hit.collider.gameObject.name)
                gameplayManager.CharacterClicked(hit.collider.gameObject:GetComponentInParent(Character).player)
				return
			end
		end

		-- Attempt to move the local character
		MoveTo(character, hit.point, -1, 0, function() end)
	end)

	moveEvent:Connect(function(player, point)
		local character = player.character

		-- move for local player is already handled
		if player.isLocal or character == nil then
			return
		end

		player.character.usePathfinding = true
		local moved = player.character:MoveTo(point, -1)

		-- If the move failed we still need the character to end up at their destination
		-- so we will teleport them instead.
		if not moved then
			character:Teleport(point)
		end
	end)

	function OnPlayerJoined(playerInfo)
	end

	function OnCharacterChanged(player : Player, character : Character)
		local playerInfo = players[player]
		local character = player.character

		playerInfo.emote.Changed:Connect(function(emote,loop)
			if emote and emote ~= "" then
				character:PlayEmote(emote, loop)
			else
				character:SetIdle()
			end
		end)

		if player.isLocal then
			character.AnimationEvent:Connect(function(evt)
				if evt.functionName == footstepEvent then
					PlayFootstepSound(playerInfo)
				end
			end)
		end

		character.StateChanged:Connect(function(newState, oldState)
			if player.isLocal then
				local wasMoving = oldState == CharacterState.Walking or oldState == CharacterState.Running
				local isMoving = newState == CharacterState.Walking or newState == CharacterState.Running
				if wasMoving and not isMoving then
					PlayFootstepSound(playerInfo)
				end

				if not isMoving then
					HideMovementIndicator()
				end
			end

			if newState == CharacterState.Idle then
				local emote = playerInfo.emote.value
				if emote ~= "" then
					character:PlayEmote(emote, true)
				end
			end
		end)
	end
	
	TrackPlayers(OnPlayerJoined, OnCharacterChanged)
end

--[[
	
	Server
	
--]] 
function self:ServerAwake()

	-- Listen for a move request and move the player's character
	moveRequest:Connect(function(player, point)
	    if not player or not player.character then
			return
		end

		-- Ensure any new players that join the scene will see the player at their final destination
		local playerInfo = players[player]
		local character = player.character
		player.character.gameObject.transform.position = point

		-- Forward the move on to all clients now
		moveEvent:FireAllClients(player, point)
	end)

	-- Listen for an emote request and play the emote on the player's character
	emoteRequest:Connect(function(player, emote, loop)
		if player.character then
			local playerInfo = players[player]
			if playerInfo == nil then
				return
			end

			-- Stop the emote?
			if (emote == "") then
				playerInfo.emote.value = ""
				return
			end
	
			-- If looping then set the emote value
			if loop then
				playerInfo.emote.value = emote
			-- Otherwise clear the emote value and play a one time emote
			else
				playerInfo.emote.value = ""
				emoteEvent:FireAllClients(player, emote);
			end			
		end
	end)

	TrackPlayers()
end
