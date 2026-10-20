options gen2
options stack = 262144
require ../common/terrain_app.das
[export]
def main(smoke : bool) : int {return run_terrain(48,smoke)}
