options gen2
options stack = 262144
require ../common/atlas_app.das
[export]
def main(smoke : bool) : int {return run_atlas(smoke)}
