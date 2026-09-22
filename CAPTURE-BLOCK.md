# Capture block

Place block `$26` (decimal 38) in a special-stage layout. HyperSonic currently
labels this entry **W block (unused)**; reload the project to see its new artwork.
The former unused W slot is reused so the block needs no additional VRAM. Existing
red/white peppermint blocks are unchanged, and no layouts were edited.

Touching the block holds Sonic at his resolved contact position in the rotating
maze, clears velocity and steering momentum, and makes him eligible to jump.
Press **A, B, or C** again to jump away from the block using the normal special-stage jump
force. Holding a jump button before touching it does not automatically release him.
Steering does not release him. The maze keeps rotating and the gameplay timer runs.
Pausing retains the hold and does not advance the release cooldown.

The same block cannot capture him for 12 active gameplay frames after release;
other capture blocks can. The original block remains solid during that interval.

Artwork uses palette line 0 (assembler `Tile_Pal1`):

| Stripe | Highlight | Base | Shadow |
|---|---|---|---|
| Blue | 05 | 02 | 01 |
| Peach | 06 | 0A | 0B |

The art is `artnem/Special W.nem`, derived from the peppermint's nine tiles.
No palette values were changed. Behavior is in
`_inc/Special Stage Capture Block.asm`; adjust `sonss_capture_grace` for the
release cooldown. No new ROM version number was introduced.
