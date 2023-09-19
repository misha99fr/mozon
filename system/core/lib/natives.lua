--позваляет получить доступ к оригинальным методам библиотек computer и component
--например если нужно исключить влияния vcomponent

local natives = {}
natives.component = table.deepclone(component)
natives.computer = table.deepclone(computer)
return natives