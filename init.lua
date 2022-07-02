local bootfs = component.proxy(computer.getBootAddress())

local gpu, screen
if computer.getBootGpu then
    gpu =computer.getBootGpu()
else
    gpu = c
end
gpu = component.proxy(gpu)
screen = component.proxy(screen)