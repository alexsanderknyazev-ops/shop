package service

import (
	"inventory/database"
	"inventory/modules"
)

func GetAllWeapon() ([]modules.Weapon, error) {
	db := database.GetDB()
	if db == nil {
		return nil, nil
	}
	var weapons []modules.Weapon

	result := db.Find(&weapons)

	return weapons, result.Error
}
