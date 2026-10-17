# Bunny asset

`bunny.msh` is converted from bgfx's `examples/assets/meshes/bunny.obj` at
commit `7e3060ccb97959dcda3f091b96d82515197028e0`; source and output SHA-256
are recorded in `bunny.json`. This is the Stanford Bunny, from the Stanford
University Computer Graphics Laboratory (zippered reconstruction).

Model terms are separate from the bgfx code license. See the
[Stanford 3D Scanning Repository, acknowledgement and usage terms](https://graphics.stanford.edu/data/3Dscanrep/).
The repository permits research and free redistribution with attribution;
commercial use requires permission. This example asset is not relicensed BSD.

Rebuild: `python tools/build_mesh_asset.py`. With `--source path/to/bunny.obj`
the conversion is offline; `--check` compares the asset and manifest exactly.
Normal builds and application startup never download or convert anything.

MSH1 is an example-local little-endian format:

- 16-byte header: ASCII `MSH1`, uint32 vertex count, uint32 index count, uint32 stride (24).
- Vertex payload: float32 position xyz and signed normal xyz, interleaved.
- Index payload: uint32 triangle indices, without padding or compression.

It contains 34,834 unique position/normal pairs and 69,451 triangles. The converter
keeps face winding and normals; it does not implement bgfx's geometry compiler,
compressed mesh chunks, materials or bounding volumes. `mesh_data.das` validates
the header, counts, payload length, finite vertex values and every index before
upload. This format is intended only for the bundled asset, not untrusted files
of arbitrary size: file loading itself occurs before the decoder's count limits.

The closed low-poly bunny in `../assets/bunny_decimated.msh` is another version
of the same Stanford model, from bgfx's `bunny_decimated.obj` at the same commit;
the attribution and model terms above also apply to it. Its source/output hashes
are in `../assets/manifest.json`. Rebuild it with `tools/build_bgfx_11_14_assets.py`.
The accompanying `.adj` file caches the opposite triangle for each edge; conversion
rejects open/nonmanifold meshes after welding equal positions. The shadow-volume
example uses this closed mesh rather than treating the original open bunny as closed.
