# SM-PreserveEntity
Extra S_PreserveEnts.

# Features
The plugin dhooks 2 functions `RoundCleanupShouldIgnore( CBaseEntity *pEnt )` and `ShouldCreateEntity( const char *pszClassName )`. As the hl2sdk comment says:

> override this to prevent removal of game specific entities that need to persist

Edit `configs/preserve_entities_classname.cfg` with classname to prevent certain type of entity from being removal and creating between rounds.

This plugins should support all hl2sdk games. But the gamedata file only contains offsets from TF2. Since they are all virtual functions you can get your own offsets from [asherkin's VTable Dumper](https://asherkin.github.io/vtable).

**Warning:** The plugin is **untested**. I was making this plugin for a project but later I have a better way to do it so...
