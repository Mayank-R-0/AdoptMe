local events = {}

function getEvent(eventName)
    if not events[eventName] then
        events[eventName] = Event.new(eventName)
    end
    return events[eventName]
end
