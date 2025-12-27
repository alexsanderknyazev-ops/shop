package modules

import (
	"time"
)

type Weapon struct {
	ID            uint      `gorm:"primaryKey;column:id;autoIncrement" json:"id"`
	Name          string    `gorm:"column:name;type:varchar(100);not null;unique" json:"name"`
	WeaponType    string    `gorm:"column:weapon_type;type:varchar(50);not null" json:"weapon_type"`
	DamageMin     int       `gorm:"column:damage_min;type:int4;not null" json:"damage_min"`
	DamageMax     int       `gorm:"column:damage_max;type:int4;not null" json:"damage_max"`
	Weight        float64   `gorm:"column:weight;type:numeric(4,2);default:0.0" json:"weight"`
	Price         int       `gorm:"column:price;type:int4;not null" json:"price"`
	Rarity        string    `gorm:"column:rarity;type:varchar(20)" json:"rarity"`
	SpecialEffect *string   `gorm:"column:special_effect;type:text" json:"special_effect,omitempty"`
	CreatedAt     time.Time `gorm:"column:created_at;autoCreateTime;default:CURRENT_TIMESTAMP" json:"created_at"`
}

func (Weapon) TableName() string {
	return "weapons"
}
