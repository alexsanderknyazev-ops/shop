package service

import (
	"inventory/database"
	"inventory/modules"
)

func GetAllArmor() ([]modules.Armor, error) {
	db := database.GetDB()
	if db == nil {
		return nil, nil
	}
	var armor []modules.Armor

	result := db.Find(&armor)

	return armor, result.Error
}
