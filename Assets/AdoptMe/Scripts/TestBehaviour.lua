--local Gamemanager = require("GameplayManager")

function callEvent()
    --Gamemanager.ChangeRole(math.random(0,1))
end

function self:ClientAwake()
    callEvent()
end
