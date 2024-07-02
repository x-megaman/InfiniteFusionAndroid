class Sprite_Player < Sprite_Character
  def initialize(viewport, character = nil)
    super
    @viewport = viewport
    @outfit_bitmap = nil
    @hat_bitmap = nil

    hatFilename = ""
    hairFilename = ""
    @hair = Sprite_Hair.new(self, hairFilename, @character_name, @viewport)
    @hat = Sprite_Hat.new(self, hatFilename, @character_name, @viewport)

    @previous_skinTone = 0

    @current_bitmap = nil
    @previous_action =nil
    getClothedPlayerSprite(true)
  end

  def updateCharacterBitmap
    skinTone = $Trainer.skin_tone ? $Trainer.skin_tone : 0
    baseBitmapFilename = getBaseOverworldSpriteFilename(@character_name, skinTone)
    if !pbResolveBitmap(baseBitmapFilename)
      baseBitmapFilename = Settings::PLAYER_GRAPHICS_FOLDER + @character_name
    end
    AnimatedBitmap.new(baseBitmapFilename, @character_hue)
  end

  def applyDayNightTone
    super
    pbDayNightTint(@hat.sprite) if @hat && @hat.sprite.bitmap
    pbDayNightTint(@hair.sprite) if @hair && @hair.sprite.bitmap
  end

  def opacity=(value)
    super
    @hat.sprite.opacity= value if @hat && @hat.sprite.bitmap
    @hair.sprite.opacity= value if @hair && @hair.sprite.bitmap
  end

  def getClothedPlayerSprite(forceUpdate=false)
    if @previous_action != @character_name || forceUpdate
      @current_bitmap = generateClothedBitmap
    end
    @previous_action = @character_name
    @hair.animate(@character_name) if @hair
    @hat.animate(@character_name) if @hat
    return @current_bitmap
  end


  def generateClothedBitmap()
    @charbitmap.bitmap.clone #nekkid sprite
    baseBitmap = @charbitmap.bitmap.clone #nekkid sprite

    outfitFilename = getOverworldOutfitFilename($Trainer.clothes, @character_name) #
    outfitFilename = getOverworldOutfitFilename(Settings::PLAYER_TEMP_OUTFIT_FALLBACK) if !pbResolveBitmap(outfitFilename)
    hairFilename = getOverworldHairFilename($Trainer.hair)
    hatFilename = getOverworldHatFilename($Trainer.hat)

    hair_color_shift = $Trainer.hair_color
    hat_color_shift = $Trainer.hat_color
    clothes_color_shift = $Trainer.clothes_color

    hair_color_shift = 0 if !hair_color_shift
    hat_color_shift = 0 if !hat_color_shift
    clothes_color_shift = 0 if !clothes_color_shift
    @hair.update(@character_name, hairFilename, hair_color_shift) if @hair
    @hat.update(@character_name, hatFilename, hat_color_shift) if @hat

    if !pbResolveBitmap(outfitFilename)
      raise "No temp clothes graphics available"
    end

    outfitBitmap = AnimatedBitmap.new(outfitFilename, clothes_color_shift) if pbResolveBitmap(outfitFilename) #pbLoadOutfitBitmap(outfitFilename) if pbResolveBitmap(outfitFilename)
    baseBitmap.blt(0, 0, outfitBitmap.bitmap, outfitBitmap.bitmap.rect) if outfitBitmap
    @previous_action = @character_name
    return baseBitmap
  end

  def positionHair(baseBitmap, hairBirmap, offset)
    baseBitmap.blt(offset[0], offset[1], hairBirmap, hairBirmap.rect)
  end


  def update
    super
  end

  def dispose
    super
    @hat.dispose if @hat
    @hair.dispose if @hair
  end

  def pbLoadOutfitBitmap(outfitFileName)
    begin
      outfitBitmap = RPG::Cache.load_bitmap("", outfitFileName)
      return outfitBitmap
    rescue
      return nil
    end
  end
end
