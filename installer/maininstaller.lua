local gpu = component.proxy((computer.getBootGpu and computer.getBootGpu() or component.list("gpu")()) or error("no gpu found", 0))
local screen = (computer.getBootScreen and computer.getBootScreen() or component.list("screen")()) or error("no screen found", 0)
gpu.bind(screen)

