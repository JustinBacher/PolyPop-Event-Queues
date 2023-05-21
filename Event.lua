Instance.properties = properties(
    {
        {name="Timed", type="Bool", value=false, onUpdate="onTimedUpdate"},
        {name="Duration", type="Int", units="ms", range={min=0}, ui={easing=5000, stride=100}},
        {name="Queue", type="Action"},
        {name="onAlert", type="Alert"},
        {name="onComplete", type="Action"},
    }
)

function Instance:onInit()
    self:onTimedUpdate()
    self:getParent():setEventName(self)
end

function Instance:onTimedUpdate()
    local timed = self.properties.Timed
    getUI():setUIProperty({{obj=self.properties:find("Duration"), visible=timed}})
    getUI():setUIProperty({{obj=self.properties:find("onComplete"), visible=not timed}})
end

function Instance:Queue(args, alert)
    self:getParent():addToQueue(self, self:findSourceAlertArgs())
end

function Instance:onComplete()
    local currentEvent = self:getParent().queue:peek_left()
    if currentEvent ~= nil and currentEvent.event == self then
        self:getParent():onQueueableCompleted()
    end
end

function Instance:findSourceAlertArgs()
    local kit = getEditor():getWireLibrary()

    for i = 1, kit:getObjectCount() do
        local wire = kit:getObjectByIndex(i)

        if wire:getTargetObject() == self.properties.Queue then
            return wire:getSourceObject():getLastArgs()
        end
    end

    return nil
end

function Instance:setAlertArgs()
    local args = self:findSourceAlertArgs()
    self.properties.onAlert:setLastArgs(args)

    return args
end