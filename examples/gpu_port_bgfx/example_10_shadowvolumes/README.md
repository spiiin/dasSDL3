# 10_shadowvolumes — bgfx port

Entry point: [main.das](main.das). See the [group guide](../README.md) for
controls, upstream correspondence, backend selection and runner requirements.

- [shadowvolumes_app.das](shadowvolumes_app.das) — application implementation.
- [shadowvolumes_geometry.das](shadowvolumes_geometry.das) — application implementation.
- [shadowvolumes_scene.das](shadowvolumes_scene.das) — application implementation.
- [shadowvolumes_topology.das](shadowvolumes_topology.das) — application implementation.
- [shadowvolume_shaders.das](shaders/shadowvolume_shaders.das) — shader DSL.

Shared modules used by this example:

- [common/mesh_data.das](../common/mesh_data.das)
- [common/port_geometry.das](../common/port_geometry.das)
- [common/stencil/shaders/stencil_scene_shaders.das](../common/stencil/shaders/stencil_scene_shaders.das)
- [common/stencil/shaders/stencil_shaders.das](../common/stencil/shaders/stencil_shaders.das)
- [common/stencil/stencil_scene_support.das](../common/stencil/stencil_scene_support.das)
- [common/stencil/stencil_support.das](../common/stencil/stencil_support.das)
