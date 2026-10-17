# Asset attribution

These are altered example ports, not the original forge-gpu distribution.
Upstream snapshot: [31f44fce](https://github.com/Nebulavenus/forge-gpu/tree/31f44fce9b69cb124b38c1bc90177ef17f1342c8).

- Lesson code/HLSL equations: Rosy Game Studio, copyright 2025, Zlib;
  see [LICENSE-forge.txt](LICENSE-forge.txt).
- Suzanne mesh and textures: Blender Foundation, CC0 1.0, as credited by forge-gpu.
- BoxTextured: Khronos glTF Sample Assets, CC BY 4.0, as credited by forge-gpu.
- CesiumMilkTruck: Cesium, CC BY 4.0, as credited by forge-gpu.
- Duck: copyright 2006 Sony; SCEA Shared Source License 1.0,
  [full license](LICENSE-SCEA.txt), [upstream notice](LICENSE-Duck.txt).
- Space Shuttle model and diffuse texture: Microsoft, CC Attribution,
  [original asset](https://sketchfab.com/3d-models/space-shuttle-0b4ef1a8fdd54b7286a2a374ac5e90d7),
  as credited in forge-gpu lesson 14.
- Milky Way panorama/cubemap: ESO / S. Brunier,
  [The Milky Way panorama](https://www.eso.org/public/images/eso0932a/), CC BY 4.0,
  as credited in forge-gpu lesson 14. The six PNG faces are copied unchanged.

[CC BY 4.0 terms](https://creativecommons.org/licenses/by/4.0/),
[CC0 terms](https://creativecommons.org/publicdomain/zero/1.0/).

Changes: baked static node transforms, FGM1 vertex/index representation, OBJ UV
conversion, a material atlas for the truck, and SDL/daScript DSL application ports.
Input/output hashes and the pinned upstream commit are in assets/sources.json.
