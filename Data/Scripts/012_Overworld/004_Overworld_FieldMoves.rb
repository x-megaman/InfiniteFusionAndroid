#===============================================================================
# Hidden move handlers
#===============================================================================
module HiddenMoveHandlers
  CanUseMove = MoveHandlerHash.new
  ConfirmUseMove = MoveHandlerHash.new
  UseMove = MoveHandlerHash.new

  def self.addCanUseMove(item, proc)
    ; CanUseMove.add(item, proc);
  end

  def self.addConfirmUseMove(item, proc)
    ; ConfirmUseMove.add(item, proc);
  end

  def self.addUseMove(item, proc)
    ; UseMove.add(item, proc);
  end

  def self.hasHandler(item)
    return CanUseMove[item] != nil && UseMove[item] != nil
  end

  # Returns whether move can be used
  def self.triggerCanUseMove(item, pokemon, showmsg)
    return false if !CanUseMove[item]
    return CanUseMove.trigger(item, pokemon, showmsg)
  end

  # Returns whether the player confirmed that they want to use the move
  def self.triggerConfirmUseMove(item, pokemon)
    return true if !ConfirmUseMove[item]
    return ConfirmUseMove.trigger(item, pokemon)
  end

  # Returns whether move was used
  def self.triggerUseMove(item, pokemon)
    return false if !UseMove[item]
    return UseMove.trigger(item, pokemon)
  end
end

def pbCanUseHiddenMove?(pkmn, move, showmsg = true)
  return HiddenMoveHandlers.triggerCanUseMove(move, pkmn, showmsg)
end

def pbConfirmUseHiddenMove(pokemon, move)
  return HiddenMoveHandlers.triggerConfirmUseMove(move, pokemon)
end

def pbUseHiddenMove(pokemon, move)
  return HiddenMoveHandlers.triggerUseMove(move, pokemon)
end

# Unused
def pbHiddenMoveEvent
  Events.onAction.trigger(nil)
end

def pbCheckHiddenMoveBadge(badge = -1, showmsg = true)
  return true if badge < 0 # No badge requirement
  return true if $DEBUG
  if (Settings::FIELD_MOVES_COUNT_BADGES) ? $Trainer.badge_count >= badge : $Trainer.badges[badge]
    return true
  end
  pbMessage(_INTL("Sorry, a new Badge is required.")) if showmsg
  return false
end

#===============================================================================
# Hidden move animation
#===============================================================================
def pbHiddenMoveAnimation(pokemon)
  return false if !pokemon
  viewport = Viewport.new(0, 0, 0, 0)
  viewport.z = 99999
  bg = Sprite.new(viewport)
  bg.bitmap = RPG::Cache.picture("hiddenMovebg")
  sprite = PokemonSprite.new(viewport)
  sprite.setOffset(PictureOrigin::Center)
  sprite.setPokemonBitmap(pokemon)
  sprite.z = 1
  sprite.visible = false
  strobebitmap = AnimatedBitmap.new("Graphics/Pictures/hiddenMoveStrobes")
  strobes = []
  15.times do |i|
    strobe = BitmapSprite.new(26 * 2, 8 * 2, viewport)
    strobe.bitmap.blt(0, 0, strobebitmap.bitmap, Rect.new(0, (i % 2) * 8 * 2, 26 * 2, 8 * 2))
    strobe.z = ((i % 2) == 0 ? 2 : 0)
    strobe.visible = false
    strobes.push(strobe)
  end
  strobebitmap.dispose
  interp = RectInterpolator.new(
    Rect.new(0, Graphics.height / 2, Graphics.width, 0),
    Rect.new(0, (Graphics.height - bg.bitmap.height) / 2, Graphics.width, bg.bitmap.height),
    Graphics.frame_rate / 4)
  ptinterp = nil
  phase = 1
  frames = 0
  strobeSpeed = 64 * 20 / Graphics.frame_rate
  loop do
    Graphics.update
    Input.update
    sprite.update
    case phase
    when 1 # Expand viewport height from zero to full
      interp.update
      interp.set(viewport.rect)
      bg.oy = (bg.bitmap.height - viewport.rect.height) / 2
      if interp.done?
        phase = 2
        ptinterp = PointInterpolator.new(
          Graphics.width + (sprite.bitmap.width / 2), bg.bitmap.height / 2,
          Graphics.width / 2, bg.bitmap.height / 2,
          Graphics.frame_rate * 4 / 10)
      end
    when 2 # Slide Pokémon sprite in from right to centre
      ptinterp.update
      sprite.x = ptinterp.x
      sprite.y = ptinterp.y
      sprite.visible = true
      if ptinterp.done?
        phase = 3
        pokemon.play_cry
        frames = 0
      end
    when 3 # Wait
      frames += 1
      if frames > Graphics.frame_rate * 3 / 4
        phase = 4
        ptinterp = PointInterpolator.new(
          Graphics.width / 2, bg.bitmap.height / 2,
          -(sprite.bitmap.width / 2), bg.bitmap.height / 2,
          Graphics.frame_rate * 4 / 10)
        frames = 0
      end
    when 4 # Slide Pokémon sprite off from centre to left
      ptinterp.update
      sprite.x = ptinterp.x
      sprite.y = ptinterp.y
      if ptinterp.done?
        phase = 5
        sprite.visible = false
        interp = RectInterpolator.new(
          Rect.new(0, (Graphics.height - bg.bitmap.height) / 2, Graphics.width, bg.bitmap.height),
          Rect.new(0, Graphics.height / 2, Graphics.width, 0),
          Graphics.frame_rate / 4)
      end
    when 5 # Shrink viewport height from full to zero
      interp.update
      interp.set(viewport.rect)
      bg.oy = (bg.bitmap.height - viewport.rect.height) / 2
      phase = 6 if interp.done?
    end
    # Constantly stream the strobes across the screen
    for strobe in strobes
      strobe.ox = strobe.viewport.rect.x
      strobe.oy = strobe.viewport.rect.y
      if !strobe.visible # Initial placement of strobes
        randomY = 16 * (1 + rand(bg.bitmap.height / 16 - 2))
        strobe.y = randomY + (Graphics.height - bg.bitmap.height) / 2
        strobe.x = rand(Graphics.width)
        strobe.visible = true
      elsif strobe.x < Graphics.width # Move strobe right
        strobe.x += strobeSpeed
      else
        # Strobe is off the screen, reposition it to the left of the screen
        randomY = 16 * (1 + rand(bg.bitmap.height / 16 - 2))
        strobe.y = randomY + (Graphics.height - bg.bitmap.height) / 2
        strobe.x = -strobe.bitmap.width - rand(Graphics.width / 4)
      end
    end
    pbUpdateSceneMap
    break if phase == 6
  end
  sprite.dispose
  for strobe in strobes
    strobe.dispose
  end
  strobes.clear
  bg.dispose
  viewport.dispose
  return true
end

#===============================================================================
# Cut
#===============================================================================
def pbCut
  move = :CUT
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_CUT, false) || (!$DEBUG && !movefinder)
    if $PokemonBag.pbQuantity(:MACHETE) <= 0
      pbMessage(_INTL("This tree looks like it can be cut down."))
      return false
    end
  end
  pbMessage(_INTL("This tree looks like it can be cut down!\1"))
  if pbConfirmMessage(_INTL("Would you like to cut it?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    return true
  end
  return false
end

HiddenMoveHandlers::CanUseMove.add(:CUT, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_CUT, showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/cuttree/i]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:CUT, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  facingEvent = $game_player.pbFacingEvent
  if facingEvent
    pbSmashEvent(facingEvent)
  end
  next true
})

def pbSmashEvent(event)
  return if !event
  if event.name[/cuttree/i]
    pbSEPlay("Cut", 80)
    $scene.spriteset.addUserAnimation(Settings::CUT_TREE_ANIMATION_ID, event.x, event.y, false, 1)
  elsif event.name[/smashrock/i]
    pbSEPlay("Rock Smash", 80)
    $scene.spriteset.addUserAnimation(Settings::ROCK_SMASH_ANIMATION_ID, event.x, event.y, false, 1)
  end
  pbMoveRoute(event, [
    PBMoveRoute::Wait, 2,
    PBMoveRoute::TurnLeft,
    PBMoveRoute::Wait, 2,
    PBMoveRoute::TurnRight,
    PBMoveRoute::Wait, 2,
    PBMoveRoute::TurnUp,
    PBMoveRoute::Wait, 2
  ])
  pbWait(Graphics.frame_rate * 4 / 10)
  event.erase
  $PokemonMap.addErasedEvent(event.id) if $PokemonMap
end

#===============================================================================
# Dig
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:DIG, proc { |move, pkmn, showmsg|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if !escape || escape == []
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:DIG, proc { |move, pkmn|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  next false if !escape || escape == []
  mapname = pbGetMapNameFromId(escape[0])
  next pbConfirmMessage(_INTL("Want to escape from here and return to {1}?", mapname))
})

HiddenMoveHandlers::UseMove.add(:DIG, proc { |move, pokemon|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if escape
    if !pbHiddenMoveAnimation(pokemon)
      pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
    end
    pbFadeOutIn {
      $game_temp.player_new_map_id = escape[0]
      $game_temp.player_new_x = escape[1]
      $game_temp.player_new_y = escape[2]
      $game_temp.player_new_direction = escape[3]
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    }
    pbEraseEscapePoint
    next true
  end
  next false
})

def pbRockClimb
  return false if $game_player.pbFacingEvent
  move = :ROCKCLIMB
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_ROCKCLIMB, false) || (!$DEBUG && !movefinder)
    if $PokemonBag.pbQuantity(:CLIMBINGGEAR) <= 0
      return false
    end
  end

  if pbConfirmMessage(_INTL("It looks like it's possible to climb. Would you like to use Rock Climb?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    climbLedge
  end
end

def climbLedge
  if Kernel.pbJumpToward(2, true)
    $scene.spriteset.addUserAnimation(DUST_ANIMATION_ID, $game_player.x, $game_player.y, true)
    $game_player.increase_steps
    $game_player.check_event_trigger_here([1, 2])
  end
end

#===============================================================================
# Dive
#===============================================================================
def pbDive
  return false if $game_player.pbFacingEvent
  map_metadata = GameData::MapMetadata.try_get($game_map.map_id)
  return false if !map_metadata || !map_metadata.dive_map_id
  move = :DIVE
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_DIVE, false) || (!$DEBUG && !movefinder)
    if $PokemonBag.pbQuantity(:SCUBAGEAR) <= 0
      pbMessage(_INTL("The sea is deep here. A Pokémon may be able to go underwater."))
      return false
    end
  end
  if pbConfirmMessage(_INTL("The sea is deep here. Would you like to use Dive?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    if movefinder
      $Trainer.surfing_pokemon= getSpecies(movefinder.species)

      echoln movefinder.species
      echoln getSpecies(movefinder.species)
    else
      $Trainer.surfing_pokemon=nil
    end
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbFadeOutIn {
      $game_temp.player_new_map_id = map_metadata.dive_map_id
      $game_temp.player_new_x = $game_player.x
      $game_temp.player_new_y = $game_player.y
      $game_temp.player_new_direction = $game_player.direction
      $PokemonGlobal.surfing = false
      $PokemonGlobal.diving = true
      pbUpdateVehicle
      $scene.transfer_player(false)
      addWaterCausticsEffect()
      $game_map.autoplay
      $game_map.refresh
    }
    return true
  end
  return false
end

def pbSurfacing
  return if !$PokemonGlobal.diving
  return false if $game_player.pbFacingEvent
  surface_map_id = nil
  GameData::MapMetadata.each do |map_data|
    next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
    surface_map_id = map_data.id
    break
  end
  return if !surface_map_id
  move = :DIVE
  movefinder = $Trainer.get_pokemon_with_move(move)
  # if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_DIVE, false) || (!$DEBUG && !movefinder)
  #   pbMessage(_INTL("Light is filtering down from above. A Pokémon may be able to surface here."))
  #   return false
  # end
  if pbConfirmMessage(_INTL("Light is filtering down from above. Would you like to use Dive?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbFadeOutIn {
      $game_temp.player_new_map_id = surface_map_id
      $game_temp.player_new_x = $game_player.x
      $game_temp.player_new_y = $game_player.y
      $game_temp.player_new_direction = $game_player.direction
      $PokemonGlobal.surfing = true
      $PokemonGlobal.diving = false
      pbUpdateVehicle
      $scene.transfer_player(false)
      surfbgm = GameData::Metadata.get.surf_BGM
      (surfbgm) ? pbBGMPlay(surfbgm) : $game_map.autoplayAsCue
      $game_map.refresh
    }
    return true
  end
  return false
end

def pbTransferUnderwater(mapid, x, y, direction = $game_player.direction)
  pbFadeOutIn {
    $game_temp.player_new_map_id = mapid
    $game_temp.player_new_x = x
    $game_temp.player_new_y = y
    $game_temp.player_new_direction = direction
    $PokemonGlobal.diving = true
    $PokemonGlobal.surfing = false
    pbUpdateVehicle
    $scene.transfer_player(false )
    addWaterCausticsEffect()

    $game_map.autoplay
    $game_map.refresh
  }
end

Events.onAction += proc { |_sender, _e|
  if $PokemonGlobal.diving
    surface_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      surface_map_id = map_data.id
      break
    end
    if surface_map_id &&
      $MapFactory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
      #$MapFactory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_surf
      pbSurfacing
    end
  else
    pbDive if $game_player.terrain_tag.can_dive
  end
}

HiddenMoveHandlers::CanUseMove.add(:DIVE, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_DIVE, showmsg)
  if $PokemonGlobal.diving
    surface_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      surface_map_id = map_data.id
      break
    end
    if !surface_map_id ||
      !$MapFactory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
  else
    if !GameData::MapMetadata.exists?($game_map.map_id) ||
      !GameData::MapMetadata.get($game_map.map_id).dive_map_id
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
    if !$game_player.terrain_tag.can_dive
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:DIVE, proc { |move, pokemon|
  wasdiving = $PokemonGlobal.diving
  if $PokemonGlobal.diving
    dive_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      dive_map_id = map_data.id
      break
    end
  else
    map_metadata = GameData::MapMetadata.try_get($game_map.map_id)
    dive_map_id = map_metadata.dive_map_id if map_metadata
  end
  next false if !dive_map_id
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbFadeOutIn {
    $game_temp.player_new_map_id = dive_map_id
    $game_temp.player_new_x = $game_player.x
    $game_temp.player_new_y = $game_player.y
    $game_temp.player_new_direction = $game_player.direction
    $PokemonGlobal.surfing = wasdiving
    $PokemonGlobal.diving = !wasdiving
    pbUpdateVehicle
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
  next true
})

#===============================================================================
# Flash
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:FLASH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_FLASH, showmsg)
  if !GameData::MapMetadata.exists?($game_map.map_id) ||
    !(GameData::MapMetadata.get($game_map.map_id).dark_map || darknessEffectOnCurrentMap())
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $PokemonGlobal.flashUsed
    pbMessage(_INTL("Flash is already being used.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLASH, proc { |move, pokemon|
  darkness = $PokemonTemp.darknessSprite
  next false if !darkness || darkness.disposed?
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $PokemonGlobal.flashUsed = true
  radiusDiff = 8 * 20 / Graphics.frame_rate
  while darkness.radius < darkness.radiusMax
    Graphics.update
    Input.update
    pbUpdateSceneMap
    darkness.radius += radiusDiff
    darkness.radius = darkness.radiusMax if darkness.radius > darkness.radiusMax
  end
  next true
})

#===============================================================================
# Fly / Teleport
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:FLY, proc { |move, pkmn, showmsg|
  next pbCanUseFly(showmsg)
})
HiddenMoveHandlers::CanUseMove.add(:TELEPORT, proc { |move, pkmn, showmsg|
  next pbCanUseFly(showmsg)
})

HiddenMoveHandlers::UseMove.add(:FLY, proc { |move, pokemon|
  next pbFly(move, pokemon)
})
HiddenMoveHandlers::UseMove.add(:TELEPORT, proc { |move, pokemon|
  next pbFly(move, pokemon)
})

def pbCanUseFly(showmsg)
  return false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_TELEPORT, showmsg)
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    return false
  end
  if !GameData::MapMetadata.exists?($game_map.map_id) ||
    !GameData::MapMetadata.get($game_map.map_id).outdoor_map
    pbMessage(_INTL("Can't use that here.")) if showmsg
    return false
  end
  return true
end

def pbFly(move, pokemon)
  if !$PokemonTemp.flydata
    pbMessage(_INTL("Can't use that here."))
    return false
  end
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbFadeOutIn {
    $game_temp.player_new_map_id = $PokemonTemp.flydata[0]
    $game_temp.player_new_x = $PokemonTemp.flydata[1]
    $game_temp.player_new_y = $PokemonTemp.flydata[2]
    $game_temp.player_new_direction = 2
    $PokemonTemp.flydata = nil
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  }
  pbEraseEscapePoint
  return true
end

#===============================================================================
# Headbutt
#===============================================================================
def pbHeadbuttEffect(event = nil)
  event = $game_player.pbFacingEvent(true) if !event
  a = (event.x + (event.x / 24).floor + 1) * (event.y + (event.y / 24).floor + 1)
  a = (a * 2 / 5) % 10 # Even 2x as likely as odd, 0 is 1.5x as likely as odd
  b = $Trainer.public_ID % 10 # Practically equal odds of each value
  chance = 1 # ~50%
  if a == b;
    chance = 8 # 10%
  elsif a > b && (a - b).abs < 5;
    chance = 5 # ~30.3%
  elsif a < b && (a - b).abs > 5;
    chance = 5 # ~9.7%
  end
  if rand(10) >= chance
    pbMessage(_INTL("Nope. Nothing..."))
  else
    enctype = (chance == 1) ? :HeadbuttLow : :HeadbuttHigh
    if !pbEncounter(enctype)
      pbMessage(_INTL("Nope. Nothing..."))
    end
  end
end

def pbHeadbutt(event = nil)
  move = :HEADBUTT
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !$DEBUG && !movefinder
    pbMessage(_INTL("A Pokémon could be in this tree. Maybe a Pokémon could shake it."))
    return false
  end
  if pbConfirmMessage(_INTL("A Pokémon could be in this tree. Would you like to use Headbutt?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbHeadbuttEffect(event)
    return true
  end
  return false
end

HiddenMoveHandlers::CanUseMove.add(:HEADBUTT, proc { |move, pkmn, showmsg|
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/headbutttree/i]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:HEADBUTT, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  facingEvent = $game_player.pbFacingEvent
  pbHeadbuttEffect(facingEvent)
})

HiddenMoveHandlers::CanUseMove.add(:RELICSONG, proc { |move, pokemon, showmsg|
  if  !(pokemon.isFusionOf(:MELOETTA_A) || pokemon.isFusionOf(:MELOETTA_P))
    pbMessage(_INTL("It won't have any effect")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:RELICSONG, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  changeMeloettaForm(pokemon)
})

def changeMeloettaForm(pokemon)
  is_meloetta_A = pokemon.isFusionOf(:MELOETTA_A)
  is_meloetta_P = pokemon.isFusionOf(:MELOETTA_P)
  if !pokemon.isFusion?
    if is_meloetta_A
      changeSpeciesSpecific(pokemon, :MELOETTA_P)
      pbMessage(_INTL("{1} changed to the Pirouette form!", pokemon.name))
    end
    if is_meloetta_P
      changeSpeciesSpecific(pokemon, :MELOETTA_A)
      pbMessage(_INTL("{1} changed to the Aria form!", pokemon.name))
    end
    return
  end
  if is_meloetta_A && is_meloetta_P
    if pokemon.species_data.get_body_species() == :MELOETTA_A
      changeSpeciesSpecific(pokemon, :B467H466)
    else
      changeSpeciesSpecific(pokemon, :B466H467)
    end
    pbMessage(_INTL("{1} changed form!", pokemon.name))
  else
    if is_meloetta_P
    replaceFusionSpecies(pokemon, :MELOETTA_P, :MELOETTA_A)
    pbMessage(_INTL("{1} changed to the Aria form!", pokemon.name))
    end
    if is_meloetta_A
      replaceFusionSpecies(pokemon, :MELOETTA_A, :MELOETTA_P)
      pbMessage(_INTL("{1} changed to the Pirouette form!", pokemon.name))
    end
  end
end

#===============================================================================
# Rock Smash
#===============================================================================
def pbRockSmashRandomEncounter
  if $PokemonEncounters.encounter_triggered?(:RockSmash, false, false)
    pbEncounter(:RockSmash)
  end
end

def pbRockSmash
  move = :ROCKSMASH
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_ROCKSMASH, false) || (!$DEBUG && !movefinder)
    if $PokemonBag.pbQuantity(:PICKAXE) <= 0
      pbMessage(_INTL("It's a rugged rock, but a Pokémon may be able to smash it."))
      return false
    end
  end
  if pbConfirmMessage(_INTL("This rock appears to be breakable. Would you like to use Rock Smash?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    facingEvent = $game_player.pbFacingEvent(true)
    pbSEPlay("Rock Smash", 80)
    $scene.spriteset.addUserAnimation(Settings::ROCK_SMASH_ANIMATION_ID, facingEvent.x, facingEvent.y, false)
    return true
  end
  return false
end

HiddenMoveHandlers::CanUseMove.add(:ROCKSMASH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_ROCKSMASH, showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/smashrock/i]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:ROCKSMASH, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  facingEvent = $game_player.pbFacingEvent
  if facingEvent
    pbSmashEvent(facingEvent)
    pbRockSmashRandomEncounter
  end
  next true
})

#===============================================================================
# Strength
#===============================================================================
def pbStrength
  if $PokemonMap.strengthUsed
    #pbMessage(_INTL("Strength made it possible to move boulders around."))
    return false
  end
  move = :STRENGTH
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_STRENGTH, false) || (!$DEBUG && !movefinder)
    if $PokemonBag.pbQuantity(:LEVER) <= 0
      pbMessage(_INTL("It looks heavy, but a Pokémon may be able to push it aside."))
      return false
    end
  end
  pbMessage(_INTL("It looks heavy, but a Pokémon may be able to push it aside.\1"))
  if pbConfirmMessage(_INTL("Would you like to use Strength?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbMessage(_INTL("{1}'s Strength made it possible to move boulders around!", speciesname))
    $PokemonMap.strengthUsed = true
    return true
  end
  return false
end

Events.onAction += proc { |_sender, _e|
  facingEvent = $game_player.pbFacingEvent
  pbStrength if facingEvent && facingEvent.name[/strengthboulder/i]
}

HiddenMoveHandlers::CanUseMove.add(:STRENGTH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_STRENGTH, showmsg)
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength is already being used.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:STRENGTH, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!\1", pokemon.name, GameData::Move.get(move).name))
  end
  pbMessage(_INTL("{1}'s Strength made it possible to move boulders around!", pokemon.name))
  $PokemonMap.strengthUsed = true
  next true
})

#===============================================================================
# Surf
#===============================================================================
def pbSurf
  return false if $game_player.pbFacingEvent
  return false if $game_player.pbHasDependentEvents?
  return false if $PokemonGlobal.diving || $PokemonGlobal.surfing
  move = :SURF
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_SURF, false) || (!$DEBUG && !movefinder)
    if $PokemonBag.pbQuantity(:SURFBOARD) <= 0
      return false
    end
  end
  if $PokemonSystem.quicksurf == 1
    surfbgm = GameData::Metadata.get.surf_BGM
    pbCueBGM(surfbgm, 0.5) if surfbgm
    surfingPoke = movefinder.species if movefinder
    pbStartSurfing(surfingPoke)
    return true
  end
  if pbConfirmMessage(_INTL("The water is a deep blue...\nWould you like to surf on it?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbCancelVehicles
    pbHiddenMoveAnimation(movefinder)
    surfbgm = GameData::Metadata.get.surf_BGM
    pbCueBGM(surfbgm, 0.5) if surfbgm && !Settings::MAPS_WITHOUT_SURF_MUSIC.include?($game_map.map_id)

    surfingPoke = movefinder.species if movefinder
    pbStartSurfing(surfingPoke)
    return true
  end
  return false
end

def pbStartSurfing(speciesID=nil)
  pbCancelVehicles
  if speciesID
    $Trainer.surfing_pokemon=getSpecies(speciesID)
  else
    $Trainer.surfing_pokemon=nil
  end
  $PokemonEncounters.reset_step_count
  $PokemonGlobal.surfing = true
  pbUpdateVehicle
  $PokemonTemp.surfJump = $MapFactory.getFacingCoords($game_player.x, $game_player.y, $game_player.direction)
  pbJumpToward
  $PokemonTemp.surfJump = nil
  $game_player.check_event_trigger_here([1, 2])
end

def pbEndSurf(_xOffset, _yOffset)
  return false if !$PokemonGlobal.surfing
  return false if $PokemonGlobal.diving

  x = $game_player.x
  y = $game_player.y
  if $game_map.terrain_tag(x, y).can_surf && !$game_player.pbFacingTerrainTag.can_surf || !$game_map.terrain_tag(x, y).can_surf
    $PokemonTemp.surfJump = [x, y]
    if pbJumpToward(1, false, true)
      $game_map.autoplayAsCue
      $game_player.increase_steps
      result = $game_player.check_event_trigger_here([1, 2])
      pbOnStepTaken(result)
    end
    $PokemonTemp.surfJump = nil
    return true

  end
  return false
end

def pbTransferSurfing(mapid, xcoord, ycoord, direction = $game_player.direction)
  pbFadeOutIn {
    $game_temp.player_new_map_id = mapid
    $game_temp.player_new_x = xcoord
    $game_temp.player_new_y = ycoord
    $game_temp.player_new_direction = direction
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
  $PokemonGlobal.surfing = true
  $PokemonGlobal.diving = false
  pbUpdateVehicle
end

Events.onAction += proc { |_sender, _e|
  next if $PokemonGlobal.surfing
  next if GameData::MapMetadata.exists?($game_map.map_id) &&
    GameData::MapMetadata.get($game_map.map_id).always_bicycle
  next if !$game_player.pbFacingTerrainTag.can_surf_freely
  pbSurf
}

#Flowers
Events.onAction += proc { |_sender, _e|
  next if !$game_player.pbFacingTerrainTag.flower
  if $game_player.pbFacingTerrainTag.flowerRed
    if $game_switches[SWITCH_ORICORIO_QUEST_IN_PROGRESS]
      oricorioEventPickFlower(:RED)
    else
      changeOricorioFlower(1)
    end
  end
  if $game_player.pbFacingTerrainTag.flowerYellow
    if $game_switches[SWITCH_ORICORIO_QUEST_IN_PROGRESS]

    else
      changeOricorioFlower(2)
    end
  end
  if $game_player.pbFacingTerrainTag.flowerPink
    if $game_switches[SWITCH_ORICORIO_QUEST_IN_PROGRESS]
      oricorioEventPickFlower(:PINK)
    else
      changeOricorioFlower(3)
    end
  end
  if $game_player.pbFacingTerrainTag.flowerBlue
    if $game_switches[SWITCH_ORICORIO_QUEST_IN_PROGRESS]
      oricorioEventPickFlower(:BLUE)
    else
      changeOricorioFlower(4)
    end
  end
}

#Trashcan
Events.onAction += proc { |_sender, _e|
  next if !$game_player.pbFacingTerrainTag.trashcan
  if $PokemonGlobal.stepcount % 25 == 0
    pbMessage(_INTL("Woah! A Pokémon jumped out of the trashcan!"))
    pbWildBattle(:TRUBBISH, 10)
    $PokemonGlobal.stepcount += 1
  end
}

HiddenMoveHandlers::CanUseMove.add(:SURF, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_SURF, showmsg)
  if $PokemonGlobal.surfing
    pbMessage(_INTL("You're already surfing.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  if GameData::MapMetadata.exists?($game_map.map_id) &&
    GameData::MapMetadata.get($game_map.map_id).always_bicycle
    pbMessage(_INTL("Let's enjoy cycling!")) if showmsg
    next false
  end
  if !$game_player.pbFacingTerrainTag.can_surf_freely ||
    !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
    pbMessage(_INTL("No surfing here!")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:SURF, proc { |move, pokemon|
  $game_temp.in_menu = false
  pbCancelVehicles
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  surfbgm = GameData::Metadata.get.surf_BGM
  pbCueBGM(surfbgm, 0.5) if surfbgm
  surfingPoke = pokemon if pokemon
  pbStartSurfing(surfingPoke)
  next true
})

#===============================================================================
# Sweet Scent
#===============================================================================
def pbSweetScent
  if $game_screen.weather_type != :None
    pbMessage(_INTL("The sweet scent faded for some reason..."))
    return
  end
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  count = 0
  viewport.color.red = 255
  viewport.color.green = 0
  viewport.color.blue = 0
  viewport.color.alpha -= 10
  alphaDiff = 12 * 20 / Graphics.frame_rate
  loop do
    if count == 0 && viewport.color.alpha < 128
      viewport.color.alpha += alphaDiff
    elsif count > Graphics.frame_rate / 4
      viewport.color.alpha -= alphaDiff
    else
      count += 1
    end
    Graphics.update
    Input.update
    pbUpdateSceneMap
    break if viewport.color.alpha <= 0
  end
  viewport.dispose
  enctype = $PokemonEncounters.encounter_type
  if enctype || !$PokemonEncounters.encounter_possible_here? ||
    !pbEncounter(enctype)
    pbMessage(_INTL("There appears to be nothing here..."))
  end
end

HiddenMoveHandlers::CanUseMove.add(:SWEETSCENT, proc { |move, pkmn, showmsg|
  next true
})

HiddenMoveHandlers::UseMove.add(:SWEETSCENT, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbSweetScent
  next true
})

#===============================================================================
# Teleport
#===============================================================================
# HiddenMoveHandlers::CanUseMove.add(:TELEPORT,proc { |move,pkmn,showmsg|
#   if !GameData::MapMetadata.exists?($game_map.map_id) ||
#      !GameData::MapMetadata.get($game_map.map_id).outdoor_map
#     pbMessage(_INTL("Can't use that here.")) if showmsg
#     next false
#   end
#   healing = $PokemonGlobal.healingSpot
#   healing = GameData::Metadata.get.home if !healing   # Home
#   if !healing
#     pbMessage(_INTL("Can't use that here.")) if showmsg
#     next false
#   end
#   if $game_player.pbHasDependentEvents?
#     pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
#     next false
#   end
#   next true
# })
#
# HiddenMoveHandlers::ConfirmUseMove.add(:TELEPORT,proc { |move,pkmn|
#   healing = $PokemonGlobal.healingSpot
#   healing = GameData::Metadata.get.home if !healing   # Home
#   next false if !healing
#   mapname = pbGetMapNameFromId(healing[0])
#   next pbConfirmMessage(_INTL("Want to return to the healing spot used last in {1}?",mapname))
# })
#
# HiddenMoveHandlers::UseMove.add(:TELEPORT,proc { |move,pokemon|
#   healing = $PokemonGlobal.healingSpot
#   healing = GameData::Metadata.get.home if !healing   # Home
#   next false if !healing
#   if !pbHiddenMoveAnimation(pokemon)
#     pbMessage(_INTL("{1} used {2}!",pokemon.name,GameData::Move.get(move).name))
#   end
#   pbFadeOutIn {
#     $game_temp.player_new_map_id    = healing[0]
#     $game_temp.player_new_x         = healing[1]
#     $game_temp.player_new_y         = healing[2]
#     $game_temp.player_new_direction = 2
#     $scene.transfer_player
#     $game_map.autoplay
#     $game_map.refresh
#   }
#   pbEraseEscapePoint
#   next true
# })

#===============================================================================
# Waterfall
#===============================================================================
def pbAscendWaterfall
  return if $game_player.direction != 8 # Can't ascend if not facing up
  terrain = $game_player.pbFacingTerrainTag
  return if !terrain.waterfall && !terrain.waterfall_crest
  oldthrough = $game_player.through
  oldmovespeed = $game_player.move_speed
  $game_player.through = true
  $game_player.move_speed = 2
  loop do
    $game_player.move_up
    terrain = $game_player.pbTerrainTag
    break if !terrain.waterfall && !terrain.waterfall_crest
  end
  $game_player.through = oldthrough
  $game_player.move_speed = oldmovespeed
end

def pbDescendWaterfall
  return if $game_player.direction != 2 # Can't descend if not facing down
  terrain = $game_player.pbFacingTerrainTag
  return if !terrain.waterfall && !terrain.waterfall_crest
  oldthrough = $game_player.through
  oldmovespeed = $game_player.move_speed
  $game_player.through = true
  $game_player.move_speed = 2
  loop do
    $game_player.move_down
    terrain = $game_player.pbTerrainTag
    break if !terrain.waterfall && !terrain.waterfall_crest
  end
  $game_player.through = oldthrough
  $game_player.move_speed = oldmovespeed
end

def pbWaterfall
  move = :WATERFALL
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_WATERFALL, false) || (!$DEBUG && !movefinder)
    if $PokemonBag.pbQuantity(:JETPACK) <= 0
      pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
      return false
    end
  end
  if pbConfirmMessage(_INTL("It's a large waterfall. Would you like to use Waterfall?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbAscendWaterfall
    return true
  end
  return false
end

Events.onAction += proc { |_sender, _e|
  terrain = $game_player.pbFacingTerrainTag
  if terrain.waterfall
    pbWaterfall
  elsif terrain.waterfall_crest
    pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
  end
}

HiddenMoveHandlers::CanUseMove.add(:WATERFALL, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_WATERFALL, showmsg)
  if !$game_player.pbFacingTerrainTag.waterfall
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:WATERFALL, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbAscendWaterfall
  next true
})

HiddenMoveHandlers::CanUseMove.add(:ROCKCLIMB, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_ROCKCLIMB, showmsg)
  if !$game_player.pbFacingTerrainTag.ledge
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

Events.onAction += proc { |_sender, _e|
  terrain = $game_player.pbFacingTerrainTag
  if terrain.ledge
    pbRockClimb
  end
}
