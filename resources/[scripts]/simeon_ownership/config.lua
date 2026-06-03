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
    { id = 'sandy',   label = 'Sandy Shores',            pos = vector4(1853.20, 3686.90, 34.27, 210.0) },
}

-- ===== Blips على الخريطة =====
-- sprite: رقم أيقونة البلِب | color: رقم اللون
Config.Blips = {
    { label = 'Simeon Showroom', pos = Config.Simeon,                    sprite = 326, color = 3,  scale = 0.9 },
    { label = 'Police Station',  pos = vector3(425.06, -979.62, 30.71),  sprite = 60,  color = 29, scale = 0.9 },
    { label = 'Airport',         pos = vector3(-1037.0, -2737.0, 13.76), sprite = 90,  color = 5,  scale = 0.9 },
}