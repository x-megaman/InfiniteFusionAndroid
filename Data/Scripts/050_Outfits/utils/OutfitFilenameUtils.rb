#Naked sprites
BASE_FOLDER = "base"
BASE_OVERWORLD_FOLDER = "overworld"
BASE_TRAINER_FOLDER = "trainer"

def getBaseOverworldSpriteFilename(action = "walk", skinTone = "default")
  base_path = Settings::PLAYER_GRAPHICS_FOLDER + BASE_FOLDER + "/" + BASE_OVERWORLD_FOLDER
  dynamic_path = _INTL("/{1}/{2}_{1}", skinTone, action)
  full_path = base_path + dynamic_path
  return full_path if pbResolveBitmap(full_path)
  return getBaseOverworldSpriteFilename(action) if skinTone != "default" #try again with default skintone
  return nil
end

def getBaseTrainerSpriteFilename(skinTone = "default")
  base_path = Settings::PLAYER_GRAPHICS_FOLDER + BASE_FOLDER + "/" + BASE_TRAINER_FOLDER
  dynamic_path = _INTL("/{1}_{2}", BASE_TRAINER_FOLDER, skinTone)
  full_path = base_path + dynamic_path
  return full_path if pbResolveBitmap(full_path)
  return getBaseTrainerSpriteFilename() #default skintone
end

### OUTFIT #

def get_clothes_sets_list_path()
  return Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_CLOTHES_FOLDER
end

def getOverworldOutfitFilename(outfit_id, action="walk")
  base_path = Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_CLOTHES_FOLDER
  dynamic_path = _INTL("/{1}/", outfit_id)
  filename = _INTL(Settings::PLAYER_CLOTHES_FOLDER + "_{1}_{2}", action, outfit_id)
  full_path = base_path + dynamic_path + filename
  #echoln full_path
  return full_path
end

def getTrainerSpriteOutfitFilename(outfit_id)
  return getOverworldOutfitFilename(outfit_id, BASE_TRAINER_FOLDER)
end

#### HAIR

def get_hair_sets_list_path()
  return Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_HAIR_FOLDER
end


# Input: red_a
# Output: ["1","red"]
def getSplitHairFilenameAndVersionFromID(hairstyle_id)
  return "" if !hairstyle_id
  hairstyle_id= hairstyle_id.to_s
  return hairstyle_id.split("_")
end

def getFullHairId(hairstyle,version)
  return _INTL("{1}_{2}",version,hairstyle)

end

def getOverworldHairFilename(hairstyle_id)
  # matches = hairstyle_id.to_s.match(/\A(\d+)([A-Za-z])?\z/)
  # return "" if !matches
  # hair_id = matches[1]
  # version = matches.length > 1 ? matches[2] : "a"
  hairstyle_split = getSplitHairFilenameAndVersionFromID(hairstyle_id)
  name= hairstyle_split[-1]
  version= hairstyle_split[-2]

  # match_data = hairstyle_id.match(/(\d+)_/)
  # version = match_data[0].to_i if match_data


  base_path = Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_HAIR_FOLDER
  dynamic_path = _INTL("/{1}/", name)
  filename = _INTL(Settings::PLAYER_HAIR_FOLDER + "_{1}_{2}",version, name)
  #filename += version if version
  full_path = base_path + dynamic_path + filename
  return full_path
end

def getTrainerSpriteHairFilename(hairstyle_id)
  # matches = hairstyle_id.to_s.match(/\A(\d+)([A-Za-z])?\z/)
  # return "" if !matches
  # hair_id = matches[1]
  # version = matches.length > 1 ? matches[2] : "a"
  return "" if !hairstyle_id
  hairstyle_id= hairstyle_id.to_s
  hairstyle_split= hairstyle_id.split("_")
  name= hairstyle_split[-1]
  version= hairstyle_split[-2]

  # match_data = hairstyle_id.match(/(\d+)_/)
  # version = match_data[0].to_i if match_data

  base_path = Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_HAIR_FOLDER
  dynamic_path = _INTL("/{1}/", name)
  filename = _INTL(Settings::PLAYER_HAIR_FOLDER + "_trainer_{1}_{2}",version, name)
  #filename += version if version
  full_path = base_path + dynamic_path + filename
  return full_path
end

####  HATS
#
def get_hats_sets_list_path()
  return Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_HAT_FOLDER
end

def getOverworldHatFilename(hat_id)
  base_path = Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_HAT_FOLDER
  dynamic_path = _INTL("/{1}/", hat_id)
  filename = _INTL(Settings::PLAYER_HAT_FOLDER + "_{1}", hat_id)
  full_path = base_path + dynamic_path + filename
  return full_path
end

def getTrainerSpriteHatFilename(hat_id)
  base_path = Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_HAT_FOLDER
  dynamic_path = _INTL("/{1}/", hat_id)
  filename = _INTL(Settings::PLAYER_HAT_FOLDER + "_trainer_{1}", hat_id)
  full_path = base_path + dynamic_path + filename
  return full_path
end

def getTrainerSpriteBallFilename(pokeball)
  base_path = Settings::PLAYER_GRAPHICS_FOLDER + Settings::PLAYER_BALL_FOLDER

  return base_path + "/" + pokeball.to_s
end