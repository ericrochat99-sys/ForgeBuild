# ForgeBuild 0.4.0 — Building Assembly Architecture

ForgeBuild is now organized around Floor, Wall, and Roof builders instead of individual CSI trades.

Existing slab and equipment-pad tools are available in Floor Builder. Existing CMU, brick, veneer, lintel, bond-beam, grout, and reinforcing tools are available in Wall Builder. Their CSI metadata remains intact for estimating.

Generated objects now carry schema-versioned assembly parameters and parent/child fields. A shared regeneration dispatcher establishes the foundation for upcoming Edit and Regenerate commands. Roof Builder is registered now, with production roof geometry scheduled after the Floor and Wall milestones.
