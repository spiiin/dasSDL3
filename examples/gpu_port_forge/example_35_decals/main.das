options gen2
options stack = 262144
require ../common/decal_app.das
[export]
def main(smoke : bool) : int {return run_decals(smoke)}
