package modules

const (
	RarityCommon    = "обычный"
	RarityUncommon  = "необычный"
	RarityRare      = "редкий"
	RarityEpic      = "эпический"
	RarityLegendary = "легендарный"
)

func GetRarityList() []string {
	return []string{
		RarityCommon,
		RarityUncommon,
		RarityRare,
		RarityEpic,
		RarityLegendary,
	}
}

func ValidateRarity(rarity string) bool {
	for _, validRarity := range GetRarityList() {
		if rarity == validRarity {
			return true
		}
	}
	return false
}
