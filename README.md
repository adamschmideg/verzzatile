# verzzatile

## Background
- [A Graph-Theoretic Introduction to Ted Nelson's Zzstructures, by McGuffin](https://www.dgp.utoronto.ca/~mjmcguff/research/zigzag/)
- [Welcome to ZigZag](https://xanadu.com/zigzag/tutorial/ZZwelcome.html)
- [ZigZag® and Its Structure](https://xanadu.com/zigzag/ZZdnld/)
- [Papers - Zz-structures](https://zzstructure.uniud.it/papers/)
- [A ternary representation of a zzstructure](https://www.researchgate.net/figure/A-ternary-representation-of-a-zzstructure-3-A-BOTTOM-UP-APPROACH-So-we-now-return-to_fig2_221267397)
- [Home - Zz-structures](https://zzstructure.uniud.it/)

## Similar projects
- [boris-s/yzz: Domain model of Ted Nelson's zz-structures.](https://github.com/boris-s/yzz)
- [enkiv2/ix: A bootable standalone zzstructure editor (or zigzag-based operating system) for the x86](https://github.com/enkiv2/ix)
- [urcoilbisurco/zzstructure: ruby implementation of Ted Nelson's zzstructure.](https://github.com/urcoilbisurco/zzstructure)
- [timthelion/petgraph-zzstructure: zzstructure and pmzzs support for petgraph](https://github.com/timthelion/petgraph-zzstructure)
- [Zzstructure Emulator | Hackaday](https://hackaday.com/2011/07/12/zzstructure-emulator/)
- [Set Your Data and Code Free from the Constraints of Hierarchies and Tables](https://www.codeproject.com/articles/82138/set-your-data-and-code-free-from-the-constraints-o)

## Short description
Here are the operations that change the zzstructure. Note that the errors messages and the primary and secondary cursors
are part of the zzstructure.

### Navigation (Cursor Movements)
These commands are for navigating the zzstructure. They allow you to move the primary and secondary cursors to different
cells. The primary cursor is the one that is used to perform operations, unless otherwise specified.

- `>`: Move to the next cell.
- `<`: Move to the previous cell.
- `^`: Move to the first cell.
- `$`: Move to the last cell.
- `@`: Go home (move to the origin cell and set the default dimension).
- `#X`: Change dimension to X. If X doesn't exist, create it.
- `~`: Swap primary and secondary cursors.
 
### Changing Data
These operations involve modifying cell values or the connections between cells.

- `,value`: Add a new cell at the primary cursor with the specified value. Then move to the new cell. You can add
  multiple consecutive cells at once by separating the values with commas.
- `&`: Connect the cell at the primary cursor with the cell at the secondary cursor in the dimension of the primary
  cursor.

### Reading
Commands in this category are designed to read or retrieve information from the zzstructure without making any changes.
Reads don't affect the cursors.

- `=`: Get the value of the cell at the primary cursor.
- `==`: Get the values along the path from the primary cursor along the next cells.
- `===`: Read all cells along a path, from the first to the last cell, in the cursor's dimension. This path includes the
  cursor.