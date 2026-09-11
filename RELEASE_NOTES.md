# ForgeBuild 1.2.10 — Drawing Tool Startup Fix

ForgeBuild v1.2.10 fixes the error that prevented Wall Builder and Floor Builder drawing tools from starting after placement controls were added.

## Fixed

- Fixed `invalid value for Float(): "line"` when starting the Wall Builder.
- Preserved placement modes such as Line, Polyline, Rectangle, Arc, Polygon, and Circle as tool settings instead of treating them as numeric dimensions.
- Preserved snap toggles and wall alignment values as tool settings.
- Kept actual dimensions, snap angles, and snap distances normalized as numeric values.
- Applied the correction to both Wall Builder and Floor Builder.
- Added regression coverage for placement-control option handling.

## Installation

Use ForgeBuild's **Check for Updates** button, or download and install `ForgeBuild-v1.2.10.rbz` from this release.
