package modules

import (
	"time"
)

type Armor struct {
	ID            uint      `gorm:"primaryKey;column:id;autoIncrement" json:"id"`
	Name          string    `gorm:"column:name;type:varchar(100);not null;unique" json:"name"`
	ArmorType     string    `gorm:"column:armor_type;type:varchar(50);not null" json:"armor_type"`
	Defense       int       `gorm:"column:defense;not null" json:"defense"`
	Weight        float64   `gorm:"column:weight;type:numeric(4,2);default:0.0" json:"weight"`
	Price         int       `gorm:"column:price;not null" json:"price"`
	Rarity        string    `gorm:"column:rarity;type:varchar(20)" json:"rarity"`
	SpecialEffect *string   `gorm:"column:special_effect;type:text" json:"special_effect,omitempty"`
	CreatedAt     time.Time `gorm:"column:created_at;autoCreateTime;default:CURRENT_TIMESTAMP" json:"created_at"`
}

func (Armor) TableName() string {
	return "armors"
}
