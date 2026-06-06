Config = {}

-- عدد الخلايا في الإنفنتوري
Config.SlotCount = 24

-- اسم ملف الحفظ
Config.SaveFile = 'inventories.json'

-- زر فتح الإنفنتوري (I = 73 control)
Config.OpenKey = 'I'

-- ============================================================
-- تعريف العناصر المتاحة في اللعبة
-- name      : الاسم التقني (= اسم الصورة: name.png في web/images)
-- label     : الاسم المعروض في الواجهة
-- type      : weapon / food / money / misc
-- stackable : هل يتكدّس في خلية وحدة؟
-- weapon    : (للسلاح) هاش السلاح في FiveM
-- maxAmmo   : (للسلاح) الذخيرة الافتراضية عند الإعطاء
-- heal      : (للأكل) كم يشفي عند الأكل
-- ============================================================
Config.Items = {
    money = {
        label = 'Money',
        type = 'money',
        stackable = true,
    },
    water = {
        label = 'Water',
        type = 'food',
        stackable = true,
        heal = 20,        -- يملأ 20 صحة
        drink = true,     -- أنيميشن شرب (مو أكل)
    },
    bread = {
        label = 'Bread',
        type = 'food',
        stackable = true,
        heal = 40,        -- يملأ 40 صحة
    },
    pistol = {
        label = 'Pistol',
        type = 'weapon',
        stackable = false,
        weapon = 'WEAPON_PISTOL',
        maxAmmo = 50,
    },
}