options gen2
options stack = 262144
require ../common/animation_app.das
[export]
def main(smoke : bool) : int {return run_animated(32,smoke)}
