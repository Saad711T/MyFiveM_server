Config = {}

-- ===== مواقع التفاعل =====
Config.Simeon = vector3(-47.16, -1097.23, 26.42)

-- نقطة الريسبون الافتراضية (تبقى للتوافق مع الكود القديم)
Config.PDSpawn = vector3(425.06, -979.62, 30.71)
Config.PDSpawnHeading = 90.0

Config.InteractDist = 3.0
Config.KeyInteract = 38 -- E

Config.OwnedFileName = 'owned_vehicles.json'

-- ===== الرصيد الابتدائي لكل لاعب جديد =====
Config.StartingBalance = 150000

-- ===== أماكن ريسبون السيارات المتعددة =====
-- يقدر اللاعب يختار من أي نقطة يطلع سيارته
Config.SpawnPoints = {
    { id = 'pd',      label = 'Mission Row PD',          pos = vector4(425.06, -979.62, 30.71, 90.0) },
    { id = 'simeon',  label = "Simeon's PDM",            pos = vector4(-30.0, -1090.0, 26.42, 70.0) },
    { id = 'airport', label = 'LS International Airport', pos = vector4(-1037.0, -2737.0, 13.76, 240.0) },
    { id = 'sandy',   label = 'Sandy Shores',            pos = vector4(1722.2, 3683.90, 34.27, 210.0) },
}

-- ===== Blips على الخريطة =====
-- sprite: رقم أيقونة البلِب | color: رقم اللون
Config.Blips = {
    { label = 'Simeon Showroom',    pos = vector3(-47.16, -1097.23, 26.42),  sprite = 326, color = 3,  scale = 0.85 },
    { label = 'Police Station',     pos = vector3(425.06, -979.62, 30.71),   sprite = 60,  color = 29, scale = 0.85 },
    { label = 'Los Santos Airport', pos = vector3(-1037.0, -2737.0, 13.76),  sprite = 307, color = 0,  scale = 0.85 },
    { label = 'Sandy Shores Airport', pos = vector3(1765.3, 3265, 13.76),  sprite = 307, color = 0,  scale = 0.85 },
    { label = 'Burger Shot',        pos = vector3(-595.71, -861.46, 25.88),  sprite = 106, color = 1,  scale = 0.80 },
    { label = 'Cluckin Bell',       pos = vector3(-184.84, -1425.82, 31.47), sprite = 106, color = 47, scale = 0.80 },
}
 

 