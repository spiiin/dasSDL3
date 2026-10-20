options gen2
options stack = 262144
require ../common/pick_app.das
[export]
def main(smoke : bool) : int {return run_pick(smoke)}
