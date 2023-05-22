local Queue = require("alertqueuer")
local eventCount = 0

Instance.properties = properties({
    {
        name="Settings",
        type="PropertyGroup",
        items={
            {name="Delay", type="Int", units="ms", range={min=0}, ui={easing=5000, stride=100}},
            {name="ClearQueue", type="Action"},
            {name="Paused", type="Bool", onUpdate="onPausedUpdate"},
        },
        ui={expand=true}
    },
    {
        name="Events",
        type="ObjectSet",
        set_types={type="PolyPopObject", index="EventQueue.Event"},
        ui={expand=true}
    },
})

function Instance:onInit()
    if self.properties.Events:getKit():getObjectCount() > 0 then
        getUI():setUIProperty({{obj=self.properties.Settings:find("Settings"), expand=false}})
    end
    self:ClearQueue()
end

function Instance:onPausedUpdate()
    if not self.properties.Settings.Paused then
        self:runNext()
    end
end

function Instance:setEventName(event)
    eventCount = eventCount + 1

    local name = event:getName()
    if name == "Event" then
        event:setName(name .. " " .. eventCount)
    end
end

function Instance:ClearQueue()
    self.queue = Queue:new()
end

function Instance:PauseQueue()
    self.queue = Queue:new()
end

function Instance:addToQueue(event, args)
    self.queue:push_right({event=event, args=args})

    if self.queue:length() == 1 then
        self:runNext()
    end
end

function Instance:onQueueableCompleted()
    self.queue:pop_left()

    if not self.queue:is_empty() then
        getAnimator():createTimer(
            self,
            self.runNext,
            milliseconds(self.properties.Settings.Delay)
        )
    end
end

function Instance:runNext()
    if self.properties.Settings.Paused or self.queue:is_empty() then
        return
    end

    local data = self.queue:peek_left()
    local eventProps = data.event.properties

    eventProps.onAlert:raise(data.args)

    if eventProps.Timed then
        getAnimator():createTimer(
            self,
            self.onQueueableCompleted,
            milliseconds(eventProps.Duration)
        )
    end
end
